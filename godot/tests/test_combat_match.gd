extends TestCase
## Turn flow, input locking, falling, wind and reset of the combat sandbox logic.

const FRAME: float = 1.0 / 60.0
## Upper bound for a whole shot (flight + resolution), in simulated seconds.
const MAX_TURN_SECONDS: float = 30.0
const FULL_THROW_ANGLE: float = 80.0


func _match() -> CombatMatch:
	return CombatMatch.new(GameMetrics.load_default(), CombatRules.load_default())


func _run_until_aiming(m: CombatMatch) -> void:
	var elapsed: float = 0.0
	while m.phase != CombatMatch.Phase.AIMING and m.phase != CombatMatch.Phase.GAME_OVER and elapsed < MAX_TURN_SECONDS:
		m.update(FRAME)
		elapsed += FRAME


func test_initial_state() -> void:
	var m: CombatMatch = _match()
	assert_true(m.active_index == 0 and m.phase == CombatMatch.Phase.AIMING, "player 1 starts aiming")
	assert_near(m.horizontal_distance_between_players(), 10.0, 1e-9, "spawns one battle screen apart")
	for c in m.combatants:
		assert_true(CharacterMotor.is_supported(m.terrain, m.rules, c), "%s stands on the ground" % c.display_name)
		assert_true(c.hp == m.rules.starting_hp, "full HP")
	assert_true(m.combatants[0].facing == 1 and m.combatants[1].facing == -1, "players face each other")


func test_inactive_player_cannot_move_aim_or_fire() -> void:
	var m: CombatMatch = _match()
	var before: Dictionary = m.snapshot()
	assert_true(not m.request_move(1, -1, 0.5), "player 2 cannot move on player 1's turn")
	assert_true(not m.request_angle_step(1, 1), "player 2 cannot aim")
	assert_true(not m.request_begin_charge(1), "player 2 cannot charge")
	assert_true(str(m.snapshot()) == str(before), "nothing changed")


func test_power_charges_linearly_and_caps() -> void:
	var m: CombatMatch = _match()
	assert_true(m.request_begin_charge(0), "charge starts")
	m.update(m.rules.power_charge_time * 0.5)
	assert_near(m.power, m.rules.power_max * 0.5, 1e-9, "half the charge time gives half power")
	m.update(m.rules.power_charge_time * 5.0)
	assert_near(m.power, m.rules.power_max, 0.0, "capped at the maximum")


func test_input_is_locked_during_flight_and_turn_switches_after_resolution() -> void:
	var m: CombatMatch = _match()
	m.request_begin_charge(0)
	m.update(0.8)
	assert_true(m.request_release(0), "release fires")
	assert_true(m.phase == CombatMatch.Phase.FLIGHT, "projectile in flight")
	assert_true(not m.request_move(0, 1, 0.5) and not m.request_angle_step(0, 1), "locked during flight")
	assert_true(not m.request_begin_charge(0), "cannot fire twice")
	_run_until_aiming(m)
	assert_true(m.active_index == 1 and m.turn_number == 2, "player 2's turn")
	assert_true(m.last_impact != null, "the shot was resolved")
	assert_near(m.active().movement_left, m.rules.movement_budget, 0.0, "movement budget reset")


func test_full_throw_hits_the_opponent_head_and_damages() -> void:
	var m: CombatMatch = _match()
	m.set_force_zero_wind(true)
	var target: CombatantState = m.combatants[1]
	assert_true(m.request_debug_fire(0, FULL_THROW_ANGLE, BallisticEvidence.FULL_THROW_POWER), "fires")
	assert_true(m.flight.hit != null and m.flight.hit.tag == CombatWorldQuery.TAG_HEAD, "Full Throw over 10 u hits a head")
	assert_true(m.flight.hit.collider == target, "it is the opponent's head")
	note("impact (%.3f, %.3f), flight %.3f s" % [m.flight.impact_x, m.flight.impact_y, m.flight.flight_time])
	_run_until_aiming(m)
	assert_true(target.hp == m.rules.starting_hp - roundi(m.rules.base_damage), "direct hit deals base damage, hp %d" % target.hp)
	assert_true(m.last_impact.crater, "a head hit also explodes (its crater may not reach the ground)")


