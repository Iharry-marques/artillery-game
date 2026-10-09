class_name BattleSetup
extends RefCounted
## Everything the battle scene needs to start a match: mode, map(s) and the
## participants. Built by GameSession from a room (PvP) or an instance (PvE).

enum Mode { SANDBOX, PVP, PVE }
enum Controller { HUMAN, AI_ARTILLERY, ENEMY_MELEE, ENEMY_ARTILLERY, BOSS }


class Participant:
	extends RefCounted
	var display_name: String
	var team: int = 0
	var controller: Controller = Controller.HUMAN
	var loadout: CombatLoadout
	## Proxy art key: &"player_blue", &"player_red" or an enemy visual.
	var visual: StringName = &"player_blue"
	var is_local_player: bool = false
	## Spawn x; NAN = pick a pad of the map.
	var spawn_x: float = NAN
	var aim_error_degrees: float = 4.0
	var reach: float = 1.0
	var move_budget: float = 4.0
	var exp_reward: int = 0
	var gold_reward: int = 0


var mode: Mode = Mode.SANDBOX
var room_name: String = ""
## PvP: one map. PvE: one map per stage.
var maps: Array[StringName] = []
## Team 0 (players) persists across PvE stages; enemies are per stage.
var players: Array[Participant] = []
## PvE only: enemies of each stage.
var stage_enemies: Array = []
var stage_titles: PackedStringArray = PackedStringArray()
var instance_id: StringName = &""
var difficulty: int = 0
## PvP only: the opposing team (team 1).
var opponents: Array[Participant] = []
var battle_seed: int = 1


func stage_count() -> int:
	return maps.size()


func participants_for_stage(stage: int) -> Array[Participant]:
	var list: Array[Participant] = []
	list.append_array(players)
	if mode == Mode.PVE:
		var enemies: Array = stage_enemies[stage]
		for enemy: Participant in enemies:
			list.append(enemy)
	else:
		list.append_array(opponents)
	return list
