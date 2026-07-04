@tool
extends Node

signal connected_to_server
signal disconnected_from_server
signal message_received(message: String)

var _tcp_server: TCPServer
var _peers: Dictionary = {}
var _peer_open_state: Dictionary = {}
var _port: int = 6505
var _listening: bool = false


func start(port: int = 6505) -> void:
	_port = port
	_tcp_server = TCPServer.new()
	var err: Error = _tcp_server.listen("127.0.0.1", _port)
	if err != OK:
		push_error("[Godot MCP] Failed to listen on port " + str(_port) + ": " + error_string(err))
		return
	_listening = true
	print("[Godot MCP] WebSocket server listening on 127.0.0.1:", _port)


func stop() -> void:
	_listening = false
	for peer_id in _peers:
		_peers[peer_id].close()
	_peers.clear()
	_peer_open_state.clear()
	if _tcp_server:
		_tcp_server.stop()
		_tcp_server = null
	disconnected_from_server.emit()


func _process(_delta: float) -> void:
	if not _listening or _tcp_server == null:
		return

	while _tcp_server.is_connection_available():
		var stream: StreamPeer = _tcp_server.take_connection()
		var ws := WebSocketPeer.new()
		ws.accept_stream(stream)
		var peer_id: int = ws.get_instance_id()
		_peers[peer_id] = ws
		_peer_open_state[peer_id] = false
		print("[Godot MCP] New WebSocket connection: ", peer_id)

	var disconnected: Array = []
	for peer_id in _peers:
		var ws: WebSocketPeer = _peers[peer_id]
		ws.poll()

		var state: int = ws.get_ready_state()
		if state == WebSocketPeer.STATE_OPEN:
			if not _peer_open_state.get(peer_id, false):
				_peer_open_state[peer_id] = true
				connected_to_server.emit()
			while ws.get_available_packet_count() > 0:
				var packet: String = ws.get_packet().get_string_from_utf8()
				message_received.emit(packet)
		elif state == WebSocketPeer.STATE_CLOSED:
			disconnected.append(peer_id)

	for peer_id in disconnected:
		print("[Godot MCP] WebSocket disconnected: ", peer_id)
		_peers.erase(peer_id)
		_peer_open_state.erase(peer_id)

	if disconnected.size() > 0 and _get_open_peer_count() == 0:
		disconnected_from_server.emit()


func send_response(response: Dictionary) -> void:
	var message: String = JSON.stringify(response)
	for peer_id in _peers:
		var ws: WebSocketPeer = _peers[peer_id]
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(message)


func send_text(text: String) -> void:
	for peer_id in _peers:
		var ws: WebSocketPeer = _peers[peer_id]
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			ws.send_text(text)


func _get_open_peer_count() -> int:
	var count := 0
	for peer_id in _peers:
		var ws: WebSocketPeer = _peers[peer_id]
		if ws.get_ready_state() == WebSocketPeer.STATE_OPEN:
			count += 1
	return count
