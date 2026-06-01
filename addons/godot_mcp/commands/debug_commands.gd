@tool
extends Node

var _output_buffer: Array = []
var _error_buffer: Array = []
const MAX_BUFFER_SIZE := 10000


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	# Capture output
	print_rich("[color=gray][Godot MCP] Debug module initialized[/color]")


func debug_get_output(params: Dictionary) -> Variant:
	var lines: int = params.get("lines", 100)
	var type: String = params.get("type", "all")

	var output: Array = []
	match type:
		"stdout":
			output = _output_buffer.slice(-lines)
		"stderr":
			output = _error_buffer.slice(-lines)
		_:
			output = (_output_buffer + _error_buffer).slice(-lines)

	return {"output": output, "count": output.size()}


func debug_get_errors(params: Dictionary) -> Variant:
	var limit: int = params.get("limit", 50)
	var errors: Array = _error_buffer.slice(-limit)
	return {"errors": errors, "count": errors.size()}


func debug_get_warnings(_params: Dictionary) -> Variant:
	# Warnings are mixed in output, filtered by common patterns
	var warnings: Array = []
	for msg in _output_buffer:
		if "WARNING" in msg or "WARN" in msg or "warning" in msg:
			warnings.append(msg)
	return {"warnings": warnings.slice(-50), "count": warnings.size()}


func debug_clear_console(_params: Dictionary) -> Variant:
	_output_buffer.clear()
	_error_buffer.clear()
	return {"success": true}


func debug_get_scene_tree(_params: Dictionary) -> Variant:
	var root: Node = get_tree().root
	if root == null:
		return {"error": {"code": -32602, "message": "Scene tree not available"}}
	return _serialize_tree(root, 0)


func _serialize_tree(node: Node, depth: int) -> Dictionary:
	var result: Dictionary = {
		"name": str(node.name),
		"type": node.get_class(),
		"children": [],
	}
	if depth < 10:
		for child in node.get_children():
			result["children"].append(_serialize_tree(child, depth + 1))
	return result
