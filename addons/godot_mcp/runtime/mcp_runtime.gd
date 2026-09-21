extends Node

## MCP Runtime Companion for Godot MCP v2.
## Runs inside the active game process in debug mode.
## Enables real in-game scene tree inspection, dynamic property tweaking,
## viewport capture, and synthetic input simulation.

const RUNTIME_PORT := 6506

var _tcp_server: TCPServer
var _clients: Array = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	# Register with Godot's built-in EngineDebugger if available
	if EngineDebugger.is_active():
		EngineDebugger.register_message_capture("godot_mcp", _on_debugger_message)

	# Also listen on a dedicated local TCP port for direct JSON IPC
	_tcp_server = TCPServer.new()
	var err: Error = _tcp_server.listen(RUNTIME_PORT, "127.0.0.1")
	if err == OK:
		print("[Godot MCP Runtime] Companion listening on 127.0.0.1:", RUNTIME_PORT)
	else:
		print("[Godot MCP Runtime] Direct socket port busy or unavailable: ", err)


func _process(_delta: float) -> void:
	if _tcp_server == null or not _tcp_server.is_listening():
		return

	while _tcp_server.is_connection_available():
		var peer: StreamPeerTCP = _tcp_server.take_connection()
		if peer:
			_clients.append(peer)

	var disconnected: Array = []
	for client in _clients:
		var status: int = client.get_status()
		if status == StreamPeerTCP.STATUS_CONNECTED:
			var bytes_avail: int = client.get_available_bytes()
			if bytes_avail > 0:
				var data_str: String = client.get_utf8_string(bytes_avail)
				_handle_direct_request(client, data_str)
		elif status == StreamPeerTCP.STATUS_ERROR or status == StreamPeerTCP.STATUS_NONE:
			disconnected.append(client)

	for c in disconnected:
		_clients.erase(c)


func _handle_direct_request(client: StreamPeerTCP, raw_data: String) -> void:
	var parsed: Variant = JSON.parse_string(raw_data)
	if not parsed is Dictionary:
		return

	var req: Dictionary = parsed
	var id: String = req.get("id", "")
	var method: String = req.get("method", "")
	var params: Dictionary = req.get("params", {})

	var result: Variant = _dispatch_runtime_command(method, params)
	var resp: Dictionary = {"id": id, "result": result}
	var resp_str: String = JSON.stringify(resp) + "\n"
	client.put_utf8_string(resp_str)


func _on_debugger_message(message: String, data: Array) -> bool:
	if message == "command":
		if data.size() >= 2:
			var method: String = data[0]
			var params: Dictionary = data[1] if data[1] is Dictionary else {}
			var result: Variant = _dispatch_runtime_command(method, params)
			EngineDebugger.send_message("godot_mcp:response", [result])
			return true
	return false


func _dispatch_runtime_command(method: String, params: Dictionary) -> Variant:
	match method:
		"get_scene_tree":
			return _get_real_scene_tree()
		"get_node_properties":
			return _get_real_node_properties(params.get("path", ""))
		"set_node_property":
			return _set_real_node_property(params.get("path", ""), params.get("property", ""), params.get("value", null))
		"capture_viewport":
			return _capture_real_game_viewport(params.get("max_width", 1280), params.get("max_height", 720))
		"simulate_input_key":
			return _simulate_key(params)
		"simulate_input_mouse":
			return _simulate_mouse(params)
		"simulate_input_action":
			return _simulate_action(params)
		"get_performance":
			return _get_real_performance()
		"ping":
			return {"pong": true, "pid": OS.get_process_id()}
	return {"error": "Unknown runtime method: " + method}


func _get_real_scene_tree() -> Dictionary:
	var root: Node = get_tree().root
	return {
		"is_playing": true,
		"game_pid": OS.get_process_id(),
		"tree": _serialize_node(root, 0, 8)
	}


func _get_real_node_properties(path: String) -> Dictionary:
	var target: Node = get_tree().root.get_node_or_null(path)
	if target == null:
		return {"error": "Node not found in game: " + path}

	var props: Dictionary = {}
	for p in target.get_property_list():
		var p_name: String = p.get("name", "")
		var usage: int = p.get("usage", 0)
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or (usage & PROPERTY_USAGE_STORAGE) != 0:
			props[p_name] = _safe_serialize(target.get(p_name))

	return {
		"path": path,
		"class": target.get_class(),
		"name": str(target.name),
		"properties": props
	}


