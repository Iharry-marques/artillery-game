class_name ContentDatabase
extends RefCounted
## All static content (items, quests, maps, enemies, dungeons, shop). Built by
## ContentCatalog; read-only at runtime.

var items: Dictionary = {}
var quests: Array[QuestDefinition] = []
var maps: Dictionary = {}
var enemies: Dictionary = {}
var instances: Array[PveInstanceDefinition] = []
var shop: Array[ShopListing] = []
var starter_equipment: Array[StringName] = []
var starter_bag: Array[Dictionary] = []
var starter_wallet: CurrencyWallet = CurrencyWallet.new()
var welcome_mails: Array[MailMessage] = []
var pvp_maps: Array[StringName] = []
var room_names: PackedStringArray = PackedStringArray()
var npc_names: PackedStringArray = PackedStringArray()


func item(id: StringName) -> ItemDefinition:
	return items.get(id, null)


func map(id: StringName) -> MapDefinition:
	return maps.get(id, null)


func enemy(id: StringName) -> EnemyDefinition:
	return enemies.get(id, null)


func instance(id: StringName) -> PveInstanceDefinition:
	for def in instances:
		if def.id == id:
			return def
	return null


func quest(id: StringName) -> QuestDefinition:
	for def in quests:
		if def.id == id:
			return def
	return null


func add_item(def: ItemDefinition) -> ItemDefinition:
	items[def.id] = def
	return def
