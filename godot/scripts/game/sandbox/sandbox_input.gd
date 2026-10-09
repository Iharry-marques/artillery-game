class_name SandboxInput
extends RefCounted
## Input actions of the combat sandbox, registered at runtime so no editor setup
## is needed.

const MOVE_LEFT: StringName = &"sandbox_move_left"
const MOVE_RIGHT: StringName = &"sandbox_move_right"
const AIM_UP: StringName = &"sandbox_aim_up"
const AIM_DOWN: StringName = &"sandbox_aim_down"
const FIRE: StringName = &"sandbox_fire"
const RESET: StringName = &"sandbox_reset"
const TOGGLE_DEBUG: StringName = &"sandbox_toggle_debug"
const TOGGLE_ZERO_WIND: StringName = &"sandbox_toggle_zero_wind"
const DEBUG_FULL_THROW: StringName = &"sandbox_debug_full_throw"

const BINDINGS: Dictionary = {
	MOVE_LEFT: [KEY_A, KEY_LEFT],
	MOVE_RIGHT: [KEY_D, KEY_RIGHT],
	AIM_UP: [KEY_W, KEY_UP],
	AIM_DOWN: [KEY_S, KEY_DOWN],
	FIRE: [KEY_SPACE],
	RESET: [KEY_R],
	TOGGLE_DEBUG: [KEY_F3],
	TOGGLE_ZERO_WIND: [KEY_Z],
	DEBUG_FULL_THROW: [KEY_F],
}

const HELP_TEXT: String = "A/D or arrows: move  |  W/S or arrows: angle  |  hold SPACE: charge, release: fire  |  R: reset  |  Z: wind 0  |  F3: debug  |  F: debug Full Throw"


static func ensure_actions() -> void:
	for action: StringName in BINDINGS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var keys: Array = BINDINGS[action]
		for key: Key in keys:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
