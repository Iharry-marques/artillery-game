class_name SandboxCapture
extends Node
## Scripted playthrough for automated visual review (--capture=<dir>): charges a
## real Full Throw, follows the shot, lets player 2 answer, digs a crater under a
## player, plays until someone is defeated, shows the debug overlay and resets.
## Screenshots and key numbers go to stdout/output_dir. Needs a real window.

## Speeds the run up; all timings are simulated time anyway.
const TIME_SCALE: float = 3.0
const MAX_WAIT_SECONDS: float = 40.0
const MAX_TURNS: int = 14
const FULL_THROW_ANGLE: int = 80
const SELF_CRATER_ANGLE: float = 90.0
const SELF_CRATER_POWER: float = 20.0
## Player 2's filler shot in the final loop: lands well in front of it.
const FILLER_SHOT_ANGLE: float = 70.0
const FILLER_SHOT_POWER: float = 45.0

var sandbox: CombatSandbox
var output_dir: String


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	Engine.time_scale = TIME_SCALE
	var combat: CombatMatch = sandbox.combat
	var initial: String = str(combat.snapshot())
	await _frames(10)
	await _shot("01_start")

	# Player 1 charges a real Full Throw with the power bar: angle 80, release at ~95.
	combat.set_force_zero_wind(true)
	combat.request_angle_step(0, FULL_THROW_ANGLE - combat.active().angle)
	# Charge in real time, like a player would (frame-sized power steps).
	Engine.time_scale = 1.0
	combat.request_begin_charge(0)
	while combat.power < BallisticEvidence.FULL_THROW_POWER:
		await get_tree().process_frame
	await _shot("02_charging")
	combat.request_release(0)
	Engine.time_scale = TIME_SCALE
	_log("P1 released at power %.2f, angle %.1f" % [combat.last_shot_power, combat.last_shot_angle])
	while combat.flight_elapsed < combat.flight.flight_time * 0.45:
		await get_tree().process_frame
	await _shot("03_flight_follow")
	await _until(CombatMatch.Phase.RESOLVING)
	await _frames(4)
	await _shot("04_impact")
	_log_impact()

	await _until(CombatMatch.Phase.AIMING)
	await _frames(40)
	await _shot("05_player2_turn")

	# Player 2 walks a little, then fires straight up to dig a crater under itself.
	for i in 40:
		combat.request_move(1, -1, 1.0 / 60.0)
		await get_tree().process_frame
	await _shot("06_player2_moved")
	var p2_feet_before: float = combat.combatants[1].feet_y
	combat.request_debug_fire(1, SELF_CRATER_ANGLE, SELF_CRATER_POWER)
	await _until(CombatMatch.Phase.RESOLVING)
	await _frames(12)
	await _shot("07_crater_and_fall")
	_log_impact()
	_log("P2 feet y %.3f -> %.3f" % [p2_feet_before, combat.combatants[1].feet_y])

	await _until(CombatMatch.Phase.AIMING)
	sandbox.debug_full_throw()
	await _until(CombatMatch.Phase.RESOLVING)
	await _frames(4)
	await _shot("08_second_shot")
	_log_impact()

	var turns: int = 0
	while combat.phase != CombatMatch.Phase.GAME_OVER and turns < MAX_TURNS:
		await _until(CombatMatch.Phase.AIMING, true)
		if combat.phase == CombatMatch.Phase.GAME_OVER:
			break
		if combat.active_index == 0:
			_fire_at_head_with_solver(combat)
		else:
			combat.request_debug_fire(1, FILLER_SHOT_ANGLE, FILLER_SHOT_POWER)
		await _until(CombatMatch.Phase.RESOLVING, true)
		_log_impact()
		turns += 1
	await _frames(30)
	await _shot("09_game_over")
	_log("phase %s, winner %d, hp %d / %d" % [
		CombatMatch.Phase.keys()[combat.phase], combat.winner_index, combat.combatants[0].hp, combat.combatants[1].hp
	])

	sandbox.set_debug_overlay_visible(true)
	await _frames(4)
	await _shot("10_debug_overlay")
	sandbox.reset_sandbox()
	await _frames(10)
	await _shot("11_reset")
	_log("reset restores the initial state: %s" % (str(combat.snapshot()) == initial))
	Engine.time_scale = 1.0
	get_tree().quit(0)


## Test automation only: BallisticSolver finds the Full Throw-power angle that
## reaches the opponent's head centre from the muzzle, at the head's height.
func _fire_at_head_with_solver(combat: CombatMatch) -> void:
	var shooter: CombatantState = combat.active()
	var target: CombatantState = combat.opponent_of(shooter.index)
	var direction: int = 1 if target.feet_x > shooter.feet_x else -1
	combat.request_face(shooter.index, direction)
	var rules: CombatRules = combat.rules
	var angle: float = BallisticSolver.solve_angle(
		combat.params, absf(target.head_center_x() - shooter.muzzle_x(rules)), BallisticEvidence.FULL_THROW_POWER,
		combat.wind * direction, BallisticEvidence.HIGH_BRANCH_MIN_ANGLE, BallisticEvidence.HIGH_BRANCH_MAX_ANGLE,
		target.head_center_y(rules) - shooter.muzzle_y(rules)
	)
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
	_log("%s | phase %s, turn %d, active P%d, wind %+.1f, hp %d / %d" % [
		name, CombatMatch.Phase.keys()[combat.phase], combat.turn_number, combat.active_index + 1, combat.wind,
		combat.combatants[0].hp, combat.combatants[1].hp
	])


func _log_impact() -> void:
	var combat: CombatMatch = sandbox.combat
	var report: CombatMatch.ImpactReport = combat.last_impact
	if report != null:
		_log("impact %s at (%.3f, %.3f), damages %s, flight %.3f s" % [report.tag, report.x, report.y, report.damages, combat.flight.flight_time])


func _log(text: String) -> void:
	print("CAPTURE " + text)
