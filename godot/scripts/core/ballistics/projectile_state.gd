class_name ProjectileState
extends RefCounted
## Kinematic state of a projectile in world units (1.0 = one horizontal distance unit).
##
## The y axis points down (Godot convention), so an upward launch has negative vy.
## Scalars are used instead of Vector2 on purpose: GDScript floats are 64-bit, while
## Vector2 is single precision in standard engine builds.

var x: float
var y: float
var vx: float
var vy: float
var time: float


func _init(p_x: float = 0.0, p_y: float = 0.0, p_vx: float = 0.0, p_vy: float = 0.0, p_time: float = 0.0) -> void:
	x = p_x
	y = p_y
	vx = p_vx
	vy = p_vy
	time = p_time
