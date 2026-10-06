class_name BallisticIntegrator
extends RefCounted
## Strategy that advances a ProjectileState under a constant acceleration.
##
## The simulation only talks to this interface, so a discrete legacy integrator
## (e.g. semi-implicit Euler) can be added later and compared without touching
## ProjectileSimulation. advance() must accept any dt in [0, time_step]: the
## simulation also calls it with partial steps to locate apex and plane crossings.


func advance(_state: ProjectileState, _ax: float, _ay: float, _dt: float) -> ProjectileState:
	push_error("BallisticIntegrator.advance() must be overridden.")
	return null
