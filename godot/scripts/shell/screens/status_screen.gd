extends ShellScreen
## Character status: base, equipment and total attributes plus derived values
## (REFERENCE ESTIMATE formulas, labelled as such).


func screen_title() -> String:
	return "Character Status"


func build() -> void:
	var p: PlayerProfile = game.profile
	var stats: CharacterStats = game.stats()
	var row: HBoxContainer = UiKit.hbox(24)
	content_root.add_child(row)

	var left: PanelContainer = UiKit.panel()
	left.custom_minimum_size = Vector2(440, 0)
	row.add_child(left)
	var left_column: VBoxContainer = UiKit.vbox(10)
	left.add_child(left_column)
	left_column.add_child(UiKit.label(p.nickname, 36, UiKit.GOLD, true))
	left_column.add_child(UiKit.label("Level %d" % p.level, 24))
	var preview := CharacterPreview.new()
	preview.custom_minimum_size = Vector2(400, 420)
	preview.show_profile(p, game.content)
	left_column.add_child(preview)
	var exp_bar := ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(400, 22)
	exp_bar.max_value = Progression.exp_to_next(p.level)
	exp_bar.value = p.exp
	exp_bar.show_percentage = false
	exp_bar.add_theme_stylebox_override("fill", UiKit.box(UiKit.SKY, Color(0, 0, 0, 0), 6, 0))
	left_column.add_child(exp_bar)
	left_column.add_child(UiKit.label("EXP %d / %d" % [p.exp, Progression.exp_to_next(p.level)], 18, UiKit.TEXT_DIM))
	left_column.add_child(UiKit.button("Open Bag", func() -> void: ScreenRouter.go(self, &"bag"), "primary", Vector2(400, 52)))

	var right: PanelContainer = UiKit.panel()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(right)
	var column: VBoxContainer = UiKit.vbox(12)
	right.add_child(column)
	var power: Label = UiKit.label("COMBAT POWER  %d" % stats.combat_power, 40, UiKit.GOLD, true)
	column.add_child(power)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 50)
	grid.add_theme_constant_override("v_separation", 10)
	column.add_child(grid)
	for header: String in ["Attribute", "Base", "Equipment", "Total"]:
		grid.add_child(UiKit.label(header, 20, UiKit.TEXT_DIM, true))
	var names: Array[Array] = [["Attack", &"attack"], ["Defense", &"defense"], ["Agility", &"agility"], ["Luck", &"luck"], ["Harm", &"harm"], ["Armor", &"armor"], ["Bonus HP", &"hp"]]
	for entry in names:
		var title: String = entry[0]
		var field: StringName = entry[1]
		grid.add_child(UiKit.label(title, 22, UiKit.TEXT, true))
		grid.add_child(UiKit.label(str(stats.base.get_stat(field)), 22))
		grid.add_child(UiKit.label("%+d" % stats.equipment.get_stat(field), 22, UiKit.GREEN))
		grid.add_child(UiKit.label(str(stats.total.get_stat(field)), 22, UiKit.GOLD, true))
	column.add_child(HSeparator.new())
	var derived: GridContainer = GridContainer.new()
	derived.columns = 2
	derived.add_theme_constant_override("h_separation", 40)
	column.add_child(derived)
	var weapon_text: String = "Unarmed"
	if stats.weapon != null:
		weapon_text = "%s  (%s, angles %d-%d°, crater %.2f u)" % [stats.weapon.display_name, stats.weapon.weapon_style, stats.weapon.min_angle, stats.weapon.max_angle, stats.weapon.crater_radius]
	var rows: Array[Array] = [
		["Max HP", str(stats.max_hp)], ["Harm", str(stats.harm)], ["Armor", str(stats.armor)],
		["Damage at center", "%d (vs. 0 defense)" % roundi(stats.harm * (1.0 + stats.total.attack / 1000.0))],
		["Critical chance", "%.1f%%" % (stats.total.luck / 40.0)], ["Weapon", weapon_text],
	]
	for entry in rows:
		var key: String = entry[0]
		var value: String = entry[1]
		derived.add_child(UiKit.label(key, 20, UiKit.TEXT_DIM, true))
		derived.add_child(UiKit.label(value, 20))
	var note: Label = UiKit.label("Formulas are REFERENCE ESTIMATES (docs/PRODUCT_SHELL.md): base = 10 + 3 per level; HP = 950 + 50 x level + defense / 8; Combat Power is cosmetic.", 15, UiKit.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)
