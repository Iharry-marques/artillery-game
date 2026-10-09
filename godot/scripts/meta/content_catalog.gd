class_name ContentCatalog
extends RefCounted
## The ORIGINAL proxy content of the reference clone: names, numbers and drop
## tables are placeholders inspired by the classic structure (docs/PRODUCT_SHELL.md),
## not historical data.

static var _cached: ContentDatabase


static func shared() -> ContentDatabase:
	if _cached == null:
		_cached = build()
	return _cached


static func build() -> ContentDatabase:
	var db := ContentDatabase.new()
	_add_weapons(db)
	_add_armor(db)
	_add_materials(db)
	_add_consumables(db)
	_add_shop(db)
	_add_maps(db)
	_add_enemies(db)
	_add_instances(db)
	_add_quests(db)
	_add_starter_kit(db)
	db.room_names = PackedStringArray([
		"Casual 1v1, all welcome", "Newbies only!", "Wind masters", "Quick match", "High angle practice",
		"No mercy", "Friendly sparring", "Full Throw club", "Last one standing", "Sunset duel",
	])
	db.npc_names = PackedStringArray([
		"Pipo", "Lumi", "Captain Bolt", "Mochi", "Rook", "Tansy", "Juniper", "Ziggy", "Nova", "Bramble",
		"Kiko", "Sora", "Pepper", "Quill", "Hazel",
	])
	return db


static func _item(id: StringName, name: String, kind: ItemDefinition.Kind, description: String, color: Color, rarity: int = 0) -> ItemDefinition:
	var def := ItemDefinition.new()
	def.id = id
	def.display_name = name
	def.kind = kind
	def.description = description
	def.color = color
	def.rarity = rarity
	return def


static func _add_weapons(db: ContentDatabase) -> void:
	var sunburst := _item(&"wpn_sunburst", "Sunburst Launcher", ItemDefinition.Kind.WEAPON,
		"Balanced starter launcher. Full 0-90 angle range.", Color(1.0, 0.6, 0.18))
	sunburst.stats = StatBlock.make(20, 0, 10, 10, 180)
	sunburst.weapon_art = &"launcher"
	sunburst.projectile_art = &"shell"
	sunburst.weapon_style = "Balanced"
	sunburst.sell_gold = 300
	db.add_item(sunburst)

	var boulder := _item(&"wpn_boulder", "Boulder Mortar", ItemDefinition.Kind.WEAPON,
		"Heavy high-angle mortar. Tough and digs big craters, but cannot fire below 30 degrees.", Color(0.55, 0.62, 0.75), 1)
	boulder.stats = StatBlock.make(10, 45, -5, 5, 165, 6)
	boulder.min_angle = 30
	boulder.max_angle = 90
	boulder.crater_radius = 0.85
	boulder.damage_radius = 1.15
	boulder.weapon_art = &"mortar"
	boulder.projectile_art = &"boulder"
	boulder.weapon_style = "Tank / Digger"
	boulder.level_required = 2
	boulder.sell_gold = 1200
	db.add_item(boulder)

	var spark := _item(&"wpn_spark", "Spark Repeater", ItemDefinition.Kind.WEAPON,
		"Hard-hitting low-angle repeater. Small craters, cannot fire above 65 degrees.", Color(0.4, 0.85, 1.0), 2)
	spark.stats = StatBlock.make(40, 0, 20, 15, 230)
	spark.min_angle = 0
	spark.max_angle = 65
	spark.crater_radius = 0.45
	spark.damage_radius = 0.9
	spark.weapon_art = &"spark"
	spark.projectile_art = &"spark"
	spark.weapon_style = "Damage"
	spark.level_required = 3
	spark.sell_gold = 2000
	db.add_item(spark)


