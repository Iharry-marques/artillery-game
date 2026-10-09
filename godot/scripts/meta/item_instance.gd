class_name ItemInstance
extends RefCounted
## A concrete item owned by the player: stack size, strengthening level,
## composition bonuses and binding.

var uid: int
var def_id: StringName
var quantity: int = 1
var enhance_level: int = 0
## Bonus from Blacksmith composition (element stones).
var composed: StatBlock = StatBlock.new()
var bound: bool = false


static func make(p_uid: int, p_def_id: StringName, p_quantity: int = 1) -> ItemInstance:
	var item := ItemInstance.new()
	item.uid = p_uid
	item.def_id = p_def_id
	item.quantity = p_quantity
	return item


func to_dict() -> Dictionary:
	return {
		"uid": uid, "def": String(def_id), "qty": quantity, "enhance": enhance_level,
		"composed": composed.to_dict(), "bound": bound,
	}


static func from_dict(data: Dictionary) -> ItemInstance:
	var item := ItemInstance.make(DataReader.get_int(data, "uid"), DataReader.get_string_name(data, "def"), DataReader.get_int(data, "qty", 1))
	item.enhance_level = DataReader.get_int(data, "enhance")
	item.composed = StatBlock.from_dict(DataReader.get_dict(data, "composed"))
	item.bound = DataReader.get_bool(data, "bound")
	return item
