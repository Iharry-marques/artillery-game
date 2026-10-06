extends TestCase
## Non-visual logic of the Ballistics Lab, plus a smoke test of the scene itself.
## No assertions on Control pixel positions.

const EPS: float = BallisticTolerances.NUMERICAL_EQUIVALENCE
const LAB_SCENE: String = "res://scenes/debug/ballistics_lab.tscn"
const RESOLUTIONS: Array[Vector2] = [
	Vector2(1280, 720), Vector2(1920, 1080), Vector2(800, 600), Vector2(880, 720), Vector2(2560, 1080), Vector2(720, 1280)
]
## Camera2D stores zoom in single precision.
const CAMERA_ZOOM_EPS: float = 1e-5
const SETTLE_FRAMES: int = 3


func _metrics() -> GameMetrics:
	return GameMetrics.load_default()


func test_battle_view_is_ten_units_wide_at_any_resolution() -> void:
	var width_units: float = _metrics().battle_view_width_units
	assert_near(width_units, 10.0, 0.0, "GameMetrics battle view width (E-01)")
	for size in RESOLUTIONS:
		var zoom: float = BattleViewFraming.zoom_for_width(size.x, width_units)
		assert_near(BattleViewFraming.visible_width_units(size.x, zoom), width_units, EPS, "%s width" % size)
		assert_near(
			BattleViewFraming.visible_height_units(size.y, zoom), width_units * size.y / size.x, EPS, "%s height follows aspect" % size
		)


func test_vertical_offset_uses_godot_y_down_convention() -> void:
	var below := LabShotSetup.new(5.0, 2.0, 85.0, 95.0)
	var above := LabShotSetup.new(5.0, -2.0, 85.0, 95.0)
	assert_near(below.target_y(), 2.0, 0.0, "+offset is world y")
	assert_near(below.height_above_shooter(), -2.0, 0.0, "+offset is BELOW the shooter")
	assert_near(above.height_above_shooter(), 2.0, 0.0, "-offset is ABOVE the shooter")
	var params: BallisticParameters = _metrics().create_ballistic_parameters()
	var level: BallisticResult = LabShotSetup.new(5.0, 0.0, 85.0, 95.0).simulate(params)
	var below_result: BallisticResult = below.simulate(params)
	var above_result: BallisticResult = above.simulate(params)
	assert_near(below_result.impact_y, 2.0, EPS, "impact lies on the lower plane")
	assert_near(above_result.impact_y, -2.0, EPS, "impact lies on the upper plane")
	assert_true(below_result.impact_x > level.impact_x, "a lower target is crossed farther away")
	assert_true(above_result.impact_x < level.impact_x, "a higher target is crossed sooner")


func test_lab_trajectory_is_the_projectile_simulation_output() -> void:
	var params: BallisticParameters = _metrics().create_ballistic_parameters()
	var setup: LabShotSetup = LabScenarios.build("A")
	var lab_result: BallisticResult = setup.simulate(params)
	var direct: BallisticResult = ProjectileSimulation.simulate_to_plane(ShotParameters.new(80.0, 95.0), params, 0.0, true)
	assert_true(lab_result.samples == direct.samples, "same samples as ProjectileSimulation")
	assert_true(lab_result.impact_x == direct.impact_x, "same impact")
	var errors: PackedFloat64Array = BallisticCalibrator.full_throw_errors(params)
	assert_near(setup.impact_error(lab_result), errors[9], EPS, "scenario A error equals the calibrated D = 10 error")


func test_facing_left_mirrors_target_and_wind() -> void:
	var params: BallisticParameters = _metrics().create_ballistic_parameters()
	var right := LabShotSetup.new(10.0, 0.0, 79.0, 95.0, -0.5, 1)
	var left := LabShotSetup.new(10.0, 0.0, 79.0, 95.0, 0.5, -1)
	assert_near(left.target_x(), -10.0, 0.0, "target on the facing side")
	assert_near(left.relative_wind(), -0.5, 0.0, "world +0.5 is a headwind when facing left")
	assert_near(left.impact_error(left.simulate(params)), -right.impact_error(right.simulate(params)), EPS, "mirrored error")


