class_name Inventory
extends RefCounted
## The Bag: a fixed number of slots. Stackable items merge up to max_stack;
## equipment always takes one slot per instance. Equipped items live in
## EquipmentLoadout, not here.

const DEFAULT_CAPACITY: int = 48

var capacity: int = DEFAULT_CAPACITY
var items: Array[ItemInstance] = []


func used_slots() -> int:
	return items.size()


func free_slots() -> int:
	return capacity - items.size()


func find(uid: int) -> ItemInstance:
	for item in items:
		if item.uid == uid:
			return item
	return null


func count(def_id: StringName) -> int:
	var total: int = 0
	for item in items:
		if item.def_id == def_id:
			total += item.quantity
	return total


## Slots needed to add `quantity` of `def` (0 if it all fits in existing stacks).
func slots_needed(def: ItemDefinition, quantity: int) -> int:
	if not def.is_stackable():
		return quantity
	var room: int = 0
	for item in items:
		if item.def_id == def.id:
			room += def.max_stack - item.quantity
	var rest: int = maxi(0, quantity - room)
	return ceili(float(rest) / def.max_stack)


func can_add(def: ItemDefinition, quantity: int) -> bool:
	return slots_needed(def, quantity) <= free_slots()


## Adds items, merging stacks first. `allocate_uid` returns fresh instance ids.
## Returns false (and adds nothing) when there is not enough room.
func add(def: ItemDefinition, quantity: int, allocate_uid: Callable) -> bool:
	if quantity <= 0 or not can_add(def, quantity):
		return false
	var remaining: int = quantity
	if def.is_stackable():
		for item in items:
			if item.def_id == def.id and item.quantity < def.max_stack:
				var moved: int = mini(remaining, def.max_stack - item.quantity)
				item.quantity += moved
				remaining -= moved
	while remaining > 0:
		var take: int = mini(remaining, def.max_stack) if def.is_stackable() else 1
		var uid: int = allocate_uid.call()
		items.append(ItemInstance.make(uid, def.id, take))
		remaining -= take
	return true


## Inserts an existing instance (e.g. an unequipped item).
func insert(item: ItemInstance) -> bool:
	if free_slots() <= 0:
		return false
	items.append(item)
	return true


func take(uid: int) -> ItemInstance:
	for i in items.size():
		if items[i].uid == uid:
			var item: ItemInstance = items[i]
			items.remove_at(i)
			return item
	return null


## Removes `quantity` units of a stackable definition across stacks.
func remove_quantity(def_id: StringName, quantity: int) -> bool:
	if count(def_id) < quantity:
		return false
	var remaining: int = quantity
	for i in range(items.size() - 1, -1, -1):
		var item: ItemInstance = items[i]
		if item.def_id != def_id or remaining <= 0:
			continue
		var used: int = mini(remaining, item.quantity)
		item.quantity -= used
		remaining -= used
		if item.quantity <= 0:
			items.remove_at(i)
	return true


func to_array() -> Array:
	var data: Array = []
	for item in items:
		data.append(item.to_dict())
	return data


static func from_array(data: Array, p_capacity: int = DEFAULT_CAPACITY) -> Inventory:
	var inventory := Inventory.new()
	inventory.capacity = p_capacity
	for entry: Dictionary in data:
		inventory.items.append(ItemInstance.from_dict(entry))
	return inventory
