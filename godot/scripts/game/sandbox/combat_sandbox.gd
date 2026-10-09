class_name CombatSandbox
extends Node2D
## The battle scene. Without a pending BattleSetup it is the hot-seat sandbox
## (Milestones 3-4); with GameSession.pending_battle it plays a PvP room or a staged
## PvE expedition: AI turns, monsters, stage transitions and the result screen.
## All rules live in CombatMatch; this node reads input, drives the camera and keeps
## the presentation in sync. Calibrated ballistics are untouched.
##
## User arguments (after "--"):
##   --capture=<absolute dir>  scripted sandbox playthrough with screenshots, then quit
##   --autoplay                the AI also plays the local player (demos, captures)

## Team colours (team 0 = blue side, team 1 = red side).
const PLAYER_COLORS: Array[Color] = [Color(0.3, 0.62, 1.0), Color(1.0, 0.42, 0.4)]
## Pause on the final blow / stage clear before moving on.
const STAGE_END_DELAY: float = 2.6
const LEAVE_CONFIRM_TIME: float = 3.0

enum After { NOTHING, NEXT_STAGE, FINISH }

## Keep the projectile this far inside the view while following it (fractions of
## the view: sides, top, bottom; the bottom one clears the HUD bar).
const FLIGHT_MARGINS: Vector3 = Vector3(0.25, 0.18, 0.34)

@onready var _background: BattleBackground = $Background as BattleBackground
@onready var _terrain_view: TerrainView = $World/TerrainView as TerrainView
@onready var _world: Node2D = $World as Node2D
@onready var _combatant_views: Array[CombatantView] = [$World/Player1 as CombatantView, $World/Player2 as CombatantView]
@onready var _projectile_view: ProjectileView = $World/Projectile as ProjectileView
@onready var _explosion_view: ExplosionView = $World/Explosion as ExplosionView
@onready var _hitbox_overlay: SandboxHitboxOverlay = $World/HitboxOverlay as SandboxHitboxOverlay
@onready var _debug_overlay: SandboxDebugOverlay = $World/DebugOverlay as SandboxDebugOverlay
@onready var _camera: BattleCamera = $World/BattleCamera as BattleCamera
@onready var _hud: SandboxHud = $Hud/HudRoot as SandboxHud

var metrics: GameMetrics
var rules: CombatRules
var art: CharacterProxyArt
var combat: CombatMatch
## Battle mode only (null = sandbox).
var setup: BattleSetup
var stage: int = 0
var ai: AiTurnDriver
var autoplay: bool = false
var outcome: BattleOutcome
## Screen opened once the battle is over (tests clear it to stay on the scene).
var finish_screen: StringName = &"result"
var stage_end_delay: float = STAGE_END_DELAY
var _colors: Array[Color] = []
var _angle_repeat_timer: float = 0.0
var _snap_camera: bool = true
var _after: After = After.NOTHING
var _after_timer: float = 0.0
var _leave_armed: float = 0.0
var _ai_status: String = ""


func _ready() -> void:
	SandboxInput.ensure_actions()
	metrics = GameMetrics.load_default()
	rules = CombatRules.load_default()
	art = CharacterProxyArt.load_default()
	setup = GameSession.get_instance().pending_battle
	autoplay = OS.get_cmdline_user_args().has("--autoplay")
	_camera.width_units = metrics.battle_view_width_units
	_camera.map_width = rules.map_width
	_debug_overlay.visible = false
	_hitbox_overlay.visible = false
	_hitbox_overlay.art = art
	_background.camera = _camera
	_explosion_view.rules = rules
	_projectile_view.art = art
	if setup != null:
		outcome = BattleOutcome.new()
		outcome.mode = setup.mode
		outcome.room_name = setup.room_name
		outcome.instance_id = setup.instance_id
		outcome.difficulty = setup.difficulty
		_hud.set_help(SandboxHud.BATTLE_HELP_TEXT)
		_add_leave_button()
	_start_match({})
	_start_capture_if_requested()


func is_battle_mode() -> bool:
	return setup != null


func _start_match(carried_hp: Dictionary) -> void:
	combat = CombatMatch.new(metrics, rules, setup, stage, carried_hp)
	if setup != null:
		ai = AiTurnDriver.new(combat, setup.battle_seed + stage * 31)
		ai.drive_humans = autoplay
	_bind_match()
	if setup != null and setup.mode == BattleSetup.Mode.PVE:
		_hud.show_banner("STAGE %d  ·  %s" % [stage + 1, setup.stage_titles[stage].to_upper()], Color(1.0, 0.86, 0.3))
		_hud.show_message("Stage %d of %d" % [stage + 1, setup.stage_count()])
	else:
		_announce_turn(combat.active_index)


