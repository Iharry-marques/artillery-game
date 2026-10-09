extends TestCase
## Battle setups: stat loadouts, teams, AI turns and PvE stages on the shared engine.

const FRAME: float = 1.0 / 30.0
const MAX_SECONDS: float = 900.0


func _metrics() -> GameMetrics:
	return GameMetrics.load_default()


func _run(battle: CombatMatch, driver: AiTurnDriver, human_skips: bool) -> void:
	var elapsed: float = 0.0
	while battle.phase != CombatMatch.Phase.GAME_OVER and elapsed < MAX_SECONDS:
		if human_skips and battle.phase == CombatMatch.Phase.AIMING and not driver.is_ai(battle.active()):
			battle.request_skip(battle.active_index)
		driver.update(FRAME)
		battle.update(FRAME)
		elapsed += FRAME


func test_pvp_setup_uses_stats_and_teams() -> void:
	var game: GameSession = MetaFixture.session()
	var room: RoomState = game.create_room("Duel", RoomState.Mode.DUEL, &"meadow")
	game.fill_room_with_ai()
	var battle := CombatMatch.new(_metrics(), game.rules, game.build_pvp_setup(room))
	assert_true(battle.combatants.size() == 2, "1v1")
	var me: CombatantState = battle.local_player()
	assert_true(me.loadout != null and me.max_hp == game.stats().max_hp, "player HP from stats")
	assert_true(me.team == 0 and battle.combatants[1].team == 1, "teams")
	assert_true(battle.combatants[1].controller == BattleSetup.Controller.AI_ARTILLERY, "AI opponent")
	MetaFixture.cleanup()


func test_ai_opponent_finishes_a_match_against_a_passive_player() -> void:
	var game: GameSession = MetaFixture.session()
	var room: RoomState = game.create_room("Duel", RoomState.Mode.DUEL, &"meadow")
	game.fill_room_with_ai()
	var setup: BattleSetup = game.build_pvp_setup(room)
	var battle := CombatMatch.new(_metrics(), game.rules, setup)
	battle.set_force_zero_wind(true)
	_run(battle, AiTurnDriver.new(battle, 7), true)
	assert_true(battle.phase == CombatMatch.Phase.GAME_OVER, "the AI wins eventually")
	assert_true(battle.winner_team == 1, "the AI team won")
	var ai: CombatantState = battle.combatants[1]
	assert_true(ai.hits > 0 and ai.damage_dealt >= battle.local_player().max_hp, "AI hit the player: %d hits" % ai.hits)
	note("AI needed %d shots, %d hits" % [ai.shots, ai.hits])
	MetaFixture.cleanup()


func test_pve_stages_have_enemies_and_carry_hp() -> void:
	var game: GameSession = MetaFixture.session()
	var setup: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.NORMAL, false)
	assert_true(setup.stage_count() == 3, "three stages")
	var stage_1 := CombatMatch.new(_metrics(), game.rules, setup, 0)
	assert_true(stage_1.combatants.size() == 3, "player + 2 grunts")
	var boss_stage := CombatMatch.new(_metrics(), game.rules, setup, 2, {0: 321})
	var boss: CombatantState = null
	for c in boss_stage.combatants:
		if c.controller == BattleSetup.Controller.BOSS:
			boss = c
	assert_true(boss != null and boss.anchored and boss.head_radius > 0.5, "anchored big-headed boss")
	assert_true(boss_stage.local_player().hp == 321, "HP carried into the stage")
	var hard: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.HARD, false)
	var hard_enemy: BattleSetup.Participant = hard.stage_enemies[0][0]
	var normal_enemy: BattleSetup.Participant = setup.stage_enemies[0][0]
	assert_true(hard_enemy.loadout.max_hp > normal_enemy.loadout.max_hp, "Hard scales HP")
	MetaFixture.cleanup()


func test_melee_enemies_walk_and_strike() -> void:
	var game: GameSession = MetaFixture.session()
	var setup: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.HERO, false)
	var battle := CombatMatch.new(_metrics(), game.rules, setup, 0)
	var me: CombatantState = battle.local_player()
	var start_hp: int = me.hp
	_run(battle, AiTurnDriver.new(battle, 3), true)
	assert_true(me.hp < start_hp, "grunts reached and hit the player")
	assert_true(battle.phase == CombatMatch.Phase.GAME_OVER and battle.winner_team == 1, "a passive player loses")
	MetaFixture.cleanup()


func test_boss_uses_its_shockwave() -> void:
	var game: GameSession = MetaFixture.session()
	var setup: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.NORMAL, false)
	var battle := CombatMatch.new(_metrics(), game.rules, setup, 2)
	var slams: Array[int] = [0]
	battle.impact_resolved.connect(func(report: CombatMatch.ImpactReport) -> void:
		if report.tag == CombatMatch.TAG_SLAM:
			slams[0] += 1)
	_run(battle, AiTurnDriver.new(battle, 11), true)
	assert_true(slams[0] > 0, "the boss slammed at least once")
	MetaFixture.cleanup()


func test_healing_kit_restores_hp_once_per_turn() -> void:
	var game: GameSession = MetaFixture.session()
	var setup: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.NORMAL, false)
	var battle := CombatMatch.new(_metrics(), game.rules, setup, 0)
	var me: CombatantState = battle.local_player()
	me.hp = 100
	assert_true(battle.request_heal(me.index), "heal")
	assert_true(me.hp == 100 + me.loadout.heal_amount, "HP restored")
	assert_true(not battle.request_heal(me.index), "once per turn")
	MetaFixture.cleanup()