func test_full_throw_preset_uses_evidence_rule_without_clamping() -> void:
	var headwind := LabShotSetup.new(10.0, 0.0, 0.0, 0.0, -0.5, 1)
	assert_near(LabAimingTools.apply_full_throw(headwind), 79.0, EPS, "D 10, headwind 0.5")
	assert_near(headwind.power, BallisticEvidence.FULL_THROW_POWER, 0.0, "Full Throw power")
	var tailwind := LabShotSetup.new(10.0, 0.0, 0.0, 0.0, 0.5, 1)
	assert_near(LabAimingTools.apply_full_throw(tailwind), 81.0, EPS, "D 10, tailwind 0.5")
	var oq22 := LabShotSetup.new(1.0, 0.0, 0.0, 0.0, 1.0, 1)
	var angle: float = LabAimingTools.apply_full_throw(oq22)
	assert_near(angle, 91.0, EPS, "D 1, tailwind 1.0 is NOT clamped")
	assert_true(LabAimingTools.is_outside_normal_range(angle), "91 deg must be flagged (OQ-22)")


func test_solver_tools_report_no_solution() -> void:
	var params: BallisticParameters = _metrics().create_ballistic_parameters()
	var unreachable := LabShotSetup.new(5.0, -20.0, 80.0, 95.0)
	var outcome: LabAimingTools.SolveOutcome = LabAimingTools.solve_angle(unreachable, params, true)
	assert_true(not outcome.found and is_nan(outcome.value), "no fallback value")
	var reachable := LabShotSetup.new(5.0, -2.0, 80.0, 95.0)
	var solved: LabAimingTools.SolveOutcome = LabAimingTools.solve_angle(reachable, params, true)
	assert_true(solved.found, "elevated target is reachable")
	reachable.angle = solved.value
	assert_near(reachable.impact_error(reachable.simulate(params)), 0.0, EPS, "solved angle hits the elevated target")


func test_playback_follows_sample_times() -> void:
	var result: BallisticResult = LabScenarios.build("A").simulate(_metrics().create_ballistic_parameters())
	assert_true(result.sample_times.size() == result.samples.size(), "one time per sample")
	for i in range(1, result.sample_times.size()):
		assert_true(result.sample_times[i] > result.sample_times[i - 1], "sample times strictly increase")
	assert_near(TrajectoryPlayback.end_time(result), result.flight_time, 0.0, "playback ends at the impact time")
	assert_true(TrajectoryPlayback.position_at(result, 0.0) == result.samples[0], "starts at launch")
	assert_true(TrajectoryPlayback.position_at(result, result.flight_time) == result.samples[result.samples.size() - 1], "ends at impact")
	var middle: int = result.samples.size() / 2
	assert_true(TrajectoryPlayback.position_at(result, result.sample_times[middle]) == result.samples[middle], "exact at sample times")


func test_lab_scene_loads_and_frames_all_camera_modes() -> void:
	var packed: PackedScene = load(LAB_SCENE) as PackedScene
	assert_true(packed != null, "scene must load")
	if packed == null:
		return
	var lab: BallisticsLab = packed.instantiate() as BallisticsLab
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	tree.root.add_child(lab)
	for i in SETTLE_FRAMES:
		await tree.process_frame

	assert_true(lab.result != null and lab.result.hit_plane(), "default scenario simulates and hits")
	assert_near(lab.setup.impact_error(lab.result), -0.0701, 0.0001, "default D 10 Full Throw error")
	assert_near(lab.visible_size_units().x, 10.0, CAMERA_ZOOM_EPS, "Battle View width")

	lab.set_camera_mode(LabDebugCamera.Mode.FOLLOW)
	lab.seek_playback(lab.result.apex_time)
	await tree.process_frame
	assert_near(lab.visible_size_units().x, 10.0, CAMERA_ZOOM_EPS, "Follow view width")

	lab.set_camera_mode(LabDebugCamera.Mode.FIT)
	await tree.process_frame
	var visible: Vector2 = lab.visible_size_units()
	var bounds: Rect2 = lab.trajectory_bounds()
	assert_true(visible.x >= bounds.size.x and visible.y >= bounds.size.y, "Fit view contains the trajectory: %s vs %s" % [visible, bounds.size])

	for id in LabScenarios.IDS:
		lab.apply_scenario(id)
		assert_true(lab.result.hit_plane(), "scenario %s hits its target plane" % id)
	lab.queue_free()
	await tree.process_frame