func _set_real_node_property(path: String, property: String, value: Variant) -> Dictionary:
	var target: Node = get_tree().root.get_node_or_null(path)
	if target == null:
		return {"error": "Node not found in game: " + path}

	var prev: Variant = target.get(property)
	target.set(property, value)
	return {
		"success": true,
		"path": path,
		"property": property,
		"previous_value": _safe_serialize(prev),
		"new_value": _safe_serialize(value)
	}


func _capture_real_game_viewport(max_w: int, max_h: int) -> Dictionary:
	var vp: Viewport = get_viewport()
	if vp == null:
		return {"error": "Viewport not available in running game"}

	var tex: ViewportTexture = vp.get_texture()
	if tex == null:
		return {"error": "Viewport texture not available"}

	var img: Image = tex.get_image()
	if img == null or img.is_empty():
		return {"error": "Captured viewport image was empty"}

	var orig_w: int = img.get_width()
	var orig_h: int = img.get_height()
	var target_w: int = orig_w
	var target_h: int = orig_h

	if orig_w > max_w or orig_h > max_h:
		var scale: float = minf(float(max_w) / float(orig_w), float(max_h) / float(orig_h))
		target_w = int(orig_w * scale)
		target_h = int(orig_h * scale)
		img.resize(target_w, target_h, Image.INTERPOLATE_BILINEAR)

	var png_buffer: PackedByteArray = img.save_png_to_buffer()
	return {
		"format": "png",
		"width": target_w,
		"height": target_h,
		"base64": Marshalls.raw_to_base64(png_buffer),
		"source": "game_process"
	}


func _simulate_key(params: Dictionary) -> Dictionary:
	var key_str: String = params.get("key", "")
	var pressed: bool = params.get("pressed", true)
	var keycode: Key = OS.find_keycode_from_string(key_str)
	if keycode == KEY_NONE and key_str.length() == 1:
		keycode = key_str.to_upper().unicode_at(0) as Key

	var ev := InputEventKey.new()
	event_set_key(ev, keycode, pressed, params)
	Input.parse_input_event(ev)
	return {"success": true, "key": key_str, "pressed": pressed}


func event_set_key(ev: InputEventKey, keycode: Key, pressed: bool, params: Dictionary) -> void:
	ev.keycode = keycode
	ev.physical_keycode = keycode
	ev.pressed = pressed
	ev.shift_pressed = params.get("shift", false)
	ev.ctrl_pressed = params.get("ctrl", false)
	ev.alt_pressed = params.get("alt", false)


func _simulate_mouse(params: Dictionary) -> Dictionary:
	var action: String = params.get("action", "click")
	var pos_arr: Array = params.get("position", [0.0, 0.0])
	var pos := Vector2(float(pos_arr[0]), float(pos_arr[1]))
	var btn_idx: int = params.get("button", MOUSE_BUTTON_LEFT)

	if action == "move":
		var ev_m := InputEventMouseMotion.new()
		ev_m.position = pos
		ev_m.global_position = pos
		Input.parse_input_event(ev_m)
		return {"success": true, "action": "move"}

	var ev_b := InputEventMouseButton.new()
	ev_b.position = pos
	ev_b.global_position = pos
	ev_b.button_index = btn_idx as MouseButton
	ev_b.pressed = true
	Input.parse_input_event(ev_b)

	if action == "click":
		var ev_up := InputEventMouseButton.new()
		ev_up.position = pos
		ev_up.global_position = pos
		ev_up.button_index = btn_idx as MouseButton
		ev_up.pressed = false
		Input.parse_input_event(ev_up)

	return {"success": true, "action": action}


func _simulate_action(params: Dictionary) -> Dictionary:
	var act_name: String = params.get("action", "")
	var pressed: bool = params.get("pressed", true)
	var strength: float = float(params.get("strength", 1.0))
	if pressed:
		Input.action_press(act_name, strength)
	else:
		Input.action_release(act_name)
	return {"success": true, "action": act_name, "pressed": pressed}


func _get_real_performance() -> Dictionary:
	return {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_time_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_time_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"physics_2d_active_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		"physics_3d_active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
	}


func _serialize_node(node: Node, depth: int, max_depth: int) -> Dictionary:
	var entry: Dictionary = {
		"name": str(node.name),
		"type": node.get_class(),
		"path": str(node.get_path()),
		"children": []
	}
	if depth < max_depth:
		for child in node.get_children():
			entry["children"].append(_serialize_node(child, depth + 1, max_depth))
	return entry


func _safe_serialize(v: Variant) -> Variant:
	if v is Vector2:
		return [v.x, v.y]
	elif v is Vector3:
		return [v.x, v.y, v.z]
	elif v is Color:
		return [v.r, v.g, v.b, v.a]
	elif v is Node:
		return str(v.get_path())
	return v
