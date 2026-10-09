class_name AiTurnDriver
extends RefCounted
## Plays the turns of AI-controlled combatants through the same requests a human
## uses (face, angle steps, charge, release, move, melee), with short "thinking"
## pauses so the player can follow. Presentation pacing only; rules stay in CombatMatch.

enum Step { THINK, AIM, CHARGE, WALK, DONE }

const THINK_TIME: float = 0.7
const ANGLE_STEP_TIME: float = 0.03
const WALK_STALL_TIME: float = 0.4
const BOSS_SLAM_FALLOFF: float = 0.7
const BOSS_SLAM_EVERY: int = 3

var battle: CombatMatch
var _rng := RandomNumberGenerator.new()
var _actor: int = -1
var _step: Step = Step.DONE
var _timer: float = 0.0
var _target_angle: int = 0
var _target_power: float = 0.0
var _target_index: int = -1
var _last_x: float = 0.0
var _stall: float = 0.0
## Short text describing what the AI is doing (for the HUD).
var status: String = ""
## Demos and captures: the AI also plays the HUMAN combatants.
var drive_humans: bool = false


func _init(p_battle: CombatMatch, seed_value: int) -> void:
	battle = p_battle
	_rng.seed = seed_value


func is_ai(combatant: CombatantState) -> bool:
	return drive_humans or combatant.controller != BattleSetup.Controller.HUMAN


func update(delta: float) -> void:
	if battle.phase != CombatMatch.Phase.AIMING and battle.phase != CombatMatch.Phase.CHARGING:
		return
	var actor: CombatantState = battle.active()
	if not is_ai(actor) or not actor.alive:
		return
	if _actor != actor.index or (_step == Step.DONE and battle.phase == CombatMatch.Phase.AIMING):
		_start(actor)
	_timer -= delta
	match _step:
		Step.THINK:
			if _timer <= 0.0:
				_decide(actor)
		Step.AIM:
			if _timer <= 0.0:
				_timer = ANGLE_STEP_TIME
				if actor.angle == _target_angle:
					battle.request_begin_charge(actor.index)
					_step = Step.CHARGE
				else:
					battle.request_angle_step(actor.index, signi(_target_angle - actor.angle))
		Step.CHARGE:
			if battle.power >= _target_power:
				battle.request_release(actor.index)
				_step = Step.DONE
		Step.WALK:
			_walk(actor, delta)


func _start(actor: CombatantState) -> void:
	_actor = actor.index
	_step = Step.THINK
	_timer = THINK_TIME
	var target: CombatantState = battle.opponent_of(actor.index)
	_target_index = target.index
	status = "%s is thinking..." % actor.display_name


func _decide(actor: CombatantState) -> void:
	var target: CombatantState = battle.combatants[_target_index]
	battle.request_face(actor.index, 1 if target.feet_x > actor.feet_x else -1)
	match actor.controller:
		BattleSetup.Controller.ENEMY_MELEE:
			_step = Step.WALK
			_last_x = actor.feet_x
			_stall = 0.0
			status = "%s charges!" % actor.display_name
			return
		BattleSetup.Controller.BOSS:
			if actor.actions_taken % BOSS_SLAM_EVERY == BOSS_SLAM_EVERY - 1:
				status = "%s uses SHOCKWAVE!" % actor.display_name
				battle.request_area_strike(actor.index, BOSS_SLAM_FALLOFF)
				_step = Step.DONE
				return
	var plan: Vector2 = ArtilleryPlanner.plan(battle, actor, target, _rng)
	_target_angle = roundi(plan.x)
	_target_power = plan.y
	_step = Step.AIM
	_timer = ANGLE_STEP_TIME
	status = "%s takes aim" % actor.display_name


func _walk(actor: CombatantState, delta: float) -> void:
	var target: CombatantState = battle.combatants[_target_index]
	var gap: float = absf(target.feet_x - actor.feet_x)
	if gap <= actor.reach * 0.85:
		battle.request_melee(actor.index, target.index)
		_step = Step.DONE
		return
	battle.request_move(actor.index, 1 if target.feet_x > actor.feet_x else -1, delta)
	if absf(actor.feet_x - _last_x) < 0.001:
		_stall += delta
	else:
		_stall = 0.0
	_last_x = actor.feet_x
	if actor.movement_left <= 0.0 or _stall > WALK_STALL_TIME:
		if not battle.request_melee(actor.index, target.index):
			battle.request_skip(actor.index)
		_step = Step.DONE
