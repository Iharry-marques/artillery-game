class_name BallisticParameters
extends RefCounted
## Physical parameters of the world for a simulation run.
##
## Usually built from GameMetrics.create_ballistic_parameters(); calibration code
## builds them directly to explore candidate values.

## World units per second squared, pointing down (+y).
var gravity: float
## Horizontal acceleration (world units / s^2) produced by 1.0 of displayed wind.
var wind_accel_per_unit: float
var power_model: PowerModel
var integrator: BallisticIntegrator
## Fixed simulation step in seconds.
var time_step: float
## Safety limit: the simulation stops with MAX_TIME after this many seconds.
var max_time: float


func _init(
	p_gravity: float,
	p_wind_accel_per_unit: float,
	p_power_model: PowerModel,
	p_time_step: float,
	p_max_time: float,
	p_integrator: BallisticIntegrator = null
) -> void:
	gravity = p_gravity
	wind_accel_per_unit = p_wind_accel_per_unit
	power_model = p_power_model
	time_step = p_time_step
	max_time = p_max_time
	integrator = p_integrator if p_integrator != null else ExactKinematicIntegrator.new()


func with_time_step(p_time_step: float) -> BallisticParameters:
	return BallisticParameters.new(gravity, wind_accel_per_unit, power_model, p_time_step, max_time, integrator)
