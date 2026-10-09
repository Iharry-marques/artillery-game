extends ShellScreen
## Character creation: nickname and outfit (no login server; local profile).

var _name_edit: LineEdit
var _outfit: int = 0
var _cards: Array[PanelContainer] = []


func has_top_bar() -> bool:
	return false


func needs_profile() -> bool:
	return false


func build() -> void:
	var center := CenterContainer.new()
	content_root.add_child(center)
	var panel: PanelContainer = UiKit.panel()
	center.add_child(panel)
	var column: VBoxContainer = UiKit.vbox(20)
	panel.add_child(column)
	column.add_child(UiKit.label("Create your character", 40, UiKit.GOLD, true))
	var row: HBoxContainer = UiKit.hbox(30)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	for outfit in 2:
		var card: PanelContainer = UiKit.inner_panel()
		card.custom_minimum_size = Vector2(300, 380)
		row.add_child(card)
		_cards.append(card)
		var inner: VBoxContainer = UiKit.vbox(8)
		card.add_child(inner)
		var preview := CharacterPreview.new()
		preview.custom_minimum_size = Vector2(260, 290)
		preview.outfit = outfit
		inner.add_child(preview)
		var pick: Button = UiKit.button("Blue outfit" if outfit == 0 else "Red outfit", func() -> void: _select(outfit), "blue" if outfit == 0 else "red", Vector2(260, 48))
		inner.add_child(pick)
	var name_row: HBoxContainer = UiKit.hbox(12)
	column.add_child(name_row)
	name_row.add_child(UiKit.label("Nickname", 24))
	_name_edit = LineEdit.new()
	_name_edit.placeholder_text = "Your name"
	_name_edit.max_length = 16
	_name_edit.custom_minimum_size = Vector2(360, 52)
	_name_edit.add_theme_font_size_override("font_size", 24)
	_name_edit.text = "Rookie"
	name_row.add_child(_name_edit)
	var buttons: HBoxContainer = UiKit.hbox(12)
	column.add_child(buttons)
	buttons.add_child(UiKit.button("◀ Back", func() -> void: ScreenRouter.go(self, &"boot"), "dark", Vector2(160, 56)))
	buttons.add_child(UiKit.spacer())
	buttons.add_child(UiKit.button("Create and enter the City ▶", _create, "primary", Vector2(380, 60)))
	_select(0)


func _select(outfit: int) -> void:
	_outfit = outfit
	for i in _cards.size():
		_cards[i].add_theme_stylebox_override("panel", UiKit.box(UiKit.NAVY_LIGHT, UiKit.GOLD if i == outfit else Color(1, 1, 1, 0.1), 14, 4 if i == outfit else 2))


func _create() -> void:
	game.delete_save()
	game.create_profile(_name_edit.text, _outfit)
	ScreenRouter.go(self, &"city")
