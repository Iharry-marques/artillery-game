class_name BallisticSolver
extends RefCounted
## Inverse questions about the projectile simulation, e.g. "which angle reaches
## distance D?". Prediction only: it runs ProjectileSimulation as a black box and
## never alters trajectories (DECISIONS D-005).
##
## All shots start at (0, 0), face +x and land on the plane y = 0 (calibration
## geometry). relative_wind > 0 is a tailwind, < 0 a headwind.

## Illinois (modified regula falsi) root finding: bracketed like bisection, but
## converges superlinearly. Stops when |miss| <= ROOT_TOLERANCE distance units or
## when the bracket shrinks below BRACKET_TOLERANCE (relative).
const ROOT_MAX_ITERATIONS: int = 200
const ROOT_TOLERANCE: float = 1e-12
const BRACKET_TOLERANCE: float = 1e-14
const PLANE_Y: float = 0.0


## Horizontal distance travelled until the descending crossing of y = 0, or NAN.
static func impact_distance(
	params: BallisticParameters, angle_degrees: float, power: float, relative_wind: float = 0.0
) -> float:
	var result: BallisticResult = simulate(params, angle_degrees, power, relative_wind)
	return result.impact_x if result.hit_plane() else NAN


static func simulate(
	params: BallisticParameters,
	angle_degrees: float,
	power: float,
	relative_wind: float = 0.0,
	record_samples: bool = false
) -> BallisticResult:
	var shot := ShotParameters.new(angle_degrees, power, relative_wind)
	return ProjectileSimulation.simulate_to_plane(shot, params, PLANE_Y, record_samples)


## Angle in [angle_lo, angle_hi] that lands at distance, or NAN if that range does
## not bracket the target. The range should cover one monotonic branch.
static func solve_angle(
	params: BallisticParameters,
	distance: float,
	power: float,
	relative_wind: float,
	angle_lo: float,
	angle_hi: float
) -> float:
	var f: Callable = func(angle: float) -> float:
		return impact_distance(params, angle, power, relative_wind) - distance
	return _find_root(f, angle_lo, angle_hi)


## Power in [power_lo, power_hi] that lands at distance, or NAN if not bracketed.
static func solve_power(
	params: BallisticParameters,
	distance: float,
	angle_degrees: float,
	relative_wind: float,
	power_lo: float,
	power_hi: float
) -> float:
	var f: Callable = func(power: float) -> float:
		return impact_distance(params, angle_degrees, power, relative_wind) - distance
	return _find_root(f, power_lo, power_hi)


static func _find_root(f: Callable, lo: float, hi: float) -> float:
	var f_lo: float = f.call(lo)
	var f_hi: float = f.call(hi)
	if is_nan(f_lo) or is_nan(f_hi) or f_lo * f_hi > 0.0:
		return NAN
	if absf(f_lo) <= ROOT_TOLERANCE:
		return lo
	if absf(f_hi) <= ROOT_TOLERANCE:
		return hi
	var last_side: int = 0
	var x: float = lo
	for i in ROOT_MAX_ITERATIONS:
		x = (lo * f_hi - hi * f_lo) / (f_hi - f_lo)
		var f_x: float = f.call(x)
		if is_nan(f_x):
			return NAN
		if absf(f_x) <= ROOT_TOLERANCE or absf(hi - lo) <= BRACKET_TOLERANCE * maxf(1.0, absf(x)):
			return x
		if (f_x < 0.0) == (f_hi < 0.0):
			hi = x
			f_hi = f_x
			if last_side == -1:
				f_lo *= 0.5
			last_side = -1
		else:
			lo = x
			f_lo = f_x
			if last_side == 1:
				f_hi *= 0.5
			last_side = 1
	return x
