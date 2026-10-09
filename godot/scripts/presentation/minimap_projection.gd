class_name MinimapProjection
extends RefCounted
## World (u) <-> minimap (px) mapping with ONE scale on both axes, so distances on
## the minimap are geometrically faithful (the camera rectangle is the 10 u ruler).

var map_size_units: Vector2
var width_px: float


func _init(p_map_size_units: Vector2, p_width_px: float) -> void:
	map_size_units = p_map_size_units
	width_px = p_width_px


func pixels_per_unit() -> float:
	return width_px / map_size_units.x


func size_px() -> Vector2:
	return map_size_units * pixels_per_unit()


## Points above or below the map stick to the top/bottom edge.
func to_minimap(point_units: Vector2) -> Vector2:
	var scale: float = pixels_per_unit()
	return Vector2(point_units.x * scale, clampf(point_units.y, 0.0, map_size_units.y) * scale)


func rect_to_minimap(rect_units: Rect2) -> Rect2:
	var top_left: Vector2 = to_minimap(rect_units.position)
	var bottom_right: Vector2 = to_minimap(rect_units.end)
	return Rect2(top_left, bottom_right - top_left)
