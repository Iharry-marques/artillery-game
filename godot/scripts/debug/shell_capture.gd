class_name ShellCapture
extends Node
## Visual review of the product shell (tools/run_shell_capture.sh <dir>): walks the
## main screens on a throwaway save, then plays a PvP duel and a PvE expedition
## with the AI on both sides, saving screenshots and quitting. Needs a window.

const SAVE_PATH: String = "user://capture_save.json"
const TIME_SCALE: float = 4.0
## Scaled seconds.
const MAX_BATTLE_SECONDS: float = 900.0

var output_dir: String


func _ready() -> void:
	if get_tree().current_scene == self:
		# Launcher scene: hand over to a runner that survives scene changes.
		var runner := ShellCapture.new()
		for arg in OS.get_cmdline_user_args():
			if arg.begins_with("--shell-capture="):
				runner.output_dir = arg.trim_prefix("--shell-capture=")
		if runner.output_dir == "":
			push_error("shell capture needs --shell-capture=<absolute dir>")
			get_tree().quit(1)
			return
		get_tree().root.add_child.call_deferred(runner)
		return
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	SaveService.delete(SAVE_PATH)
	var game := GameSession.new(SAVE_PATH)
	GameSession.replace_instance(game)
	await _screen(&"boot", "01_boot_new")
	await _screen(&"character", "02_character_create")
	game.create_profile("Captain Rook", 0)
	await _screen(&"boot", "03_boot_continue")
	await _screen(&"city", "04_city")
	await _screen(&"status", "05_status")
	await _screen(&"bag", "06_bag")
	await _click_first_slot()
	await _shot("07_bag_item_details")
	await _screen(&"shop", "08_shop")
	await _screen(&"blacksmith", "09_blacksmith_strengthen")
	await _screen(&"game_hall", "10_game_hall")
	game.create_room("Captain Rook's room", RoomState.Mode.DUEL, game.content.pvp_maps[0])
	game.fill_room_with_ai()
	await _screen(&"battle_room", "11_battle_room")

	game.pending_battle = game.build_pvp_setup(game.current_room)
	await _battle("12_pvp_battle", false)
	await _wait_for_screen(&"ResultScreen")
	await _shot("13_pvp_result")
	game.claim_card(1)
	await _screen(&"result", "14_pvp_result_card")

	await _screen(&"expedition", "15_pve_selection")
	await _screen(&"party_room", "16_pve_party_room")
	game.pending_battle = game.build_pve_setup(game.selected_instance, game.selected_difficulty, true)
	await _battle("17_pve_stage1", true)
	await _wait_for_screen(&"ResultScreen")
	await _shot("19_pve_result")
	await _screen(&"city", "20_city_after")
	_log("profile level %d, exp %d, gold %d, battles %d" % [game.profile.level, game.profile.exp, game.profile.wallet.gold, game.profile.counter(&"battles")])
	Engine.time_scale = 1.0
	SaveService.delete(SAVE_PATH)
	get_tree().quit(0)


func _screen(screen: StringName, shot_name: String) -> void:
	var path: String = ScreenRouter.SCREENS[screen]
	get_tree().change_scene_to_file(path)
	await _frames(12)
	await _shot(shot_name)


func _click_first_slot() -> void:
	var slots: Array[Node] = get_tree().current_scene.find_children("*", "ItemSlot", true, false)
	for node in slots:
		var slot := node as ItemSlot
		if slot != null and slot.uid >= 0:
			slot.pressed.emit()
			break
	await _frames(4)


## Plays the pending battle with the AI on every side. PvE: shoots the first stage,
## then clears stages until the boss stage for a second shot.
func _battle(shot_name: String, pve: bool) -> void:
	get_tree().change_scene_to_file(ScreenRouter.SCREENS[&"battle"])
	await _frames(4)
	var sandbox := get_tree().current_scene as CombatSandbox
	sandbox.ai.drive_humans = true
	Engine.time_scale = TIME_SCALE
	await _wait_turns(sandbox, 3)
	await _shot(shot_name)
	if not pve:
		_weaken_opponents(sandbox)
	if pve:
		while sandbox.stage < sandbox.setup.stage_count() - 1:
			for c in sandbox.combat.combatants:
				if c.team == 1:
					c.defeat()
			var stage: int = sandbox.stage
			while sandbox.stage == stage:
				await get_tree().process_frame
			sandbox.ai.drive_humans = true
		await _frames(30)
		await _wait_for_boss_turn(sandbox)
		await _shot("18_pve_boss_stage")
		_weaken_opponents(sandbox)
	var waited: float = 0.0
	while is_instance_valid(sandbox) and get_tree().current_scene == sandbox and waited < MAX_BATTLE_SECONDS:
		waited += get_process_delta_time()
		await get_tree().process_frame
	Engine.time_scale = 1.0


## Review shortcut: one more hit ends the battle (the capture is about screens, not balance).
func _weaken_opponents(sandbox: CombatSandbox) -> void:
	for c in sandbox.combat.combatants:
		if c.team != sandbox.combat.local_player().team and c.alive:
			c.hp = mini(c.hp, 1)


func _wait_for_boss_turn(sandbox: CombatSandbox) -> void:
	var waited: float = 0.0
	while waited < 120.0:
		var active: CombatantState = sandbox.combat.active()
		if active.controller == BattleSetup.Controller.BOSS and sandbox.combat.phase != CombatMatch.Phase.FLIGHT:
			await _frames(20)
			return
		waited += get_process_delta_time()
		await get_tree().process_frame


func _wait_turns(sandbox: CombatSandbox, turns: int) -> void:
	var target: int = sandbox.combat.turn_number + turns
	var waited: float = 0.0
	while sandbox.combat.turn_number < target and waited < 60.0:
		if sandbox.combat.phase == CombatMatch.Phase.FLIGHT and sandbox.combat.turn_number == target - 1:
			return
		waited += get_process_delta_time()
		await get_tree().process_frame


func _wait_for_screen(node_name: StringName) -> void:
	for i in 600:
		if get_tree().current_scene != null and get_tree().current_scene.name == node_name:
			break
		await get_tree().process_frame
	await _frames(12)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(output_dir.path_join(shot_name + ".png"))
	_log(shot_name)


func _log(text: String) -> void:
	print("CAPTURE " + text)
