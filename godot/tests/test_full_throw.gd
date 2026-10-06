extends TestCase
## Full Throw (power 95) as a calibration TEST of the single physical model.
## Nothing here changes the physics; the rule is evaluated from the outside.


func _params() -> BallisticParameters:
	return GameMetrics.load_default().create_ballistic_parameters()


func _assert_zero_wind_hit(distance: float) -> void:
	var angle: float = BallisticEvidence.full_throw_angle(distance, 0.0)
	var impact: float = BallisticSolver.impact_distance(_params(), angle, BallisticEvidence.FULL_THROW_POWER)
	assert_near(impact, distance, BallisticTolerances.FULL_THROW_MAX_IMPACT_ERROR, "D = %s, angle %s" % [distance, angle])
	note("D = %s, angle %s: impact %.4f (error %+.4f)" % [distance, angle, impact, impact - distance])


func test_distance_3_angle_87() -> void:
	_assert_zero_wind_hit(3.0)


func test_distance_5_angle_85() -> void:
	_assert_zero_wind_hit(5.0)


func test_distance_10_angle_80() -> void:
	_assert_zero_wind_hit(10.0)


func test_distances_1_to_10_follow_angle_90_minus_distance() -> void:
	var errors: PackedFloat64Array = BallisticCalibrator.full_throw_errors(_params())
	var sum_abs: float = 0.0
	var max_abs: float = 0.0
	for i in errors.size():
		var distance: float = BallisticEvidence.FULL_THROW_DISTANCES[i]
		assert_near(distance + errors[i], distance, BallisticTolerances.FULL_THROW_MAX_IMPACT_ERROR, "D = %s" % distance)
		sum_abs += absf(errors[i])
		max_abs = maxf(max_abs, absf(errors[i]))
	var mean_abs: float = sum_abs / errors.size()
	assert_true(mean_abs <= BallisticTolerances.FULL_THROW_MEAN_IMPACT_ERROR, "mean absolute error %.4f" % mean_abs)
	note("mean absolute error %.4f u, max %.4f u" % [mean_abs, max_abs])


func test_wind_correction_is_two_degrees_per_unit() -> void:
	var worst: float = 0.0
	for row in BallisticCalibrator.wind_corrections(_params()):
		var error: float = row["error"]
		assert_near(error, 0.0, BallisticTolerances.WIND_CORRECTION_ERROR_DEGREES, "D = %s, wind %+.1f: correction %+.4f" % [
			row["distance"], row["wind"], row["correction"]
		])
		worst = maxf(worst, absf(error))
	note("worst wind correction error: %.4f degrees" % worst)


func test_aiming_with_the_wind_rule_hits_the_target() -> void:
	var params: BallisticParameters = _params()
	for distance in BallisticEvidence.WIND_RULE_CHECK_DISTANCES:
		for wind in BallisticTolerances.WIND_RULE_TEST_WINDS:
			var angle: float = BallisticEvidence.full_throw_angle(distance, wind)
			var impact: float = BallisticSolver.impact_distance(params, angle, BallisticEvidence.FULL_THROW_POWER, wind)
			assert_near(impact, distance, BallisticTolerances.WIND_RULE_IMPACT_ERROR, "D = %s, wind %+.1f, angle %s" % [distance, wind, angle])
