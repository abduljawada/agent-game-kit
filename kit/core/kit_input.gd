extends Node
## Registers the kit's default input actions at startup.
## Add or change bindings in DEFAULT_ACTIONS. Actions already defined in
## Project Settings > Input Map are left alone, so editor bindings win.
## Keyboard keys are bound as physical keys so layouts like AZERTY work.

const DEFAULT_ACTIONS := {
	&"move_left": {"keys": [KEY_A, KEY_LEFT], "joy": [JOY_BUTTON_DPAD_LEFT]},
	&"move_right": {"keys": [KEY_D, KEY_RIGHT], "joy": [JOY_BUTTON_DPAD_RIGHT]},
	&"move_up": {"keys": [KEY_W, KEY_UP], "joy": [JOY_BUTTON_DPAD_UP]},
	&"move_down": {"keys": [KEY_S, KEY_DOWN], "joy": [JOY_BUTTON_DPAD_DOWN]},
	&"jump": {"keys": [KEY_SPACE, KEY_Z], "joy": [JOY_BUTTON_A]},
	&"interact": {"keys": [KEY_E, KEY_X], "joy": [JOY_BUTTON_X]},
	&"attack": {"keys": [KEY_J, KEY_C], "joy": [JOY_BUTTON_B]},
	&"pause": {"keys": [KEY_ESCAPE, KEY_P], "joy": [JOY_BUTTON_START]},
}


func _enter_tree() -> void:
	register_defaults()


static func register_defaults() -> void:
	for action: StringName in DEFAULT_ACTIONS:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action, 0.2)
		for code: int in DEFAULT_ACTIONS[action]["keys"]:
			var key := InputEventKey.new()
			key.physical_keycode = code as Key
			InputMap.action_add_event(action, key)
		for button: int in DEFAULT_ACTIONS[action]["joy"]:
			var joy := InputEventJoypadButton.new()
			joy.button_index = button as JoyButton
			InputMap.action_add_event(action, joy)
