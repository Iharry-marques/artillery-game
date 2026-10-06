extends TestCase
## BallisticSolver with a target plane above or below the shooter (Godot y-down:
## target_y < 0 is ABOVE). Deterministic checks against the simulator itself.

const EPS: float = BallisticTolerances.NUMERICAL_EQUIVALENCE
const POWER: float = BallisticEvidence.FULL_THROW_POWER
const TARGET_HEIGHTS: Array[float] = [-3.0, -1.0, 0.0, 1.0, 3.0]
const DISTANCES: Array[float] = [3.0, 5.0, 10.0]
## Higher than the Full Throw apex (~14 u): unreachable at power 95.
const UNREACHABLE_TARGET_Y: float = -20.0
## Fixed angle for power solving: steep enough that the apex of the weakest shot
## reaching y = -3 lies before x = 3 (apex x ~1.6 u), so every case is solvable.
const POWER_SOLVE_ANGLE: float = 75.0


func _params() -> BallisticParameters:
	return GameMetrics.load_default().create_ballistic_parameters()


func test_solved_angle_hits_targets_at_any_height() -> void:
	var params: BallisticParameters = _params()
	for target_y in TARGET_HEIGHTS:
		for distance in DISTANCES:
			var angle: float = BallisticSolver.solve_angle(
				params, distance, POWER, 0.0,
				BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE, target_y
			)
			var label: String = "D %s, target y %s" % [distance, target_y]
			assert_true(not is_nan(angle), "%s: a high-arc solution must exist" % label)
			var result: BallisticResult = BallisticSolver.simulate(params, angle, POWER, 0.0, false, target_y)
			assert_true(result.hit_plane(), "%s: must hit the target plane" % label)
			assert_near(result.impact_x, distance, EPS, "%s: impact x" % label)
			assert_near(result.impact_y, target_y, EPS, "%s: impact y" % label)


func test_solved_power_hits_targets_at_any_height() -> void:
	var params: BallisticParameters = _params()
	for target_y in TARGET_HEIGHTS:
		for distance in DISTANCES:
			var power: float = BallisticSolver.solve_power(
				params, distance, POWER_SOLVE_ANGLE, 0.5,
				BallisticEvidence.SEARCH_MIN_POWER, BallisticEvidence.SEARCH_MAX_POWER, target_y
			)
			var label: String = "D %s, target y %s" % [distance, target_y]
			assert_true(not is_nan(power), "%s: a power solution must exist" % label)
			assert_near(
				BallisticSolver.impact_distance(params, POWER_SOLVE_ANGLE, power, 0.5, target_y), distance, EPS, "%s: impact x" % label
			)


func test_lower_target_plane_is_crossed_farther() -> void:
	# Same shot: a lower plane is crossed later, so the projectile lands farther.
	var params: BallisticParameters = _params()
	var above: float = BallisticSolver.impact_distance(params, 85.0, POWER, 0.0, -2.0)
	var level: float = BallisticSolver.impact_distance(params, 85.0, POWER, 0.0, 0.0)
	var below: float = BallisticSolver.impact_distance(params, 85.0, POWER, 0.0, 2.0)
	assert_true(above < level and level < below, "impact order above < level < below: %s, %s, %s" % [above, level, below])


func test_default_target_plane_is_unchanged() -> void:
	var params: BallisticParameters = _params()
	var implicit: float = BallisticSolver.solve_angle(
		params, 7.0, POWER, -1.0, BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE
	)
	var explicit: float = BallisticSolver.solve_angle(
		params, 7.0, POWER, -1.0, BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE, 0.0
	)
	assert_true(implicit == explicit, "target_y defaults to 0")


func test_unreachable_height_reports_no_solution() -> void:
	var params: BallisticParameters = _params()
	assert_true(is_nan(BallisticSolver.impact_distance(params, 80.0, POWER, 0.0, UNREACHABLE_TARGET_Y)), "impact must be NAN")
	var angle: float = BallisticSolver.solve_angle(
		params, 5.0, POWER, 0.0, BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE, UNREACHABLE_TARGET_Y
	)
	assert_true(is_nan(angle), "no angle can reach a plane above the apex")


func test_descending_crossing_cannot_happen_before_the_apex() -> void:
	# D 3, target 3 u above, 60 deg: even the weakest shot that reaches y = -3 peaks
	# at x ~3.46, so it can only cross that plane DESCENDING beyond x = 3.
	var power: float = BallisticSolver.solve_power(
		_params(), 3.0, 60.0, 0.0, BallisticEvidence.SEARCH_MIN_POWER, BallisticEvidence.SEARCH_MAX_POWER, -3.0
	)
	assert_true(is_nan(power), "no power solution, got %s" % power)
