@tool
extends Node

const MCPRuntimeBridge = preload("res://addons/godot_mcp/core/mcp_runtime_bridge.gd")

## Remote Scene Tree and Runtime Profiler Inspector for Godot MCP v2.
## Enables inspecting and modifying active gameplay nodes, monitors, and performance budgets.


func runtime_get_remote_scene_tree(_params: Dictionary = {}) -> Variant:
	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = MCPRuntimeBridge.query_runtime("get_scene_tree")
		if not rt_res.has("error"):
			return rt_res

	var root: Node = get_tree().root
	if root == null:
		return {"error": {"code": -32602, "message": "Root node not available"}}

	var is_playing: bool = EditorInterface.is_playing_scene()
	return {
		"is_playing": is_playing,
		"tree": _serialize_runtime_node(root, 0, 8)
	}


func runtime_get_node_properties(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Node path is required"}}

	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = MCPRuntimeBridge.query_runtime("get_node_properties", {"path": path})
		if not rt_res.has("error"):
			return rt_res

	var root: Node = get_tree().root
	var target: Node = root.get_node_or_null(path)
	if target == null:
		return {"error": {"code": -32602, "message": "Node not found at path: " + path}}

	var props: Dictionary = {}
	for p in target.get_property_list():
		var p_name: String = p.get("name", "")
		var usage: int = p.get("usage", 0)
		# Filter for readable/script/storage properties
		if (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0 or (usage & PROPERTY_USAGE_STORAGE) != 0:
			var val: Variant = target.get(p_name)
			props[p_name] = _safe_serialize_variant(val)

	return {
		"path": path,
		"class": target.get_class(),
		"name": str(target.name),
		"properties": props
	}


func runtime_set_node_property(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value", null)

	if path.is_empty() or property.is_empty():
		return {"error": {"code": -32602, "message": "Path and property name are required"}}

	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = MCPRuntimeBridge.query_runtime("set_node_property", {
			"path": path,
			"property": property,
			"value": value
		})
		if not rt_res.has("error"):
			return rt_res

	var root: Node = get_tree().root
	var target: Node = root.get_node_or_null(path)
	if target == null:
		return {"error": {"code": -32602, "message": "Node not found at path: " + path}}

	var prev_value: Variant = target.get(property)
	target.set(property, value)

	return {
		"success": true,
		"path": path,
		"property": property,
		"previous_value": _safe_serialize_variant(prev_value),
		"new_value": _safe_serialize_variant(value)
	}


func runtime_get_performance_metrics(_params: Dictionary = {}) -> Variant:
	if EditorInterface.is_playing_scene():
		var rt_res: Dictionary = MCPRuntimeBridge.query_runtime("get_performance")
		if not rt_res.has("error"):
			return rt_res

	var perf := {
		"fps": Performance.get_monitor(Performance.TIME_FPS),
		"process_time_ms": Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"physics_time_ms": Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives_rendered": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"static_memory_max_bytes": Performance.get_monitor(Performance.MEMORY_STATIC_MAX),
		"object_count": Performance.get_monitor(Performance.OBJECT_COUNT),
		"node_count": Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"resource_count": Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT),
		"physics_2d_active_objects": Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS),
		"physics_3d_active_objects": Performance.get_monitor(Performance.PHYSICS_3D_ACTIVE_OBJECTS),
	}
	return perf


func _serialize_runtime_node(node: Node, depth: int, max_depth: int) -> Dictionary:
	var entry: Dictionary = {
		"name": str(node.name),
		"type": node.get_class(),
		"path": str(node.get_path()),
		"children": []
	}

	if depth < max_depth:
		for child in node.get_children():
			entry["children"].append(_serialize_runtime_node(child, depth + 1, max_depth))

	return entry


func _safe_serialize_variant(v: Variant) -> Variant:
	if v is Vector2:
		return [v.x, v.y]
	elif v is Vector3:
		return [v.x, v.y, v.z]
	elif v is Color:
		return [v.r, v.g, v.b, v.a]
	elif v is Node:
		return str(v.get_path())
	elif v is Resource:
		return v.resource_path if not v.resource_path.is_empty() else v.get_class()
	return v
