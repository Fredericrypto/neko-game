extends SceneTree
## Uso: godot --headless --path . -s tools/setup_input_map.gd
## Escreve o Input Map no project.godot (teclado por tecla física, funciona em ABNT2/QWERTY).

func _key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.physical_keycode = code
	return e

func _btn(i: int) -> InputEventJoypadButton:
	var e := InputEventJoypadButton.new()
	e.button_index = i
	return e

func _axis(a: int, v: float) -> InputEventJoypadMotion:
	var e := InputEventJoypadMotion.new()
	e.axis = a
	e.axis_value = v
	return e

func _init() -> void:
	var map := {
		"move_left": [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _btn(JOY_BUTTON_DPAD_LEFT)],
		"move_right": [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _btn(JOY_BUTTON_DPAD_RIGHT)],
		"move_down": [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _btn(JOY_BUTTON_DPAD_DOWN)],
		"jump": [_key(KEY_SPACE), _key(KEY_W), _key(KEY_UP), _btn(JOY_BUTTON_A)],
		"run": [_key(KEY_SHIFT), _btn(JOY_BUTTON_X), _axis(JOY_AXIS_TRIGGER_RIGHT, 1.0)],
		"interact": [_key(KEY_E), _btn(JOY_BUTTON_Y)],
		"pause": [_key(KEY_ESCAPE), _btn(JOY_BUTTON_START)],
		"weight_down": [_key(KEY_1)],
		"weight_up": [_key(KEY_2)],
	}
	for action in map:
		ProjectSettings.set_setting("input/" + action, {"deadzone": 0.5, "events": map[action]})
	var err := ProjectSettings.save()
	print("Input Map salvo: ", error_string(err))
	quit()
