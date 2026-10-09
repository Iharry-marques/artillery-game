extends TestCase
## Projectile/world collision: terrain vs head circles vs bounds, nearest hit wins,
## and the collision-aware simulation still follows the calibrated trajectory.

const EPS: float = 1e-9
const CELL: float = 0.1
## Combatant feet at y = 2 on a 10 x 4 u test grid; head centre at 2 - 0.65.
const FEET_Y: float = 2.0


func _rules() -> CombatRules:
	return CombatRules.load_default()


func _grid() -> TerrainMask:
	return TerrainMask.new(100, 40, CELL)


func _combatant_at(x: float) -> CombatantState:
	return CombatantState.new(1, "Target", x, FEET_Y, -1, _rules())


func test_segment_hits_circular_head() -> void:
	assert_near(CombatWorldQuery.segment_circle_hit(0.0, 0.0, 4.0, 0.0, 2.0, 0.0, 0.5), 0.375, EPS, "enters at x = 1.5")
	assert_near(CombatWorldQuery.segment_circle_hit(0.0, 1.0, 4.0, 1.0, 2.0, 0.0, 0.5), -1.0, 0.0, "passes above")
	assert_near(CombatWorldQuery.segment_circle_hit(2.0, 0.0, 4.0, 0.0, 2.0, 0.0, 0.5), 0.0, 0.0, "starts inside")


func test_nearer_terrain_beats_farther_head() -> void:
	var rules: CombatRules = _rules()
	var terrain: TerrainMask = _grid()
	terrain.fill_rect(Rect2(2.0, 0.0, 0.2, 4.0))
	var target: CombatantState = _combatant_at(3.0)
	var y: float = target.head_center_y(rules)
	var hit: BallisticHit = CombatWorldQuery.new(terrain, rules, [target]).first_hit(0.5, y, 3.9, y)
	assert_true(hit != null and hit.tag == CombatWorldQuery.TAG_TERRAIN, "terrain is hit first")
	assert_near(hit.x, 2.0, EPS, "at the wall face")


func test_nearer_head_beats_farther_terrain() -> void:
	var rules: CombatRules = _rules()
	var terrain: TerrainMask = _grid()
	terrain.fill_rect(Rect2(2.0, 0.0, 0.2, 4.0))
	var target: CombatantState = _combatant_at(1.2)
	var y: float = target.head_center_y(rules)
	var hit: BallisticHit = CombatWorldQuery.new(terrain, rules, [target]).first_hit(0.2, y, 3.9, y)
	assert_true(hit != null and hit.tag == CombatWorldQuery.TAG_HEAD, "the head is hit first")
	assert_true(hit.collider == target, "the hit reports the combatant")
	assert_near(hit.x, 1.2 - rules.head_radius, EPS, "at the head surface")


func test_fast_segment_does_not_tunnel_through_a_head() -> void:
	var rules: CombatRules = _rules()
	var target: CombatantState = _combatant_at(5.0)
	var y: float = target.head_center_y(rules)
	var hit: BallisticHit = CombatWorldQuery.new(_grid(), rules, [target]).first_hit(0.1, y, 9.9, y + 0.01)
	assert_true(hit != null and hit.tag == CombatWorldQuery.TAG_HEAD, "a 10 u segment still hits a 0.5 u head")


func test_leaving_the_map_is_a_bounds_hit() -> void:
	var rules: CombatRules = _rules()
	var query := CombatWorldQuery.new(_grid(), rules, [])
	var left: BallisticHit = query.first_hit(0.5, 1.0, -0.5, 1.0)
	assert_true(left != null and left.tag == CombatWorldQuery.TAG_BOUNDS, "left edge")
	assert_near(left.x, 0.0, EPS, "exits at x = 0")
	var below: BallisticHit = query.first_hit(5.0, rules.death_y() - 0.1, 5.0, rules.death_y() + 0.1)
	assert_true(below != null and below.tag == CombatWorldQuery.TAG_BOUNDS, "death line")
	assert_true(query.first_hit(5.0, -50.0, 5.0, -60.0) == null, "the sky above the map is open")


func test_dead_combatants_are_not_hit() -> void:
	var rules: CombatRules = _rules()
	var target: CombatantState = _combatant_at(5.0)
	target.defeat()
	var y: float = target.head_center_y(rules)
	assert_true(CombatWorldQuery.new(_grid(), rules, [target]).first_hit(0.1, y, 9.9, y) == null, "nothing to hit")


func test_collision_simulation_matches_the_calibrated_full_throw() -> void:
	# Flat floor at y = 5, launch just above it: the Full Throw must land where the
	# plane-crossing model says (to within one terrain cell).
	var rules: CombatRules = _rules()
	var cell: float = rules.terrain_cell_size
	var terrain := TerrainMask.new(roundi(30.0 / cell), roundi(10.0 / cell), cell)
	terrain.fill_below_surface(func(_x: float) -> float: return 5.0)
	var params: BallisticParameters = GameMetrics.load_default().create_ballistic_parameters()
	var shot := ShotParameters.new(80.0, BallisticEvidence.FULL_THROW_POWER, 0.0, 1, 2.0, 5.0 - 1e-6)
	var result: BallisticResult = ProjectileSimulation.simulate_with_collisions(shot, params, CombatWorldQuery.new(terrain, rules, []), true)
	var plane: BallisticResult = ProjectileSimulation.simulate_to_plane(shot, params, 5.0 - 1e-6)
	assert_true(result.termination == BallisticResult.Termination.COLLISION, "hits the floor")
	assert_true(result.hit.tag == CombatWorldQuery.TAG_TERRAIN, "terrain hit")
	assert_near(result.impact_x, plane.impact_x, cell, "same landing point as the calibrated model")
	assert_near(result.impact_x - 2.0, 9.9299, cell, "Full Throw D = 10 lands near 9.93 u")
	assert_near(result.flight_time, plane.flight_time, params.time_step, "same flight time")
	note("collision impact %.4f vs plane %.4f" % [result.impact_x - 2.0, plane.impact_x - 2.0])
