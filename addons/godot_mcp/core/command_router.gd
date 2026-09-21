@tool
extends Node

const SessionAuth = preload("res://addons/godot_mcp/core/session_auth.gd")
const CompatHelper = preload("res://addons/godot_mcp/core/compat_helper.gd")

## Central RPC Command Router for Godot MCP v2.
## Dispatches incoming JSON-RPC commands, handles async execution, validates session auth,
## and routes across all core and extended command modules.

var _websocket_client: Node
var _scene_commands: Node
var _node_commands: Node
var _script_commands: Node
var _resource_commands: Node
var _project_commands: Node
var _editor_commands: Node
var _file_commands: Node
var _signal_commands: Node
var _runtime_commands: Node
var _debug_commands: Node
var _animation_commands: Node
var _shader_commands: Node
var _physics_commands: Node
var _ui_commands: Node
var _audio_commands: Node
var _lighting_commands: Node
var _particles_commands: Node
var _import_export_commands: Node
var _classdb_commands: Node

# v2 Extended Modules
var _transaction_manager: Node
var _viewport_commands: Node
var _input_commands: Node
var _playtest_commands: Node
var _runtime_inspector: Node


func setup(websocket_client: Node) -> void:
	_websocket_client = websocket_client
	_load_command_modules()


func _load_command_modules() -> void:
	# Core helpers & transactions
	_transaction_manager = preload("res://addons/godot_mcp/core/transaction_manager.gd").new()
	add_child(_transaction_manager)

	_scene_commands = preload("res://addons/godot_mcp/commands/scene_commands.gd").new()
	_node_commands = preload("res://addons/godot_mcp/commands/node_commands.gd").new()
	_script_commands = preload("res://addons/godot_mcp/commands/script_commands.gd").new()
	_script_commands.setup(_transaction_manager)

	_resource_commands = preload("res://addons/godot_mcp/commands/resource_commands.gd").new()
	_project_commands = preload("res://addons/godot_mcp/commands/project_commands.gd").new()
	_editor_commands = preload("res://addons/godot_mcp/commands/editor_commands.gd").new()
	_file_commands = preload("res://addons/godot_mcp/commands/file_commands.gd").new()
	_file_commands.setup(_transaction_manager)

	_signal_commands = preload("res://addons/godot_mcp/commands/signal_commands.gd").new()
	_runtime_commands = preload("res://addons/godot_mcp/commands/runtime_commands.gd").new()
	_debug_commands = preload("res://addons/godot_mcp/commands/debug_commands.gd").new()
	_animation_commands = preload("res://addons/godot_mcp/commands/animation_commands.gd").new()
	_shader_commands = preload("res://addons/godot_mcp/commands/shader_commands.gd").new()
	_physics_commands = preload("res://addons/godot_mcp/commands/physics_commands.gd").new()
	_ui_commands = preload("res://addons/godot_mcp/commands/ui_commands.gd").new()
	_audio_commands = preload("res://addons/godot_mcp/commands/audio_commands.gd").new()
	_lighting_commands = preload("res://addons/godot_mcp/commands/lighting_commands.gd").new()
	_particles_commands = preload("res://addons/godot_mcp/commands/particles_commands.gd").new()
	_import_export_commands = preload("res://addons/godot_mcp/commands/import_export_commands.gd").new()
	_classdb_commands = preload("res://addons/godot_mcp/commands/classdb_commands.gd").new()

	# v2 Extended Modules
	_viewport_commands = preload("res://addons/godot_mcp/commands/viewport_commands.gd").new()
	_input_commands = preload("res://addons/godot_mcp/commands/input_commands.gd").new()
	_playtest_commands = preload("res://addons/godot_mcp/commands/playtest_commands.gd").new()
	_playtest_commands.setup(_input_commands, _viewport_commands, _debug_commands)

	_runtime_inspector = preload("res://addons/godot_mcp/commands/runtime_inspector.gd").new()

	for module in [_scene_commands, _node_commands, _script_commands, _resource_commands,
		_project_commands, _editor_commands, _file_commands, _signal_commands,
		_runtime_commands, _debug_commands, _animation_commands, _shader_commands,
		_physics_commands, _ui_commands, _audio_commands, _lighting_commands,
		_particles_commands, _import_export_commands, _classdb_commands,
		_viewport_commands, _input_commands, _playtest_commands, _runtime_inspector]:
		add_child(module)


