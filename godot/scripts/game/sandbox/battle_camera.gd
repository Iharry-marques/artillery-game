class_name BattleCamera
extends Camera2D
## Gameplay camera: always exactly GameMetrics.battle_view_width_units wide
## (BattleViewFraming), easing between framings, with a short presentation-only
## shake on explosions. The vertical extent follows the window aspect; a high shot
## may leave the view, which is expected.

const SHAKE_DECAY: float = 7.0
const SHAKE_FREQUENCY: float = 38.0

## Set by the sandbox from GameMetrics / CombatRules.
var width_units: float = 0.0
var map_width: float = 0.0
var _center_units: Vector2 = Vector2.ZERO
var _shake_units: float = 0.0
var _time: float = 0.0


## Eases towards `target` with exponential smoothing at `rate` (1/s); `snap` jumps.
func track(target_units: Vector2, delta: float, rate: float, snap: bool = false) -> void:
	_time += delta
	var size: Vector2 = get_viewport_rect().size
	var zoom_value: float = BattleViewFraming.zoom_for_width(size.x, width_units)
	zoom = Vector2(zoom_value, zoom_value)
	var target: Vector2 = _clamp_horizontally(target_units)
	if snap:
		_center_units = target
	else:
		_center_units = _center_units.lerp(target, 1.0 - exp(-rate * delta))
	_shake_units *= exp(-SHAKE_DECAY * delta)
	var wobble := Vector2(sin(_time * SHAKE_FREQUENCY), cos(_time * SHAKE_FREQUENCY * 1.3)) * _shake_units
	position = WorldCanvas.units_to_canvas(_center_units + wobble)


## Pushes the camera so `point` stays inside the view, `margins` away from the
## edges (fractions of the view: left/right, top, bottom). The bottom margin keeps
## the point above the HUD bar.
func contain(point_units: Vector2, side_margin: float, top_margin: float, bottom_margin: float) -> void:
	var visible: Vector2 = visible_size_units()
	var half: Vector2 = visible * 0.5
	var left: float = _center_units.x - half.x + visible.x * side_margin
	var right: float = _center_units.x + half.x - visible.x * side_margin
	var top: float = _center_units.y - half.y + visible.y * top_margin
	var bottom: float = _center_units.y + half.y - visible.y * bottom_margin
	if point_units.x < left:
		_center_units.x -= left - point_units.x
	elif point_units.x > right:
		_center_units.x += point_units.x - right
	if point_units.y < top:
		_center_units.y -= top - point_units.y
	elif point_units.y > bottom:
		_center_units.y += point_units.y - bottom
	_center_units = _clamp_horizontally(_center_units)
	position = WorldCanvas.units_to_canvas(_center_units)


func shake(strength_units: float) -> void:
	_shake_units = maxf(_shake_units, strength_units)


## Feet of a character placed at `fraction` of the view height (from the top).
func framing_for_feet(feet_units: Vector2, fraction: float) -> Vector2:
	return Vector2(feet_units.x, feet_units.y - visible_size_units().y * (fraction - 0.5))


func visible_size_units() -> Vector2:
	var size: Vector2 = get_viewport_rect().size
	var zoom_value: float = BattleViewFraming.zoom_for_width(size.x, width_units)
	return Vector2(
		BattleViewFraming.visible_width_units(size.x, zoom_value),
		BattleViewFraming.visible_height_units(size.y, zoom_value)
	)


## Visible world rectangle (u), excluding the shake.
func visible_rect_units() -> Rect2:
	var visible: Vector2 = visible_size_units()
	return Rect2(_center_units - visible * 0.5, visible)


func _clamp_horizontally(point: Vector2) -> Vector2:
	var half: float = width_units * 0.5
	if map_width <= width_units:
		return Vector2(map_width * 0.5, point.y)
	return Vector2(clampf(point.x, half, map_width - half), point.y)
