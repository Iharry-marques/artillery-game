class_name CombatMatch
extends RefCounted
## Turn-based combat flow of the sandbox (pure logic, no nodes; driven by update()).
##
## AIMING -> CHARGING -> FLIGHT -> RESOLVING -> next player's AIMING (or GAME_OVER).
## Shots use the calibrated ProjectileSimulation with the world collision query.
## Two players simply alternate; the historical delay/agility order is not modelled.

signal shot_fired(result: BallisticResult)
signal impact_resolved(report: ImpactReport)
signal terrain_changed(region: Rect2i, center_x: float, center_y: float, radius: float)
signal turn_started(active_index: int)
signal match_over(winner_index: int)

enum Phase { AIMING, CHARGING, FLIGHT, RESOLVING, GAME_OVER }

const TAG_TIMEOUT: StringName = &"timeout"
const NO_WINNER: int = -1


class ImpactReport:
	extends RefCounted
	var x: float
	var y: float
	var tag: StringName
	var crater: bool = false
	## Damage dealt to each combatant, by index.
	var damages: PackedInt32Array = PackedInt32Array()


var metrics: GameMetrics
var rules: CombatRules
var params: BallisticParameters
var terrain: TerrainMask
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
var _drawn_wind: float = 0.0
var _resolve_timer: float = 0.0
var _wind_generator: WindGenerator


func _init(p_metrics: GameMetrics, p_rules: CombatRules) -> void:
	metrics = p_metrics
	rules = p_rules
	params = metrics.create_ballistic_parameters()
	reset()


## Restores the initial deterministic state: terrain, players, HP, wind (including
## the debug "force zero" toggle), turn.
func reset() -> void:
	force_zero_wind = false
	terrain = ReferenceBattleMap.build(rules)
	combatants.clear()
	var center: float = rules.map_width * 0.5
	for i in rules.spawn_x.size():
		var x: float = rules.spawn_x[i]
		var combatant := CombatantState.new(i, "Player %d" % (i + 1), x, 0.0, 1 if x < center else -1, rules)
		CharacterMotor.place_on_ground(terrain, rules, combatant)
		combatants.append(combatant)
	_wind_generator = WindGenerator.new(rules)
	active_index = 0
	turn_number = 1
	phase = Phase.AIMING
	power = 0.0
	last_shot_power = NAN
	last_shot_angle = NAN
	flight = null
	flight_elapsed = 0.0
	last_impact = null
	winner_index = NO_WINNER
	_draw_wind()
	turn_started.emit(active_index)


func active() -> CombatantState:
	return combatants[active_index]


func opponent_of(index: int) -> CombatantState:
	return combatants[(index + 1) % combatants.size()]


func can_act(player_index: int) -> bool:
	return player_index == active_index and phase == Phase.AIMING and active().alive


func request_move(player_index: int, direction: int, delta: float) -> bool:
	if not can_act(player_index) or direction == 0:
		return false
	var combatant: CombatantState = active()
	combatant.facing = direction
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
	combatant.angle = clampi(combatant.angle + steps, rules.angle_min, rules.angle_max)
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


## Debug only: fires with an exact angle and power, bypassing the charge bar.
func request_debug_fire(player_index: int, angle: float, shot_power: float) -> bool:
	if not can_act(player_index):
		return false
	_fire(angle, shot_power)
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
			if not active().alive or alive_count() <= 1:
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


func horizontal_distance_between_players() -> float:
	return absf(combatants[1].feet_x - combatants[0].feet_x)


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
	last_shot_angle = angle
	last_shot_power = shot_power
	power = 0.0
	flight_elapsed = 0.0
	phase = Phase.FLIGHT
	shot_fired.emit(flight)


func _resolve_impact() -> void:
	var report := ImpactReport.new()
	report.x = flight.impact_x
	report.y = flight.impact_y
	report.tag = flight.hit.tag if flight.hit != null else TAG_TIMEOUT
	report.damages.resize(combatants.size())
	if report.tag == CombatWorldQuery.TAG_TERRAIN or report.tag == CombatWorldQuery.TAG_HEAD:
		report.crater = true
		var region: Rect2i = terrain.carve_circle(report.x, report.y, rules.crater_radius)
		if region.has_area():
			terrain_changed.emit(region, report.x, report.y, rules.crater_radius)
		for combatant in combatants:
			if combatant.alive:
				var damage: int = DamageModel.damage_to(rules, combatant, report.x, report.y)
				combatant.apply_damage(damage)
				report.damages[combatant.index] = damage
	last_impact = report
	_resolve_timer = rules.impact_hold_time
	phase = Phase.RESOLVING
	impact_resolved.emit(report)


## Lets every living character fall onto its support. True when all are settled.
func _settle(delta: float) -> bool:
	var settled: bool = true
	for combatant in combatants:
		if combatant.alive and not CharacterMotor.fall(terrain, rules, combatant, rules.fall_speed * delta):
			settled = false
	return settled


func _end_turn() -> void:
	if alive_count() <= 1:
		phase = Phase.GAME_OVER
		winner_index = NO_WINNER
		for combatant in combatants:
			if combatant.alive:
				winner_index = combatant.index
		match_over.emit(winner_index)
		return
	active_index = (active_index + 1) % combatants.size()
	turn_number += 1
	active().movement_left = rules.movement_budget
	power = 0.0
	_draw_wind()
	phase = Phase.AIMING
	turn_started.emit(active_index)


## Always draws from the generator so the sequence stays reproducible.
func _draw_wind() -> void:
	_drawn_wind = _wind_generator.next_wind()
	wind = 0.0 if force_zero_wind else _drawn_wind
