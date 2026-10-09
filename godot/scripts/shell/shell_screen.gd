class_name ShellScreen
extends Control
## Base of every product screen: theme, backdrop, top bar and helpers.

var game: GameSession
var top_bar: TopBar
## Area below the top bar where screens put their content.
var content_root: MarginContainer


func _ready() -> void:
	game = GameSession.get_instance()
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if needs_profile() and not game.has_profile():
		ScreenRouter.go(self, &"boot")
		return
	var backdrop := ScreenBackdrop.new()
	_style_backdrop(backdrop)
	add_child(backdrop)
	content_root = MarginContainer.new()
	content_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_root.add_theme_constant_override("margin_left", 28)
	content_root.add_theme_constant_override("margin_right", 28)
	content_root.add_theme_constant_override("margin_top", 92 if has_top_bar() else 24)
	content_root.add_theme_constant_override("margin_bottom", 24)
	add_child(content_root)
	if has_top_bar():
		top_bar = TopBar.new()
		add_child(top_bar)
		top_bar.setup(screen_title(), show_back(), back_label())
		top_bar.back_pressed.connect(go_back)
	build()


## Override: screen content.
func build() -> void:
	pass


func screen_title() -> String:
	return ""


func has_top_bar() -> bool:
	return true


func show_back() -> bool:
	return true


func needs_profile() -> bool:
	return true


## Caption of the back button (where go_back() leads).
func back_label() -> String:
	return "City"


func go_back() -> void:
	ScreenRouter.go(self, &"city")


func _style_backdrop(_backdrop: ScreenBackdrop) -> void:
	pass


func toast(text: String, good: bool = true) -> void:
	Toast.popup_text(self, text, good)
	if top_bar != null:
		top_bar.refresh()


func refresh_top_bar() -> void:
	if top_bar != null:
		top_bar.refresh()
