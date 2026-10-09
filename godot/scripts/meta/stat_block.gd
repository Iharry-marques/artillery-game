class_name StatBlock
extends RefCounted
## Character / equipment attributes (REFERENCE ESTIMATE model, docs/PRODUCT_SHELL.md).
## attack, defense, agility, luck are the classic base stats; harm comes from the
## weapon, armor from clothes/hat, hp is a flat bonus.

const FIELDS: Array[StringName] = [&"attack", &"defense", &"agility", &"luck", &"harm", &"armor", &"hp"]

var attack: int = 0
var defense: int = 0
var agility: int = 0
var luck: int = 0
var harm: int = 0
var armor: int = 0
var hp: int = 0


static func make(p_attack: int = 0, p_defense: int = 0, p_agility: int = 0, p_luck: int = 0, p_harm: int = 0, p_armor: int = 0, p_hp: int = 0) -> StatBlock:
	var block := StatBlock.new()
	block.attack = p_attack
	block.defense = p_defense
	block.agility = p_agility
	block.luck = p_luck
	block.harm = p_harm
	block.armor = p_armor
	block.hp = p_hp
	return block


func plus(other: StatBlock) -> StatBlock:
	return StatBlock.make(
		attack + other.attack, defense + other.defense, agility + other.agility, luck + other.luck,
		harm + other.harm, armor + other.armor, hp + other.hp
	)


func scaled(factor: float) -> StatBlock:
	return StatBlock.make(
		roundi(attack * factor), roundi(defense * factor), roundi(agility * factor), roundi(luck * factor),
		roundi(harm * factor), roundi(armor * factor), roundi(hp * factor)
	)


func get_stat(field: StringName) -> int:
	return get(field)


func is_zero() -> bool:
	for field in FIELDS:
		if get_stat(field) != 0:
			return false
	return true


func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for field in FIELDS:
		var value: int = get_stat(field)
		if value != 0:
			data[String(field)] = value
	return data


static func from_dict(data: Dictionary) -> StatBlock:
	var block := StatBlock.new()
	for field in FIELDS:
		block.set(field, DataReader.get_int(data, String(field)))
	return block
