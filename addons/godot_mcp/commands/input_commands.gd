@tool
extends Node

const MCPRuntimeBridge = preload("res://addons/godot_mcp/core/mcp_runtime_bridge.gd")

## Synthetic Input Simulation for Godot MCP v2.
## Enables autonomous playtesting, keyboard, mouse, and action events.


func input_simulate_key(params: Dictionary) -> Variant:
	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = await MCPRuntimeBridge.query_runtime("simulate_input_key", params)
		if not rt_res.has("error"):
			return rt_res

	var key_str: String = params.get("key", "")
	var pressed: bool = params.get("pressed", true)
	var echo: bool = params.get("echo", false)
	var shift: bool = params.get("shift", false)
	var ctrl: bool = params.get("ctrl", false)
	var alt: bool = params.get("alt", false)
	var meta: bool = params.get("meta", false)

	if key_str.is_empty():
		return {"error": {"code": -32602, "message": "Key name is required"}}

	var keycode: Key = OS.find_keycode_from_string(key_str)
	if keycode == KEY_NONE:
		# Fallback: check if ASCII character or numeric keycode
		if key_str.length() == 1:
			keycode = key_str.to_upper().unicode_at(0) as Key
		elif key_str.is_valid_int():
			keycode = key_str.to_int() as Key
		else:
			return {"error": {"code": -32602, "message": "Unknown key name: " + key_str}}

	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	event.pressed = pressed
	event.echo = echo
	event.shift_pressed = shift
	event.ctrl_pressed = ctrl
	event.alt_pressed = alt
	event.meta_pressed = meta

	Input.parse_input_event(event)
	return {
		"success": true,
		"key": key_str,
		"keycode": int(keycode),
		"pressed": pressed
	}


func input_simulate_mouse(params: Dictionary) -> Variant:
	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = await MCPRuntimeBridge.query_runtime("simulate_input_mouse", params)
		if not rt_res.has("error"):
			return rt_res

	var action: String = params.get("action", "click").to_lower()
	var pos_array: Array = params.get("position", [0.0, 0.0])
	var button_index: int = params.get("button", MOUSE_BUTTON_LEFT)
	var pressed: bool = params.get("pressed", true)

	var pos := Vector2(float(pos_array[0]), float(pos_array[1]))

	if action == "move":
		var motion_event := InputEventMouseMotion.new()
		motion_event.position = pos
		motion_event.global_position = pos
		Input.parse_input_event(motion_event)
		return {"success": true, "action": "move", "position": [pos.x, pos.y]}

	var btn_event := InputEventMouseButton.new()
	btn_event.position = pos
	btn_event.global_position = pos
	btn_event.button_index = button_index as MouseButton

	if action == "click":
		# Emit press then release
		btn_event.pressed = true
		Input.parse_input_event(btn_event)

		var release_event := InputEventMouseButton.new()
		release_event.position = pos
		release_event.global_position = pos
		release_event.button_index = button_index as MouseButton
		release_event.pressed = false
		Input.parse_input_event(release_event)
	else:
		btn_event.pressed = pressed
		Input.parse_input_event(btn_event)

	return {
		"success": true,
		"action": action,
		"position": [pos.x, pos.y],
		"button": button_index,
		"pressed": pressed if action != "click" else true
	}


func input_simulate_action(params: Dictionary) -> Variant:
	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = await MCPRuntimeBridge.query_runtime("simulate_input_action", params)
		if not rt_res.has("error"):
			return rt_res

	var action_name: String = params.get("action", "")
	var pressed: bool = params.get("pressed", true)
	var strength: float = float(params.get("strength", 1.0))

	if action_name.is_empty():
		return {"error": {"code": -32602, "message": "Action name is required"}}

	if pressed:
		Input.action_press(action_name, strength)
	else:
		Input.action_release(action_name)

	return {
		"success": true,
		"action": action_name,
		"pressed": pressed,
		"strength": strength
	}
