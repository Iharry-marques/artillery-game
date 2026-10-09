class_name SandboxHud
extends Control
## Battle HUD in the classic artillery layout (original procedural drawing):
## top-left player cards, top-centre wind, top-right minimap, bottom-left angle
## dial, bottom-centre power meter (the dominant element), bottom-right turn status.

const BAR_HEIGHT_PX: float = 132.0
const PANEL_COLOR: Color = Color(0.07, 0.09, 0.16, 0.88)
const PANEL_BORDER: Color = Color(0.45, 0.6, 0.95, 0.8)
const TEXT_COLOR: Color = Color(0.95, 0.97, 1.0)
const DIM_TEXT: Color = Color(0.68, 0.74, 0.86)
const ACCENT: Color = Color(1.0, 0.82, 0.28)
const BANNER_TIME: float = 1.6
const HELP_TEXT: String = "A/D move · W/S angle · SPACE power\nR reset · Z wind 0 · F2 hitbox · F3 debug · F auto"


static func panel_style(radius: int = 10) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = PANEL_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 4
	return style


## Large horizontal power meter: 0..max with numbered ticks, sweeping fill and the
## previous shot marker.
class PowerMeter:
	extends Control
	var value: float = 0.0
	var maximum: float = 100.0
	var last_shot: float = NAN
	var charging: bool = false

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var bar := Rect2(Vector2(0, 18), Vector2(size.x, size.y - 18))
		draw_rect(bar.grow(3), Color(0.02, 0.03, 0.06, 0.95))
		draw_rect(bar, Color(0.16, 0.18, 0.26))
		var fill_width: float = bar.size.x * clampf(value / maximum, 0.0, 1.0)
		var steps: int = 40
		for i in steps:
			var x0: float = bar.size.x * i / steps
			if x0 >= fill_width:
				break
			var w: float = minf(bar.size.x / steps, fill_width - x0)
			var t: float = float(i) / steps
			var color: Color = Color(0.3, 0.85, 0.35).lerp(Color(1.0, 0.85, 0.2), minf(1.0, t * 1.6)).lerp(Color(1.0, 0.3, 0.2), maxf(0.0, t - 0.65) * 2.8)
			draw_rect(Rect2(bar.position + Vector2(x0, 0), Vector2(w, bar.size.y)), color)
		draw_rect(Rect2(bar.position, Vector2(fill_width, bar.size.y * 0.35)), Color(1, 1, 1, 0.18))
		for i in range(0, 11):
			var x: float = bar.size.x * i / 10.0
			draw_line(Vector2(x, bar.position.y), Vector2(x, bar.position.y + bar.size.y * (0.5 if i % 5 == 0 else 0.28)), Color(1, 1, 1, 0.55), 2.0 if i % 5 == 0 else 1.0)
			var label: String = str(i * 10)
			var width: float = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
			draw_string(font, Vector2(clampf(x - width * 0.5, 0, size.x - width), 13), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM_TEXT)
		if not is_nan(last_shot):
			var lx: float = bar.size.x * last_shot / maximum
			draw_line(Vector2(lx, bar.position.y - 4), Vector2(lx, bar.end.y + 4), Color(0.4, 0.9, 1.0), 3.0)
		draw_rect(bar, Color(0.75, 0.82, 1.0, 0.9), false, 2.0)


