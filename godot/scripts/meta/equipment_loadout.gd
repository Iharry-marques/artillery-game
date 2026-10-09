class_name EquipmentLoadout
extends RefCounted
## Equipped items by slot. Equipping moves the instance out of the Bag; the
## previous item in that slot goes back to the Bag.

var equipped: Dictionary = {}


func get_item(slot: ItemDefinition.Slot) -> ItemInstance:
	return equipped.get(slot, null)


func all_items() -> Array[ItemInstance]:
	var result: Array[ItemInstance] = []
	for slot: int in equipped:
		var item: ItemInstance = equipped[slot]
		result.append(item)
	return result


func find(uid: int) -> ItemInstance:
	for item in all_items():
		if item.uid == uid:
			return item
	return null


## Returns an error message, or "" on success.
func equip(inventory: Inventory, content: ContentDatabase, uid: int, level: int) -> String:
	var item: ItemInstance = inventory.find(uid)
	if item == null:
		return "Item not in the bag"
	var def: ItemDefinition = content.item(item.def_id)
	if def == null or not def.is_equipment():
		return "This item cannot be equipped"
	if level < def.level_required:
		return "Requires level %d" % def.level_required
	var slot: ItemDefinition.Slot = def.slot()
	inventory.take(uid)
	var previous: ItemInstance = get_item(slot)
	if previous != null:
		inventory.insert(previous)
	item.bound = true
	equipped[slot] = item
	return ""


func unequip(inventory: Inventory, slot: ItemDefinition.Slot) -> String:
	var item: ItemInstance = get_item(slot)
	if item == null:
		return "Nothing equipped"
	if not inventory.insert(item):
		return "The bag is full"
	equipped.erase(slot)
	return ""


func to_dict() -> Dictionary:
	var data: Dictionary = {}
	for slot: int in equipped:
		var item: ItemInstance = equipped[slot]
		data[str(slot)] = item.to_dict()
	return data


static func from_dict(data: Dictionary) -> EquipmentLoadout:
	var loadout := EquipmentLoadout.new()
	for key: String in data:
		var entry: Dictionary = data[key]
		loadout.equipped[key.to_int()] = ItemInstance.from_dict(entry)
	return loadout
