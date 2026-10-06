class_name BallisticCalibrator
extends RefCounted
## Solves the ballistic parameters from BallisticEvidence by running the real
## simulator (DECISIONS D-004). Used by the calibration tool and by the tests.
##
## Error metrics (docs/PHYSICS_MODEL.md), both minimised with Gauss-Newton:
## - K: least squares of the Full Throw impact error,
##   sum over D = 1..10 of (impact(angle = 90 - D, power = 95) - D)^2.
## - Wind ratio: least squares of the wind correction error,
##   sum over D and W = +/-1 of (solved_angle(W) - solved_angle(0) - 2 * W)^2.

## Gauss-Newton settings for the one-parameter least-squares fits.
const GAUSS_NEWTON_MAX_ITERATIONS: int = 50
## Relative step size at which the fit stops. The finite-difference derivative
## carries ~1e-10 relative noise, so tighter values only add iterations.
const GAUSS_NEWTON_TOLERANCE: float = 1e-9
## Relative finite-difference step for the residual derivative.
const FINITE_DIFFERENCE_STEP: float = 1e-6
## Starting points. Impacts are exactly linear in K and nearly linear in the wind
## ratio, so the fits do not depend on these guesses.
const K_INITIAL_GUESS: float = 1.0
const WIND_RATIO_INITIAL_GUESS: float = 0.0
## Gravity used while solving time-scale-independent quantities. Landing points do not
## depend on it once K is fixed (verified by tests).
const UNIT_GRAVITY: float = 1.0


## Runs the full calibration. Engineering values (time step, max flight time) are
## taken from base; the result is a new GameMetrics.
static func calibrate(base: GameMetrics) -> GameMetrics:
	var k: float = calibrate_k(base)
	var gravity: float = gravity_for_flight_time(base, k, BallisticEvidence.PROVISIONAL_FULL_THROW_FLIGHT_TIME)
	var without_wind: GameMetrics = with_values(base, k, 0.0, gravity)
	var wind_ratio: float = calibrate_wind_ratio(without_wind)
	return with_values(base, k, wind_ratio, gravity)


static func with_values(base: GameMetrics, k: float, wind_ratio: float, gravity: float) -> GameMetrics:
	var metrics: GameMetrics = base.duplicate() as GameMetrics
	metrics.ballistic_k = k
	metrics.ballistic_k_reference_power = BallisticEvidence.FULL_THROW_POWER
	metrics.wind_accel_ratio = wind_ratio
	metrics.gravity = gravity
	return metrics


# --- Zero-wind Full Throw ---------------------------------------------------


static func calibrate_k(base: GameMetrics) -> float:
	var residuals: Callable = func(k: float) -> PackedFloat64Array:
		return full_throw_errors(with_values(base, k, 0.0, UNIT_GRAVITY).create_ballistic_parameters())
	return least_squares_1d(residuals, K_INITIAL_GUESS)


## Impact errors (impact - D) of the zero-wind Full Throw rule, one per distance.
static func full_throw_errors(params: BallisticParameters) -> PackedFloat64Array:
	var errors := PackedFloat64Array()
	for distance in BallisticEvidence.FULL_THROW_DISTANCES:
		var angle: float = BallisticEvidence.full_throw_angle(distance, 0.0)
		var impact: float = BallisticSolver.impact_distance(params, angle, BallisticEvidence.FULL_THROW_POWER)
		errors.append(impact - distance)
	return errors


## Independent closed-form check of K for a drag-free parabola on flat ground:
## impact = K * sin(2 * angle), so least squares gives K = sum(D * s) / sum(s^2).
static func analytic_k_least_squares() -> float:
	var numerator: float = 0.0
	var denominator: float = 0.0
	for distance in BallisticEvidence.FULL_THROW_DISTANCES:
		var s: float = sin(2.0 * deg_to_rad(BallisticEvidence.full_throw_angle(distance, 0.0)))
		numerator += distance * s
		denominator += s * s
	return numerator / denominator


# --- Time scale ---------------------------------------------------------------


static func full_throw_flight_time(params: BallisticParameters, distance: float) -> float:
	var angle: float = BallisticEvidence.full_throw_angle(distance, 0.0)
	return BallisticSolver.simulate(params, angle, BallisticEvidence.FULL_THROW_POWER).flight_time


## With K fixed, flight time scales as 1 / sqrt(gravity): measure it at unit
## gravity and rescale. The caller should verify the result with the simulator.
static func gravity_for_flight_time(base: GameMetrics, k: float, target_flight_time: float) -> float:
	var unit_params: BallisticParameters = with_values(base, k, 0.0, UNIT_GRAVITY).create_ballistic_parameters()
	var unit_time: float = full_throw_flight_time(unit_params, BallisticEvidence.FLIGHT_TIME_REFERENCE_DISTANCE)
	var ratio: float = unit_time / target_flight_time
	return UNIT_GRAVITY * ratio * ratio


# --- Wind ---------------------------------------------------------------------


