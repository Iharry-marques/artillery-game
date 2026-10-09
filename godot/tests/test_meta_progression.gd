extends TestCase
## Save/load, quests, mail, EXP curve, rooms and battle rewards.


func test_save_and_load_round_trip() -> void:
	var game: GameSession = MetaFixture.session("Saver")
	var weapon: ItemInstance = game.profile.equipment.get_item(ItemDefinition.Slot.WEAPON)
	weapon.enhance_level = 4
	game.grant(Reward.make(150, 777, [Reward.item(&"stone_3", 2)]))
	game.record(&"battle_finished")
	game.save()
	var reloaded := GameSession.new(MetaFixture.TEST_SAVE)
	assert_true(reloaded.has_profile(), "save found")
	var p: PlayerProfile = reloaded.profile
	assert_true(p.nickname == "Saver" and p.level == game.profile.level and p.exp == game.profile.exp, "identity and EXP")
	assert_true(p.wallet.gold == game.profile.wallet.gold, "gold")
	assert_true(p.inventory.count(&"stone_3") == 2, "inventory")
	assert_true(p.equipment.get_item(ItemDefinition.Slot.WEAPON).enhance_level == 4, "equipment and strengthening")
	assert_true(reloaded.quest_complete(reloaded.content.quest(&"q_first_battle")), "quest progress")
	assert_true(JSON.stringify(p.to_dict(), "", true) == JSON.stringify(game.profile.to_dict(), "", true), "identical data (key order aside)")
	reloaded.delete_save()
	assert_true(not SaveService.exists(MetaFixture.TEST_SAVE), "developer reset deletes the save")


func test_exp_curve_levels_up() -> void:
	var profile := PlayerProfile.new()
	var gained: int = Progression.add_exp(profile, Progression.exp_to_next(1) + Progression.exp_to_next(2) + 5)
	assert_true(gained == 2 and profile.level == 3 and profile.exp == 5, "two levels, 5 left over")
	assert_true(Progression.exp_to_next(5) > Progression.exp_to_next(2), "curve grows")


func test_quest_claim_grants_reward_once() -> void:
	var game: GameSession = MetaFixture.session()
	var quest: QuestDefinition = game.content.quest(&"q_first_battle")
	assert_true(game.claim_quest(quest.id) == "Not completed yet", "cannot claim early")
	game.record(&"battle_finished")
	var gold: int = game.profile.wallet.gold
	assert_true(game.claim_quest(quest.id) == "", "claim succeeds")
	assert_true(game.profile.wallet.gold == gold + quest.reward.gold, "reward granted")
	assert_true(game.claim_quest(quest.id) == "Already claimed", "only once")
	MetaFixture.cleanup()


func test_level_quest_tracks_the_level() -> void:
	var game: GameSession = MetaFixture.session()
	game.grant(Reward.make(Progression.exp_to_next(1) + Progression.exp_to_next(2)))
	assert_true(game.profile.level == 3, "level 3")
	assert_true(game.quest_complete(game.content.quest(&"q_level_3")), "Rising Star complete")
	MetaFixture.cleanup()


func test_mail_attachment_is_claimed_once() -> void:
	var game: GameSession = MetaFixture.session()
	var mail: MailMessage = game.profile.mails[0]
	var gold: int = game.profile.wallet.gold
	assert_true(game.claim_mail(mail) == "", "claim")
	assert_true(game.profile.wallet.gold == gold + mail.attachment.gold, "gold attached")
	assert_true(game.claim_mail(mail) == "Nothing to claim", "already claimed")
	MetaFixture.cleanup()


func test_room_flow_create_fill_and_start() -> void:
	var game: GameSession = MetaFixture.session()
	game.refresh_rooms()
	assert_true(game.rooms.size() == GameSession.GENERATED_ROOMS, "simulated room list")
	var room: RoomState = game.create_room("My room", RoomState.Mode.TEAM, &"canyon")
	assert_true(room.player() != null and room.player().is_host, "player hosts")
	assert_true(room.start_blocker() != "", "cannot start alone")
	game.fill_room_with_ai()
	assert_true(room.is_full() and room.start_blocker() == "", "AI fills and is ready")
	var setup: BattleSetup = game.build_pvp_setup(room)
	assert_true(setup.players.size() == 2 and setup.opponents.size() == 2, "2v2 setup")
	game.leave_room()
	assert_true(room.player() == null and game.current_room == null, "left the room")
	MetaFixture.cleanup()


func test_joining_rooms_checks_state_and_lock() -> void:
	var game: GameSession = MetaFixture.session()
	var room := RoomState.new()
	room.locked = true
	assert_true(game.join_room(room) == "This room is password protected", "locked")
	room.locked = false
	room.state = RoomState.State.PLAYING
	assert_true(game.join_room(room) == "This room is already playing", "playing")
	room.state = RoomState.State.WAITING
	assert_true(game.join_room(room) == "" and room.player() != null, "joined")
	MetaFixture.cleanup()


func test_battle_rewards_progress_and_flip_cards() -> void:
	var game: GameSession = MetaFixture.session()
	var outcome := BattleOutcome.new()
	outcome.mode = BattleSetup.Mode.PVP
	outcome.victory = true
	var gold: int = game.profile.wallet.gold
	var reward: Reward = game.finish_battle(outcome)
	assert_true(reward.exp > 0 and game.profile.wallet.gold == gold + reward.gold, "win reward applied")
	assert_true(game.profile.counter(&"pvp_wins") == 1, "win counted")
	assert_true(game.quest_complete(game.content.quest(&"q_win_pvp")), "Hall Champion completed")
	assert_true(game.last_cards.size() == RewardCalculator.CARD_COUNT, "4 flip cards")
	var card: Reward = game.claim_card(2)
	assert_true(card != null and game.claim_card(1) == null, "one card per battle")
	var surrender := BattleOutcome.new()
	surrender.mode = BattleSetup.Mode.PVP
	surrender.surrendered = true
	assert_true(game.finish_battle(surrender).is_empty(), "leaving early gives nothing")
	MetaFixture.cleanup()