## Quarter dial (0..90 degrees) with the needle at the real gameplay angle.
class AngleGauge:
	extends Control
	var angle: float = 0.0
	var facing: int = 1
	var min_angle: float = 0.0
	var max_angle: float = 90.0

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var radius: float = size.y - 18.0
		var center := Vector2(12.0 if facing > 0 else size.x - 12.0, size.y - 8.0)
		var dir: float = 1.0 if facing > 0 else -1.0
		var start: float = -PI * 0.5 if facing > 0 else PI
		var points := PackedVector2Array([center])
		for i in 31:
			var a: float = deg_to_rad(90.0 * i / 30.0)
			points.append(center + Vector2(dir * cos(a), -sin(a)) * radius)
		draw_colored_polygon(points, Color(0.16, 0.2, 0.32, 0.95))
		draw_arc(center, radius, start, start + PI * 0.5, 32, Color(0.75, 0.82, 1.0, 0.9), 2.0)
		for deg in range(0, 91, 10):
			var a: float = deg_to_rad(float(deg))
			var outer := center + Vector2(dir * cos(a), -sin(a)) * radius
			var inner := center + Vector2(dir * cos(a), -sin(a)) * (radius - (12.0 if deg % 30 == 0 else 6.0))
			draw_line(inner, outer, Color(1, 1, 1, 0.6), 2.0 if deg % 30 == 0 else 1.0)
		var needle_angle: float = deg_to_rad(angle)
		var tip := center + Vector2(dir * cos(needle_angle), -sin(needle_angle)) * (radius - 4.0)
		draw_line(center, tip, ACCENT, 4.0)
		draw_circle(tip, 4.0, ACCENT)
		draw_circle(center, 6.0, Color(0.95, 0.95, 1.0))
		var text: String = "%d°" % roundi(angle)
		var width: float = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34).x
		var text_x: float = size.x - width - 4.0 if facing > 0 else 4.0
		draw_string_outline(font, Vector2(text_x, size.y - 14.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, 5, Color(0, 0, 0, 0.8))
		draw_string(font, Vector2(text_x, size.y - 14.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 34, TEXT_COLOR)
		draw_string(font, Vector2(text_x, size.y - 54.0), "ANGLE", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM_TEXT)


## Wind arrow (length grows with magnitude) and the numeric value.
class WindIndicator:
	extends Control
	var wind: float = 0.0
	var maximum: float = 2.0
	var forced_zero: bool = false

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		draw_style_box(SandboxHud.panel_style(14), Rect2(Vector2.ZERO, size))
		draw_string(font, Vector2(14, 20), "WIND", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, DIM_TEXT)
		var center := Vector2(size.x * 0.4, size.y * 0.6)
		var magnitude: float = clampf(absf(wind) / maximum, 0.0, 1.0)
		var half: float = 14.0 + 34.0 * magnitude
		var dir: float = signf(wind)
		if dir != 0.0:
			var tail := center - Vector2(dir * half, 0.0)
			var tip := center + Vector2(dir * half, 0.0)
			draw_line(tail, tip - Vector2(dir * 10.0, 0.0), Color(0.55, 0.85, 1.0), 9.0)
			draw_colored_polygon(PackedVector2Array([tip, tip - Vector2(dir * 22.0, 14.0), tip - Vector2(dir * 22.0, -14.0)]), Color(0.55, 0.85, 1.0))
		else:
			draw_circle(center, 7.0, Color(0.55, 0.85, 1.0))
		var text: String = "%.1f" % absf(wind)
		var text_at := Vector2(size.x * 0.72, center.y + 10.0)
		draw_string_outline(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, 6, Color(0.02, 0.05, 0.12))
		draw_string(font, text_at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, TEXT_COLOR)
		if forced_zero:
			draw_string(font, Vector2(size.x - 70, 20), "FORCED 0", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, ACCENT)


## Player identity and HP.
class PlayerCard:
	extends Control
	var display_name: String = ""
	var hp: int = 100
	var max_hp: int = 100
	var color: Color = Color.WHITE
	var active: bool = false
	var alive: bool = true

	func _draw() -> void:
		var font: Font = ThemeDB.fallback_font
		var style: StyleBoxFlat = SandboxHud.panel_style(12)
		if active:
			style.border_color = ACCENT
			style.set_border_width_all(3)
		draw_style_box(style, Rect2(Vector2.ZERO, size))
		var badge := Vector2(30, size.y * 0.5)
		draw_circle(badge, 20.0, Color(0.05, 0.05, 0.1))
		draw_circle(badge, 17.0, color if alive else Color(0.45, 0.45, 0.5))
		draw_string(font, Vector2(56, 22), display_name.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 15, TEXT_COLOR if alive else DIM_TEXT)
		var bar := Rect2(Vector2(56, 30), Vector2(size.x - 70, 14))
		draw_rect(bar.grow(2), Color(0.02, 0.03, 0.06))
		var fraction: float = clampf(float(hp) / max_hp, 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * fraction, bar.size.y)), Color(0.35, 0.92, 0.4).lerp(Color(0.98, 0.3, 0.28), 1.0 - fraction))
		var label: String = "%d / %d" % [hp, max_hp] if alive else "DEFEATED"
		draw_string(font, Vector2(bar.position.x + 6, bar.end.y - 2), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.05, 0.05, 0.08))
		if active and alive:
			draw_string(font, Vector2(size.x - 52, 22), "TURN", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, ACCENT)


