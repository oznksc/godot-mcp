@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")
const PathSandbox = preload("res://addons/godot_mcp/core/path_sandbox.gd")


func audio_create_player(params: Dictionary) -> Variant:
	var type: String = params.get("type", "AudioStreamPlayer")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")
	var stream_path: String = params.get("stream_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	if not stream_path.is_empty() and not PathSandbox.is_path_safe(stream_path):
		return {"error": {"code": -32001, "message": "Path traversal or invalid path: " + stream_path}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	var node: Node
	match type:
		"AudioStreamPlayer":
			node = AudioStreamPlayer.new()
		"AudioStreamPlayer2D":
			node = AudioStreamPlayer2D.new()
		"AudioStreamPlayer3D":
			node = AudioStreamPlayer3D.new()
		_:
			return {"error": {"code": -32602, "message": "Unknown audio player type: " + type}}

	node.name = node_name
	if not stream_path.is_empty():
		var stream: AudioStream = ResourceLoader.load(stream_path)
		if stream:
			node.stream = stream

	UndoRedoHelper.add_node(parent, node, node_name)
	return {"success": true, "node": node_name, "type": type}


func audio_set_stream(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var stream_path: String = params.get("stream_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	if not PathSandbox.is_path_safe(stream_path):
		return {"error": {"code": -32001, "message": "Path traversal or invalid path: " + stream_path}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var stream: AudioStream = ResourceLoader.load(stream_path)
	if stream == null:
		return {"error": {"code": -32603, "message": "Failed to load audio stream: " + stream_path}}

	node.stream = stream
	return {"success": true, "node": path, "stream": stream_path}


func audio_set_bus(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var bus_name: String = params.get("bus_name", "Master")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if node.has_method("set_bus"):
		node.bus = bus_name
	return {"success": true, "node": path, "bus": bus_name}


func audio_get_bus_layout(_params: Dictionary) -> Variant:
	var buses: Array = []
	for i in range(AudioServer.bus_count):
		var bus_info: Dictionary = {
			"name": AudioServer.get_bus_name(i),
			"volume_db": AudioServer.get_bus_volume_db(i),
			"mute": AudioServer.is_bus_mute(i),
			"send": AudioServer.get_bus_send(i),
		}
		buses.append(bus_info)
	return {"buses": buses, "count": buses.size()}
