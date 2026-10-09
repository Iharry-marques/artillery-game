extends ShellScreen
## Expedition Pier: dungeon selection, stages, enemies, difficulty and rewards.


func screen_title() -> String:
	return "Expedition Pier"


func _style_backdrop(backdrop: ScreenBackdrop) -> void:
	backdrop.top_color = Color(0.2, 0.5, 0.75)
	backdrop.bottom_color = Color(0.55, 0.85, 0.85)
	backdrop.hill_color = Color(0.25, 0.55, 0.65)


func build() -> void:
	var row: HBoxContainer = UiKit.hbox(20)
	content_root.add_child(row)
	var list: PanelContainer = UiKit.panel()
	list.custom_minimum_size = Vector2(420, 0)
	row.add_child(list)
	var list_column: VBoxContainer = UiKit.vbox(12)
	list.add_child(list_column)
	list_column.add_child(UiKit.label("Dungeons", 30, UiKit.GOLD, true))
	for instance in game.content.instances:
		var button: Button = UiKit.button(instance.display_name, func() -> void:
			game.selected_instance = instance.id
			ScreenRouter.go(self, &"expedition"), "primary" if instance.id == game.selected_instance else "dark", Vector2(380, 70))
		list_column.add_child(button)
	for locked: String in ["Ember Caves  (coming soon)", "Frost Spire  (coming soon)"]:
		var future: Button = UiKit.button(locked, func() -> void: pass, "dark", Vector2(380, 60))
		future.disabled = true
		list_column.add_child(future)

	var detail: PanelContainer = UiKit.panel()
	detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(detail)
	var column: VBoxContainer = UiKit.vbox(14)
	detail.add_child(column)
	var instance: PveInstanceDefinition = game.content.instance(game.selected_instance)
	column.add_child(UiKit.label(instance.display_name, 42, UiKit.GOLD, true))
	var description: Label = UiKit.label(instance.description, 20)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(description)
	column.add_child(UiKit.label("Recommended level %d   ·   %d stages" % [instance.level_required, instance.stages.size()], 18, UiKit.TEXT_DIM))
	var stages: HBoxContainer = UiKit.hbox(16)
	column.add_child(stages)
	for i in instance.stages.size():
		var stage: Dictionary = instance.stages[i]
		var card: PanelContainer = UiKit.inner_panel()
		card.custom_minimum_size = Vector2(300, 240)
		stages.add_child(card)
		var inner: VBoxContainer = UiKit.vbox(6)
		card.add_child(inner)
		var title: String = stage["title"]
		inner.add_child(UiKit.label("Stage %d" % (i + 1), 16, UiKit.TEXT_DIM))
		inner.add_child(UiKit.label(title, 22, UiKit.GOLD, true))
		var enemy_row: HBoxContainer = UiKit.hbox(4)
		inner.add_child(enemy_row)
		var enemies: Array = stage["enemies"]
		for entry: Dictionary in enemies:
			var enemy_id: StringName = entry["enemy"]
			var def: EnemyDefinition = game.content.enemy(enemy_id)
			var picture := TextureRect.new()
			picture.texture = EnemyArt.shared().texture(def.visual)
			picture.custom_minimum_size = Vector2(90, 110) if def.behavior != EnemyDefinition.Behavior.BOSS else Vector2(140, 140)
			picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			picture.tooltip_text = def.display_name
			enemy_row.add_child(picture)
	column.add_child(UiKit.label("Difficulty", 24, UiKit.TEXT, true))
	var difficulties: HBoxContainer = UiKit.hbox(12)
	column.add_child(difficulties)
	for difficulty in 3:
		var label: String = "%s\nHP x%.1f · rewards x%.1f" % [PveInstanceDefinition.difficulty_name(difficulty), PveInstanceDefinition.HP_SCALE[difficulty], PveInstanceDefinition.REWARD_SCALE[difficulty]]
		difficulties.add_child(UiKit.button(label, func() -> void:
			game.selected_difficulty = difficulty
			ScreenRouter.go(self, &"expedition"), "primary" if difficulty == game.selected_difficulty else "dark", Vector2(260, 76)))
	column.add_child(UiKit.label("Possible drops: Strengthen Stones, Horned Helm, Scale Vest, Amber Ring, element stones", 17, UiKit.TEXT_DIM))
	column.add_child(UiKit.button("ENTER  ▶", func() -> void: ScreenRouter.go(self, &"party_room"), "primary", Vector2(340, 70)))
