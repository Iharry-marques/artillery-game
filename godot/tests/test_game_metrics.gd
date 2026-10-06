extends TestCase
## The stored metrics must be reproducible from the calibration code.

const RELATIVE_EPS: float = 1e-9


func test_metrics_resource_is_complete() -> void:
	var metrics: GameMetrics = GameMetrics.load_default()
	assert_true(metrics != null, "game_metrics.tres must load")
	if metrics == null:
		return
	for property: StringName in [&"ballistic_k", &"ballistic_k_reference_power", &"wind_accel_ratio", &"gravity", &"time_step", &"max_flight_time", &"battle_view_width_units"]:
		var value: float = metrics.get(property)
		assert_true(value > 0.0, "%s must be positive, got %s" % [property, value])


func test_stored_metrics_match_a_fresh_calibration() -> void:
	var stored: GameMetrics = GameMetrics.load_default()
	var fresh: GameMetrics = BallisticCalibrator.calibrate(stored)
	for property: StringName in [&"ballistic_k", &"ballistic_k_reference_power", &"wind_accel_ratio", &"gravity"]:
		var expected: float = fresh.get(property)
		var actual: float = stored.get(property)
		assert_near(actual, expected, RELATIVE_EPS * absf(expected), "%s (run tools/ballistics/calibrate.sh --write-metrics)" % property)


func test_derived_values_follow_k_and_gravity() -> void:
	var metrics: GameMetrics = GameMetrics.load_default()
	var launch_speed: float = metrics.create_power_model().initial_speed(metrics.ballistic_k_reference_power)
	assert_near(launch_speed * launch_speed / metrics.gravity, metrics.ballistic_k, RELATIVE_EPS * metrics.ballistic_k, "v(ref)^2 / g == K")
	assert_near(metrics.wind_accel_per_unit() / metrics.gravity, metrics.wind_accel_ratio, RELATIVE_EPS, "wind accel / g == ratio")


func test_provisional_full_throw_flight_time() -> void:
	var params: BallisticParameters = GameMetrics.load_default().create_ballistic_parameters()
	var flight_time: float = BallisticCalibrator.full_throw_flight_time(params, BallisticEvidence.FLIGHT_TIME_REFERENCE_DISTANCE)
	assert_near(flight_time, BallisticEvidence.PROVISIONAL_FULL_THROW_FLIGHT_TIME, 1e-6, "Full Throw flight time at D = 10")
