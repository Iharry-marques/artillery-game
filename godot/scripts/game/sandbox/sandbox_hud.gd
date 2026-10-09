class_name SandboxHud
extends Control
## Plain gameplay HUD (no art): turn, angle, power gauge, wind, HP, movement,
## messages and the minimap slot. Rebuilt from the match every frame.

const BAR_HEIGHT_PX: float = 118.0
const PANEL_COLOR: Color = Color(0.06, 0.07, 0.09, 0.82)
const DIM_TEXT: Color = Color(0.7, 0.75, 0.82)
const BIG_FONT: int = 30
const MID_FONT: int = 18
const SMALL_FONT: int = 13


## Power gauge 0..power_max with 10-point ticks and the last shot marker.
class PowerGauge:
	extends Control
	var value: float = 0.0
	var maximum: float = 100.0
	var last_shot: float = NAN

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.6))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * value / maximum, size.y)), Color(1.0, 0.55, 0.2))
		for i in range(1, 10):
			var x: float = size.x * i / 10.0
			draw_line(Vector2(x, 0.0), Vector2(x, size.y * (0.55 if i == 5 else 0.3)), Color(1, 1, 1, 0.5), 1.0)
		if not is_nan(last_shot):
			var x: float = size.x * last_shot / maximum
			draw_line(Vector2(x, -4.0), Vector2(x, size.y + 4.0), Color(0.4, 0.9, 1.0), 2.0)
		draw_rect(rect, Color(1, 1, 1, 0.5), false, 1.0)


var minimap: SandboxMinimap
var player_colors: Array[Color] = []
var _turn: Label
var _movement: Label
var _angle: Label
var _power: Label
var _gauge: PowerGauge
var _wind: Label
var _hp: Array[Label] = []
var _message: Label
var _help: Label


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	var bar := Panel.new()
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	bar.add_theme_stylebox_override("panel", style)
	bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar.offset_top = -BAR_HEIGHT_PX
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bar)

	_turn = _label(bar, Vector2(16, 10), MID_FONT)
	_movement = _label(bar, Vector2(16, 40), SMALL_FONT)
	_help = _label(bar, Vector2(16, 92), SMALL_FONT)
	_help.add_theme_color_override("font_color", DIM_TEXT)
	_help.text = SandboxInput.HELP_TEXT

	_angle = _label(bar, Vector2(360, 4), BIG_FONT)
	_power = _label(bar, Vector2(520, 10), MID_FONT)
	_gauge = PowerGauge.new()
	_gauge.position = Vector2(520, 44)
	_gauge.size = Vector2(380, 26)
	bar.add_child(_gauge)

	for i in 2:
		_hp.append(_label(bar, Vector2(940, 10 + 30 * i), MID_FONT))

	_wind = _label(self, Vector2(0, 12), MID_FONT)
	_wind.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_wind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_wind.offset_left = -200
	_wind.offset_right = 200
	_message = _label(self, Vector2(0, 44), MID_FONT)
	_message.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_message.offset_left = -360
	_message.offset_right = 360
	_message.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))

	minimap = SandboxMinimap.new()
	minimap.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	minimap.offset_left = -SandboxMinimap.WIDTH_PX - 12.0
	minimap.offset_top = 12.0
	add_child(minimap)


func show_message(text: String) -> void:
	_message.text = text


func refresh(combat: CombatMatch) -> void:
	var active: CombatantState = combat.active()
	_turn.text = "TURN %d  |  %s" % [combat.turn_number, active.display_name]
	_turn.add_theme_color_override("font_color", player_colors[active.index])
	_movement.text = "Movement left %.2f / %.2f u" % [active.movement_left, combat.rules.movement_budget]
	_angle.text = "%d°" % active.angle
	var charging: bool = combat.phase == CombatMatch.Phase.CHARGING
	_power.text = "POWER %5.1f%s" % [combat.power if charging else 0.0, "" if is_nan(combat.last_shot_power) else "   (last %.1f)" % combat.last_shot_power]
	_gauge.value = combat.power if charging else 0.0
	_gauge.maximum = combat.rules.power_max
	_gauge.last_shot = combat.last_shot_power
	_gauge.queue_redraw()
	_wind.text = "WIND %s %.1f%s" % [_wind_arrow(combat.wind), absf(combat.wind), "   (forced 0, Z)" if combat.force_zero_wind else ""]
	for c in combat.combatants:
		_hp[c.index].text = "%s  HP %3d%s" % [c.display_name, c.hp, "" if c.alive else "  DEFEATED"]
		_hp[c.index].add_theme_color_override("font_color", player_colors[c.index] if c.alive else Color(0.5, 0.5, 0.5))


func _wind_arrow(wind: float) -> String:
	if wind > 0.0:
		return "→"
	if wind < 0.0:
		return "←"
	return "·"


func _label(parent: Control, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label
