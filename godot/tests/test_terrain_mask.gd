extends TestCase
## TerrainMask queries on small hand-built grids (4 x 4 u, 0.1 u cells, ground at y = 2).

const EPS: float = 1e-9
const CELL: float = 0.1
const SIZE_CELLS: int = 40
const GROUND_Y: float = 2.0


func _flat() -> TerrainMask:
	var mask := TerrainMask.new(SIZE_CELLS, SIZE_CELLS, CELL)
	mask.fill_below_surface(func(_x: float) -> float: return GROUND_Y)
	return mask


func test_solid_and_empty_queries() -> void:
	var mask: TerrainMask = _flat()
	assert_true(mask.is_solid(1.0, 3.0), "below the surface is solid")
	assert_true(not mask.is_solid(1.0, 1.0), "above the surface is empty")
	assert_true(not mask.is_solid(-1.0, 3.0), "outside the grid is empty")
	assert_true(not mask.is_solid(1.0, 10.0), "below the grid is empty (void)")


func test_crater_removes_terrain_only_inside_the_circle() -> void:
	var mask: TerrainMask = _flat()
	var before: int = mask.solid_cell_count()
	var region: Rect2i = mask.carve_circle(2.0, 2.0, 0.5)
	assert_true(region.has_area(), "carving solid terrain reports a changed region")
	assert_true(not mask.is_solid(2.0, 2.3), "inside the crater is now empty")
	assert_true(mask.is_solid(2.0, 2.7), "just below the crater is still solid")
	assert_true(mask.is_solid(0.5, 3.5), "distant terrain is untouched")
	assert_true(mask.solid_cell_count() < before, "cells were removed")
	assert_true(not mask.carve_circle(2.0, 0.5, 0.3).has_area(), "carving air changes nothing")


func test_segment_finds_first_terrain_cell() -> void:
	var mask: TerrainMask = _flat()
	assert_near(mask.segment_hit(1.05, 0.5, 1.05, 3.5), 0.5, EPS, "vertical segment enters ground at y = 2")
	assert_near(mask.segment_hit(0.55, 0.55, 3.55, 3.55), (GROUND_Y - 0.55) / 3.0, EPS, "diagonal segment")
	assert_near(mask.segment_hit(1.0, 0.5, 3.0, 0.5), -1.0, 0.0, "segment in the air misses")
	assert_near(mask.segment_hit(1.0, 3.0, 2.0, 3.5), 0.0, 0.0, "segment starting inside terrain hits at 0")


func test_fast_segment_cannot_tunnel_through_a_thin_wall() -> void:
	var mask := TerrainMask.new(SIZE_CELLS, SIZE_CELLS, CELL)
	mask.fill_rect(Rect2(2.0, 0.0, CELL, 4.0))
	var t: float = mask.segment_hit(0.05, 1.0, 100.05, 1.05)
	assert_near(t, (2.0 - 0.05) / 100.0, EPS, "a 100 u segment still stops at a one-cell wall")
	assert_true(mask.segment_hit(1.95, 1.0, 2.15, 1.0) >= 0.0, "a segment jumping across the wall still hits")


func test_support_query_and_overhangs() -> void:
	var mask: TerrainMask = _flat()
	assert_near(mask.ground_below(1.0, 0.0), GROUND_Y, EPS, "ground below the feet")
	mask.fill_rect(Rect2(0.5, 1.0, 1.0, 0.2))
	assert_near(mask.ground_below(1.0, 0.0), 1.0, EPS, "a ledge above the ground is found first")
	assert_near(mask.ground_below(1.0, 1.3), GROUND_Y, EPS, "below the ledge, the real ground is found")
	mask.carve_circle(3.0, 3.0, 5.0)
	assert_true(is_nan(mask.ground_below(3.0, 0.0)), "no support left: NAN")


func test_procedural_map_is_deterministic() -> void:
	var rules: CombatRules = CombatRules.load_default()
	var a: TerrainMask = ProceduralTestMap.build(rules)
	var b: TerrainMask = ProceduralTestMap.build(rules)
	assert_true(a.solid_cell_count() == b.solid_cell_count(), "same map every time")
	for spawn in rules.spawn_x:
		assert_near(a.ground_below(spawn, 0.0), rules.ground_level_y, 1e-6, "spawn pad at ground level")
