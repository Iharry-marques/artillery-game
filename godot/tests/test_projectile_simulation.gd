extends TestCase
## Behaviour of the simulation itself, independent of any aiming technique.

const EPS: float = BallisticTolerances.NUMERICAL_EQUIVALENCE


class QuadraticPowerModel:
	extends PowerModel

	func initial_speed(power: float) -> float:
		return 0.01 * power * power


func _params() -> BallisticParameters:
	return GameMetrics.load_default().create_ballistic_parameters()


func test_matches_closed_form_parabola_with_wind() -> void:
	var params: BallisticParameters = _params()
	for wind: float in [-2.0, 0.0, 1.5]:
		var shot := ShotParameters.new(70.0, 80.0, wind)
		var result: BallisticResult = ProjectileSimulation.simulate_to_plane(shot, params, 0.0)
		var speed: float = params.power_model.initial_speed(shot.power)
		var angle: float = deg_to_rad(shot.angle_degrees)
		var vx: float = speed * cos(angle)
		var rise_speed: float = speed * sin(angle)
		var ax: float = wind * params.wind_accel_per_unit
		var flight_time: float = 2.0 * rise_speed / params.gravity
		var apex_time: float = rise_speed / params.gravity
		assert_true(result.hit_plane(), "wind %s: should hit the plane" % wind)
		assert_near(result.flight_time, flight_time, EPS, "wind %s: flight time" % wind)
		assert_near(result.impact_x, vx * flight_time + 0.5 * ax * flight_time * flight_time, EPS, "wind %s: impact x" % wind)
		assert_near(result.impact_y, 0.0, EPS, "wind %s: impact y" % wind)
		assert_near(result.apex_time, apex_time, EPS, "wind %s: apex time" % wind)
		assert_near(result.apex_y, -rise_speed * rise_speed / (2.0 * params.gravity), EPS, "wind %s: apex y" % wind)
		assert_near(result.apex_x, vx * apex_time + 0.5 * ax * apex_time * apex_time, EPS, "wind %s: apex x" % wind)


func test_is_deterministic() -> void:
	var params: BallisticParameters = _params()
	var shot := ShotParameters.new(77.0, 95.0, -1.3)
	var first: BallisticResult = ProjectileSimulation.simulate_to_plane(shot, params, 0.0, true)
	var second: BallisticResult = ProjectileSimulation.simulate_to_plane(shot, params, 0.0, true)
	assert_true(first.impact_x == second.impact_x, "impact x must be bit-identical")
	assert_true(first.flight_time == second.flight_time, "flight time must be bit-identical")
	assert_true(first.samples == second.samples, "trajectory samples must be identical")


func test_facing_mirrors_the_trajectory() -> void:
	var params: BallisticParameters = _params()
	var right: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(60.0, 70.0, 0.8, 1), params, 0.0)
	var left: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(60.0, 70.0, -0.8, -1), params, 0.0)
	assert_near(left.impact_x, -right.impact_x, EPS, "mirrored shot with mirrored wind")
	assert_near(left.flight_time, right.flight_time, EPS, "mirrored flight time")


func test_launch_position_only_translates_the_trajectory() -> void:
	var params: BallisticParameters = _params()
	var at_origin: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(75.0, 90.0, 0.5), params, 0.0)
	var shifted: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(75.0, 90.0, 0.5, 1, 12.0, -3.0), params, -3.0)
	assert_near(shifted.impact_x - 12.0, at_origin.impact_x, EPS, "translated impact")
	assert_near(shifted.flight_time, at_origin.flight_time, EPS, "translated flight time")


func test_landing_points_do_not_depend_on_gravity_when_k_is_fixed() -> void:
	var metrics: GameMetrics = GameMetrics.load_default()
	var reference: PackedFloat64Array = BallisticCalibrator.full_throw_errors(metrics.create_ballistic_parameters())
	for gravity: float in [1.0, 3.0, 12.5]:
		var variant: GameMetrics = BallisticCalibrator.with_values(metrics, metrics.ballistic_k, metrics.wind_accel_ratio, gravity)
		var errors: PackedFloat64Array = BallisticCalibrator.full_throw_errors(variant.create_ballistic_parameters())
		for i in errors.size():
			assert_near(errors[i], reference[i], EPS, "gravity %s, D = %d" % [gravity, i + 1])


func test_rise_and_fall_inside_one_step_still_hits_the_plane() -> void:
	# Regression: a hop shorter than one time step used to be reported as NO_ASCENT.
	var params: BallisticParameters = _params()
	var shot := ShotParameters.new(45.0, 0.5)
	var result: BallisticResult = ProjectileSimulation.simulate_to_plane(shot, params, 0.0)
	var speed: float = params.power_model.initial_speed(shot.power)
	var expected_flight_time: float = 2.0 * speed * sin(deg_to_rad(45.0)) / params.gravity
	assert_true(expected_flight_time < params.time_step, "scenario must fit inside one step")
	assert_true(result.hit_plane(), "short hop must hit the plane, got %s" % result.termination_name())
	assert_near(result.flight_time, expected_flight_time, EPS, "short hop flight time")


func test_flat_shot_reports_no_ascent() -> void:
	var result: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(0.0, 50.0), _params(), 0.0)
	assert_true(result.termination == BallisticResult.Termination.NO_ASCENT, "got %s" % result.termination_name())


func test_max_time_stops_the_simulation() -> void:
	var params: BallisticParameters = _params()
	params.max_time = 0.5
	var result: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(80.0, 95.0), params, 0.0)
	assert_true(result.termination == BallisticResult.Termination.MAX_TIME, "got %s" % result.termination_name())
	assert_true(result.flight_time <= 0.5 + params.time_step, "stopped near max_time")


func test_power_model_is_replaceable() -> void:
	var params: BallisticParameters = _params()
	params.power_model = QuadraticPowerModel.new()
	var result: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(60.0, 40.0), params, 0.0)
	assert_near(result.launch_speed, 16.0, EPS, "simulation must use the injected power model")