static func _add_armor(db: ContentDatabase) -> void:
	var tunic := _item(&"clo_cotton", "Cotton Tunic", ItemDefinition.Kind.CLOTHES, "Comfortable everyday tunic.", Color(0.45, 0.65, 0.95))
	tunic.stats = StatBlock.make(0, 20, 5, 0, 0, 12)
	tunic.sell_gold = 150
	db.add_item(tunic)
	var vest := _item(&"clo_scale", "Scale Vest", ItemDefinition.Kind.CLOTHES, "Overlapping scales turn splash damage aside.", Color(0.4, 0.75, 0.55), 1)
	vest.stats = StatBlock.make(0, 45, 0, 5, 0, 26)
	vest.level_required = 2
	vest.sell_gold = 900
	db.add_item(vest)
	var cap := _item(&"hat_cap", "Explorer Cap", ItemDefinition.Kind.HAT, "A cap with a lucky feather.", Color(0.95, 0.75, 0.3))
	cap.stats = StatBlock.make(0, 12, 0, 5, 0, 8)
	cap.sell_gold = 120
	db.add_item(cap)
	var helm := _item(&"hat_horn", "Horned Helm", ItemDefinition.Kind.HAT, "Dropped in Sprout Hollow. Sturdy and a little scary.", Color(0.75, 0.55, 0.4), 2)
	helm.stats = StatBlock.make(5, 30, 0, 0, 0, 18)
	helm.sell_gold = 800
	db.add_item(helm)
	var ring := _item(&"ring_amber", "Amber Ring", ItemDefinition.Kind.RING, "Warm amber that sharpens aim and luck.", Color(1.0, 0.7, 0.2), 1)
	ring.stats = StatBlock.make(15, 0, 0, 15)
	ring.sell_gold = 600
	db.add_item(ring)
	var pendant := _item(&"neck_leaf", "Leaf Pendant", ItemDefinition.Kind.NECKLACE, "A living leaf that keeps you on your feet.", Color(0.4, 0.85, 0.4), 1)
	pendant.stats = StatBlock.make(0, 0, 10, 0, 0, 0, 120)
	pendant.sell_gold = 600
	db.add_item(pendant)


static func _add_materials(db: ContentDatabase) -> void:
	var stone_colors: Array[Color] = [Color(0.6, 0.85, 1.0), Color(0.45, 0.9, 0.5), Color(1.0, 0.75, 0.25), Color(0.95, 0.4, 0.9)]
	for level in range(1, 5):
		var stone := _item(StringName("stone_%d" % level), "Strengthen Stone Lv%d" % level, ItemDefinition.Kind.STONE,
			"Used at the Blacksmith to strengthen weapons, clothes and hats. Higher levels give better odds.",
			stone_colors[level - 1], level - 1)
		stone.stone_level = level
		stone.max_stack = 99
		stone.sell_gold = 20 * level * level
		db.add_item(stone)
	var elements: Array[Array] = [
		[&"elem_attack", "Ember Stone", &"attack", Color(1.0, 0.4, 0.3)],
		[&"elem_defense", "Shell Stone", &"defense", Color(0.35, 0.55, 0.8)],
		[&"elem_agility", "Breeze Stone", &"agility", Color(0.4, 0.9, 0.85)],
		[&"elem_luck", "Clover Stone", &"luck", Color(0.5, 0.9, 0.35)],
	]
	for entry in elements:
		var element_id: StringName = entry[0]
		var element_name: String = entry[1]
		var element_stat: StringName = entry[2]
		var element_color: Color = entry[3]
		var element := _item(element_id, element_name, ItemDefinition.Kind.ELEMENT_STONE,
			"Composition stone: adds %s to an equipment piece at the Blacksmith." % String(element_stat).capitalize(), element_color, 1)
		element.element = element_stat
		element.max_stack = 99
		element.sell_gold = 50
		db.add_item(element)
	var charm := _item(&"charm_luck", "Lucky Charm", ItemDefinition.Kind.CHARM, "+15% strengthening chance for one attempt.", Color(0.4, 1.0, 0.6), 1)
	charm.charm_bonus = 0.15
	charm.max_stack = 99
	db.add_item(charm)
	var seal := _item(&"charm_guard", "Guardian Seal", ItemDefinition.Kind.PROTECTION, "Protects an item from losing a level when strengthening fails.", Color(0.95, 0.9, 0.5), 2)
	seal.max_stack = 99
	db.add_item(seal)