static func calibrate_wind_ratio(metrics: GameMetrics) -> float:
	var residuals: Callable = func(ratio: float) -> PackedFloat64Array:
		var params: BallisticParameters = with_values(metrics, metrics.ballistic_k, ratio, metrics.gravity).create_ballistic_parameters()
		var errors := PackedFloat64Array()
		for row in wind_corrections(params):
			var error: float = row["error"]
			errors.append(error)
		return errors
	return least_squares_1d(residuals, WIND_RATIO_INITIAL_GUESS)


## One row per (distance, +/- calibration wind): the angle that really hits D with
## and without wind, the measured correction and its error versus the player rule.
static func wind_corrections(params: BallisticParameters) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var magnitude: float = BallisticEvidence.WIND_CALIBRATION_MAGNITUDE
	for distance in BallisticEvidence.WIND_CALIBRATION_DISTANCES:
		var zero_angle: float = solve_high_angle(params, distance, 0.0)
		for wind: float in [-magnitude, magnitude]:
			var wind_angle: float = solve_high_angle(params, distance, wind)
			var correction: float = wind_angle - zero_angle
			rows.append({
				"distance": distance,
				"wind": wind,
				"zero_angle": zero_angle,
				"wind_angle": wind_angle,
				"correction": correction,
				"error": correction - BallisticEvidence.FULL_THROW_WIND_FACTOR * wind,
			})
	return rows


static func solve_high_angle(params: BallisticParameters, distance: float, relative_wind: float) -> float:
	return BallisticSolver.solve_angle(
		params,
		distance,
		BallisticEvidence.FULL_THROW_POWER,
		relative_wind,
		BallisticEvidence.HIGH_BRANCH_MIN_ANGLE,
		BallisticEvidence.HIGH_BRANCH_MAX_ANGLE
	)


# --- Predictions (same model, no tuning) -----------------------------------


## For a fixed-angle technique: zero-wind power for distance, the angle correction
## that compensates +/-1 wind at that power, and the power correction alternative.
## NAN means the branch has no solution.
static func technique_prediction(params: BallisticParameters, technique_angle: float, distance: float) -> Dictionary:
	var branch: Vector2 = BallisticEvidence.angle_branch(technique_angle)
	var power: float = BallisticSolver.solve_power(
		params, distance, technique_angle, 0.0, BallisticEvidence.SEARCH_MIN_POWER, BallisticEvidence.SEARCH_MAX_POWER
	)
	var prediction: Dictionary = {"angle": technique_angle, "distance": distance, "power": power}
	for label: String in ["head", "tail"]:
		var wind: float = -1.0 if label == "head" else 1.0
		var wind_angle: float = BallisticSolver.solve_angle(params, distance, power, wind, branch.x, branch.y)
		var wind_power: float = BallisticSolver.solve_power(
			params, distance, technique_angle, wind, BallisticEvidence.SEARCH_MIN_POWER, BallisticEvidence.SEARCH_MAX_POWER
		)
		prediction[label + "_angle_correction"] = wind_angle - technique_angle
		prediction[label + "_power_correction"] = wind_power - power
	return prediction


## Power that best fits angle = 90 - 2 * D over the Full Throw distances (least squares).
static func half_throw_best_power(params: BallisticParameters) -> float:
	var residuals: Callable = func(power: float) -> PackedFloat64Array:
		return half_throw_errors(params, power)
	return least_squares_1d(residuals, BallisticEvidence.FULL_THROW_POWER)


static func half_throw_errors(params: BallisticParameters, power: float) -> PackedFloat64Array:
	var errors := PackedFloat64Array()
	for distance in BallisticEvidence.FULL_THROW_DISTANCES:
		var impact: float = BallisticSolver.impact_distance(params, BallisticEvidence.half_throw_angle(distance), power)
		errors.append(impact - distance)
	return errors


# --- Numerics -----------------------------------------------------------------


## Minimises sum(residuals(p)^2) over one parameter with Gauss-Newton, using a
## forward finite difference for the derivative. Returns NAN if a residual is NAN.
static func least_squares_1d(residuals: Callable, initial: float) -> float:
	var p: float = initial
	for i in GAUSS_NEWTON_MAX_ITERATIONS:
		var h: float = FINITE_DIFFERENCE_STEP * maxf(absf(p), 1.0)
		var r: PackedFloat64Array = residuals.call(p)
		var r_h: PackedFloat64Array = residuals.call(p + h)
		var numerator: float = 0.0
		var denominator: float = 0.0
		for j in r.size():
			var derivative: float = (r_h[j] - r[j]) / h
			numerator += derivative * r[j]
			denominator += derivative * derivative
		if is_nan(numerator) or is_nan(denominator) or denominator == 0.0:
			return NAN
		var delta: float = -numerator / denominator
		p += delta
		if absf(delta) <= GAUSS_NEWTON_TOLERANCE * maxf(absf(p), 1.0):
			return p
	push_warning("least_squares_1d did not converge; returning the last estimate.")
	return p
