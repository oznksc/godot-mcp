@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")


func signal_connect(params: Dictionary) -> Variant:
	var source_path: String = params.get("source_path", "")
	var signal_name: String = params.get("signal_name", "")
	var target_path: String = params.get("target_path", "")
	var method_name: String = params.get("method_name", "")
	var binds: Array = params.get("binds", [])

	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var source: Node = root.get_node_or_null(source_path)
	if source == null:
		return {"error": {"code": -32602, "message": "Source node not found: " + source_path}}

	var target: Node = root.get_node_or_null(target_path)
	if target == null:
		return {"error": {"code": -32602, "message": "Target node not found: " + target_path}}

	if not source.has_signal(signal_name):
		return {"error": {"code": -32602, "message": "Signal not found: " + signal_name}}

	if not target.has_method(method_name):
		return {"error": {"code": -32602, "message": "Method not found: " + method_name}}

	var callable: Callable = Callable(target, method_name)
	if binds.size() > 0:
		source.connect(signal_name, callable.bindv(binds))
	else:
		source.connect(signal_name, callable)
	return {"success": true, "source": source_path, "signal": signal_name, "target": target_path, "method": method_name}


func signal_disconnect(params: Dictionary) -> Variant:
	var source_path: String = params.get("source_path", "")
	var signal_name: String = params.get("signal_name", "")
	var target_path: String = params.get("target_path", "")
	var method_name: String = params.get("method_name", "")

	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var source: Node = root.get_node_or_null(source_path)
	if source == null:
		return {"error": {"code": -32602, "message": "Source node not found: " + source_path}}

	var target: Node = root.get_node_or_null(target_path)
	if target == null:
		return {"error": {"code": -32602, "message": "Target node not found: " + target_path}}

	var callable: Callable = Callable(target, method_name)
	if source.is_signal_connected(signal_name, callable):
		source.disconnect(signal_name, callable)
		return {"success": true, "source": source_path, "signal": signal_name, "target": target_path}
	return {"error": {"code": -32602, "message": "Signal not connected"}}


func signal_list_connections(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var connections: Array = []
	for sig in node.get_signal_list():
		var signal_name: String = sig["name"]
		var conns: Array = node.get_signal_connection_list(signal_name)
		for conn in conns:
			connections.append({
				"signal": signal_name,
				"target": str(conn["callable"].get_object().get_path()) if conn["callable"].get_object() is Node else "unknown",
				"method": conn["callable"].get_method(),
				"binds": conn["binds"],
			})
	return {"node": path, "connections": connections}


func signal_list_available(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var signals_list: Array = []
	for sig in node.get_signal_list():
		var signal_info: Dictionary = {"name": sig["name"], "flags": sig["flags"]}
		var args: Array = []
		for arg in sig.get("args", []):
			args.append({"name": arg["name"], "type": arg["type"]})
		signal_info["args"] = args
		signals_list.append(signal_info)
	return {"node": path, "signals": signals_list}


func signal_emit(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var signal_name: String = params.get("signal_name", "")
	var args: Array = params.get("args", [])

	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if not node.has_signal(signal_name):
		return {"error": {"code": -32602, "message": "Signal not found: " + signal_name}}

	node.emit_signal(signal_name, *args)
	return {"success": true, "emitted": signal_name, "on": path}