static func _add_consumables(db: ContentDatabase) -> void:
	var heal := _item(&"item_heal", "Healing Kit", ItemDefinition.Kind.CONSUMABLE, "Battle item: restore 300 HP (key 1, once per turn).", Color(1.0, 0.45, 0.5))
	heal.heal_amount = 300
	heal.max_stack = 99
	heal.sell_gold = 30
	db.add_item(heal)
	var box := _item(&"box_starter", "Starter Gift Box", ItemDefinition.Kind.BOX, "Open it from the Bag for a few useful supplies.", Color(1.0, 0.55, 0.75), 1)
	box.max_stack = 99
	box.box_contents = [Reward.item(&"stone_1", 5), Reward.item(&"item_heal", 2), Reward.item(&"elem_attack", 2)]
	db.add_item(box)


static func _add_shop(db: ContentDatabase) -> void:
	var gold := CurrencyWallet.Currency.GOLD
	var coupons := CurrencyWallet.Currency.COUPONS
	var vouchers := CurrencyWallet.Currency.VOUCHERS
	db.shop = [
		ShopListing.make(&"wpn_boulder", ShopListing.Category.WEAPONS, gold, 6000),
		ShopListing.make(&"wpn_spark", ShopListing.Category.WEAPONS, coupons, 1200),
		ShopListing.make(&"wpn_sunburst", ShopListing.Category.WEAPONS, gold, 1500),
		ShopListing.make(&"clo_scale", ShopListing.Category.CLOTHES, gold, 4500),
		ShopListing.make(&"clo_cotton", ShopListing.Category.CLOTHES, gold, 800),
		ShopListing.make(&"hat_cap", ShopListing.Category.CLOTHES, gold, 600),
		ShopListing.make(&"ring_amber", ShopListing.Category.CLOTHES, coupons, 800),
		ShopListing.make(&"neck_leaf", ShopListing.Category.CLOTHES, vouchers, 900),
		ShopListing.make(&"item_heal", ShopListing.Category.CONSUMABLES, gold, 400, 3),
		ShopListing.make(&"box_starter", ShopListing.Category.CONSUMABLES, vouchers, 300),
		ShopListing.make(&"stone_1", ShopListing.Category.MATERIALS, gold, 500, 5),
		ShopListing.make(&"stone_2", ShopListing.Category.MATERIALS, gold, 900, 2),
		ShopListing.make(&"stone_3", ShopListing.Category.MATERIALS, coupons, 300),
		ShopListing.make(&"charm_luck", ShopListing.Category.MATERIALS, vouchers, 400),
		ShopListing.make(&"charm_guard", ShopListing.Category.MATERIALS, coupons, 500),
		ShopListing.make(&"elem_attack", ShopListing.Category.MATERIALS, gold, 400, 2),
		ShopListing.make(&"elem_defense", ShopListing.Category.MATERIALS, gold, 400, 2),
		ShopListing.make(&"elem_agility", ShopListing.Category.MATERIALS, gold, 400, 2),
		ShopListing.make(&"elem_luck", ShopListing.Category.MATERIALS, gold, 400, 2),
	]


static func _map(id: StringName, name: String, features: Array[Vector3], left: Array[float], right: Array[float], islands: Array[Rect2] = []) -> MapDefinition:
	var def := MapDefinition.new()
	def.id = id
	def.display_name = name
	def.features = features
	def.ripples = [Vector3(0.22, 0.8, 0.0), Vector3(0.1, 2.1, 1.0)]
	def.islands = islands
	def.left_pads = PackedFloat64Array(left)
	def.right_pads = PackedFloat64Array(right)
	return def


