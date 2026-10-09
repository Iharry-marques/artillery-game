class_name CombatantState
extends RefCounted
## Gameplay state of one character. The FeetAnchor (feet_x, feet_y) is the stable
## reference: movement and terrain support use it. The head circle is the hittable
## geometry; the body is visual only (docs/COMBAT_SANDBOX.md).

var index: int
var display_name: String
var feet_x: float
var feet_y: float
var facing: int
var hp: int
var angle: int
var movement_left: float
var alive: bool = true


func _init(p_index: int, p_name: String, p_feet_x: float, p_feet_y: float, p_facing: int, rules: CombatRules) -> void:
	index = p_index
	display_name = p_name
	feet_x = p_feet_x
	feet_y = p_feet_y
	facing = p_facing
	hp = rules.starting_hp
	angle = rules.initial_angle
	movement_left = rules.movement_budget


## Head centre in 64-bit floats (gameplay geometry). Use head_center() only for drawing.
func head_center_x() -> float:
	return feet_x


func head_center_y(rules: CombatRules) -> float:
	return feet_y - rules.head_center_height


## Single precision (Vector2): for presentation only.
func head_center(rules: CombatRules) -> Vector2:
	return Vector2(head_center_x(), head_center_y(rules))


## Provisional launch point (OQ-09). The ballistic model itself is calibrated from
## a point launch; this offset is gameplay geometry, not a recalibration.
func muzzle_x(rules: CombatRules) -> float:
	return feet_x + facing * rules.muzzle_forward


func muzzle_y(rules: CombatRules) -> float:
	return feet_y - rules.muzzle_up


func apply_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp == 0:
		alive = false


func defeat() -> void:
	hp = 0
	alive = false
