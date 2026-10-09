class_name BattleOutcome
extends RefCounted
## What happened in a battle, reported back to the metagame for rewards.

var mode: BattleSetup.Mode = BattleSetup.Mode.SANDBOX
var victory: bool = false
var surrendered: bool = false
var stages_cleared: int = 0
var damage_dealt: int = 0
var shots: int = 0
var hits: int = 0
var kills: int = 0
var heal_items_used: int = 0
var enemy_exp: int = 0
var enemy_gold: int = 0
var instance_id: StringName = &""
var difficulty: int = 0
var room_name: String = ""


func accuracy() -> float:
	return float(hits) / shots if shots > 0 else 0.0
