class_name CombatMatch
extends RefCounted
## Turn-based combat flow (pure logic, no nodes; driven by update()).
##
## AIMING -> CHARGING -> FLIGHT -> RESOLVING -> next combatant's AIMING (or GAME_OVER).
## Shots use the calibrated ProjectileSimulation with the world collision query.
## Without a BattleSetup this is the two-player hot-seat sandbox (placeholder
## damage). With one, combatants get stat loadouts, teams, AI controllers and the
## stage's map; turns interleave the teams (the historical delay/agility order is
## not modelled yet).

signal shot_fired(result: BallisticResult)
signal impact_resolved(report: ImpactReport)
signal terrain_changed(region: Rect2i, center_x: float, center_y: float, radius: float)
signal turn_started(active_index: int)
signal match_over(winner_index: int)

enum Phase { AIMING, CHARGING, FLIGHT, RESOLVING, GAME_OVER }

const TAG_TIMEOUT: StringName = &"timeout"
const TAG_MELEE: StringName = &"melee"
const TAG_SLAM: StringName = &"slam"
const NO_WINNER: int = -1
## Short pause after a melee hit, a slam or a skipped turn (s).
const QUICK_RESOLVE_TIME: float = 0.6


class ImpactReport:
	extends RefCounted
	var x: float
	var y: float
	var tag: StringName
	var crater: bool = false
	var crater_radius: float = 0.0
	var attacker_index: int = -1
	## Damage dealt to each combatant, by index.
	var damages: PackedInt32Array = PackedInt32Array()
	var criticals: PackedByteArray = PackedByteArray()


var metrics: GameMetrics
var rules: CombatRules
var params: BallisticParameters
var setup: BattleSetup
var stage: int = 0
var terrain: TerrainMask
var map_definition: MapDefinition
var combatants: Array[CombatantState] = []
var active_index: int = 0
var turn_number: int = 1
var phase: Phase = Phase.AIMING
var wind: float = 0.0
var force_zero_wind: bool = false
## Power currently charging (CHARGING) or 0.
var power: float = 0.0
var last_shot_power: float = NAN
var last_shot_angle: float = NAN
var flight: BallisticResult
## Simulated seconds of the current flight already played back.
var flight_elapsed: float = 0.0
var last_impact: ImpactReport
var winner_index: int = NO_WINNER
var winner_team: int = NO_WINNER
var _drawn_wind: float = 0.0
var _resolve_timer: float = 0.0
var _wind_generator: WindGenerator
var _turn_order: PackedInt32Array = PackedInt32Array()
var _turn_cursor: int = 0
var _carried_hp: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func _init(p_metrics: GameMetrics, p_rules: CombatRules, p_setup: BattleSetup = null, p_stage: int = 0, p_carried_hp: Dictionary = {}) -> void:
	metrics = p_metrics
	rules = p_rules
	setup = p_setup
	stage = p_stage
	_carried_hp = p_carried_hp
	params = metrics.create_ballistic_parameters()
	reset()


## Restores the initial deterministic state: terrain, combatants, HP, wind (including
## the debug "force zero" toggle), turn.
func reset() -> void:
	force_zero_wind = false
	combatants.clear()
	if setup == null:
		_build_sandbox()
	else:
		_build_from_setup()
	_wind_generator = WindGenerator.new(rules)
	_rng.seed = setup.battle_seed + stage * 7919 if setup != null else 1
	_turn_order = _interleave_teams()
	_turn_cursor = 0
	active_index = _turn_order[0]
	turn_number = 1
	phase = Phase.AIMING
	power = 0.0
	last_shot_power = NAN
	last_shot_angle = NAN
	flight = null
	flight_elapsed = 0.0
	last_impact = null
	winner_index = NO_WINNER
	winner_team = NO_WINNER
	_begin_turn_for(active())
	_draw_wind()
	turn_started.emit(active_index)


func _build_sandbox() -> void:
	map_definition = ReferenceBattleMap.definition(rules)
	terrain = BattleMapBuilder.build(map_definition, rules)
	var center: float = rules.map_width * 0.5
	for i in rules.spawn_x.size():
		var x: float = rules.spawn_x[i]
		var combatant := CombatantState.new(i, "Player %d" % (i + 1), x, 0.0, 1 if x < center else -1, rules)
		combatant.visual = &"player_blue" if i == 0 else &"player_red"
		CharacterMotor.place_on_ground(terrain, rules, combatant)
		combatants.append(combatant)


