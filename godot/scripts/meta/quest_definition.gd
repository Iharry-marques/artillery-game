class_name QuestDefinition
extends RefCounted
## A lightweight main quest: count an event up to a target, then claim a reward.

var id: StringName
var title: String
var description: String
## GameSession event that advances it (e.g. &"battle_finished", &"pvp_win").
var event: StringName
var target: int = 1
var reward: Reward = Reward.new()


static func make(p_id: StringName, p_title: String, p_description: String, p_event: StringName, p_target: int, p_reward: Reward) -> QuestDefinition:
	var quest := QuestDefinition.new()
	quest.id = p_id
	quest.title = p_title
	quest.description = p_description
	quest.event = p_event
	quest.target = p_target
	quest.reward = p_reward
	return quest
