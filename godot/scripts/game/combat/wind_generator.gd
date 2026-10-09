class_name WindGenerator
extends RefCounted
## Seeded, reproducible provisional wind: a uniform value in [-wind_max, wind_max]
## snapped to wind_step, drawn once per turn. GAME DESIGN PLACEHOLDER (OQ-08).

var _rng := RandomNumberGenerator.new()
var _rules: CombatRules


func _init(rules: CombatRules) -> void:
	_rules = rules
	_rng.seed = rules.wind_seed


func next_wind() -> float:
	var steps: int = roundi(_rules.wind_max / _rules.wind_step)
	return _rng.randi_range(-steps, steps) * _rules.wind_step