func _build_from_setup() -> void:
	map_definition = ContentCatalog.shared().map(setup.maps[stage])
	terrain = BattleMapBuilder.build(map_definition, rules)
	var pads: Array[PackedFloat64Array] = [map_definition.left_pads, map_definition.right_pads]
	var used: Array[int] = [0, 0]
	var participants: Array[BattleSetup.Participant] = setup.participants_for_stage(stage)
	for i in participants.size():
		var participant: BattleSetup.Participant = participants[i]
		var side: int = clampi(participant.team, 0, 1)
		var x: float = participant.spawn_x
		if is_nan(x):
			var side_pads: PackedFloat64Array = pads[side]
			x = side_pads[used[side] % side_pads.size()] + (used[side] / side_pads.size()) * (1.5 if side == 0 else -1.5)
			used[side] += 1
		var combatant := CombatantState.new(i, participant.display_name, x, 0.0, 1 if side == 0 else -1, rules)
		combatant.team = participant.team
		combatant.controller = participant.controller
		combatant.visual = participant.visual
		combatant.is_local_player = participant.is_local_player
		combatant.reach = participant.reach
		combatant.aim_error_degrees = participant.aim_error_degrees
		combatant.exp_reward = participant.exp_reward
		combatant.gold_reward = participant.gold_reward
		if participant.controller == BattleSetup.Controller.ENEMY_MELEE:
			combatant.turn_movement = participant.move_budget
		combatant.apply_loadout(participant.loadout)
		if participant.team == 0 and _carried_hp.has(i):
			combatant.hp = _carried_hp[i]
			combatant.alive = combatant.hp > 0
		CharacterMotor.place_on_ground(terrain, rules, combatant)
		combatants.append(combatant)


## Turn order alternating the teams: A1, B1, A2, B2, ... (extra members at the end).
func _interleave_teams() -> PackedInt32Array:
	var by_team: Dictionary = {}
	var teams: Array[int] = []
	for c in combatants:
		if not by_team.has(c.team):
			by_team[c.team] = []
			teams.append(c.team)
		var list: Array = by_team[c.team]
		list.append(c.index)
	teams.sort()
	var order := PackedInt32Array()
	var round_index: int = 0
	var added: bool = true
	while added:
		added = false
		for team in teams:
			var list: Array = by_team[team]
			if round_index < list.size():
				var index: int = list[round_index]
				order.append(index)
				added = true
		round_index += 1
	return order


func active() -> CombatantState:
	return combatants[active_index]


func opponent_of(index: int) -> CombatantState:
	var me: CombatantState = combatants[index]
	var best: CombatantState = null
	for c in combatants:
		if c.team != me.team and c.alive and (best == null or absf(c.feet_x - me.feet_x) < absf(best.feet_x - me.feet_x)):
			best = c
	return best if best != null else combatants[(index + 1) % combatants.size()]


func local_player() -> CombatantState:
	for c in combatants:
		if c.is_local_player:
			return c
	return combatants[0]


func can_act(player_index: int) -> bool:
	return player_index == active_index and phase == Phase.AIMING and active().alive


func angle_limits(combatant: CombatantState) -> Vector2i:
	if combatant.loadout != null:
		return Vector2i(combatant.loadout.min_angle, combatant.loadout.max_angle)
	return Vector2i(rules.angle_min, rules.angle_max)


func request_move(player_index: int, direction: int, delta: float) -> bool:
	if not can_act(player_index) or direction == 0:
		return false
	var combatant: CombatantState = active()
	combatant.facing = direction
	if combatant.anchored:
		return false
	var wanted: float = minf(rules.move_speed * delta, combatant.movement_left)
	if wanted <= 0.0:
		return false
	var moved: float = CharacterMotor.walk(terrain, rules, combatant, direction * wanted)
	combatant.movement_left = maxf(0.0, combatant.movement_left - moved)
	return moved > 0.0


func request_face(player_index: int, direction: int) -> bool:
	if not can_act(player_index) or direction == 0:
		return false
	active().facing = direction
	return true


func request_angle_step(player_index: int, steps: int) -> bool:
	if not can_act(player_index):
		return false
	var combatant: CombatantState = active()
	var limits: Vector2i = angle_limits(combatant)
	combatant.angle = clampi(combatant.angle + steps, limits.x, limits.y)
	return true


func request_begin_charge(player_index: int) -> bool:
	if not can_act(player_index):
		return false
	phase = Phase.CHARGING
	power = 0.0
	return true


func request_release(player_index: int) -> bool:
	if phase != Phase.CHARGING or player_index != active_index:
		return false
	_fire(active().angle, power)
	return true


