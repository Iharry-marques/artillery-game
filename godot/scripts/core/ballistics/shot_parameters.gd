class_name ShotParameters
extends RefCounted
## What the shooter controls for one shot, plus the wind of the turn.

var origin_x: float
var origin_y: float
## Degrees above the horizontal, measured in the facing direction.
var angle_degrees: float
## Gauge value, nominally 0..100.
var power: float
## +1 shoots toward +x, -1 toward -x.
var facing: int
## Signed world wind: positive pushes toward +x, regardless of facing.
var wind: float


func _init(
	p_angle_degrees: float,
	p_power: float,
	p_wind: float = 0.0,
	p_facing: int = 1,
	p_origin_x: float = 0.0,
	p_origin_y: float = 0.0
) -> void:
	angle_degrees = p_angle_degrees
	power = p_power
	wind = p_wind
	facing = p_facing
	origin_x = p_origin_x
	origin_y = p_origin_y
