class_name BallisticsLab
extends Control
## Developer instrument that visualises ProjectileSimulation (Milestone 2).
## Not the battle scene. Every trajectory comes from LabShotSetup.simulate(), which
## calls the same ProjectileSimulation the tests use.
##
## User arguments (after "--"):
##   --capture=<absolute dir>  save screenshots of every scenario and camera mode, then quit

@onready var _viewport: SubViewport = $Layout/WorldView/WorldViewport as SubViewport
@onready var _renderer: LabTrajectoryRenderer = $Layout/WorldView/WorldViewport/World/TrajectoryRenderer as LabTrajectoryRenderer
@onready var _shooter: LabReferenceMarker = $Layout/WorldView/WorldViewport/World/ShooterMarker as LabReferenceMarker
@onready var _target: LabReferenceMarker = $Layout/WorldView/WorldViewport/World/TargetMarker as LabReferenceMarker
@onready var _playback: LabPlaybackMarker = $Layout/WorldView/WorldViewport/World/PlaybackMarker as LabPlaybackMarker
@onready var _camera: LabDebugCamera = $Layout/WorldView/WorldViewport/World/DebugCamera as LabDebugCamera
@onready var _panel: LabPanel = $Layout/Panel as LabPanel

var metrics: GameMetrics
var params: BallisticParameters
var setup: LabShotSetup
var result: BallisticResult
var camera_mode: LabDebugCamera.Mode = LabDebugCamera.Mode.BATTLE
var _last_visible_units: Vector2 = Vector2.ZERO


func _ready() -> void:
	metrics = GameMetrics.load_default()
	params = metrics.create_ballistic_parameters()
	_camera.battle_width_units = metrics.battle_view_width_units

	_panel.setup_edited.connect(_on_setup_edited)
	_panel.full_throw_requested.connect(apply_full_throw)
	_panel.solve_angle_requested.connect(solve_angle)
	_panel.solve_power_requested.connect(solve_power)
	_panel.scenario_requested.connect(apply_scenario)
	_panel.camera_mode_requested.connect(set_camera_mode)
	_panel.playback_requested.connect(_on_playback_requested)
	_panel.playback_speed_changed.connect(func(speed: float) -> void: _playback.playback_speed = speed)

	apply_scenario(LabScenarios.DEFAULT_ID)
	_start_capture_if_requested()


func _process(_delta: float) -> void:
	_update_camera()
	var visible: Vector2 = _camera.visible_size_units()
	if not visible.is_equal_approx(_last_visible_units):
		_last_visible_units = visible
		_refresh_results()


func apply_scenario(id: String) -> void:
	setup = LabScenarios.build(id)
	_panel.set_setup(setup)
	_panel.set_note("Scenario %s: %s" % [id, LabScenarios.title(id)])
	recompute()


func apply_full_throw() -> void:
	var angle: float = LabAimingTools.apply_full_throw(setup)
	var note: String = "Full Throw preset (evidence-based aiming technique, not physics): power %s, angle = 90 - D + 2 x relative wind = %.3f deg." % [
		BallisticEvidence.FULL_THROW_POWER, angle
	]
	if LabAimingTools.is_outside_normal_range(angle):
		note += "\nWARNING: angle outside 0-90 deg. Not clamped. See OQ-22."
	_panel.set_setup(setup)
	_panel.set_note(note)
	recompute()


func solve_angle(high_arc: bool) -> void:
	_show_solve(LabAimingTools.solve_angle(setup, params, high_arc))


func solve_power() -> void:
	_show_solve(LabAimingTools.solve_power(setup, params))


func set_camera_mode(mode: LabDebugCamera.Mode) -> void:
	camera_mode = mode
	if mode == LabDebugCamera.Mode.FOLLOW:
		_playback.restart()
	_update_camera()
	_refresh_results()


func seek_playback(time: float) -> void:
	_playback.seek(time)
	_update_camera()


func recompute() -> void:
	result = setup.simulate(params)
	_renderer.show_result(setup, result)
	_shooter.facing = setup.facing
	_shooter.caption = "shooter (0, 0)"
	_target.position = LabView.to_canvas(setup.target_x(), setup.target_y())
	_target.caption = "target (%.2f, %+.2f)" % [setup.target_x(), setup.target_y()]
	_playback.load_result(result, camera_mode == LabDebugCamera.Mode.FOLLOW)
	_update_camera()
	_refresh_results()


## Bounds (u) of the trajectory, shooter, target and apex for the Fit view.
func trajectory_bounds() -> Rect2:
	var bounds := Rect2(Vector2.ZERO, Vector2.ZERO)
	for sample in result.samples:
		bounds = bounds.expand(sample)
	bounds = bounds.expand(Vector2(setup.target_x(), setup.target_y()))
	return bounds.expand(Vector2(result.apex_x, result.apex_y))


func visible_size_units() -> Vector2:
	return _camera.visible_size_units()


func _update_camera() -> void:
	match camera_mode:
		LabDebugCamera.Mode.BATTLE:
			_camera.frame_battle(0.0, setup.target_x())
		LabDebugCamera.Mode.FOLLOW:
			_camera.frame_follow(_playback.position_units())
		LabDebugCamera.Mode.FIT:
			_camera.frame_fit(trajectory_bounds())


func _refresh_results() -> void:
	_panel.set_results(LabResultFormatter.format(setup, result, metrics, camera_mode, _camera.visible_size_units()))


func _show_solve(outcome: LabAimingTools.SolveOutcome) -> void:
	var text: String = "Solve %s (BallisticSolver)\nrequested: %s\n" % [outcome.quantity, outcome.requested]
	if outcome.found:
		text += "solved: %.6f%s" % [outcome.value, " (%s)" % outcome.note if outcome.note != "" else ""]
		if outcome.quantity == "angle":
			setup.angle = outcome.value
		else:
			setup.power = outcome.value
		_panel.set_setup(setup)
		recompute()
	else:
		text += "NO SOLUTION (nothing was changed)"
	_panel.set_note(text)


func _on_setup_edited(edited: LabShotSetup) -> void:
	setup = edited
	recompute()


func _on_playback_requested(action: String) -> void:
	match action:
		"play":
			_playback.play()
		"pause":
			_playback.pause()
		"restart":
			_playback.restart()


func _start_capture_if_requested() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			var capture := LabCapture.new()
			capture.lab = self
			capture.output_dir = arg.trim_prefix("--capture=")
			add_child(capture)
