class_name ExactKinematicIntegrator
extends BallisticIntegrator
## Baseline integrator (DECISIONS D-012): exact kinematics for constant acceleration.
##
##   p(t + dt) = p + v * dt + 0.5 * a * dt^2
##   v(t + dt) = v + a * dt
##
## Every step lands exactly on the analytic parabola, so the trajectory does not
## depend on the time step (up to floating-point rounding).


func advance(state: ProjectileState, ax: float, ay: float, dt: float) -> ProjectileState:
	var half_dt_squared: float = 0.5 * dt * dt
	return ProjectileState.new(
		state.x + state.vx * dt + ax * half_dt_squared,
		state.y + state.vy * dt + ay * half_dt_squared,
		state.vx + ax * dt,
		state.vy + ay * dt,
		state.time + dt
	)
