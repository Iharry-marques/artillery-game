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
var max_hp: int
var angle: int
var movement_left: float
var alive: bool = true
## Team id (sandbox: one team per player). Battles end when one team remains.
var team: int = 0
var controller: BattleSetup.Controller = BattleSetup.Controller.HUMAN
## Stat-based battle data; null in the plain sandbox (placeholder damage model).
var loadout: CombatLoadout
var visual: StringName = &"player_blue"
var is_local_player: bool = false
## Hit geometry (from the loadout, else CombatRules).
var head_radius: float
var head_height: float
var anchored: bool = false
var turn_movement: float
var reach: float = 1.0
var aim_error_degrees: float = 4.0
var exp_reward: int = 0
var gold_reward: int = 0
# Battle statistics.
var shots: int = 0
var hits: int = 0
var damage_dealt: int = 0
var kills: int = 0
var heals_used: int = 0
var healed_this_turn: bool = false
var actions_taken: int = 0


func _init(p_index: int, p_name: String, p_feet_x: float, p_feet_y: float, p_facing: int, rules: CombatRules) -> void:
	index = p_index
	team = p_index
	display_name = p_name
	feet_x = p_feet_x
	feet_y = p_feet_y
	facing = p_facing
	hp = rules.starting_hp
	max_hp = rules.starting_hp
	angle = rules.initial_angle
	turn_movement = rules.movement_budget
	movement_left = rules.movement_budget
	head_radius = rules.head_radius
	head_height = rules.head_center_height


## Applies a stat loadout (battle setups): HP, hit geometry and angle limits.
func apply_loadout(p_loadout: CombatLoadout) -> void:
	loadout = p_loadout
	max_hp = p_loadout.max_hp
	hp = max_hp
	head_radius = p_loadout.head_radius
	head_height = p_loadout.head_center_height
	anchored = p_loadout.anchored
	angle = clampi(angle, p_loadout.min_angle, p_loadout.max_angle)


func has_weapon() -> bool:
	return loadout == null or loadout.weapon_art != &""


## Head centre in 64-bit floats (gameplay geometry). Use head_center() only for drawing.
func head_center_x() -> float:
	return feet_x


func head_center_y(_rules: CombatRules = null) -> float:
	return feet_y - head_height


## Single precision (Vector2): for presentation only.
func head_center(rules: CombatRules) -> Vector2:
	return Vector2(head_center_x(), head_center_y(rules))


func weapon_pivot_x(rules: CombatRules) -> float:
	return feet_x + facing * rules.weapon_pivot_forward


func weapon_pivot_y(rules: CombatRules) -> float:
	return feet_y - rules.weapon_pivot_up


## Launch point: tip of the barrel at `angle_degrees` (OQ-09). The ballistic model
## is calibrated from a point launch; this is gameplay geometry, not a recalibration.
## Weaponless monsters throw from the front-top of their head.
func muzzle_x(rules: CombatRules, angle_degrees: float) -> float:
	if not has_weapon():
		return feet_x + facing * head_radius * 0.8
	return weapon_pivot_x(rules) + facing * rules.weapon_barrel_length * cos(deg_to_rad(angle_degrees))


func muzzle_y(rules: CombatRules, angle_degrees: float) -> float:
	if not has_weapon():
		return head_center_y() - head_radius * 0.8
	return weapon_pivot_y(rules) - rules.weapon_barrel_length * sin(deg_to_rad(angle_degrees))


func is_inside_head(_rules: CombatRules, x: float, y: float) -> bool:
	var dx: float = x - head_center_x()
	var dy: float = y - head_center_y()
	return dx * dx + dy * dy <= head_radius * head_radius


func heal(amount: int) -> void:
	hp = mini(max_hp, hp + amount)


func apply_damage(amount: int) -> void:
	hp = maxi(0, hp - amount)
	if hp == 0:
		alive = false


func defeat() -> void:
	hp = 0
	alive = false
