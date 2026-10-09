extends TestCase
## Bag, equipment, stats, shop and gift boxes.


func test_starter_profile_is_equipped_and_funded() -> void:
	var game: GameSession = MetaFixture.session()
	var p: PlayerProfile = game.profile
	assert_true(p.equipment.get_item(ItemDefinition.Slot.WEAPON) != null, "starter weapon equipped")
	assert_true(p.equipment.get_item(ItemDefinition.Slot.CLOTHES) != null and p.equipment.get_item(ItemDefinition.Slot.HAT) != null, "clothes and hat equipped")
	assert_true(p.inventory.count(&"stone_1") == 6, "starter stones")
	assert_true(p.wallet.gold > 0 and p.wallet.coupons > 0, "developer currency")
	assert_true(p.mails.size() == 2, "welcome mails")
	MetaFixture.cleanup()


func test_stacking_respects_max_stack_and_capacity() -> void:
	var content: ContentDatabase = ContentCatalog.shared()
	var inventory := Inventory.new()
	inventory.capacity = 3
	var uid: Array[int] = [0]
	var next: Callable = func() -> int:
		uid[0] += 1
		return uid[0]
	assert_true(inventory.add(content.item(&"stone_1"), 150, next), "150 stones fit in 2 stacks")
	assert_true(inventory.used_slots() == 2 and inventory.count(&"stone_1") == 150, "99 + 51")
	assert_true(inventory.add(content.item(&"stone_1"), 48, next), "fills the open stack")
	assert_true(inventory.used_slots() == 2, "no new slot")
	assert_true(not inventory.add(content.item(&"wpn_spark"), 2, next), "2 weapons need 2 slots, only 1 free")
	assert_true(inventory.remove_quantity(&"stone_1", 120) and inventory.count(&"stone_1") == 78, "remove across stacks")


func test_equipping_a_weapon_changes_stats_and_quest() -> void:
	var game: GameSession = MetaFixture.session()
	var before: CharacterStats = game.stats()
	game.profile.level = 3
	game.profile.inventory.add(game.content.item(&"wpn_spark"), 1, game.profile.uid_allocator())
	var spark: ItemInstance = game.profile.inventory.items[game.profile.inventory.items.size() - 1]
	assert_true(game.equip(spark.uid) == "", "equip succeeds")
	var after: CharacterStats = game.stats()
	assert_true(after.weapon.id == &"wpn_spark", "new weapon active")
	assert_true(after.harm > before.harm, "harm rises: %d -> %d" % [before.harm, after.harm])
	assert_true(game.profile.inventory.count(&"wpn_sunburst") == 1, "old weapon returned to the bag")
	assert_true(game.quest_complete(game.content.quest(&"q_new_weapon")), "New Arsenal quest completed")
	MetaFixture.cleanup()


func test_level_requirement_blocks_equipping() -> void:
	var game: GameSession = MetaFixture.session()
	game.profile.inventory.add(game.content.item(&"wpn_spark"), 1, game.profile.uid_allocator())
	var spark: ItemInstance = game.profile.inventory.items[game.profile.inventory.items.size() - 1]
	assert_true(game.equip(spark.uid).begins_with("Requires level"), "level 1 cannot use a level 3 weapon")
	MetaFixture.cleanup()


func test_shop_purchase_moves_currency_and_items() -> void:
	var game: GameSession = MetaFixture.session()
	var listing: ShopListing = null
	for entry in game.content.shop:
		if entry.item_id == &"stone_1":
			listing = entry
	var gold: int = game.profile.wallet.gold
	var stones: int = game.profile.inventory.count(&"stone_1")
	assert_true(game.buy(listing, 2) == "", "purchase succeeds")
	assert_true(game.profile.wallet.gold == gold - listing.price * 2, "gold spent")
	assert_true(game.profile.inventory.count(&"stone_1") == stones + listing.quantity * 2, "stones received")
	game.profile.wallet.gold = 0
	assert_true(game.buy(listing) == "Not enough Gold", "cannot buy without money")
	assert_true(game.quest_complete(game.content.quest(&"q_buy")), "Window Shopper completed")
	MetaFixture.cleanup()


func test_gift_box_opens_into_items() -> void:
	var game: GameSession = MetaFixture.session()
	var box: ItemInstance = null
	for item in game.profile.inventory.items:
		if item.def_id == &"box_starter":
			box = item
	var heals: int = game.profile.inventory.count(&"item_heal")
	assert_true(game.use_item(box.uid) == "", "box opens")
	assert_true(game.profile.inventory.count(&"box_starter") == 0, "box consumed")
	assert_true(game.profile.inventory.count(&"item_heal") == heals + 2, "contents added")
	MetaFixture.cleanup()


func test_combat_power_and_derived_stats() -> void:
	var game: GameSession = MetaFixture.session()
	var stats: CharacterStats = game.stats()
	assert_true(stats.max_hp >= 1000, "HP around 1000 at level 1: %d" % stats.max_hp)
	assert_true(stats.harm == 180, "starter weapon harm")
	assert_true(stats.combat_power > 0, "combat power computed")
	assert_true(stats.total.attack == stats.base.attack + stats.equipment.attack, "total = base + equipment")
	MetaFixture.cleanup()
