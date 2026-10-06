class_name BallisticSolver
extends RefCounted
## Inverse questions about the projectile simulation, e.g. "which angle reaches
## distance D?". Prediction only: it runs ProjectileSimulation as a black box and
## never alters trajectories (DECISIONS D-005).
##
## All shots start at (0, 0) and face +x; the motion is mirror-symmetric, so a
## shot facing -x is the same problem with the relative wind. Impact is the
## descending crossing of the horizontal plane y = target_y (Godot convention:
## y grows downward, so target_y < 0 is ABOVE the shooter). relative_wind > 0 is
## a tailwind, < 0 a headwind.

## Illinois (modified regula falsi) root finding: bracketed like bisection, but
## converges superlinearly. Stops when |miss| <= ROOT_TOLERANCE distance units or
## when the bracket shrinks below BRACKET_TOLERANCE (relative).
const ROOT_MAX_ITERATIONS: int = 200
const ROOT_TOLERANCE: float = 1e-12
const BRACKET_TOLERANCE: float = 1e-14
## Bisection steps used to find the edge of the reachable region when one end of
## the search range cannot reach the target plane (e.g. too little power for an
## elevated target).
const REACHABLE_EDGE_ITERATIONS: int = 60


## Horizontal distance travelled until the descending crossing of y = target_y, or
## NAN if the projectile never reaches that plane while descending.
static func impact_distance(
	params: BallisticParameters,
	angle_degrees: float,
	power: float,
	relative_wind: float = 0.0,
	target_y: float = 0.0
) -> float:
	var result: BallisticResult = simulate(params, angle_degrees, power, relative_wind, false, target_y)
	return result.impact_x if result.hit_plane() else NAN


static func simulate(
	params: BallisticParameters,
	angle_degrees: float,
	power: float,
	relative_wind: float = 0.0,
	record_samples: bool = false,
	target_y: float = 0.0
) -> BallisticResult:
	var shot := ShotParameters.new(angle_degrees, power, relative_wind)
	return ProjectileSimulation.simulate_to_plane(shot, params, target_y, record_samples)


## Angle in [angle_lo, angle_hi] that lands at distance, or NAN if that range does
## not bracket the target. The range should cover one monotonic branch.
static func solve_angle(
	params: BallisticParameters,
	distance: float,
	power: float,
	relative_wind: float,
	angle_lo: float,
	angle_hi: float,
	target_y: float = 0.0
) -> float:
	var f: Callable = func(angle: float) -> float:
		return impact_distance(params, angle, power, relative_wind, target_y) - distance
	return _find_root(f, angle_lo, angle_hi)


## Power in [power_lo, power_hi] that lands at distance, or NAN if not bracketed.
static func solve_power(
	params: BallisticParameters,
	distance: float,
	angle_degrees: float,
	relative_wind: float,
	power_lo: float,
	power_hi: float,
	target_y: float = 0.0
) -> float:
	var f: Callable = func(power: float) -> float:
		return impact_distance(params, angle_degrees, power, relative_wind, target_y) - distance
	return _find_root(f, power_lo, power_hi)


## Root of f in [lo, hi], or NAN when there is none. f is NAN where the target
## plane is unreachable; that region is assumed to touch only one end of the range,
## which is then moved to the edge of the reachable region before searching.
static func _find_root(f: Callable, lo: float, hi: float) -> float:
	var f_lo: float = f.call(lo)
	var f_hi: float = f.call(hi)
	if is_nan(f_lo) and is_nan(f_hi):
		return NAN
	if is_nan(f_lo):
		lo = _reachable_edge(f, lo, hi)
		f_lo = f.call(lo)
	elif is_nan(f_hi):
		hi = _reachable_edge(f, hi, lo)
		f_hi = f.call(hi)
	if f_lo * f_hi > 0.0:
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


## Point nearest to `unreachable` (within the bisection resolution) where f is defined.
static func _reachable_edge(f: Callable, unreachable: float, reachable: float) -> float:
	for i in REACHABLE_EDGE_ITERATIONS:
		var mid: float = 0.5 * (unreachable + reachable)
		var value: float = f.call(mid)
		if is_nan(value):
			unreachable = mid
		else:
			reachable = mid
	return reachable