func test_terrain_hit_leaves_a_crater() -> void:
	var m: CombatMatch = _match()
	m.set_force_zero_wind(true)
	var solid_before: int = m.terrain.solid_cell_count()
	assert_true(m.request_debug_fire(0, 45.0, 25.0), "fires a short shot")
	assert_true(m.flight.hit != null and m.flight.hit.tag == CombatWorldQuery.TAG_TERRAIN, "lands on terrain")
	_run_until_aiming(m)
	assert_true(m.terrain.solid_cell_count() < solid_before, "cells were removed")
	assert_true(not m.terrain.is_solid(m.last_impact.x, m.last_impact.y + 0.1), "the impact point is now empty")


func test_walking_follows_the_surface_and_spends_the_budget() -> void:
	# Walks left, over gentle bumps (towards the centre the hill is steeper than
	# max_slope_degrees and blocks the way, by design of the placeholder map).
	var m: CombatMatch = _match()
	var walker: CombatantState = m.combatants[0]
	var start_x: float = walker.feet_x
	for i in 600:
		m.request_move(0, -1, FRAME)
		m.update(FRAME)
	assert_near(walker.movement_left, 0.0, 1e-9, "budget spent")
	assert_true(start_x - walker.feet_x <= m.rules.movement_budget + 1e-9, "never beyond the budget")
	assert_true(start_x - walker.feet_x > 0.5, "actually moved")
	assert_true(walker.facing == -1, "turned to face the walking direction")
	assert_true(CharacterMotor.is_supported(m.terrain, m.rules, walker), "still on the ground")


func test_walls_block_movement() -> void:
	var rules: CombatRules = CombatRules.load_default()
	var terrain := TerrainMask.new(100, 60, 0.1)
	terrain.fill_below_surface(func(_x: float) -> float: return 4.0)
	terrain.fill_rect(Rect2(5.0, 1.0, 0.5, 3.0))
	var walker := CombatantState.new(0, "W", 3.0, 4.0, 1, rules)
	CharacterMotor.walk(terrain, rules, walker, 4.0)
	assert_true(walker.feet_x < 5.0, "stopped before the wall, x = %.3f" % walker.feet_x)
	assert_near(walker.feet_y, 4.0, 1e-9, "still on the floor")


func test_character_falls_when_support_is_removed() -> void:
	var m: CombatMatch = _match()
	var target: CombatantState = m.combatants[1]
	var start_y: float = target.feet_y
	m.terrain.carve_circle(target.feet_x, target.feet_y, 1.0)
	for i in 120:
		m.update(FRAME)
	assert_true(target.feet_y > start_y + 0.9, "fell into the crater: %.3f -> %.3f" % [start_y, target.feet_y])
	assert_true(CharacterMotor.is_supported(m.terrain, m.rules, target), "landed on the crater floor")


func test_falling_below_the_death_line_defeats_and_ends_the_match() -> void:
	var m: CombatMatch = _match()
	var target: CombatantState = m.combatants[1]
	target.feet_x = m.rules.map_width + 1.0
	for i in 600:
		m.update(FRAME)
	assert_true(not target.alive and target.hp == 0, "defeated")
	assert_true(m.phase == CombatMatch.Phase.GAME_OVER and m.winner_index == 0, "player 1 wins")


func test_wind_is_seeded_and_can_be_forced_to_zero() -> void:
	var a: CombatMatch = _match()
	var b: CombatMatch = _match()
	assert_near(a.wind, b.wind, 0.0, "same seed, same first wind")
	assert_true(absf(a.wind) <= a.rules.wind_max + 1e-9, "within range")
	var drawn: float = a.wind
	a.set_force_zero_wind(true)
	assert_near(a.wind, 0.0, 0.0, "forced to zero")
	a.set_force_zero_wind(false)
	assert_near(a.wind, drawn, 0.0, "restored")


func test_reset_restores_the_initial_deterministic_state() -> void:
	var m: CombatMatch = _match()
	var initial: String = str(m.snapshot())
	for i in 30:
		m.request_move(0, 1, FRAME)
	m.request_angle_step(0, 10)
	m.request_debug_fire(0, FULL_THROW_ANGLE, BallisticEvidence.FULL_THROW_POWER)
	_run_until_aiming(m)
	assert_true(str(m.snapshot()) != initial, "the match changed")
	m.reset()
	assert_true(str(m.snapshot()) == initial, "reset restores terrain, players, HP, wind, turn")
