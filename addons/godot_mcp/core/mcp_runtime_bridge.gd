@tool
extends RefCounted
class_name MCPRuntimeBridge

## Client bridge running in the EditorPlugin that communicates with the
## active game process's MCP Runtime Companion on port 6506.

const RUNTIME_PORT := 6506


static func is_game_running() -> bool:
	return EditorInterface.is_playing_scene()


static func query_runtime(method: String, params: Dictionary = {}, timeout_ms: int = 2000) -> Dictionary:
	if not is_game_running():
		return {"error": "Game is not currently running"}

	var peer := StreamPeerTCP.new()
	var err: Error = peer.connect_to_host("127.0.0.1", RUNTIME_PORT)
	if err != OK:
		return {"error": "Could not connect to Runtime Companion: " + error_string(err)}

	# Wait for connection
	var start_time: int = Time.get_ticks_msec()
	while peer.get_status() == StreamPeerTCP.STATUS_CONNECTING:
		peer.poll()
		OS.delay_msec(10)
		if Time.get_ticks_msec() - start_time > timeout_ms:
			peer.disconnect_from_host()
			return {"error": "Connection to Runtime Companion timed out"}

	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		return {"error": "Runtime Companion not reachable on port " + str(RUNTIME_PORT)}

	var req_id: String = "rt_" + str(randi() % 100000)
	var req_dict: Dictionary = {
		"id": req_id,
		"method": method,
		"params": params
	}
	var msg: String = JSON.stringify(req_dict)
	peer.put_utf8_string(msg)

	# Read response
	var response_data: String = ""
	start_time = Time.get_ticks_msec()
	while true:
		peer.poll()
		var bytes_avail: int = peer.get_available_bytes()
		if bytes_avail > 0:
			response_data += peer.get_utf8_string(bytes_avail)
			if response_data.ends_with("\n"):
				break
		OS.delay_msec(10)
		if Time.get_ticks_msec() - start_time > timeout_ms:
			peer.disconnect_from_host()
			return {"error": "Runtime Companion response timed out"}

	peer.disconnect_from_host()

	var parsed: Variant = JSON.parse_string(response_data)
	if parsed is Dictionary and parsed.has("result"):
		return parsed["result"]
	elif parsed is Dictionary:
		return parsed
	return {"error": "Invalid response from Runtime Companion: " + response_data}
