extends TestCase
## World -> minimap mapping: one scale on both axes, so the camera rectangle is a
## faithful 10 u ruler.

const EPS: float = 1e-4


func test_corners_and_uniform_scale() -> void:
	var p := MinimapProjection.new(Vector2(36.0, 18.0), 300.0)
	assert_near(p.pixels_per_unit(), 300.0 / 36.0, 1e-9, "scale from the width")
	assert_near(p.size_px().y, 150.0, EPS, "height keeps the map aspect")
	assert_true(p.to_minimap(Vector2.ZERO).is_equal_approx(Vector2.ZERO), "top-left corner")
	assert_true(p.to_minimap(Vector2(36.0, 18.0)).is_equal_approx(Vector2(300.0, 150.0)), "bottom-right corner")


func test_battle_view_rectangle_is_ten_units_wide() -> void:
	var p := MinimapProjection.new(Vector2(36.0, 18.0), 300.0)
	var rect: Rect2 = p.rect_to_minimap(Rect2(Vector2(8.0, 9.0), Vector2(10.0, 5.625)))
	assert_near(rect.size.x, 10.0 * p.pixels_per_unit(), EPS, "10 u wide")
	assert_near(rect.size.y, 5.625 * p.pixels_per_unit(), EPS, "same scale vertically")


func test_points_above_the_map_stick_to_the_top_edge() -> void:
	var p := MinimapProjection.new(Vector2(36.0, 18.0), 300.0)
	assert_near(p.to_minimap(Vector2(10.0, -5.0)).y, 0.0, EPS, "projectile above the map")
	assert_near(p.to_minimap(Vector2(10.0, 30.0)).y, 150.0, EPS, "below the map")