func _process(delta: float) -> void:
	if _human_turn():
		_handle_held_input(delta)
	if ai != null:
		ai.update(delta)
		if ai.status != _ai_status:
			_ai_status = ai.status
			if _ai_status != "":
				_hud.show_message(_ai_status)
	combat.update(delta)
	_update_camera(delta)
	for view in _combatant_views:
		if view.state == null or not view.visible:
			continue
		view.is_active = view.state.index == combat.active_index and combat.phase != CombatMatch.Phase.GAME_OVER
		view.is_aiming = view.is_active and (combat.phase == CombatMatch.Phase.AIMING or combat.phase == CombatMatch.Phase.CHARGING)
	_hud.refresh(combat)
	_leave_armed = maxf(0.0, _leave_armed - delta)
	if _after != After.NOTHING:
		_after_timer -= delta
		if _after_timer <= 0.0:
			var action: After = _after
			_after = After.NOTHING
			if action == After.NEXT_STAGE:
				var carried: Dictionary = combat.carried_hp()
				stage += 1
				_start_match(carried)
			else:
				_finish()


## True when the active combatant is controlled by the keyboard.
func _human_turn() -> bool:
	if ai == null:
		return true
	return not ai.is_ai(combat.active())


func _unhandled_input(event: InputEvent) -> void:
	if setup != null:
		_battle_input(event)
		return
	if event.is_action_pressed(SandboxInput.RESET):
		reset_sandbox()
	elif event.is_action_pressed(SandboxInput.TOGGLE_DEBUG):
		_debug_overlay.visible = not _debug_overlay.visible
	elif event.is_action_pressed(SandboxInput.TOGGLE_HITBOXES):
		_hitbox_overlay.visible = not _hitbox_overlay.visible
	elif event.is_action_pressed(SandboxInput.TOGGLE_ZERO_WIND):
		combat.set_force_zero_wind(not combat.force_zero_wind)
		_hud.show_message("Wind forced to 0" if combat.force_zero_wind else "Wind back to the seeded generator")
	elif event.is_action_pressed(SandboxInput.DEBUG_FULL_THROW):
		debug_full_throw()


func _battle_input(event: InputEvent) -> void:
	if event.is_action_pressed(SandboxInput.TOGGLE_HITBOXES):
		_hitbox_overlay.visible = not _hitbox_overlay.visible
	elif event.is_action_pressed(SandboxInput.TOGGLE_DEBUG):
		_debug_overlay.visible = not _debug_overlay.visible
	elif event.is_action_pressed(&"ui_cancel"):
		request_leave()
	elif event is InputEventKey and (event as InputEventKey).pressed and (event as InputEventKey).keycode == KEY_1:
		use_heal_item()


## Uses a Healing Kit on the local player (its own turn, once per turn).
func use_heal_item() -> void:
	var me: CombatantState = combat.local_player()
	if not _human_turn() or not combat.request_heal(me.index):
		var left: int = me.loadout.heal_items - me.heals_used if me.loadout != null else 0
		_hud.show_message("No Healing Kit to use now (%d left)" % maxi(left, 0))
		return
	_combatant_views[me.index].flash()
	_hud.show_message("%s used a Healing Kit (+%d HP)" % [me.display_name, me.loadout.heal_amount])


## Leaving needs a second press within LEAVE_CONFIRM_TIME; it counts as a defeat.
func request_leave() -> void:
	if _after == After.FINISH:
		return
	if _leave_armed <= 0.0:
		_leave_armed = LEAVE_CONFIRM_TIME
		_hud.show_message("Press ESC / Leave again to give up (counts as a defeat)")
		return
	_accumulate(false)
	outcome.surrendered = true
	outcome.victory = false
	_finish()


func _add_leave_button() -> void:
	var leave: Button = UiKit.button("Leave", request_leave, "dark", Vector2(130, 42))
	leave.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	leave.offset_left = -SandboxMinimap.WIDTH_PX - 20.0 - 142.0
	leave.offset_right = -SandboxMinimap.WIDTH_PX - 32.0
	leave.offset_top = 12.0
	leave.offset_bottom = 54.0
	leave.focus_mode = Control.FOCUS_NONE
	_hud.add_child(leave)


## Adds the local player's numbers of the finished stage to the battle outcome.
func _accumulate(stage_won: bool) -> void:
	var me: CombatantState = combat.local_player()
	outcome.shots += me.shots
	outcome.hits += me.hits
	outcome.damage_dealt += me.damage_dealt
	outcome.kills += me.kills
	outcome.heal_items_used += me.heals_used
	for c in combat.combatants:
		if c.team != me.team and not c.alive:
			outcome.enemy_exp += c.exp_reward
			outcome.enemy_gold += c.gold_reward
	if stage_won:
		outcome.stages_cleared += 1
	# Healing Kits are a shared stock across the stages of one expedition.
	if me.loadout != null:
		me.loadout.heal_items = maxi(0, me.loadout.heal_items - me.heals_used)


