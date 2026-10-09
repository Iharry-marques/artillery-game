class_name BattleCamera
extends Camera2D
## Gameplay camera: always exactly GameMetrics.battle_view_width_units wide
## (BattleViewFraming), smoothly moving between framings. The vertical extent
## follows the window aspect; a high shot may leave the view, which is expected.

## Set by the sandbox from GameMetrics / CombatRules.
var width_units: float = 0.0
var follow_rate: float = 0.0
var map_width: float = 0.0
var _center_units: Vector2 = Vector2.ZERO
var _target_units: Vector2 = Vector2.ZERO


## Moves towards `target` with exponential smoothing; `snap` jumps immediately.
func track(target_units: Vector2, delta: float, snap: bool = false) -> void:
	var size: Vector2 = get_viewport_rect().size
	var zoom_value: float = BattleViewFraming.zoom_for_width(size.x, width_units)
	zoom = Vector2(zoom_value, zoom_value)
	_target_units = _clamp_horizontally(target_units)
	if snap:
		_center_units = _target_units
	else:
		_center_units = _center_units.lerp(_target_units, 1.0 - exp(-follow_rate * delta))
	position = WorldCanvas.units_to_canvas(_center_units)


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


func visible_rect_units() -> Rect2:
	var visible: Vector2 = visible_size_units()
	return Rect2(_center_units - visible * 0.5, visible)


func _clamp_horizontally(point: Vector2) -> Vector2:
	var half: float = width_units * 0.5
	if map_width <= width_units:
		return Vector2(map_width * 0.5, point.y)
	return Vector2(clampf(point.x, half, map_width - half), point.y)
