extends ShellScreen
## Start screen: continue, new character, settings, developer tools.

var _confirm_reset: bool = false
var _reset_button: Button


func has_top_bar() -> bool:
	return false


func needs_profile() -> bool:
	return false


func _style_backdrop(backdrop: ScreenBackdrop) -> void:
	backdrop.top_color = Color(0.25, 0.45, 0.92)
	backdrop.bottom_color = Color(0.95, 0.82, 0.6)


func build() -> void:
	var center := CenterContainer.new()
	content_root.add_child(center)
	var column: VBoxContainer = UiKit.vbox(18)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	center.add_child(column)

	var logo: Label = UiKit.label("ARTILLERY GAME", 92, UiKit.GOLD, true)
	logo.add_theme_constant_override("outline_size", 18)
	logo.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(logo)
	var tag: Label = UiKit.label("Reference Clone  ·  offline build  ·  original proxy art", 22, UiKit.TEXT)
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(tag)

	var showcase := HBoxContainer.new()
	showcase.alignment = BoxContainer.ALIGNMENT_CENTER
	showcase.add_theme_constant_override("separation", 80)
	column.add_child(showcase)
	for outfit in 2:
		var preview := CharacterPreview.new()
		preview.custom_minimum_size = Vector2(210, 240)
		preview.outfit = outfit
		preview.weapon_art = [&"launcher", &"spark"][outfit]
		showcase.add_child(preview)

	var panel: PanelContainer = UiKit.panel()
	column.add_child(panel)
	var buttons: VBoxContainer = UiKit.vbox(12)
	panel.add_child(buttons)
	if game.has_profile():
		buttons.add_child(UiKit.button("▶  Continue as %s (Lv %d)" % [game.profile.nickname, game.profile.level], func() -> void: ScreenRouter.go(self, &"city"), "primary", Vector2(460, 64)))
		buttons.add_child(UiKit.button("New character", func() -> void: ScreenRouter.go(self, &"character"), "blue", Vector2(460, 52)))
	else:
		buttons.add_child(UiKit.button("▶  Start game", func() -> void: ScreenRouter.go(self, &"character"), "primary", Vector2(460, 64)))
	buttons.add_child(UiKit.button("Toggle fullscreen (F11)", DisplayControl.toggle_fullscreen, "dark", Vector2(460, 48)))
	var dev: HBoxContainer = UiKit.hbox(12)
	buttons.add_child(dev)
	dev.add_child(UiKit.button("Ballistics Lab", func() -> void: ScreenRouter.go(self, &"lab"), "dark", Vector2(224, 44)))
	_reset_button = UiKit.button("Reset local profile", _on_reset, "red", Vector2(224, 44))
	_reset_button.disabled = not game.has_profile()
	dev.add_child(_reset_button)
	buttons.add_child(UiKit.button("Quit", func() -> void: get_tree().quit(), "dark", Vector2(460, 44)))


func _on_reset() -> void:
	if not _confirm_reset:
		_confirm_reset = true
		_reset_button.text = "Click again to DELETE"
		return
	game.delete_save()
	toast("Local profile deleted")
	ScreenRouter.go(self, &"boot")
