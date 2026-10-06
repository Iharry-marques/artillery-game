class_name LabCapture
extends Node
## Developer capture: walks every scenario in every camera mode, prints the key
## numbers, saves a screenshot of each and quits. Requires a real window (the
## headless renderer produces no image).

const SETTLE_FRAMES: int = 3
const MODES: Array[LabDebugCamera.Mode] = [
	LabDebugCamera.Mode.BATTLE, LabDebugCamera.Mode.FOLLOW, LabDebugCamera.Mode.FIT
]
## Full Throw helper check: D = 1 with a 1.0 tailwind needs 91 degrees (OQ-22).
const OQ22_DISTANCE: float = 1.0
const OQ22_TAILWIND: float = 1.0

var lab: BallisticsLab
var output_dir: String


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(output_dir)
	for id in LabScenarios.IDS:
		lab.apply_scenario(id)
		for mode in MODES:
			lab.set_camera_mode(mode)
			if mode == LabDebugCamera.Mode.FOLLOW:
				lab.seek_playback(lab.result.apex_time)
			await _capture("%s_%s" % [id, LabDebugCamera.mode_name(mode).to_lower()])

	lab.apply_scenario(LabScenarios.DEFAULT_ID)
	lab.setup.distance = OQ22_DISTANCE
	lab.setup.wind = OQ22_TAILWIND
	lab.apply_full_throw()
	lab.set_camera_mode(LabDebugCamera.Mode.BATTLE)
	await _capture("G_full_throw_oq22_battle")
	get_tree().quit(0)


func _capture(name: String) -> void:
	for i in SETTLE_FRAMES:
		await get_tree().process_frame
	var setup: LabShotSetup = lab.setup
	var result: BallisticResult = lab.result
	var visible: Vector2 = lab.visible_size_units()
	print("CAPTURE %s | D %.2f y %+.2f angle %.3f power %.2f wind %+.2f | %s impact %.4f error %+.4f | T %.4f | apex (%.4f, %.4f) | view %.4f x %.4f u" % [
		name, setup.distance, setup.target_y(), setup.angle, setup.power, setup.wind, result.termination_name(),
		result.impact_x, setup.impact_error(result), result.flight_time, result.apex_x, result.apex_y, visible.x, visible.y
	])
	var image: Image = get_viewport().get_texture().get_image()
	image.save_png(output_dir.path_join(name + ".png"))
