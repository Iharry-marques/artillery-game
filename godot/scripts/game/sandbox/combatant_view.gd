class_name CombatantView
extends Node2D
## CharacterRoot of one combatant (node origin = FeetAnchor). Presentation only:
##   CharacterRoot
##   ├── Visual (mirrored by facing)
##   │   ├── Body (sprite, idle / aim pose)
##   │   └── WeaponPivot (rotates to the gameplay angle)
##   │       └── Weapon (sprite)
##   └── Head
##       └── HeadHitbox (marker at the gameplay hit circle; drawn by the F2 overlay)
## HP bar, name and the active-turn marker are drawn on the root (never mirrored).

const SHADOW_COLOR: Color = Color(0.0, 0.0, 0.0, 0.22)
const HP_BAR_WIDTH_UNITS: float = 0.74
const HP_BAR_HEIGHT_PX: float = 7.0
const HP_GAP_UNITS: float = 0.14
const NAME_FONT_SIZE: int = 14
const DEAD_TINT: Color = Color(0.55, 0.55, 0.6, 0.85)
const FLASH_TIME: float = 0.28
const SHAKE_UNITS: float = 0.05
const MARKER_BOB_UNITS: float = 0.05

var state: CombatantState
var rules: CombatRules
var art: CharacterProxyArt
var variant_index: int = 0
var team_color: Color = Color.WHITE
var is_active: bool = false
var is_aiming: bool = false

var _visual: Node2D
var _body: Sprite2D
var _weapon_pivot: Node2D
var _head: Node2D
var _hitbox: Node2D
var _flash: float = 0.0
var _time: float = 0.0


func _ready() -> void:
	_visual = Node2D.new()
	_visual.name = "Visual"
	add_child(_visual)
	_body = Sprite2D.new()
	_body.name = "Body"
	_body.centered = false
	_visual.add_child(_body)
	_weapon_pivot = Node2D.new()
	_weapon_pivot.name = "WeaponPivot"
	_visual.add_child(_weapon_pivot)
	var weapon := Sprite2D.new()
	weapon.name = "Weapon"
	weapon.centered = false
	_weapon_pivot.add_child(weapon)
	_head = Node2D.new()
	_head.name = "Head"
	add_child(_head)
	_hitbox = Node2D.new()
	_hitbox.name = "HeadHitbox"
	_head.add_child(_hitbox)


## Binds the art; call after `state`, `rules` and `art` are set.
func setup() -> void:
	var scale_factor: float = art.sprite_scale()
	_body.scale = Vector2.ONE * scale_factor
	_body.offset = -art.feet_anchor_px
	var weapon: Sprite2D = _weapon_pivot.get_node("Weapon") as Sprite2D
	weapon.texture = art.weapon
	weapon.scale = Vector2.ONE * scale_factor
	weapon.offset = -art.weapon_pivot_px
	_weapon_pivot.position = WorldCanvas.to_canvas(rules.weapon_pivot_forward, -rules.weapon_pivot_up)
	_head.position = WorldCanvas.to_canvas(0.0, -rules.head_center_height)


## Gameplay angle (degrees above the horizontal, towards facing) -> local rotation.
static func weapon_rotation(angle_degrees: float) -> float:
	return -deg_to_rad(angle_degrees)


func flash() -> void:
	_flash = FLASH_TIME


func weapon_pivot_rotation() -> float:
	return _weapon_pivot.rotation


func _process(delta: float) -> void:
	_time += delta
	_flash = maxf(0.0, _flash - delta)
	var shake: float = 0.0
	if _flash > 0.0:
		shake = sin(_time * 70.0) * SHAKE_UNITS * (_flash / FLASH_TIME)
	position = WorldCanvas.to_canvas(state.feet_x + shake, state.feet_y)
	_visual.scale = Vector2(state.facing, 1.0)
	_body.texture = art.body_texture(variant_index, is_aiming and state.alive)
	_weapon_pivot.rotation = weapon_rotation(state.angle)
	var tint: Color = Color.WHITE if state.alive else DEAD_TINT
	if _flash > 0.0:
		tint = tint.lerp(Color(2.2, 1.6, 1.6), _flash / FLASH_TIME)
	_visual.modulate = tint
	queue_redraw()


func _draw() -> void:
	var ppu: float = WorldCanvas.PIXELS_PER_UNIT
	var scale_px: float = WorldCanvas.screen_scale(self)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.32))
	draw_circle(Vector2.ZERO, 0.32 * ppu, SHADOW_COLOR)
	draw_set_transform_matrix(Transform2D.IDENTITY)

	var top: float = -(art.total_height_u + HP_GAP_UNITS) * ppu
	var width: float = HP_BAR_WIDTH_UNITS * ppu
	var height: float = HP_BAR_HEIGHT_PX / scale_px
	var back := Rect2(-0.5 * width, top, width, height)
	draw_rect(back.grow(1.5 / scale_px), Color(0.05, 0.05, 0.08, 0.85))
	var fraction: float = float(state.hp) / float(rules.starting_hp)
	var fill: Color = Color(0.35, 0.92, 0.4).lerp(Color(0.98, 0.3, 0.28), 1.0 - fraction)
	draw_rect(Rect2(back.position, Vector2(width * fraction, height)), fill)
	WorldCanvas.draw_text(
		self, Vector2(-0.5 * width, top - 4.0 / scale_px), state.display_name, team_color, NAME_FONT_SIZE, Color(0, 0, 0, 0.9)
	)
	if is_active and state.alive:
		var bob: float = sin(_time * 5.0) * MARKER_BOB_UNITS * ppu
		var tip := Vector2(0.0, top - 0.3 * ppu + bob)
		var half: float = 0.11 * ppu
		var arrow := PackedVector2Array([tip + Vector2(-half, -half * 1.3), tip + Vector2(half, -half * 1.3), tip])
		draw_colored_polygon(arrow, Color(1.0, 0.86, 0.25))
		draw_polyline(arrow + PackedVector2Array([arrow[0]]), Color(0.3, 0.2, 0.05), 1.5 / scale_px)
