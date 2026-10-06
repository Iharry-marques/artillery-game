class_name LabPanel
extends PanelContainer
## Developer controls and read-outs of the Ballistics Lab. Emits requests; the
## BallisticsLab node decides what to do with them.

signal setup_edited(setup: LabShotSetup)
signal full_throw_requested
signal solve_angle_requested(high_arc: bool)
signal solve_power_requested
signal scenario_requested(id: String)
signal camera_mode_requested(mode: LabDebugCamera.Mode)
signal playback_requested(action: String)
signal playback_speed_changed(speed: float)

const PANEL_WIDTH_PX: float = 420.0
const MONO_FONT_NAMES: PackedStringArray = ["Menlo", "Consolas", "DejaVu Sans Mono", "Courier New", "monospace"]
const READOUT_FONT_SIZE: int = 11
const NOTE_FONT_SIZE: int = 12

var _distance: SpinBox
var _offset: SpinBox
var _angle: SpinBox
var _power: SpinBox
var _wind: SpinBox
var _facing: OptionButton
var _speed: SpinBox
var _note: Label
var _results: Label


func _ready() -> void:
	custom_minimum_size = Vector2(PANEL_WIDTH_PX, 0.0)
	var root := VBoxContainer.new()
	add_child(root)

	# Read-outs stay fixed at the top; the controls scroll underneath.
	_add_title(root, "BALLISTICS LAB  (debug instrument, units: u)")
	_results = Label.new()
	var mono := SystemFont.new()
	mono.font_names = MONO_FONT_NAMES
	_results.add_theme_font_override("font", mono)
	_results.add_theme_font_size_override("font_size", READOUT_FONT_SIZE)
	root.add_child(_results)
	_note = Label.new()
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.add_theme_font_size_override("font_size", NOTE_FONT_SIZE)
	_note.add_theme_color_override("font_color", Color(1.0, 0.85, 0.5))
	root.add_child(_note)
	root.add_child(HSeparator.new())

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(scroll)
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(box)

	_add_title(box, "Scenarios")
	var scenario_row := HBoxContainer.new()
	box.add_child(scenario_row)
	for id in LabScenarios.IDS:
		var button: Button = _add_button(scenario_row, id, func() -> void: scenario_requested.emit(id))
		button.tooltip_text = LabScenarios.title(id)

	_add_title(box, "Camera")
	var camera_row := HBoxContainer.new()
	box.add_child(camera_row)
	_add_button(camera_row, "Battle (10 u)", func() -> void: camera_mode_requested.emit(LabDebugCamera.Mode.BATTLE))
	_add_button(camera_row, "Follow", func() -> void: camera_mode_requested.emit(LabDebugCamera.Mode.FOLLOW))
	_add_button(camera_row, "Fit (analysis)", func() -> void: camera_mode_requested.emit(LabDebugCamera.Mode.FIT))

	_add_title(box, "Playback (presentation only)")
	var playback_row := HBoxContainer.new()
	box.add_child(playback_row)
	for action: String in ["play", "pause", "restart"]:
		_add_button(playback_row, action.capitalize(), func() -> void: playback_requested.emit(action))
	_speed = _add_spin(box, "Speed (x)", 0.05, 8.0, 0.05, false)
	_speed.value = 1.0
	_speed.value_changed.connect(func(value: float) -> void: playback_speed_changed.emit(value))

	_add_title(box, "Shot")
	_distance = _add_spin(box, "Distance (u)", 0.0, 60.0, 0.01)
	_offset = _add_spin(box, "Target y (u)  + below / - above", -30.0, 30.0, 0.01)
	_angle = _add_spin(box, "Angle (deg)", -90.0, 270.0, 0.001)
	_power = _add_spin(box, "Power", 0.0, 200.0, 0.001)
	_wind = _add_spin(box, "Wind (world, + pushes to +x)", -10.0, 10.0, 0.01)
	_facing = OptionButton.new()
	_facing.add_item("Facing right (+x)", 0)
	_facing.add_item("Facing left (-x)", 1)
	_facing.item_selected.connect(func(_index: int) -> void: _emit_setup())
	box.add_child(_facing)

	_add_title(box, "Aiming helpers (prediction only)")
	_add_button(box, "Apply Full Throw (evidence preset)", func() -> void: full_throw_requested.emit())
	var solve_row := HBoxContainer.new()
	box.add_child(solve_row)
	_add_button(solve_row, "Solve angle: high", func() -> void: solve_angle_requested.emit(true))
	_add_button(solve_row, "Solve angle: low", func() -> void: solve_angle_requested.emit(false))
	_add_button(solve_row, "Solve power", func() -> void: solve_power_requested.emit())


## Shows a setup without emitting setup_edited.
func set_setup(setup: LabShotSetup) -> void:
	_distance.set_value_no_signal(setup.distance)
	_offset.set_value_no_signal(setup.target_y())
	_angle.set_value_no_signal(setup.angle)
	_power.set_value_no_signal(setup.power)
	_wind.set_value_no_signal(setup.wind)
	_facing.select(0 if setup.facing > 0 else 1)


func set_note(text: String) -> void:
	_note.text = text


func set_results(text: String) -> void:
	_results.text = text


func _emit_setup() -> void:
	setup_edited.emit(LabShotSetup.new(
		_distance.value, _offset.value, _angle.value, _power.value, _wind.value, 1 if _facing.selected == 0 else -1
	))


func _add_title(parent: Container, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0))
	parent.add_child(label)


func _add_spin(
	parent: Container, text: String, min_value: float, max_value: float, step: float, edits_setup: bool = true
) -> SpinBox:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	var spin := SpinBox.new()
	spin.min_value = min_value
	spin.max_value = max_value
	spin.step = step
	spin.custom_minimum_size = Vector2(130.0, 0.0)
	spin.update_on_text_changed = true
	spin.select_all_on_focus = true
	if edits_setup:
		spin.value_changed.connect(func(_value: float) -> void: _emit_setup())
	row.add_child(spin)
	return spin


func _add_button(parent: Container, text: String, on_pressed: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(on_pressed)
	parent.add_child(button)
	return button
