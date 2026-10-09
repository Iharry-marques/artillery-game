class_name ProjectileSimulation
extends RefCounted
## Deterministic projectile simulation: ONE physical model for every aiming technique.
##
## Pure logic with no nodes, scene tree, physics frames or render frames.
## Candidate model (docs/PHYSICS_MODEL.md): constant gravity on +y, wind as a
## constant horizontal acceleration, no drag. Aiming techniques never branch here.

## Bisection iterations used to locate the apex and the plane crossing inside a
## step. 64 halvings shrink any time-step bracket below double precision.
const SUB_STEP_BISECTION_ITERATIONS: int = 64


## Simulates until the projectile crosses the horizontal plane y = plane_y while
## descending (calibration geometry: no terrain, no hitboxes, no muzzle offset).
static func simulate_to_plane(
	shot: ShotParameters,
	params: BallisticParameters,
	plane_y: float,
	record_samples: bool = false
) -> BallisticResult:
	var integrator: BallisticIntegrator = params.integrator
	var speed: float = params.power_model.initial_speed(shot.power)
	var angle: float = deg_to_rad(shot.angle_degrees)
	var ax: float = shot.wind * params.wind_accel_per_unit
	var ay: float = params.gravity
	var state := ProjectileState.new(
		shot.origin_x, shot.origin_y, shot.facing * speed * cos(angle), -speed * sin(angle), 0.0
	)

	var result := BallisticResult.new()
	result.launch_speed = speed
	_store_apex(result, state)
	if record_samples:
		_record_sample(result, state)

	var max_steps: int = ceili(params.max_time / params.time_step)
	for step in max_steps:
		var next: ProjectileState = integrator.advance(state, ax, ay, params.time_step)
		result.step_count = step + 1

		# A step may contain the apex. The descending crossing can only lie after it,
		# even when the whole rise and fall happen inside this single step.
		var descent_start: ProjectileState = state
		var descent_tau: float = 0.0
		if state.vy < 0.0 and next.vy >= 0.0:
			descent_tau = _locate_within_step(
				state, ax, ay, 0.0, params.time_step, integrator, func(s: ProjectileState) -> float: return s.vy
			)
			descent_start = integrator.advance(state, ax, ay, descent_tau)
			_store_apex(result, descent_start)

		if descent_start.y < plane_y and next.y >= plane_y:
			var impact_tau: float = _locate_within_step(
				state, ax, ay, descent_tau, params.time_step, integrator,
				func(s: ProjectileState) -> float: return s.y - plane_y
			)
			_finish(result, BallisticResult.Termination.IMPACT_PLANE, integrator.advance(state, ax, ay, impact_tau), record_samples)
			return result

		# Below the plane, moving down, and it did not cross: with gravity > 0 it never rises again.
		if next.y >= plane_y and next.vy >= 0.0:
			_finish(result, BallisticResult.Termination.NO_ASCENT, next, record_samples)
			return result

		state = next
		if record_samples:
			_record_sample(result, state)

	_finish(result, BallisticResult.Termination.MAX_TIME, state, false)
	return result


## Simulates until `query` reports a hit on the segment between two consecutive
## states (gameplay geometry: terrain, hitboxes, map bounds). The trajectory is the
## same as simulate_to_plane(); only the termination differs. The impact is the
## query's contact point on the segment, at time state.time + fraction * dt.
static func simulate_with_collisions(
	shot: ShotParameters,
	params: BallisticParameters,
	query: BallisticCollisionQuery,
	record_samples: bool = false
) -> BallisticResult:
	var integrator: BallisticIntegrator = params.integrator
	var speed: float = params.power_model.initial_speed(shot.power)
	var angle: float = deg_to_rad(shot.angle_degrees)
	var ax: float = shot.wind * params.wind_accel_per_unit
	var ay: float = params.gravity
	var state := ProjectileState.new(
		shot.origin_x, shot.origin_y, shot.facing * speed * cos(angle), -speed * sin(angle), 0.0
	)

	var result := BallisticResult.new()
	result.launch_speed = speed
	_store_apex(result, state)
	if record_samples:
		_record_sample(result, state)

	var max_steps: int = ceili(params.max_time / params.time_step)
	for step in max_steps:
		var next: ProjectileState = integrator.advance(state, ax, ay, params.time_step)
		result.step_count = step + 1
		var hit: BallisticHit = query.first_hit(state.x, state.y, next.x, next.y)
		var hit_tau: float = hit.fraction * params.time_step if hit != null else params.time_step

		if state.vy < 0.0 and next.vy >= 0.0:
			var apex_tau: float = _locate_within_step(
				state, ax, ay, 0.0, params.time_step, integrator, func(s: ProjectileState) -> float: return s.vy
			)
			if apex_tau <= hit_tau:
				_store_apex(result, integrator.advance(state, ax, ay, apex_tau))

		if hit != null:
			var contact := ProjectileState.new(hit.x, hit.y, 0.0, 0.0, state.time + hit_tau)
			result.hit = hit
			_finish(result, BallisticResult.Termination.COLLISION, contact, record_samples)
			return result

		state = next
		if record_samples:
			_record_sample(result, state)

	_finish(result, BallisticResult.Termination.MAX_TIME, state, false)
	return result


## Finds the sub-step time in [lo, hi] where metric(state) changes from < 0 to >= 0.
## Uses the integrator itself, so the located point lies on the integrator's own path.
static func _locate_within_step(
	state: ProjectileState,
	ax: float,
	ay: float,
	lo: float,
	hi: float,
	integrator: BallisticIntegrator,
	metric: Callable
) -> float:
	for i in SUB_STEP_BISECTION_ITERATIONS:
		var mid: float = 0.5 * (lo + hi)
		var value: float = metric.call(integrator.advance(state, ax, ay, mid))
		if value < 0.0:
			lo = mid
		else:
			hi = mid
	return hi


static func _store_apex(result: BallisticResult, state: ProjectileState) -> void:
	result.apex_x = state.x
	result.apex_y = state.y
	result.apex_time = state.time


static func _finish(
	result: BallisticResult,
	termination: BallisticResult.Termination,
	state: ProjectileState,
	record_sample: bool
) -> void:
	result.termination = termination
	result.impact_x = state.x
	result.impact_y = state.y
	result.flight_time = state.time
	if record_sample:
		_record_sample(result, state)


static func _record_sample(result: BallisticResult, state: ProjectileState) -> void:
	result.samples.append(Vector2(state.x, state.y))
	result.sample_times.append(state.time)
