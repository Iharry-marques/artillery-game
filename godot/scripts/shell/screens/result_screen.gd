extends ShellScreen
## Battle result: victory/defeat, statistics, EXP/Gold, level up and the classic
## "flip one of four cards" reward.

var _cards_row: HBoxContainer


func screen_title() -> String:
	return "Battle Result"


func show_back() -> bool:
	return false


func build() -> void:
	var outcome: BattleOutcome = game.last_outcome
	if outcome == null:
		ScreenRouter.go(self, &"city")
		return
	var column: VBoxContainer = UiKit.vbox(10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	content_root.add_child(column)
	var title: String = "VICTORY!" if outcome.victory else ("LEFT THE BATTLE" if outcome.surrendered else "DEFEAT")
	var banner: Label = UiKit.label(title, 80, UiKit.GOLD if outcome.victory else UiKit.RED, true)
	banner.add_theme_constant_override("outline_size", 18)
	banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(banner)
	var subtitle: String = outcome.room_name
	if outcome.mode == BattleSetup.Mode.PVE:
		subtitle += "  ·  %s  ·  stages cleared %d" % [PveInstanceDefinition.difficulty_name(outcome.difficulty), outcome.stages_cleared]
	var sub: Label = UiKit.label(subtitle, 24)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(sub)

	var row: HBoxContainer = UiKit.hbox(24)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	var stats_panel: PanelContainer = UiKit.panel()
	stats_panel.custom_minimum_size = Vector2(460, 0)
	row.add_child(stats_panel)
	var stats: VBoxContainer = UiKit.vbox(4)
	stats_panel.add_child(stats)
	stats.add_child(UiKit.label("Your battle", 26, UiKit.GOLD, true))
	for entry: Array in [["Damage dealt", str(outcome.damage_dealt)], ["Shots", str(outcome.shots)], ["Hits", str(outcome.hits)], ["Accuracy", "%d%%" % roundi(outcome.accuracy() * 100.0)], ["Kills", str(outcome.kills)], ["Healing Kits used", str(outcome.heal_items_used)]]:
		var line: HBoxContainer = UiKit.hbox()
		stats.add_child(line)
		var key: String = entry[0]
		var value: String = entry[1]
		line.add_child(UiKit.label(key, 20, UiKit.TEXT_DIM))
		line.add_child(UiKit.spacer())
		line.add_child(UiKit.label(value, 20, UiKit.TEXT, true))
	var reward_panel: PanelContainer = UiKit.panel()
	reward_panel.custom_minimum_size = Vector2(460, 0)
	row.add_child(reward_panel)
	var rewards: VBoxContainer = UiKit.vbox(4)
	reward_panel.add_child(rewards)
	rewards.add_child(UiKit.label("Rewards", 26, UiKit.GOLD, true))
	var reward: Reward = game.last_reward
	rewards.add_child(UiKit.label("+%d EXP" % reward.exp, 30, UiKit.SKY, true))
	rewards.add_child(UiKit.label("+%d Gold" % reward.gold, 30, UiKit.GOLD, true))
	if game.last_levels_gained > 0:
		var level_up: Label = UiKit.label("LEVEL UP!  Now level %d" % game.profile.level, 30, UiKit.GREEN, true)
		rewards.add_child(level_up)
	rewards.add_child(UiKit.label("Level %d   EXP %d / %d" % [game.profile.level, game.profile.exp, Progression.exp_to_next(game.profile.level)], 18, UiKit.TEXT_DIM))

	if not game.last_cards.is_empty():
		var hint: Label = UiKit.label("Pick a card!", 24, UiKit.TEXT, true)
		hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(hint)
		_cards_row = UiKit.hbox(20)
		_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_child(_cards_row)
		_build_cards()

	var buttons: HBoxContainer = UiKit.hbox(16)
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(buttons)
	if outcome.mode == BattleSetup.Mode.PVP and game.current_room != null:
		buttons.add_child(UiKit.button("Back to the room", func() -> void: ScreenRouter.go(self, &"battle_room"), "blue", Vector2(260, 60)))
	if outcome.mode == BattleSetup.Mode.PVE:
		buttons.add_child(UiKit.button("Back to the Expedition", func() -> void: ScreenRouter.go(self, &"expedition"), "blue", Vector2(300, 60)))
	buttons.add_child(UiKit.button("Back to the City", func() -> void:
		game.leave_room()
		ScreenRouter.go(self, &"city"), "primary", Vector2(260, 60)))


func _build_cards() -> void:
	for child in _cards_row.get_children():
		child.queue_free()
	for i in game.last_cards.size():
		var revealed: bool = game.card_claimed >= 0
		var card := Button.new()
		card.custom_minimum_size = Vector2(150, 168)
		var face: Color = UiKit.GOLD if i == game.card_claimed else (UiKit.NAVY_LIGHT if revealed else UiKit.ORANGE)
		card.add_theme_stylebox_override("normal", UiKit.box(face, UiKit.GOLD_DARK, 14, 4, 4))
		card.add_theme_stylebox_override("hover", UiKit.box(face.lightened(0.15), UiKit.GOLD, 14, 4, 6))
		card.add_theme_stylebox_override("disabled", UiKit.box(face, UiKit.GOLD_DARK, 14, 4, 4))
		card.disabled = revealed
		if revealed:
			card.text = _card_text(game.last_cards[i])
			card.add_theme_font_size_override("font_size", 17)
			if i == game.card_claimed:
				card.add_theme_color_override("font_disabled_color", UiKit.NAVY_DEEP)
				card.add_theme_color_override("font_outline_color", Color(1, 1, 1, 0))
			card.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		else:
			card.text = "?"
			card.add_theme_font_size_override("font_size", 64)
			card.pressed.connect(func() -> void:
				var reward: Reward = game.claim_card(i)
				if reward != null:
					toast("You got %s!" % _card_text(reward))
				_build_cards())
		_cards_row.add_child(card)


static func _card_text(reward: Reward) -> String:
	if not reward.items.is_empty():
		var entry: Dictionary = reward.items[0]
		var id: StringName = entry["id"]
		var qty: int = DataReader.get_int(entry, "qty", 1)
		return "%s\nx%d" % [ContentCatalog.shared().item(id).display_name, qty]
	return "%d Gold" % reward.gold
