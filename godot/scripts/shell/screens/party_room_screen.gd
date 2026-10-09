extends ShellScreen
## Expedition party room: your party (you + an optional AI ally), difficulty, start.


func screen_title() -> String:
	return "Party Room"


func back_label() -> String:
	return "Expedition"


func go_back() -> void:
	ScreenRouter.go(self, &"expedition")


func build() -> void:
	var instance: PveInstanceDefinition = game.content.instance(game.selected_instance)
	var column: VBoxContainer = UiKit.vbox(16)
	content_root.add_child(column)
	var header: PanelContainer = UiKit.panel()
	column.add_child(header)
	header.add_child(UiKit.label("%s  ·  %s  ·  %d stages" % [instance.display_name, PveInstanceDefinition.difficulty_name(game.selected_difficulty), instance.stages.size()], 28, UiKit.GOLD, true))
	var party_row: HBoxContainer = UiKit.hbox(20)
	party_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(party_row)
	party_row.add_child(_slot("%s (you)" % game.profile.nickname, "Level %d · Power %d" % [game.profile.level, game.stats().combat_power], game.profile.outfit, true))
	if game.party_with_ally:
		party_row.add_child(_slot("Ally (AI)", "Boulder Mortar · supports from range", 1 - game.profile.outfit, true))
	else:
		party_row.add_child(_slot("Open slot", "Invite an AI ally", 0, false))
	party_row.add_child(_slot("Open slot", "Friends join in the online version", 0, false))
	var bottom: HBoxContainer = UiKit.hbox(16)
	column.add_child(bottom)
	bottom.add_child(UiKit.button("Remove ally" if game.party_with_ally else "Add AI ally", func() -> void:
		game.party_with_ally = not game.party_with_ally
		ScreenRouter.go(self, &"party_room"), "blue", Vector2(240, 60)))
	bottom.add_child(UiKit.label("HP carries over between stages. Healing Kits: %d (key 1 in battle)." % game.profile.inventory.count(&"item_heal"), 18, UiKit.TEXT_DIM))
	bottom.add_child(UiKit.spacer())
	bottom.add_child(UiKit.button("START EXPEDITION", _start, "primary", Vector2(360, 70)))


func _slot(title: String, subtitle: String, outfit: int, filled: bool) -> Control:
	var panel: PanelContainer = UiKit.inner_panel()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var column: VBoxContainer = UiKit.vbox(8)
	panel.add_child(column)
	if filled:
		var preview := CharacterPreview.new()
		preview.custom_minimum_size = Vector2(260, 300)
		preview.outfit = outfit
		preview.weapon_art = &"mortar" if title.begins_with("Ally") else &"launcher"
		if not title.begins_with("Ally"):
			preview.show_profile(game.profile, game.content)
		column.add_child(preview)
	column.add_child(UiKit.label(title, 24, UiKit.GOLD if filled else UiKit.TEXT_DIM, true))
	column.add_child(UiKit.label(subtitle, 16, UiKit.TEXT_DIM))
	return panel


func _start() -> void:
	game.pending_battle = game.build_pve_setup(game.selected_instance, game.selected_difficulty, game.party_with_ally)
	ScreenRouter.go(self, &"battle")
