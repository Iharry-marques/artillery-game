class_name Reward
extends RefCounted
## A bundle of EXP, currencies and items granted by battles, quests and mail.

var exp: int = 0
var gold: int = 0
var coupons: int = 0
var vouchers: int = 0
## Each entry: {"id": StringName, "qty": int}.
var items: Array[Dictionary] = []


static func make(p_exp: int = 0, p_gold: int = 0, p_items: Array[Dictionary] = [], p_coupons: int = 0, p_vouchers: int = 0) -> Reward:
	var reward := Reward.new()
	reward.exp = p_exp
	reward.gold = p_gold
	reward.items = p_items
	reward.coupons = p_coupons
	reward.vouchers = p_vouchers
	return reward


static func item(id: StringName, qty: int = 1) -> Dictionary:
	return {"id": id, "qty": qty}


func is_empty() -> bool:
	return exp == 0 and gold == 0 and coupons == 0 and vouchers == 0 and items.is_empty()


func to_dict() -> Dictionary:
	var item_list: Array = []
	for entry in items:
		var id: StringName = entry["id"]
		item_list.append({"id": String(id), "qty": entry["qty"]})
	return {"exp": exp, "gold": gold, "coupons": coupons, "vouchers": vouchers, "items": item_list}


static func from_dict(data: Dictionary) -> Reward:
	var reward := Reward.new()
	reward.exp = DataReader.get_int(data, "exp")
	reward.gold = DataReader.get_int(data, "gold")
	reward.coupons = DataReader.get_int(data, "coupons")
	reward.vouchers = DataReader.get_int(data, "vouchers")
	for entry: Dictionary in DataReader.get_array(data, "items"):
		reward.items.append({"id": DataReader.get_string_name(entry, "id"), "qty": DataReader.get_int(entry, "qty", 1)})
	return reward
