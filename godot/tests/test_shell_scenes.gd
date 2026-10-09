extends TestCase
## Smoke tests of the product shell: every screen scene builds from a local
## profile without script errors, and the battle scene plays PvE stages (HP carried,
## result recorded) and PvP surrender. No pixel assertions.

const BATTLE_SCENE: String = "res://scenes/gameplay/combat_sandbox.tscn"
const SHELL_SCREENS: Array[StringName] = [
	&"boot", &"character", &"city", &"status", &"bag", &"shop", &"blacksmith",
	&"game_hall", &"battle_room", &"result", &"expedition", &"party_room",
]
const SETTLE_FRAMES: int = 3


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _session() -> GameSession:
	var game: GameSession = MetaFixture.session()
	GameSession.replace_instance(game)
	return game


func _release() -> void:
	GameSession.replace_instance(null)
	MetaFixture.cleanup()


func _settle(frames: int = SETTLE_FRAMES) -> void:
	for i in frames:
		await _tree().process_frame


func test_every_shell_screen_builds() -> void:
	var game: GameSession = _session()
	game.refresh_rooms()
	game.create_room("Smoke room", RoomState.Mode.DUEL, game.content.pvp_maps[0])
	var played := BattleOutcome.new()
	played.mode = BattleSetup.Mode.PVP
	played.victory = true
	played.room_name = "Smoke room"
	game.finish_battle(played)
	for screen in SHELL_SCREENS:
		var path: String = ScreenRouter.SCREENS[screen]
		var packed: PackedScene = load(path) as PackedScene
		assert_true(packed != null, "%s scene loads" % screen)
		if packed == null:
			continue
		var node: ShellScreen = packed.instantiate() as ShellScreen
		assert_true(node != null, "%s root is a ShellScreen" % screen)
		if node == null:
			continue
		_tree().root.add_child(node)
		await _settle()
		assert_true(node.find_children("*", "Control", true, false).size() > 10, "%s built its content" % screen)
		node.queue_free()
		await _settle(1)
	assert_true(game.last_cards.size() == RewardCalculator.CARD_COUNT, "a victory offers the flip cards")
	_release()


func _battle(game: GameSession) -> CombatSandbox:
	var sandbox: CombatSandbox = (load(BATTLE_SCENE) as PackedScene).instantiate() as CombatSandbox
	sandbox.finish_screen = &""
	sandbox.stage_end_delay = 0.0
	_tree().root.add_child(sandbox)
	return sandbox


func _defeat_team(combat: CombatMatch, team: int) -> void:
	for c in combat.combatants:
		if c.team == team:
			c.defeat()


func test_pve_battle_scene_plays_stages_and_records_the_clear() -> void:
	var game: GameSession = _session()
	game.pending_battle = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.NORMAL, true)
	var sandbox: CombatSandbox = _battle(game)
	await _settle()
	assert_true(sandbox.is_battle_mode(), "pending battle switches the scene to battle mode")
	var combat: CombatMatch = sandbox.combat
	for c in combat.combatants:
		var view: CombatantView = sandbox.get_node("World/Player%d" % (c.index + 1)) as CombatantView
		assert_true(view != null and view.state == c, "a view per combatant (%s)" % c.display_name)
		var head: Node2D = view.get_node("Head") as Node2D
		assert_near(-head.position.y / WorldCanvas.PIXELS_PER_UNIT, c.head_height, 1e-5, "%s head node at its hitbox" % c.display_name)
		if c.team == 1:
			var body: Sprite2D = view.get_node("Visual/Body") as Sprite2D
			assert_true(body.texture == EnemyArt.shared().texture(c.visual), "%s uses its monster art" % c.display_name)
			assert_true(not (view.get_node("Visual/WeaponPivot") as Node2D).visible, "monsters carry no weapon")

	var me: CombatantState = combat.local_player()
	me.hp = 777
	for stage in game.content.instance(&"sprout_hollow").stages.size():
		_defeat_team(sandbox.combat, 1)
		await _settle(4)
		if stage < 2:
			assert_true(sandbox.stage == stage + 1, "stage %d cleared -> next stage" % (stage + 1))
			assert_true(sandbox.combat.local_player().hp == 777, "HP carries into stage %d" % (stage + 2))
	assert_true(game.last_outcome != null and game.last_outcome.victory, "expedition recorded as a victory")
	assert_true(game.last_outcome.stages_cleared == 3, "three stages cleared")
	assert_true(game.profile.counter(&"pve_clears") == 1, "clear counted in the profile")
	assert_true(game.last_reward.exp > 0 and game.last_reward.gold > 0, "rewards granted")
	assert_true(game.pending_battle == null, "pending battle consumed")
	sandbox.queue_free()
	await _settle(1)
	_release()


func test_boss_stage_uses_the_large_boss_hitbox() -> void:
	var game: GameSession = _session()
	var setup: BattleSetup = game.build_pve_setup(&"sprout_hollow", PveInstanceDefinition.Difficulty.HARD, false)
	var boss_stage := CombatMatch.new(GameMetrics.load_default(), game.rules, setup, 2)
	var boss: CombatantState = null
	for c in boss_stage.combatants:
		if c.controller == BattleSetup.Controller.BOSS:
			boss = c
	assert_true(boss != null, "stage 3 has a boss")
	if boss != null:
		var def: EnemyDefinition = game.content.enemy(&"shell_king")
		assert_near(boss.head_radius, EnemyArt.shared().head_radius_u(boss.visual), 1e-6, "boss hitbox radius matches its art")
		assert_near(boss.head_height, def.head_center_height, 1e-6, "boss hitbox height from its definition")
		assert_true(boss.head_radius > game.rules.head_radius * 2.0, "the boss is a much larger target")
	_release()


func test_enemy_art_matches_enemy_hitboxes() -> void:
	var content: ContentDatabase = ContentCatalog.shared()
	for key: StringName in content.enemies:
		var def: EnemyDefinition = content.enemies[key]
		assert_true(EnemyArt.shared().has(def.visual), "%s has proxy art" % def.id)
		assert_near(EnemyArt.shared().head_radius_u(def.visual), def.head_radius, 1e-3, "%s head radius art = gameplay" % def.id)
		assert_near(EnemyArt.shared().head_center_u(def.visual).y, def.head_center_height, 1e-3, "%s head height art = gameplay" % def.id)


func test_pvp_battle_scene_leave_counts_as_a_defeat() -> void:
	var game: GameSession = _session()
	game.refresh_rooms()
	var room: RoomState = game.create_room("Duel", RoomState.Mode.DUEL, game.content.pvp_maps[0])
	game.fill_room_with_ai()
	game.pending_battle = game.build_pvp_setup(room)
	var sandbox: CombatSandbox = _battle(game)
	await _settle()
	assert_true(sandbox.combat.combatants.size() == 2, "duel has two combatants")
	sandbox.request_leave()
	assert_true(game.last_outcome == null, "the first press only asks for confirmation")
	sandbox.request_leave()
	assert_true(game.last_outcome != null and game.last_outcome.surrendered and not game.last_outcome.victory, "second press surrenders")
	assert_true(game.profile.counter(&"battles") == 0, "a surrender is not a finished battle")
	assert_true(room.state == RoomState.State.WAITING, "the room is back to waiting")
	sandbox.queue_free()
	await _settle(1)
	_release()
