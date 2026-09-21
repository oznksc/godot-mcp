@tool
extends RefCounted
class_name MCPRuntimeBridge

## Client bridge running in the EditorPlugin that communicates with the
## active game process's MCP Runtime Companion on port 6506.

const RUNTIME_PORT := 6506
const SessionAuth = preload("res://addons/godot_mcp/core/session_auth.gd")


static func is_game_running() -> bool:
	if Engine.is_editor_hint() and EditorInterface != null:
		return EditorInterface.is_playing_scene()
	return false


static func _yield_frame() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		await tree.process_frame
	else:
		OS.delay_msec(5)


static func query_runtime(method: String, params: Dictionary = {}, timeout_ms: int = 400) -> Dictionary:
	if not is_game_running():
		return {"error": "Game is not currently running"}

	var peer := StreamPeerTCP.new()
	var err: Error = peer.connect_to_host("127.0.0.1", RUNTIME_PORT)
	if err != OK:
		return {"error": "Could not connect to Runtime Companion: " + error_string(err)}

	# Non-blocking wait for connection
	var start_time: int = Time.get_ticks_msec()
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		peer.poll()
		if Time.get_ticks_msec() - start_time > timeout_ms:
			peer.disconnect_from_host()
			return {"error": "Connection to Runtime Companion timed out"}
		await _yield_frame()

	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		peer.disconnect_from_host()
		return {"error": "Runtime Companion not reachable on port " + str(RUNTIME_PORT)}

	var req_id: String = "rt_" + str(randi() % 100000)
	var req_dict: Dictionary = {
		"id": req_id,
		"method": method,
		"params": params,
		"token": SessionAuth.get_session_token()
	}
	var msg: String = JSON.stringify(req_dict)
	peer.put_utf8_string(msg)

	# Non-blocking read response
	var response_data: String = ""
	start_time = Time.get_ticks_msec()
	while true:
		peer.poll()
		var bytes_avail: int = peer.get_available_bytes()
		if bytes_avail > 0:
			response_data += peer.get_utf8_string(bytes_avail)
			if response_data.ends_with("\n"):
				break
		var status = peer.get_status()
		if status != StreamPeerTCP.STATUS_CONNECTED:
			break
		if Time.get_ticks_msec() - start_time > timeout_ms:
			peer.disconnect_from_host()
			return {"error": "Runtime Companion response timed out"}
		await _yield_frame()

	peer.disconnect_from_host()

	var parsed: Variant = JSON.parse_string(response_data)
	if parsed is Dictionary and parsed.has("result"):
		return parsed["result"]
	elif parsed is Dictionary:
		return parsed
	return {"error": "Invalid response from Runtime Companion: " + response_data}
