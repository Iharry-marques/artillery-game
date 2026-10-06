class_name PowerModel
extends RefCounted
## Maps the power gauge value (0..100) to launch speed in world units per second.
##
## This is the only place where power becomes speed. The current hypothesis is
## linear (LinearPowerModel); a nonlinear mapping can replace it without changing
## ProjectileSimulation.


func initial_speed(_power: float) -> float:
	push_error("PowerModel.initial_speed() must be overridden.")
	return 0.0