func _finish() -> void:
	_after = After.NOTHING
	var game: GameSession = GameSession.get_instance()
	game.finish_battle(outcome)
	if finish_screen != &"":
		ScreenRouter.go(self, finish_screen)


func set_debug_overlay_visible(enabled: bool) -> void:
	_debug_overlay.visible = enabled


func set_hitbox_overlay_visible(enabled: bool) -> void:
	_hitbox_overlay.visible = enabled


func reset_sandbox() -> void:
	combat.reset()
	_bind_views()
	_hud.show_message("Sandbox reset")
	_announce_turn(combat.active_index)


## Debug helper: aims the evidence-based Full Throw rule (power 95, angle = 90 - D
## + 2 x relative wind, D = feet-to-feet distance) at the opponent and fires.
func debug_full_throw() -> void:
	if not combat.can_act(combat.active_index):
		return
	var shooter: CombatantState = combat.active()
	var target: CombatantState = combat.opponent_of(shooter.index)
	var direction: int = 1 if target.feet_x > shooter.feet_x else -1
	combat.request_face(shooter.index, direction)
	var distance: float = absf(target.feet_x - shooter.feet_x)
	var angle: float = BallisticEvidence.full_throw_angle(distance, combat.wind * direction)
	if angle < rules.angle_min or angle > rules.angle_max:
		_hud.show_message("DEBUG Full Throw needs %.2f°, outside the %d-%d input range (OQ-22). Not fired." % [angle, rules.angle_min, rules.angle_max])
		return
	combat.request_angle_step(shooter.index, roundi(angle) - shooter.angle)
	combat.request_debug_fire(shooter.index, angle, BallisticEvidence.FULL_THROW_POWER)
	_hud.show_message("DEBUG Full Throw: D %.2f u, angle %.2f°, power %s" % [distance, angle, BallisticEvidence.FULL_THROW_POWER])


func _bind_match() -> void:
	combat.shot_fired.connect(func(result: BallisticResult) -> void: _debug_overlay.remember_flight(result))
	combat.terrain_changed.connect(_terrain_view.apply_crater)
	combat.impact_resolved.connect(_on_impact)
	combat.turn_started.connect(_announce_turn)
	combat.match_over.connect(_on_match_over)
	_bind_views()


## One view per combatant: the scene's Player1/Player2 plus Player3.. created on demand.
func _ensure_views(count: int) -> void:
	while _combatant_views.size() < count:
		var view := CombatantView.new()
		view.name = "Player%d" % (_combatant_views.size() + 1)
		_world.add_child(view)
		_world.move_child(view, _projectile_view.get_index())
		_combatant_views.append(view)
	for i in _combatant_views.size():
		var used: bool = i < count
		_combatant_views[i].visible = used
		_combatant_views[i].process_mode = Node.PROCESS_MODE_INHERIT if used else Node.PROCESS_MODE_DISABLED


func _bind_views() -> void:
	_terrain_view.build(combat.terrain)
	_ensure_views(combat.combatants.size())
	_colors.clear()
	for c in combat.combatants:
		_colors.append(PLAYER_COLORS[clampi(c.team, 0, 1)])
	_hud.player_colors = _colors
	for i in combat.combatants.size():
		var view: CombatantView = _combatant_views[i]
		var state: CombatantState = combat.combatants[i]
		view.state = state
		view.rules = rules
		view.art = art
		view.variant_index = 1 if state.visual == &"player_red" else 0
		view.team_color = Color(1.0, 0.9, 0.45) if state.is_local_player else _colors[i]
		view.setup()
	_projectile_view.combat = combat
	_hitbox_overlay.combat = combat
	_debug_overlay.combat = combat
	_debug_overlay.camera = _camera
	_debug_overlay.remember_flight(null)
	_hud.minimap.combat = combat
	_hud.minimap.camera = _camera
	_hud.minimap.projectile = _projectile_view
	_hud.minimap.player_colors = _colors
	_hud.minimap.invalidate()
	_snap_camera = true


func _handle_held_input(delta: float) -> void:
	var player: int = combat.active_index
	var direction: int = int(Input.is_action_pressed(SandboxInput.MOVE_RIGHT)) - int(Input.is_action_pressed(SandboxInput.MOVE_LEFT))
	if direction != 0:
		combat.request_move(player, direction, delta)

	var aim: int = int(Input.is_action_pressed(SandboxInput.AIM_UP)) - int(Input.is_action_pressed(SandboxInput.AIM_DOWN))
	if Input.is_action_just_pressed(SandboxInput.AIM_UP) or Input.is_action_just_pressed(SandboxInput.AIM_DOWN):
		combat.request_angle_step(player, aim)
		_angle_repeat_timer = rules.angle_repeat_interval * 3.0
	elif aim != 0:
		_angle_repeat_timer -= delta
		if _angle_repeat_timer <= 0.0:
			combat.request_angle_step(player, aim)
			_angle_repeat_timer = rules.angle_repeat_interval

	if Input.is_action_just_pressed(SandboxInput.FIRE):
		combat.request_begin_charge(player)
	elif Input.is_action_just_released(SandboxInput.FIRE):
		combat.request_release(player)


