class_name LinearPowerModel
extends PowerModel
## Candidate hypothesis (not historically confirmed): initial_speed = power * power_scale.

var power_scale: float


func _init(p_power_scale: float) -> void:
	power_scale = p_power_scale


func initial_speed(power: float) -> float:
	return power * power_scale
