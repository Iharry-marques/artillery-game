class_name GameMetrics
extends Resource
## Central gameplay constants. Values live in res://config/game_metrics.tres; their
## evidence class and origin are documented in docs/GAME_METRICS.md.
##
## The ballistic data is stored as the quantities the evidence actually constrains:
## two dimensionless relationships (CALIBRATED) plus one time-scale value
## (ESTIMATED). power_scale and the wind acceleration are derived, never stored.

const DEFAULT_PATH: String = "res://config/game_metrics.tres"

@export_group("Calibrated relationships")
## K = v(ballistic_k_reference_power)^2 / gravity, in distance units. Fixes where shots land.
@export var ballistic_k: float = 0.0
## Power at which ballistic_k is defined (the Full Throw power).
@export var ballistic_k_reference_power: float = 0.0
## Horizontal wind acceleration produced by 1.0 of wind, as a fraction of gravity.
@export var wind_accel_ratio: float = 0.0

@export_group("Time scale (provisional)")
## Distance units per second squared. Changes flight duration only, not landing points.
@export var gravity: float = 0.0

@export_group("Simulation")
## Fixed step in seconds. The baseline integrator makes results independent of it.
@export var time_step: float = 0.0
## Safety cut-off for a single flight, in seconds.
@export var max_flight_time: float = 0.0


static func load_default() -> GameMetrics:
	return load(DEFAULT_PATH) as GameMetrics


## Launch speed per power point, from K and gravity (linear power hypothesis).
func power_scale() -> float:
	return sqrt(ballistic_k * gravity) / ballistic_k_reference_power


func wind_accel_per_unit() -> float:
	return wind_accel_ratio * gravity


func create_power_model() -> PowerModel:
	return LinearPowerModel.new(power_scale())


func create_ballistic_parameters() -> BallisticParameters:
	return BallisticParameters.new(
		gravity, wind_accel_per_unit(), create_power_model(), time_step, max_flight_time
	)
