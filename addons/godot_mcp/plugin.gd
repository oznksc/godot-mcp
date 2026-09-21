@tool
extends EditorPlugin

const SessionAuth = preload("res://addons/godot_mcp/core/session_auth.gd")

const WS_PORT := 6505

var _websocket_client: Node
var _command_router: Node
var _status_panel: Control
var _log_panel: Control


func _ready() -> void:
	pass


func _enter_tree() -> void:
	SessionAuth.init_session()

	_websocket_client = preload("res://addons/godot_mcp/core/websocket_client.gd").new()
	_websocket_client.name = "MCPWebSocketClient"
	add_child(_websocket_client)

	_command_router = preload("res://addons/godot_mcp/core/command_router.gd").new()
	_command_router.name = "MCPCommandRouter"
	_command_router.setup(_websocket_client)
	add_child(_command_router)

	_status_panel = preload("res://addons/godot_mcp/ui/status_panel.gd").new()
	_status_panel.name = "MCPStatusPanel"
	add_control_to_bottom_panel(_status_panel, "MCP Status")

	_log_panel = preload("res://addons/godot_mcp/ui/log_panel.gd").new()
	_log_panel.name = "MCPLogPanel"
	add_control_to_bottom_panel(_log_panel, "MCP Log")

	_websocket_client.connected_to_server.connect(_on_connected)
	_websocket_client.disconnected_from_server.connect(_on_disconnected)
	_websocket_client.message_received.connect(_on_message)

	_websocket_client.start(WS_PORT)
	print("[Godot MCP v2] Plugin loaded, listening on port ", WS_PORT)


func _exit_tree() -> void:
	if _websocket_client:
		_websocket_client.stop()
		_websocket_client.queue_free()
	if _command_router:
		_command_router.queue_free()
	if _status_panel:
		_status_panel.queue_free()
	if _log_panel:
		_log_panel.queue_free()
	print("[Godot MCP v2] Plugin unloaded")


func _on_connected() -> void:
	_status_panel.set_connected(true)
	_log_panel.add_log("Connected to MCP Server")


func _on_disconnected() -> void:
	_status_panel.set_connected(false)
	_log_panel.add_log("Disconnected from MCP Server")


func _on_message(message: String) -> void:
	_log_panel.add_log("Received: " + message.left(200))
	var response: Dictionary = await _command_router.execute(message)
	_websocket_client.send_response(response)
	_log_panel.add_log("Sent: " + JSON.stringify(response).left(200))
