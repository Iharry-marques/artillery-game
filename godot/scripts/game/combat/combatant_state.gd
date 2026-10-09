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


func weapon_pivot_x(rules: CombatRules) -> float:
	return feet_x + facing * rules.weapon_pivot_forward


func weapon_pivot_y(rules: CombatRules) -> float:
	return feet_y - rules.weapon_pivot_up


## Launch point: tip of the barrel at `angle_degrees` (OQ-09). The ballistic model
## is calibrated from a point launch; this is gameplay geometry, not a recalibration.
func muzzle_x(rules: CombatRules, angle_degrees: float) -> float:
	return weapon_pivot_x(rules) + facing * rules.weapon_barrel_length * cos(deg_to_rad(angle_degrees))


func muzzle_y(rules: CombatRules, angle_degrees: float) -> float:
	return weapon_pivot_y(rules) - rules.weapon_barrel_length * sin(deg_to_rad(angle_degrees))


func is_inside_head(rules: CombatRules, x: float, y: float) -> bool:
	var dx: float = x - head_center_x()
	var dy: float = y - head_center_y(rules)
	return dx * dx + dy * dy <= rules.head_radius * rules.head_radius


func apply_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp == 0:
		alive = false


func defeat() -> void:
	hp = 0
	alive = false
