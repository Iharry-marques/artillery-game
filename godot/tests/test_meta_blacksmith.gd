extends TestCase
## Strengthen / compose / fuse / transfer and their effect on stats.


func _weapon(game: GameSession) -> ItemInstance:
	return game.profile.equipment.get_item(ItemDefinition.Slot.WEAPON)


func test_success_chance_falls_with_level() -> void:
	var content: ContentDatabase = ContentCatalog.shared()
	var one: Array[ItemDefinition] = [content.item(&"stone_1")]
	assert_true(EnhancementRules.success_chance(1, one, 0.0) > EnhancementRules.success_chance(6, one, 0.0), "early levels are easier")
	var three: Array[ItemDefinition] = [content.item(&"stone_3"), content.item(&"stone_3"), content.item(&"stone_3")]
	assert_near(EnhancementRules.success_chance(1, three, 0.0), 1.0, 0.0, "capped at 100%")
	assert_near(EnhancementRules.success_chance(13, one, 0.0), 0.0, 0.0, "nothing above +12")


func test_strengthening_consumes_materials_and_can_raise_stats() -> void:
	var game: GameSession = MetaFixture.session()
	var weapon: ItemInstance = _weapon(game)
	var harm_before: int = game.stats().harm
	var gold_before: int = game.profile.wallet.gold
	var stones: Array[StringName] = [&"stone_2", &"stone_2"]
	var preview: Blacksmith.Preview = Blacksmith.preview_strengthen(game.profile, game.content, weapon.uid, stones, false, false)
	assert_near(preview.chance, 1.0, 0.0, "two Lv2 stones guarantee +1")
	var outcome: Blacksmith.Outcome = game.strengthen(weapon.uid, stones, false, false)
	assert_true(outcome.ok and outcome.success and weapon.enhance_level == 1, "now +1")
	assert_true(game.profile.inventory.count(&"stone_2") == 0, "stones consumed")
	assert_true(game.profile.wallet.gold == gold_before - preview.cost, "gold paid")
	assert_true(game.stats().harm > harm_before, "harm rises after strengthening")
	assert_true(game.quest_complete(game.content.quest(&"q_strengthen")), "forge quest completed")
	MetaFixture.cleanup()


func test_failure_drops_a_level_unless_protected() -> void:
	var game: GameSession = MetaFixture.session()
	var weapon: ItemInstance = _weapon(game)
	weapon.enhance_level = 8
	game.profile.inventory.add(game.content.item(&"stone_1"), 40, game.profile.uid_allocator())
	game.profile.inventory.add(game.content.item(&"charm_guard"), 20, game.profile.uid_allocator())
	var stones: Array[StringName] = [&"stone_1"]
	var drops: int = 0
	var protected_drops: int = 0
	for i in 15:
		var level: int = weapon.enhance_level
		var outcome: Blacksmith.Outcome = game.strengthen(weapon.uid, stones, false, i % 2 == 0)
		if not outcome.success and weapon.enhance_level < level:
			if i % 2 == 0:
				protected_drops += 1
			else:
				drops += 1
		weapon.enhance_level = 8
	assert_true(protected_drops == 0, "Guardian Seal prevents level loss")
	assert_true(drops > 0, "unprotected failures at +8 drop a level")
	MetaFixture.cleanup()


func test_rng_is_reproducible_from_the_profile_seed() -> void:
	var a: GameSession = MetaFixture.session()
	var rolls_a: Array[float] = [a.profile.next_rng().randf(), a.profile.next_rng().randf()]
	var b: GameSession = MetaFixture.session()
	var rolls_b: Array[float] = [b.profile.next_rng().randf(), b.profile.next_rng().randf()]
	assert_true(rolls_a == rolls_b, "same seed, same rolls")
	MetaFixture.cleanup()


func test_compose_fuse_and_transfer() -> void:
	var game: GameSession = MetaFixture.session()
	var weapon: ItemInstance = _weapon(game)
	game.profile.inventory.add(game.content.item(&"elem_attack"), 1, game.profile.uid_allocator())
	var attack_before: int = game.stats().total.attack
	assert_true(game.compose(weapon.uid, &"elem_attack").ok, "compose succeeds")
	assert_true(game.stats().total.attack == attack_before + Blacksmith.COMPOSE_POINTS, "attack +3")

	game.profile.inventory.add(game.content.item(&"stone_1"), 20, game.profile.uid_allocator())
	var lv1: int = game.profile.inventory.count(&"stone_1")
	var lv2: int = game.profile.inventory.count(&"stone_2")
	var fuse: Blacksmith.Outcome = game.fuse(1)
	assert_true(fuse.ok and game.profile.inventory.count(&"stone_1") == lv1 - 4, "4 stones consumed")
	assert_true(game.profile.inventory.count(&"stone_2") == lv2 + (1 if fuse.success else 0), "result matches outcome")

	game.profile.inventory.add(game.content.item(&"wpn_boulder"), 1, game.profile.uid_allocator())
	var boulder: ItemInstance = game.profile.inventory.items[game.profile.inventory.items.size() - 1]
	weapon.enhance_level = 5
	assert_true(game.transfer(weapon.uid, boulder.uid).ok, "transfer succeeds")
	assert_true(boulder.enhance_level == 5 and weapon.enhance_level == 0, "level moved")
	var hat: ItemInstance = game.profile.equipment.get_item(ItemDefinition.Slot.HAT)
	assert_true(not game.transfer(boulder.uid, hat.uid).ok, "weapon to hat is refused")
	MetaFixture.cleanup()
