class_name LabDebugCamera
extends Camera2D
## Developer camera with three framings (presentation only):
## - BATTLE: exactly battle_width_units wide, shooter-target midpoint centred.
## - FOLLOW: same width, centred on the playback marker.
## - FIT: frames the whole trajectory, shooter and target (engineering view, not gameplay).

enum Mode { BATTLE, FOLLOW, FIT }

## In Battle View, y = 0 sits at this fraction of the view height (from the top).
const BATTLE_BASELINE_SCREEN_FRACTION: float = 0.7
const FIT_PADDING_FRACTION: float = 0.12
const FIT_MIN_SPAN_UNITS: float = 2.0
## Extra room below the framed content (fraction of its height) for the labels
## drawn under the target plane.
const FIT_LABEL_ROOM_FRACTION: float = 0.08

## Set from GameMetrics.battle_view_width_units by the Lab.
var battle_width_units: float = 0.0


static func mode_name(value: Mode) -> String:
	return Mode.keys()[value]


func frame_battle(shooter_x: float, target_x: float) -> void:
	_set_zoom(BattleViewFraming.zoom_for_width(_viewport_size().x, battle_width_units))
	var height: float = visible_size_units().y
	_center_on(Vector2(0.5 * (shooter_x + target_x), -height * (BATTLE_BASELINE_SCREEN_FRACTION - 0.5)))


func frame_follow(point_units: Vector2) -> void:
	_set_zoom(BattleViewFraming.zoom_for_width(_viewport_size().x, battle_width_units))
	_center_on(point_units)


func frame_fit(bounds_units: Rect2) -> void:
	bounds_units = bounds_units.grow_individual(0.0, 0.0, 0.0, bounds_units.size.y * FIT_LABEL_ROOM_FRACTION)
	var span := Vector2(maxf(bounds_units.size.x, FIT_MIN_SPAN_UNITS), maxf(bounds_units.size.y, FIT_MIN_SPAN_UNITS))
	span *= 1.0 + 2.0 * FIT_PADDING_FRACTION
	_set_zoom(BattleViewFraming.zoom_to_fit(_viewport_size(), span))
	_center_on(bounds_units.get_center())


func visible_size_units() -> Vector2:
	var size: Vector2 = _viewport_size()
	return Vector2(
		BattleViewFraming.visible_width_units(size.x, zoom.x),
		BattleViewFraming.visible_height_units(size.y, zoom.y)
	)


func _viewport_size() -> Vector2:
	return get_viewport_rect().size


func _set_zoom(value: float) -> void:
	zoom = Vector2(value, value)


func _center_on(point_units: Vector2) -> void:
	position = WorldCanvas.units_to_canvas(point_units)
