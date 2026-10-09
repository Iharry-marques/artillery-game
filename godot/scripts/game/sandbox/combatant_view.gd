class_name CombatantView
extends Node2D
## Procedural debug body of one combatant. Node origin = FeetAnchor.
## CharacterRoot (this node) draws BodyVisual (rectangle), HeadHitbox (circle,
## the actual hittable geometry), the FeetAnchor marker and the aim line.

const OUTLINE_PX: float = 2.0
const AIM_LENGTH_UNITS: float = 0.9
const HP_BAR_WIDTH_UNITS: float = 0.8
const HP_BAR_HEIGHT_UNITS: float = 0.08
const HP_BAR_GAP_UNITS: float = 0.18
const DEAD_COLOR: Color = Color(0.45, 0.45, 0.45)

var state: CombatantState
var rules: CombatRules
var color: Color = Color.WHITE
var is_active: bool = false
var show_aim: bool = false


func _process(_delta: float) -> void:
	position = WorldCanvas.to_canvas(state.feet_x, state.feet_y)
	queue_redraw()


func _draw() -> void:
	var ppu: float = WorldCanvas.PIXELS_PER_UNIT
	var scale_px: float = WorldCanvas.screen_scale(self)
	var outline: float = OUTLINE_PX / scale_px
	var body_color: Color = color.darkened(0.35) if state.alive else DEAD_COLOR.darkened(0.3)
	var head_color: Color = color if state.alive else DEAD_COLOR

	var body := Rect2(-0.5 * rules.body_width * ppu, -rules.body_height * ppu, rules.body_width * ppu, rules.body_height * ppu)
	draw_rect(body, body_color)
	var head := Vector2(0.0, -rules.head_center_height * ppu)
	var head_radius: float = rules.head_radius * ppu
	draw_circle(head, head_radius, head_color)
	draw_arc(head, head_radius, 0.0, TAU, 40, Color.WHITE if is_active else head_color.darkened(0.4), outline)
	draw_circle(head + Vector2(state.facing * head_radius * 0.45, -head_radius * 0.15), head_radius * 0.18, Color(0.08, 0.08, 0.1))

	var foot: float = 0.12 * ppu
	draw_line(Vector2(-foot, 0.0), Vector2(foot, 0.0), Color.WHITE, outline)

	if show_aim and state.alive:
		var muzzle := Vector2(state.facing * rules.muzzle_forward * ppu, -rules.muzzle_up * ppu)
		var radians: float = deg_to_rad(state.angle)
		var direction := Vector2(state.facing * cos(radians), -sin(radians))
		draw_line(muzzle, muzzle + direction * AIM_LENGTH_UNITS * ppu, Color(1.0, 1.0, 1.0, 0.85), outline)
		draw_circle(muzzle, 3.0 / scale_px, Color.WHITE)

	_draw_hp_bar(ppu)
	if is_active and state.alive:
		var top: float = -(rules.head_center_height + rules.head_radius + HP_BAR_GAP_UNITS + 0.3) * ppu
		draw_colored_polygon(PackedVector2Array([
			Vector2(-0.12 * ppu, top), Vector2(0.12 * ppu, top), Vector2(0.0, top + 0.16 * ppu)
		]), Color(1.0, 0.9, 0.3))


func _draw_hp_bar(ppu: float) -> void:
	var y: float = -(rules.head_center_height + rules.head_radius + HP_BAR_GAP_UNITS) * ppu
	var width: float = HP_BAR_WIDTH_UNITS * ppu
	var back := Rect2(-0.5 * width, y, width, HP_BAR_HEIGHT_UNITS * ppu)
	draw_rect(back, Color(0.0, 0.0, 0.0, 0.6))
	var fraction: float = float(state.hp) / float(rules.starting_hp)
	draw_rect(Rect2(back.position, Vector2(width * fraction, back.size.y)), Color(0.35, 0.9, 0.4).lerp(Color(0.95, 0.3, 0.3), 1.0 - fraction))
