class_name EnemyDefinition
extends RefCounted
## A PvE monster template. Stats use the same REFERENCE ESTIMATE damage model as
## players; behaviour picks the AI brain.

enum Behavior { MELEE, ARTILLERY, BOSS }

var id: StringName
var display_name: String
var behavior: Behavior
## Proxy art key (assets/enemies/<visual>.png).
var visual: StringName
var max_hp: int
var stats: StatBlock = StatBlock.new()
var head_radius: float = 0.3
var head_center_height: float = 0.6
var crater_radius: float = 0.5
var damage_radius: float = 1.0
var min_angle: int = 20
var max_angle: int = 85
## Melee reach in u (MELEE / BOSS slam).
var reach: float = 1.0
var move_budget: float = 3.0
## Anchored enemies never fall (bosses ignore ring-out).
var anchored: bool = false
## Aim error (degrees, 1 sigma) for artillery shots.
var aim_error_degrees: float = 3.0
var exp_reward: int = 0
var gold_reward: int = 0
