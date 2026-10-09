class_name UiKit
extends RefCounted
## Shared look of the product shell: a bright, rounded "classic online game"
## style built only from StyleBoxFlat (original, no external art). Reference
## resolution 1600x900; sizes below are in those units.

const NAVY: Color = Color(0.11, 0.15, 0.29)
const NAVY_LIGHT: Color = Color(0.18, 0.25, 0.44)
const NAVY_DEEP: Color = Color(0.07, 0.09, 0.18)
const GOLD: Color = Color(1.0, 0.8, 0.32)
const GOLD_DARK: Color = Color(0.72, 0.5, 0.15)
const ORANGE: Color = Color(1.0, 0.58, 0.16)
const ORANGE_DARK: Color = Color(0.78, 0.36, 0.06)
const SKY: Color = Color(0.32, 0.65, 1.0)
const SKY_DARK: Color = Color(0.16, 0.4, 0.78)
const GREEN: Color = Color(0.35, 0.82, 0.42)
const RED: Color = Color(0.95, 0.35, 0.35)
const TEXT: Color = Color(0.98, 0.98, 1.0)
const TEXT_DIM: Color = Color(0.72, 0.78, 0.9)
const OUTLINE: Color = Color(0.04, 0.05, 0.12)
const RARITY_COLORS: Array[Color] = [Color(0.75, 0.78, 0.85), Color(0.4, 0.85, 0.45), Color(0.35, 0.65, 1.0), Color(0.8, 0.45, 1.0)]

static var _theme: Theme
static var _bold: FontVariation


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 18
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_outline_color", "Label", OUTLINE)
	t.set_constant("outline_size", "Label", 4)
	t.set_stylebox("panel", "PanelContainer", box(NAVY, GOLD, 14, 3))
	t.set_stylebox("panel", "Panel", box(NAVY, GOLD, 14, 3))
	_button_styles(t, "Button", ORANGE, ORANGE_DARK)
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_hover_color", "Button", TEXT)
	t.set_color("font_pressed_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(0.75, 0.75, 0.8))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 4)
	t.set_font("font", "Button", bold_font())
	t.set_stylebox("normal", "LineEdit", box(NAVY_DEEP, SKY, 8, 2))
	t.set_stylebox("focus", "LineEdit", box(NAVY_DEEP, GOLD, 8, 2))
	t.set_color("font_color", "LineEdit", TEXT)
	t.set_stylebox("background", "ProgressBar", box(NAVY_DEEP, Color(0, 0, 0, 0), 6, 0))
	t.set_stylebox("fill", "ProgressBar", box(GREEN, Color(0, 0, 0, 0), 6, 0))
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	t.set_stylebox("panel", "TooltipPanel", box(NAVY_DEEP, GOLD, 8, 2))
	t.set_color("font_color", "TooltipLabel", TEXT)
	t.set_color("font_color", "CheckBox", TEXT)
	t.set_color("font_color", "OptionButton", TEXT)
	_button_styles(t, "OptionButton", SKY, SKY_DARK)
	_theme = t
	return t


static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.7
	return _bold


static func box(color: Color, border: Color, radius: int, border_width: int, shadow: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(10)
	if shadow > 0:
		style.shadow_color = Color(0, 0, 0, 0.35)
		style.shadow_size = shadow
	return style


static func _button_styles(t: Theme, type: String, color: Color, dark: Color) -> void:
	var normal: StyleBoxFlat = box(color, dark, 12, 3)
	normal.border_width_bottom = 6
	var hover: StyleBoxFlat = box(color.lightened(0.15), dark, 12, 3)
	hover.border_width_bottom = 6
	var pressed: StyleBoxFlat = box(dark, dark.darkened(0.2), 12, 3)
	pressed.content_margin_top = 14
	var disabled: StyleBoxFlat = box(Color(0.35, 0.37, 0.45), Color(0.25, 0.26, 0.32), 12, 3)
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())


## Applies a colour variant to one button ("primary" orange, "blue", "green", "red", "dark").
static func tint(button: Button, variant: String) -> Button:
	var colors: Dictionary = {
		"blue": [SKY, SKY_DARK], "green": [GREEN, Color(0.15, 0.55, 0.22)], "red": [RED, Color(0.6, 0.15, 0.15)],
		"dark": [NAVY_LIGHT, NAVY_DEEP], "gold": [GOLD, GOLD_DARK],
	}
	if not colors.has(variant):
		return button
	var pair: Array = colors[variant]
	var color: Color = pair[0]
	var dark: Color = pair[1]
	var normal: StyleBoxFlat = box(color, dark, 12, 3)
	normal.border_width_bottom = 6
	var hover: StyleBoxFlat = box(color.lightened(0.15), dark, 12, 3)
	hover.border_width_bottom = 6
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", box(dark, dark.darkened(0.2), 12, 3))
	return button


static func label(text: String, size: int = 18, color: Color = TEXT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if bold:
		l.add_theme_font_override("font", bold_font())
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func button(text: String, on_pressed: Callable, variant: String = "primary", min_size: Vector2 = Vector2(150, 50)) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", 20)
	b.pressed.connect(on_pressed)
	return tint(b, variant)


static func panel(color: Color = NAVY, border: Color = GOLD, radius: int = 16) -> PanelContainer:
	var p := PanelContainer.new()
	var style: StyleBoxFlat = box(color, border, radius, 3, 6)
	style.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", style)
	return p


static func inner_panel() -> PanelContainer:
	var p := PanelContainer.new()
	var style: StyleBoxFlat = box(NAVY_LIGHT, Color(1, 1, 1, 0.12), 12, 2)
	style.set_content_margin_all(12)
	p.add_theme_stylebox_override("panel", style)
	return p


static func vbox(separation: int = 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", separation)
	return v


static func hbox(separation: int = 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", separation)
	return h


static func spacer(horizontal: bool = true) -> Control:
	var c := Control.new()
	if horizontal:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


static func rarity_color(rarity: int) -> Color:
	return RARITY_COLORS[clampi(rarity, 0, RARITY_COLORS.size() - 1)]


static func currency_color(currency: CurrencyWallet.Currency) -> Color:
	return [GOLD, Color(1.0, 0.45, 0.75), Color(0.45, 0.9, 1.0)][currency]


## Multi-line description of item stats, with strengthening.
static func stat_lines(block: StatBlock) -> PackedStringArray:
	var lines := PackedStringArray()
	var names: Dictionary = {&"harm": "Harm", &"attack": "Attack", &"defense": "Defense", &"agility": "Agility", &"luck": "Luck", &"armor": "Armor", &"hp": "HP"}
	for field: StringName in [&"harm", &"attack", &"defense", &"agility", &"luck", &"armor", &"hp"]:
		var value: int = block.get_stat(field)
		if value != 0:
			lines.append("%s %+d" % [names[field], value])
	return lines