static func _add_maps(db: ContentDatabase) -> void:
	var meadow := _map(&"meadow", "Sunny Meadow", [
		Vector3(3.2, 4.2, 4.2), Vector3(8.6, 3.0, 1.1), Vector3(16.3, 2.6, 1.3),
		Vector3(19.9, 2.0, 0.85), Vector3(27.6, 3.4, -2.4), Vector3(33.2, 3.4, 3.4),
	], [13.0, 9.5], [23.0, 26.5], [Rect2(Vector2(18.4, 7.5), Vector2(1.7, 0.42))])
	var canyon := _map(&"canyon", "Canyon Ridge", [
		Vector3(2.5, 3.5, 3.0), Vector3(10.5, 3.2, 1.8), Vector3(18.0, 3.0, -3.0),
		Vector3(25.5, 3.2, 1.8), Vector3(33.5, 3.5, 3.0),
	], [11.0, 7.5], [25.0, 28.5], [Rect2(Vector2(18.0, 8.6), Vector2(1.4, 0.4))])
	var hollow_1 := _map(&"hollow_1", "Mossy Path", [
		Vector3(3.0, 3.5, 3.5), Vector3(15.5, 2.4, 1.0), Vector3(30.5, 4.0, 2.2),
	], [9.0, 12.0], [22.0, 26.0, 29.0])
	var hollow_2 := _map(&"hollow_2", "Pebble Ridge", [
		Vector3(3.0, 3.5, 3.0), Vector3(17.0, 2.5, -1.6), Vector3(24.0, 2.0, 1.4), Vector3(32.5, 3.5, 3.2),
	], [9.0, 12.0], [20.0, 23.5, 28.0], [Rect2(Vector2(15.0, 8.4), Vector2(1.3, 0.38))])
	var hollow_3 := _map(&"hollow_3", "Shell King's Den", [
		Vector3(2.5, 3.5, 3.4), Vector3(14.5, 2.6, 0.9), Vector3(33.5, 3.0, 4.5),
	], [8.5, 11.5], [21.0, 27.0])
	var all_maps: Array[MapDefinition] = [meadow, canyon, hollow_1, hollow_2, hollow_3]
	for def in all_maps:
		db.maps[def.id] = def
	db.pvp_maps = [&"meadow", &"canyon"]


static func _enemy(id: StringName, name: String, behavior: EnemyDefinition.Behavior, visual: StringName, hp: int, stats: StatBlock) -> EnemyDefinition:
	var def := EnemyDefinition.new()
	def.id = id
	def.display_name = name
	def.behavior = behavior
	def.visual = visual
	def.max_hp = hp
	def.stats = stats
	return def


static func _add_enemies(db: ContentDatabase) -> void:
	var grunt := _enemy(&"sprout_grunt", "Sprout Grunt", EnemyDefinition.Behavior.MELEE, &"sprout_grunt", 420, StatBlock.make(20, 15, 10, 5, 110, 5))
	grunt.head_radius = 0.3
	grunt.head_center_height = 0.42
	grunt.reach = 1.1
	grunt.move_budget = 3.5
	grunt.exp_reward = 40
	grunt.gold_reward = 60
	var slinger := _enemy(&"pebble_slinger", "Pebble Slinger", EnemyDefinition.Behavior.ARTILLERY, &"pebble_slinger", 520, StatBlock.make(25, 25, 5, 10, 135, 10))
	slinger.head_radius = 0.3
	slinger.head_center_height = 0.62
	slinger.min_angle = 35
	slinger.max_angle = 85
	slinger.crater_radius = 0.5
	slinger.aim_error_degrees = 2.5
	slinger.exp_reward = 55
	slinger.gold_reward = 80
	var king := _enemy(&"shell_king", "Shell King", EnemyDefinition.Behavior.BOSS, &"shell_king", 2600, StatBlock.make(40, 60, 0, 10, 200, 30))
	king.head_radius = 0.72
	king.head_center_height = 1.3
	king.crater_radius = 1.0
	king.damage_radius = 1.5
	king.min_angle = 40
	king.max_angle = 88
	king.anchored = true
	king.aim_error_degrees = 1.5
	king.exp_reward = 300
	king.gold_reward = 600
	var all_enemies: Array[EnemyDefinition] = [grunt, slinger, king]
	for def in all_enemies:
		db.enemies[def.id] = def