var minimap: SandboxMinimap
var player_colors: Array[Color] = []
var _cards: Array[PlayerCard] = []
var _wind: WindIndicator
var _angle: AngleGauge
var _power: PowerMeter
var _power_value: Label
var _status: Label
var _movement: ProgressBar
var _message: Label
var _banner: Label
var _banner_age: float = BANNER_TIME


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	for i in 2:
		var card := PlayerCard.new()
		card.position = Vector2(12, 12 + 62 * i)
		card.size = Vector2(250, 54)
		add_child(card)
		_cards.append(card)

	_wind = WindIndicator.new()
	_wind.size = Vector2(210, 70)
	_wind.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wind.position = Vector2(-105, 10)
	add_child(_wind)

	_message = _make_label(self, 20, ACCENT)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.offset_left = -380
	_message.offset_right = 380
	_message.offset_top = 88

	_banner = _make_label(self, 48, Color.WHITE)
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.offset_left = -400
	_banner.offset_right = 400
	_banner.offset_top = -205
	_banner.offset_bottom = -145
	_banner.add_theme_constant_override("outline_size", 10)

	minimap = SandboxMinimap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -SandboxMinimap.WIDTH_PX - 20.0
	minimap.offset_top = 12.0
	add_child(minimap)

	var bar := PanelContainer.new()
	var style: StyleBoxFlat = panel_style(16)
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 8
	style.content_margin_bottom = 6
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -BAR_HEIGHT_PX
	bar.offset_left = -4
	bar.offset_right = 4
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(row)

	_angle = AngleGauge.new()
	_angle.custom_minimum_size = Vector2(230, 110)
	row.add_child(_angle)

	var center := VBoxContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(center)
	_power = PowerMeter.new()
	_power.custom_minimum_size = Vector2(420, 66)
	_power.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.add_child(_power)
	_power_value = _make_label(center, 15, DIM_TEXT)
	_power_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(250, 0)
	right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(right)
	_status = _make_label(right, 18, TEXT_COLOR)
	_make_label(right, 12, DIM_TEXT).text = "MOVEMENT"
	_movement = ProgressBar.new()
	_movement.custom_minimum_size = Vector2(240, 14)
	_movement.show_percentage = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.8, 1.0)
	fill.set_corner_radius_all(4)
	_movement.add_theme_stylebox_override("fill", fill)
	var back := StyleBoxFlat.new()
	back.bg_color = Color(0.03, 0.04, 0.08)
	back.set_corner_radius_all(4)
	_movement.add_theme_stylebox_override("background", back)
	right.add_child(_movement)
	var help := _make_label(right, 11, DIM_TEXT)
	help.text = HELP_TEXT


func show_message(text: String) -> void:
	_message.text = text


func show_banner(text: String, color: Color) -> void:
	_banner.text = text
	_banner.add_theme_color_override("font_color", color)
	_banner_age = 0.0


func _process(delta: float) -> void:
	_banner_age += delta
	var t: float = _banner_age / BANNER_TIME
	_banner.modulate.a = clampf(2.5 * (1.0 - t), 0.0, 1.0)
	_banner.scale = Vector2.ONE * (1.0 + 0.25 * maxf(0.0, 1.0 - _banner_age / 0.2))
	_banner.pivot_offset = _banner.size * 0.5


func refresh(combat: CombatMatch) -> void:
	var active: CombatantState = combat.active()
	for c in combat.combatants:
		var card: PlayerCard = _cards[c.index]
		card.display_name = c.display_name
		card.hp = c.hp
		card.max_hp = combat.rules.starting_hp
		card.color = player_colors[c.index]
		card.active = c.index == combat.active_index and combat.phase != CombatMatch.Phase.GAME_OVER
		card.alive = c.alive
		card.queue_redraw()
	_wind.wind = combat.wind
	_wind.maximum = combat.rules.wind_max
	_wind.forced_zero = combat.force_zero_wind
	_wind.queue_redraw()
	_angle.angle = active.angle
	_angle.facing = active.facing
	_angle.queue_redraw()
	var charging: bool = combat.phase == CombatMatch.Phase.CHARGING
	_power.value = combat.power if charging else 0.0
	_power.maximum = combat.rules.power_max
	_power.last_shot = combat.last_shot_power
	_power.queue_redraw()
	_power_value.text = "POWER %.1f%s" % [combat.power if charging else 0.0, "" if is_nan(combat.last_shot_power) else "     last shot %.1f" % combat.last_shot_power]
	_status.text = "TURN %d   %s" % [combat.turn_number, active.display_name.to_upper()]
	_status.add_theme_color_override("font_color", player_colors[active.index])
	_movement.max_value = combat.rules.movement_budget
	_movement.value = active.movement_left


func _make_label(parent: Control, size_px: int, color: Color) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", size_px)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.03, 0.08, 0.9))
	label.add_theme_constant_override("outline_size", 5)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
