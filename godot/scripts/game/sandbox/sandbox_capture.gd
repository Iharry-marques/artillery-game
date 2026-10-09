class_name SandboxCapture
extends Node
## Scripted playthrough for visual review (--capture=<dir>): idle view, aiming,
## power at ~50%, a charged Full Throw in flight, the crater, a head hit, the
## minimap with separated players, the F2 hitbox and F3 debug overlays, a game over
## and a reset. Screenshots and key numbers go to output_dir / stdout. Needs a window.

## Speeds up waiting phases; charging always runs in real time.
const TIME_SCALE: float = 2.5
const MAX_WAIT_SECONDS: float = 40.0
const MAX_TURNS: int = 12
const FULL_THROW_ANGLE: int = 80
const HALF_POWER: float = 50.0
const WALK_FRAMES: int = 70
const FILLER_SHOT_ANGLE: float = 70.0
const FILLER_SHOT_POWER: float = 45.0

var sandbox: CombatSandbox
var output_dir: String


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	var combat: CombatMatch = sandbox.combat
	var initial: String = str(combat.snapshot())
	await _frames(30)
	await _shot("01_idle_battle")

	combat.set_force_zero_wind(true)
	while combat.active().angle < FULL_THROW_ANGLE:
		combat.request_angle_step(0, 1)
		await _frames(2)
	await _shot("02_aiming")

	combat.request_begin_charge(0)
	while combat.power < HALF_POWER:
		await get_tree().process_frame
	await _shot("03_power_charging_50")
	while combat.power < BallisticEvidence.FULL_THROW_POWER:
		await get_tree().process_frame
	combat.request_release(0)
	_log("P1 released at power %.2f, angle %.1f" % [combat.last_shot_power, combat.last_shot_angle])
	Engine.time_scale = TIME_SCALE
	while combat.flight_elapsed < combat.flight.flight_time * 0.4:
		await get_tree().process_frame
	await _shot("04_full_throw_flight")
	await _until(CombatMatch.Phase.RESOLVING)
	await _frames(6)
	await _shot("05_impact_crater")
	_log_impact()

	await _until(CombatMatch.Phase.AIMING)
	await _frames(30)
	sandbox.debug_full_throw()
	await _until(CombatMatch.Phase.RESOLVING)
	await _frames(5)
	await _shot("06_player_hit")
	_log_impact()

	await _until(CombatMatch.Phase.AIMING)
	for i in WALK_FRAMES:
		combat.request_move(0, -1, 1.0 / 60.0)
		await get_tree().process_frame
	await _frames(40)
	await _shot("07_minimap_players_separated")
	_log("distance between players %.2f u" % combat.horizontal_distance_between_players())

	sandbox.set_hitbox_overlay_visible(true)
	await _frames(4)
	await _shot("08_hitbox_overlay")
	sandbox.set_hitbox_overlay_visible(false)
	sandbox.set_debug_overlay_visible(true)
	await _frames(4)
	await _shot("09_debug_overlay")
	sandbox.set_debug_overlay_visible(false)

	var turns: int = 0
	while combat.phase != CombatMatch.Phase.GAME_OVER and turns < MAX_TURNS:
		await _until(CombatMatch.Phase.AIMING, true)
		if combat.phase == CombatMatch.Phase.GAME_OVER:
			break
		if combat.active_index == 1:
			_fire_at_head_with_solver(combat)
		else:
			combat.request_debug_fire(0, FILLER_SHOT_ANGLE, FILLER_SHOT_POWER)
		await _until(CombatMatch.Phase.RESOLVING, true)
		_log_impact()
		turns += 1
	await _frames(20)
	await _shot("10_game_over")
	_log("phase %s, winner %d, hp %d / %d" % [
		CombatMatch.Phase.keys()[combat.phase], combat.winner_index, combat.combatants[0].hp, combat.combatants[1].hp
	])

	sandbox.reset_sandbox()
	await _frames(20)
	await _shot("11_reset")
	_log("reset restores the initial state: %s" % (str(combat.snapshot()) == initial))
	Engine.time_scale = 1.0
	get_tree().quit(0)


## Test automation only: BallisticSolver finds the Full Throw-power angle that
## reaches the opponent's head centre from the launch point, at the head's height.
func _fire_at_head_with_solver(combat: CombatMatch) -> void:
	var shooter: CombatantState = combat.active()
	var target: CombatantState = combat.opponent_of(shooter.index)
	var direction: int = 1 if target.feet_x > shooter.feet_x else -1
	combat.request_face(shooter.index, direction)
	var rules: CombatRules = combat.rules
	var guess: float = 80.0
	var angle: float = guess
	# The launch point moves with the angle: refine the angle a few times.
	for i in 4:
		angle = BallisticSolver.solve_angle(
			combat.params, absf(target.head_center_x() - shooter.muzzle_x(rules, guess)), BallisticEvidence.FULL_THROW_POWER,
			combat.wind * direction, BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE,
			target.head_center_y(rules) - shooter.muzzle_y(rules, guess)
		)
		if is_nan(angle):
			angle = guess
			break
		guess = angle
	combat.request_angle_step(shooter.index, roundi(angle) - shooter.angle)
	_log("solver angle %.3f" % angle)
	combat.request_debug_fire(shooter.index, angle, BallisticEvidence.FULL_THROW_POWER)


func _until(phase: CombatMatch.Phase, or_game_over: bool = false) -> void:
	var waited: float = 0.0
	var combat: CombatMatch = sandbox.combat
	while combat.phase != phase and waited < MAX_WAIT_SECONDS:
		if or_game_over and combat.phase == CombatMatch.Phase.GAME_OVER:
			return
		waited += get_process_delta_time()
		await get_tree().process_frame


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(name: String) -> void:
	await get_tree().process_frame
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(output_dir.path_join(name + ".png"))
	var combat: CombatMatch = sandbox.combat
	_log("%s | phase %s, turn %d, active P%d, angle %d, wind %+.1f, hp %d / %d" % [
		name, CombatMatch.Phase.keys()[combat.phase], combat.turn_number, combat.active_index + 1, combat.active().angle,
		combat.wind, combat.combatants[0].hp, combat.combatants[1].hp
	])


func _log_impact() -> void:
	var combat: CombatMatch = sandbox.combat
	var report: CombatMatch.ImpactReport = combat.last_impact
	if report != null:
		_log("impact %s at (%.3f, %.3f), damages %s, flight %.3f s" % [report.tag, report.x, report.y, report.damages, combat.flight.flight_time])


func _log(text: String) -> void:
	print("CAPTURE " + text)