static func _add_instances(db: ContentDatabase) -> void:
	var hollow := PveInstanceDefinition.new()
	hollow.id = &"sprout_hollow"
	hollow.display_name = "Sprout Hollow"
	hollow.description = "A mossy hollow overrun by sprout creatures. Its master, the Shell King, waits in the den below."
	hollow.level_required = 1
	hollow.stages = [
		{"title": "Mossy Path", "map": &"hollow_1", "enemies": [{"enemy": &"sprout_grunt", "x": 22.0}, {"enemy": &"sprout_grunt", "x": 26.0}]},
		{"title": "Pebble Ridge", "map": &"hollow_2", "enemies": [{"enemy": &"sprout_grunt", "x": 20.0}, {"enemy": &"pebble_slinger", "x": 23.5}, {"enemy": &"pebble_slinger", "x": 28.0}]},
		{"title": "Shell King's Den", "map": &"hollow_3", "enemies": [{"enemy": &"sprout_grunt", "x": 21.0}, {"enemy": &"shell_king", "x": 27.0}]},
	]
	hollow.loot = [
		{"id": &"stone_2", "qty": 2, "weight": 30}, {"id": &"stone_3", "qty": 1, "weight": 12},
		{"id": &"hat_horn", "qty": 1, "weight": 8}, {"id": &"clo_scale", "qty": 1, "weight": 6},
		{"id": &"ring_amber", "qty": 1, "weight": 6}, {"id": &"elem_defense", "qty": 2, "weight": 18},
		{"id": &"item_heal", "qty": 3, "weight": 20}, {"id": &"charm_guard", "qty": 1, "weight": 5},
	]
	hollow.clear_reward = Reward.make(150, 400)
	db.instances = [hollow]


static func _add_quests(db: ContentDatabase) -> void:
	db.quests = [
		QuestDefinition.make(&"q_first_battle", "First Taste of Battle", "Finish any battle (PvP or Expedition).", &"battle_finished", 1,
			Reward.make(100, 300, [Reward.item(&"stone_1", 3)])),
		QuestDefinition.make(&"q_new_weapon", "New Arsenal", "Equip a weapon other than the Sunburst Launcher.", &"equip_new_weapon", 1,
			Reward.make(50, 0, [Reward.item(&"stone_1", 5)], 0, 300)),
		QuestDefinition.make(&"q_buy", "Window Shopper", "Buy any item in the Shop.", &"shop_purchase", 1,
			Reward.make(30, 200)),
		QuestDefinition.make(&"q_strengthen", "Spark of the Forge", "Successfully strengthen an item at the Blacksmith.", &"strengthen_success", 1,
			Reward.make(80, 300, [Reward.item(&"charm_guard", 1)])),
		QuestDefinition.make(&"q_win_pvp", "Hall Champion", "Win a PvP match in the Game Hall.", &"pvp_win", 1,
			Reward.make(150, 500, [Reward.item(&"stone_2", 1)])),
		QuestDefinition.make(&"q_clear_pve", "Hollow Explorer", "Clear Sprout Hollow on any difficulty.", &"pve_clear", 1,
			Reward.make(300, 800, [Reward.item(&"elem_luck", 2), Reward.item(&"elem_agility", 2)])),
		QuestDefinition.make(&"q_level_3", "Rising Star", "Reach level 3.", &"level_reached", 3,
			Reward.make(0, 1000, [Reward.item(&"neck_leaf", 1)])),
	]


static func _add_starter_kit(db: ContentDatabase) -> void:
	db.starter_equipment = [&"wpn_sunburst", &"clo_cotton", &"hat_cap"]
	db.starter_bag = [
		Reward.item(&"stone_1", 6), Reward.item(&"stone_2", 2), Reward.item(&"charm_luck", 1),
		Reward.item(&"item_heal", 3), Reward.item(&"box_starter", 1),
	]
	db.starter_wallet.gold = 25000
	db.starter_wallet.coupons = 5000
	db.starter_wallet.vouchers = 2000
	db.welcome_mails = [
		MailMessage.make(&"mail_welcome", "Welcome to the city!",
			"Here are some supplies to get you started. Visit the Blacksmith to strengthen your launcher!",
			Reward.make(0, 3000, [Reward.item(&"stone_2", 2), Reward.item(&"charm_luck", 1)])),
		MailMessage.make(&"mail_expedition", "Expedition supplies",
			"The Expedition Pier is open. Healing Kits keep you alive between stages (key 1 in battle).",
			Reward.make(0, 0, [Reward.item(&"item_heal", 3)], 0, 500)),
	]