## AI and debug: fires with an exact angle and power, bypassing the charge bar.
func request_debug_fire(player_index: int, angle: float, shot_power: float) -> bool:
	if not can_act(player_index):
		return false
	_fire(angle, shot_power)
	return true


## Uses a carried Healing Kit (once per turn; does not end the turn).
func request_heal(player_index: int) -> bool:
	var combatant: CombatantState = combatants[player_index]
	if not can_act(player_index) or combatant.loadout == null or combatant.healed_this_turn:
		return false
	if combatant.heals_used >= combatant.loadout.heal_items or combatant.hp >= combatant.max_hp:
		return false
	combatant.heal(combatant.loadout.heal_amount)
	combatant.heals_used += 1
	combatant.healed_this_turn = true
	return true


## Ends the turn without acting.
func request_skip(player_index: int) -> bool:
	if not can_act(player_index):
		return false
	_quick_resolve(_empty_report(TAG_TIMEOUT, active().feet_x, active().feet_y))
	return true


## Melee strike on an adjacent enemy (PvE monsters).
func request_melee(player_index: int, target_index: int) -> bool:
	if not can_act(player_index):
		return false
	var attacker: CombatantState = active()
	var target: CombatantState = combatants[target_index]
	if not target.alive or target.team == attacker.team or absf(target.feet_x - attacker.feet_x) > attacker.reach:
		return false
	var report: ImpactReport = _empty_report(TAG_MELEE, target.head_center_x(), target.head_center_y())
	_damage(attacker, target, 1.0, report)
	attacker.actions_taken += 1
	_quick_resolve(report)
	return true


## Boss shockwave: hits every enemy with a fixed falloff, whatever the distance.
func request_area_strike(player_index: int, falloff: float) -> bool:
	if not can_act(player_index):
		return false
	var attacker: CombatantState = active()
	var report: ImpactReport = _empty_report(TAG_SLAM, attacker.feet_x, attacker.feet_y)
	for target in combatants:
		if target.alive and target.team != attacker.team:
			_damage(attacker, target, falloff, report)
	attacker.actions_taken += 1
	_quick_resolve(report)
	return true


func set_force_zero_wind(enabled: bool) -> void:
	force_zero_wind = enabled
	if phase == Phase.AIMING or phase == Phase.CHARGING:
		wind = 0.0 if enabled else _drawn_wind


func update(delta: float) -> void:
	match phase:
		Phase.AIMING, Phase.CHARGING:
			if phase == Phase.CHARGING:
				power = minf(power + rules.power_max / rules.power_charge_time * delta, rules.power_max)
			_settle(delta)
			if not active().alive or alive_team_count() <= 1:
				_end_turn()
		Phase.FLIGHT:
			flight_elapsed = minf(flight_elapsed + delta * rules.flight_playback_speed, flight.flight_time)
			if flight_elapsed >= flight.flight_time:
				_resolve_impact()
		Phase.RESOLVING:
			_resolve_timer -= delta
			var settled: bool = _settle(delta)
			if _resolve_timer <= 0.0 and settled:
				_end_turn()


func alive_count() -> int:
	var count: int = 0
	for combatant in combatants:
		if combatant.alive:
			count += 1
	return count


func alive_team_count() -> int:
	var teams: Dictionary = {}
	for combatant in combatants:
		if combatant.alive:
			teams[combatant.team] = true
	return teams.size()


func team_alive(team: int) -> bool:
	for combatant in combatants:
		if combatant.alive and combatant.team == team:
			return true
	return false


func horizontal_distance_between_players() -> float:
	return absf(combatants[1].feet_x - combatants[0].feet_x)


## HP of the team-0 combatants, to carry into the next PvE stage.
func carried_hp() -> Dictionary:
	var hp: Dictionary = {}
	for combatant in combatants:
		if combatant.team == 0:
			hp[combatant.index] = combatant.hp
	return hp


## Deterministic state summary (tests and debugging).
func snapshot() -> Dictionary:
	var people: Array[Dictionary] = []
	for c in combatants:
		people.append({"x": c.feet_x, "y": c.feet_y, "hp": c.hp, "angle": c.angle, "move": c.movement_left, "facing": c.facing})
	return {
		"solid_cells": terrain.solid_cell_count(),
		"combatants": people,
		"active": active_index,
		"turn": turn_number,
		"phase": phase,
		"wind": wind,
	}


