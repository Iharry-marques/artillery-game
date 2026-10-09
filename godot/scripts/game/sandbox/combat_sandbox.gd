class_name CombatSandbox
extends Node2D
## First playable scene (Milestone 3): two debug characters on a destructible
## procedural map, hot-seat turns. All rules live in CombatMatch; this node only
## reads input, drives the camera and keeps the views in sync.
##
## User arguments (after "--"):
##   --capture=<absolute dir>  scripted playthrough with screenshots, then quit

const PLAYER_COLORS: Array[Color] = [Color(0.35, 0.75, 1.0), Color(1.0, 0.5, 0.45)]

@onready var _terrain_view: TerrainView = $World/TerrainView as TerrainView
@onready var _combatant_views: Array[CombatantView] = [$World/Player1 as CombatantView, $World/Player2 as CombatantView]
@onready var _projectile_view: ProjectileView = $World/Projectile as ProjectileView
@onready var _explosion_view: ExplosionView = $World/Explosion as ExplosionView
@onready var _debug_overlay: SandboxDebugOverlay = $World/DebugOverlay as SandboxDebugOverlay
@onready var _camera: BattleCamera = $World/BattleCamera as BattleCamera
@onready var _hud: SandboxHud = $Hud/HudRoot as SandboxHud

var metrics: GameMetrics
var rules: CombatRules
var combat: CombatMatch
var _angle_repeat_timer: float = 0.0
var _snap_camera: bool = true


func _ready() -> void:
	SandboxInput.ensure_actions()
	metrics = GameMetrics.load_default()
	rules = CombatRules.load_default()
	combat = CombatMatch.new(metrics, rules)
	_camera.width_units = metrics.battle_view_width_units
	_camera.follow_rate = rules.camera_follow_rate
	_camera.map_width = rules.map_width
	_debug_overlay.visible = false
	_hud.player_colors = PLAYER_COLORS
	_explosion_view.rules = rules
	_bind_match()
	_start_capture_if_requested()


func _process(delta: float) -> void:
	_handle_held_input(delta)
	combat.update(delta)
	_update_camera(delta)
	for view in _combatant_views:
		view.is_active = view.state.index == combat.active_index and combat.phase != CombatMatch.Phase.GAME_OVER
		view.show_aim = view.is_active and (combat.phase == CombatMatch.Phase.AIMING or combat.phase == CombatMatch.Phase.CHARGING)
	_hud.refresh(combat)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(SandboxInput.RESET):
		reset_sandbox()
	elif event.is_action_pressed(SandboxInput.TOGGLE_DEBUG):
		_debug_overlay.visible = not _debug_overlay.visible
	elif event.is_action_pressed(SandboxInput.TOGGLE_ZERO_WIND):
		combat.set_force_zero_wind(not combat.force_zero_wind)
		_hud.show_message("Wind forced to 0" if combat.force_zero_wind else "Wind back to the seeded generator")
	elif event.is_action_pressed(SandboxInput.DEBUG_FULL_THROW):
		debug_full_throw()


func set_debug_overlay_visible(enabled: bool) -> void:
	_debug_overlay.visible = enabled


func reset_sandbox() -> void:
	combat.reset()
	_bind_views()
	_hud.show_message("Sandbox reset")


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
	combat.request_debug_fire(shooter.index, angle, BallisticEvidence.FULL_THROW_POWER)
	_hud.show_message("DEBUG Full Throw: D %.2f u, angle %.2f°, power %s" % [distance, angle, BallisticEvidence.FULL_THROW_POWER])


func _bind_match() -> void:
	combat.shot_fired.connect(func(result: BallisticResult) -> void: _debug_overlay.remember_flight(result))
	combat.terrain_changed.connect(_terrain_view.apply_crater)
	combat.impact_resolved.connect(_on_impact)
	combat.turn_started.connect(func(index: int) -> void: _hud.show_message("%s's turn" % combat.combatants[index].display_name))
	combat.match_over.connect(_on_match_over)
	_bind_views()


func _bind_views() -> void:
	_terrain_view.build(combat.terrain)
	for i in _combatant_views.size():
		_combatant_views[i].state = combat.combatants[i]
		_combatant_views[i].rules = rules
		_combatant_views[i].color = PLAYER_COLORS[i]
	_projectile_view.combat = combat
	_debug_overlay.combat = combat
	_debug_overlay.camera = _camera
	_debug_overlay.remember_flight(null)
	_hud.minimap.combat = combat
	_hud.minimap.camera = _camera
	_hud.minimap.projectile = _projectile_view
	_hud.minimap.player_colors = PLAYER_COLORS
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
	match combat.phase:
		CombatMatch.Phase.FLIGHT:
			target = _projectile_view.current_position_units()
		CombatMatch.Phase.RESOLVING:
			target = Vector2(combat.last_impact.x, combat.last_impact.y)
		_:
			var active: CombatantState = combat.active()
			target = _camera.framing_for_feet(Vector2(active.feet_x, active.feet_y), rules.turn_framing_fraction)
	_camera.track(target, delta, _snap_camera or combat.phase == CombatMatch.Phase.FLIGHT)
	_snap_camera = false


func _on_impact(report: CombatMatch.ImpactReport) -> void:
	_explosion_view.show_impact(report, combat.combatants)
	var parts: PackedStringArray = []
	for c in combat.combatants:
		if report.damages[c.index] > 0:
			parts.append("%s -%d" % [c.display_name, report.damages[c.index]])
	match report.tag:
		CombatWorldQuery.TAG_HEAD:
			_hud.show_message("HEAD HIT!  " + ", ".join(parts))
		CombatWorldQuery.TAG_BOUNDS:
			_hud.show_message("Left the map")
		_:
			_hud.show_message(", ".join(parts) if not parts.is_empty() else "Terrain hit")


func _on_match_over(winner: int) -> void:
	if winner == CombatMatch.NO_WINNER:
		_hud.show_message("Draw!  Press R to restart")
	else:
		_hud.show_message("%s wins!  Press R to restart" % combat.combatants[winner].display_name)


func _start_capture_if_requested() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var capture := SandboxCapture.new()
			capture.sandbox = self
			capture.output_dir = arg.trim_prefix("--capture=")
			add_child(capture)