func execute(raw_message: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(raw_message)
	if parsed == null or not parsed is Dictionary:
		return _error_response("", -32700, "Parse error")

	var request: Dictionary = parsed
	var id: String = request.get("id", "")
	var method: String = request.get("method", "")
	var params: Dictionary = request.get("params", {})

	if method.is_empty():
		return _error_response(id, -32600, "Missing method")

	# Log command received in debug buffer
	if _debug_commands and _debug_commands.has_method("add_log"):
		_debug_commands.add_log("CMD: " + method)

	# Session auth check (unless it's handshake, ping, or status)
	if method != "system_handshake" and method != "system_ping" and method != "system_get_capabilities":
		var token: String = request.get("token", "")
		if token.is_empty():
			token = params.get("session_token", "")
		if not SessionAuth.validate_token(token):
			return _error_response(id, -32000, "Unauthorized: invalid or missing session token")

	var result: Variant = await _dispatch(method, params)
	if result is Dictionary and result.has("error"):
		var err_dict: Dictionary = result["error"]
		var err_code: int = err_dict.get("code", -32603)
		var err_msg: String = err_dict.get("message", "Internal error")
		if _debug_commands and _debug_commands.has_method("add_log"):
			_debug_commands.add_log("ERR [" + str(err_code) + "]: " + err_msg, true)
		return _error_response(id, err_code, err_msg)

	return {"id": id, "result": result}


func _dispatch(method: String, params: Dictionary) -> Variant:
	if method.begins_with("system_"):
		return _handle_system(method, params)

	var modules: Array = [
		["transaction_", _transaction_manager],
		["viewport_", _viewport_commands],
		["input_", _input_commands],
		["playtest_", _playtest_commands],
		["runtime_", _runtime_inspector],
		["runtime_", _runtime_commands],
		["scene_", _scene_commands],
		["node_", _node_commands],
		["script_", _script_commands],
		["resource_", _resource_commands],
		["project_", _project_commands],
		["editor_", _editor_commands],
		["file_", _file_commands],
		["signal_", _signal_commands],
		["debug_", _debug_commands],
		["animation_", _animation_commands],
		["shader_", _shader_commands],
		["physics_", _physics_commands],
		["ui_", _ui_commands],
		["audio_", _audio_commands],
		["lighting_", _lighting_commands],
		["particles_", _particles_commands],
		["import_", _import_export_commands],
		["export_", _import_export_commands],
		["classdb_", _classdb_commands],
	]

	for module_entry in modules:
		var prefix: String = module_entry[0]
		var module: Node = module_entry[1]
		if method.begins_with(prefix) and module.has_method(method):
			return await module.call(method, params)

	return {"error": {"code": -32601, "message": "Method not found: " + method}}


func _handle_system(method: String, params: Dictionary) -> Variant:
	match method:
		"system_handshake":
			var client_token: String = params.get("session_token", "")
			var token: String = SessionAuth.get_session_token()
			var payload: Dictionary = CompatHelper.get_handshake_payload(token)
			payload["client_compatible"] = true
			return payload
		"system_get_capabilities":
			return {
				"capabilities": CompatHelper.get_capabilities(),
				"godot_version": CompatHelper.get_godot_version(),
				"protocol_version": CompatHelper.PROTOCOL_VERSION
			}
		"system_ping":
			return {"pong": true, "time": Time.get_unix_time_from_system()}
	return {"error": {"code": -32601, "message": "Unknown system method: " + method}}


func _error_response(id: String, code: int, message: String) -> Dictionary:
	return {
		"id": id,
		"error": {
			"code": code,
			"message": message,
		}
	}
