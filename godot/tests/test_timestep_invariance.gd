extends TestCase
## The baseline integrator is exact for constant acceleration (DECISIONS D-012), so
## impact, flight time and apex must not depend on the time step.

const EPS: float = BallisticTolerances.NUMERICAL_EQUIVALENCE


func test_impact_flight_time_and_apex_are_time_step_invariant() -> void:
	var params: BallisticParameters = GameMetrics.load_default().create_ballistic_parameters()
	var worst: float = 0.0
	for shot in BallisticEvidence.TIME_STEP_CHECK_SHOTS:
		var results: Array[BallisticResult] = []
		for dt in BallisticEvidence.TIME_STEP_VARIANTS:
			results.append(BallisticSolver.simulate(params.with_time_step(dt), shot.x, shot.y, shot.z))
		var reference: BallisticResult = results[0]
		for i in range(1, results.size()):
			var other: BallisticResult = results[i]
			var label: String = "angle %s power %s wind %s, dt %s" % [
				shot.x, shot.y, shot.z, BallisticEvidence.TIME_STEP_LABELS[i]
			]
			assert_true(other.hit_plane(), "%s: should hit the plane" % label)
			assert_near(other.impact_x, reference.impact_x, EPS, "%s: impact x" % label)
			assert_near(other.flight_time, reference.flight_time, EPS, "%s: flight time" % label)
			assert_near(other.apex_x, reference.apex_x, EPS, "%s: apex x" % label)
			assert_near(other.apex_y, reference.apex_y, EPS, "%s: apex y" % label)
			worst = maxf(worst, absf(other.impact_x - reference.impact_x))
	note("worst impact spread across dt = 1/30, 1/60, 1/120: %s u" % String.num_scientific(worst))
