class_name PlayerProfile
extends RefCounted
## The local (offline) player account: identity, progression, currencies, Bag,
## equipment, quests, mail and counters. Serialised by SaveService.

const VERSION: int = 1

var nickname: String = "Player"
## 0 = blue outfit, 1 = red outfit (proxy art variants).
var outfit: int = 0
var level: int = 1
var exp: int = 0
var wallet: CurrencyWallet = CurrencyWallet.new()
var inventory: Inventory = Inventory.new()
var equipment: EquipmentLoadout = EquipmentLoadout.new()
## Quest id -> {"progress": int, "claimed": bool}.
var quests: Dictionary = {}
var mails: Array[MailMessage] = []
## Lifetime counters (battles, wins, strengthen attempts...).
var counters: Dictionary = {}
## Deterministic local RNG: every random roll advances this counter.
var rng_seed: int = 20261009
var rng_counter: int = 0
var next_uid: int = 1


func allocate_uid() -> int:
	next_uid += 1
	return next_uid - 1


func uid_allocator() -> Callable:
	return allocate_uid


func next_rng() -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([rng_seed, rng_counter])
	rng_counter += 1
	return rng


func counter(key: StringName) -> int:
	return counters.get(key, 0)


func bump_counter(key: StringName, amount: int = 1) -> void:
	counters[key] = counter(key) + amount


## Finds an item in the Bag or equipped.
func find_item(uid: int) -> ItemInstance:
	var item: ItemInstance = inventory.find(uid)
	return item if item != null else equipment.find(uid)


func is_equipped(uid: int) -> bool:
	return equipment.find(uid) != null


func to_dict() -> Dictionary:
	var mail_list: Array = []
	for mail in mails:
		mail_list.append(mail.to_dict())
	var counter_data: Dictionary = {}
	for key: StringName in counters:
		counter_data[String(key)] = counters[key]
	return {
		"version": VERSION, "nickname": nickname, "outfit": outfit, "level": level, "exp": exp,
		"wallet": wallet.to_dict(), "inventory": inventory.to_array(), "capacity": inventory.capacity,
		"equipment": equipment.to_dict(), "quests": quests, "mails": mail_list, "counters": counter_data,
		"rng_seed": rng_seed, "rng_counter": rng_counter, "next_uid": next_uid,
	}


static func from_dict(data: Dictionary) -> PlayerProfile:
	var profile := PlayerProfile.new()
	profile.nickname = DataReader.get_string(data, "nickname", "Player")
	profile.outfit = DataReader.get_int(data, "outfit")
	profile.level = DataReader.get_int(data, "level", 1)
	profile.exp = DataReader.get_int(data, "exp")
	profile.wallet = CurrencyWallet.from_dict(DataReader.get_dict(data, "wallet"))
	profile.inventory = Inventory.from_array(DataReader.get_array(data, "inventory"), DataReader.get_int(data, "capacity", Inventory.DEFAULT_CAPACITY))
	profile.equipment = EquipmentLoadout.from_dict(DataReader.get_dict(data, "equipment"))
	var quest_data: Dictionary = DataReader.get_dict(data, "quests")
	for key: String in quest_data:
		var state: Dictionary = quest_data[key]
		profile.quests[StringName(key)] = {"progress": DataReader.get_int(state, "progress"), "claimed": DataReader.get_bool(state, "claimed")}
	for entry: Dictionary in DataReader.get_array(data, "mails"):
		profile.mails.append(MailMessage.from_dict(entry))
	var counter_data: Dictionary = DataReader.get_dict(data, "counters")
	for key: String in counter_data:
		profile.counters[StringName(key)] = DataReader.get_int(counter_data, key)
	profile.rng_seed = DataReader.get_int(data, "rng_seed", profile.rng_seed)
	profile.rng_counter = DataReader.get_int(data, "rng_counter")
	profile.next_uid = DataReader.get_int(data, "next_uid", 1)
	return profile