func _fire(angle: float, shot_power: float) -> void:
	var shooter: CombatantState = active()
	var shot := ShotParameters.new(angle, shot_power, wind, shooter.facing, shooter.muzzle_x(rules, angle), shooter.muzzle_y(rules, angle))
	var query := CombatWorldQuery.new(terrain, rules, combatants, shooter)
	flight = ProjectileSimulation.simulate_with_collisions(shot, params, query, true)
	shooter.shots += 1
	shooter.actions_taken += 1
	last_shot_angle = angle
	last_shot_power = shot_power
	power = 0.0
	flight_elapsed = 0.0
	phase = Phase.FLIGHT
	shot_fired.emit(flight)


func _resolve_impact() -> void:
	var shooter: CombatantState = active()
	var report: ImpactReport = _empty_report(flight.hit.tag if flight.hit != null else TAG_TIMEOUT, flight.impact_x, flight.impact_y)
	if report.tag == CombatWorldQuery.TAG_TERRAIN or report.tag == CombatWorldQuery.TAG_HEAD:
		report.crater = true
		report.crater_radius = shooter.loadout.crater_radius if shooter.loadout != null else rules.crater_radius
		var region: Rect2i = terrain.carve_circle(report.x, report.y, report.crater_radius)
		if region.has_area():
			terrain_changed.emit(region, report.x, report.y, report.crater_radius)
		var damage_radius: float = shooter.loadout.damage_radius if shooter.loadout != null else rules.damage_radius
		for combatant in combatants:
			if not combatant.alive:
				continue
			var distance: float = DamageModel.distance_to_head(rules, combatant, report.x, report.y)
			if shooter.loadout != null and combatant.loadout != null:
				_damage(shooter, combatant, maxf(0.0, 1.0 - distance / damage_radius), report)
			else:
				var damage: int = DamageModel.damage_to(rules, combatant, report.x, report.y)
				combatant.apply_damage(damage)
				report.damages[combatant.index] = damage
				_count_hit(shooter, combatant, damage)
	last_impact = report
	_resolve_timer = rules.impact_hold_time
	phase = Phase.RESOLVING
	impact_resolved.emit(report)


func _damage(attacker: CombatantState, target: CombatantState, falloff: float, report: ImpactReport) -> void:
	var crit_roll: float = _rng.randf()
	var amount: int = DamageFormula.damage(attacker.loadout, target.loadout, falloff, crit_roll)
	if amount <= 0:
		return
	target.apply_damage(amount)
	report.damages[target.index] += amount
	if crit_roll < attacker.loadout.luck / 4000.0:
		report.criticals[target.index] = 1
	_count_hit(attacker, target, amount)


func _count_hit(attacker: CombatantState, target: CombatantState, amount: int) -> void:
	if amount <= 0 or target.team == attacker.team:
		return
	attacker.hits += 1
	attacker.damage_dealt += amount
	if not target.alive:
		attacker.kills += 1


func _empty_report(tag: StringName, x: float, y: float) -> ImpactReport:
	var report := ImpactReport.new()
	report.tag = tag
	report.x = x
	report.y = y
	report.attacker_index = active_index
	report.damages.resize(combatants.size())
	report.criticals.resize(combatants.size())
	return report


func _quick_resolve(report: ImpactReport) -> void:
	last_impact = report
	_resolve_timer = QUICK_RESOLVE_TIME
	phase = Phase.RESOLVING
	impact_resolved.emit(report)


## Lets every living, non-anchored character fall onto its support. True when settled.
func _settle(delta: float) -> bool:
	var settled: bool = true
	for combatant in combatants:
		if combatant.alive and not combatant.anchored and not CharacterMotor.fall(terrain, rules, combatant, rules.fall_speed * delta):
			settled = false
	return settled


func _end_turn() -> void:
	if alive_team_count() <= 1:
		phase = Phase.GAME_OVER
		winner_index = NO_WINNER
		winner_team = NO_WINNER
		for combatant in combatants:
			if combatant.alive:
				winner_index = combatant.index
				winner_team = combatant.team
				break
		match_over.emit(winner_index)
		return
	for i in _turn_order.size():
		_turn_cursor = (_turn_cursor + 1) % _turn_order.size()
		if combatants[_turn_order[_turn_cursor]].alive:
			break
	active_index = _turn_order[_turn_cursor]
	turn_number += 1
	_begin_turn_for(active())
	power = 0.0
	_draw_wind()
	phase = Phase.AIMING
	turn_started.emit(active_index)


func _begin_turn_for(combatant: CombatantState) -> void:
	combatant.movement_left = combatant.turn_movement
	combatant.healed_this_turn = false


## Always draws from the generator so the sequence stays reproducible.
func _draw_wind() -> void:
	_drawn_wind = _wind_generator.next_wind()
	wind = 0.0 if force_zero_wind else _drawn_wind
