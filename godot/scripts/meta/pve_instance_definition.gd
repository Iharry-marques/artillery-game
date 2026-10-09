class_name PveInstanceDefinition
extends RefCounted
## An Expedition dungeon: sequential stages, difficulty scaling and loot.

enum Difficulty { NORMAL, HARD, HERO }

const HP_SCALE: Array[float] = [1.0, 1.5, 2.2]
const DAMAGE_SCALE: Array[float] = [1.0, 1.3, 1.7]
const REWARD_SCALE: Array[float] = [1.0, 1.7, 2.6]

var id: StringName
var display_name: String
var description: String
var level_required: int = 1
## Each stage: {"title": String, "map": StringName, "enemies": Array[{"enemy": StringName, "x": float}]}.
var stages: Array[Dictionary] = []
## Flip-card loot pool: {"id": StringName, "qty": int, "weight": int}.
var loot: Array[Dictionary] = []
var clear_reward: Reward = Reward.new()


static func difficulty_name(value: Difficulty) -> String:
	return ["Normal", "Hard", "Hero"][value]
