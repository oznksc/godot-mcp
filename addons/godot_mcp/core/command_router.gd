@tool
extends Node

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


func setup(websocket_client: Node) -> void:
	_websocket_client = websocket_client
	_load_command_modules()


func _load_command_modules() -> void:
	_scene_commands = preload("res://addons/godot_mcp/commands/scene_commands.gd").new()
	_node_commands = preload("res://addons/godot_mcp/commands/node_commands.gd").new()
	_script_commands = preload("res://addons/godot_mcp/commands/script_commands.gd").new()
	_resource_commands = preload("res://addons/godot_mcp/commands/resource_commands.gd").new()
	_project_commands = preload("res://addons/godot_mcp/commands/project_commands.gd").new()
	_editor_commands = preload("res://addons/godot_mcp/commands/editor_commands.gd").new()
	_file_commands = preload("res://addons/godot_mcp/commands/file_commands.gd").new()
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

	for module in [_scene_commands, _node_commands, _script_commands, _resource_commands,
		_project_commands, _editor_commands, _file_commands, _signal_commands,
		_runtime_commands, _debug_commands, _animation_commands, _shader_commands,
		_physics_commands, _ui_commands, _audio_commands, _lighting_commands,
		_particles_commands, _import_export_commands, _classdb_commands]:
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

	var result: Variant = _dispatch(method, params)
	if result is Dictionary and result.has("error"):
		return _error_response(id, result["error"]["code"], result["error"]["message"])

	return {"id": id, "result": result}


func _dispatch(method: String, params: Dictionary) -> Variant:
	var modules: Array = [
		["scene_", _scene_commands],
		["node_", _node_commands],
		["script_", _script_commands],
		["resource_", _resource_commands],
		["project_", _project_commands],
		["editor_", _editor_commands],
		["file_", _file_commands],
		["signal_", _signal_commands],
		["runtime_", _runtime_commands],
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
			return module.call(method, params)

	return {"error": {"code": -32601, "message": "Method not found: " + method}}


func _error_response(id: String, code: int, message: String) -> Dictionary:
	return {
		"id": id,
		"error": {
			"code": code,
			"message": message,
		}
	}