func _update_camera(delta: float) -> void:
	var target: Vector2
	var rate: float = rules.camera_follow_rate
	match combat.phase:
		CombatMatch.Phase.FLIGHT:
			target = _projectile_view.current_position_units()
			rate = rules.camera_flight_rate
		CombatMatch.Phase.RESOLVING:
			target = _camera.framing_for_feet(Vector2(combat.last_impact.x, combat.last_impact.y), rules.turn_framing_fraction)
			rate = rules.camera_flight_rate
		_:
			var active: CombatantState = combat.active()
			target = _camera.framing_for_feet(Vector2(active.feet_x, active.feet_y), rules.turn_framing_fraction)
	_camera.track(target, delta, rate, _snap_camera)
	if combat.phase == CombatMatch.Phase.FLIGHT:
		_camera.contain(_projectile_view.current_position_units(), FLIGHT_MARGINS.x, FLIGHT_MARGINS.y, FLIGHT_MARGINS.z)
	if _snap_camera:
		_background.reference_camera_px = _camera.position
	_snap_camera = false


func _announce_turn(index: int) -> void:
	var combatant: CombatantState = combat.combatants[index]
	var name: String = combatant.display_name
	if setup != null and combatant.is_local_player:
		_hud.show_message("Your turn!  W/S angle · hold SPACE for power")
		_hud.show_banner("YOUR TURN", Color(1.0, 0.86, 0.3))
		return
	_hud.show_message("%s's turn" % name)
	if setup == null or combatant.controller != BattleSetup.Controller.HUMAN:
		_hud.show_banner("%s TURN" % name.to_upper(), _colors[index])


func _on_impact(report: CombatMatch.ImpactReport) -> void:
	_explosion_view.show_impact(report, combat.combatants)
	if report.crater:
		_camera.shake(rules.camera_shake_units)
	var parts: PackedStringArray = []
	for c in combat.combatants:
		if report.damages[c.index] > 0:
			parts.append("%s -%d" % [c.display_name, report.damages[c.index]])
			_combatant_views[c.index].flash()
	match report.tag:
		CombatWorldQuery.TAG_HEAD:
			_hud.show_message("HEAD HIT!  " + ", ".join(parts))
		CombatWorldQuery.TAG_BOUNDS:
			_hud.show_message("Left the map")
		CombatMatch.TAG_SLAM:
			_hud.show_message("SHOCKWAVE!  " + ", ".join(parts))
		CombatMatch.TAG_MELEE:
			_hud.show_message("Smash!  " + ", ".join(parts))
		CombatMatch.TAG_TIMEOUT:
			pass
		_:
			_hud.show_message(", ".join(parts) if not parts.is_empty() else "Terrain hit")


func _on_match_over(winner: int) -> void:
	if setup != null:
		_on_battle_over()
		return
	if winner == CombatMatch.NO_WINNER:
		_hud.show_message("Draw!  Press R to restart")
		_hud.show_banner("DRAW", Color.WHITE)
	else:
		var name: String = combat.combatants[winner].display_name
		_hud.show_message("%s wins!  Press R to restart" % name)
		_hud.show_banner("%s WINS!" % name.to_upper(), _colors[winner])


func _on_battle_over() -> void:
	var won: bool = combat.winner_team == combat.local_player().team
	_accumulate(won)
	if won and setup.mode == BattleSetup.Mode.PVE and stage + 1 < setup.stage_count():
		_hud.show_banner("STAGE CLEAR!", Color(0.5, 1.0, 0.55))
		_hud.show_message("Get ready for stage %d: %s" % [stage + 2, setup.stage_titles[stage + 1]])
		_after = After.NEXT_STAGE
	else:
		outcome.victory = won
		_hud.show_banner("VICTORY!" if won else "DEFEAT", Color(1.0, 0.86, 0.3) if won else Color(1.0, 0.4, 0.38))
		_hud.show_message("Expedition cleared!" if won and setup.mode == BattleSetup.Mode.PVE else ("Your team wins!" if won else "Your team was defeated"))
		_after = After.FINISH
	_after_timer = stage_end_delay


func _start_capture_if_requested() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var capture := SandboxCapture.new()
			capture.sandbox = self
			capture.output_dir = arg.trim_prefix("--capture=")
			add_child(capture)
