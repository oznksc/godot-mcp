@tool
extends Node

## Debug commands for Godot MCP v2.
## Captures engine console output, user://logs/godot.log, and parses error locations for jump-to-code.

var _output_buffer: Array = []
var _error_buffer: Array = []
const MAX_BUFFER_SIZE := 10000


func _ready() -> void:
	if not Engine.is_editor_hint():
		return
	add_log("[Godot MCP] Debug module initialized", false)


func add_log(message: String, is_error: bool = false) -> void:
	var entry: Dictionary = {
		"timestamp": Time.get_datetime_string_from_system(),
		"message": message,
		"is_error": is_error
	}

	if is_error or "ERROR" in message or "SCRIPT ERROR" in message:
		entry["is_error"] = true
		entry["parsed_location"] = _parse_error_location(message)
		_error_buffer.append(entry)
		if _error_buffer.size() > MAX_BUFFER_SIZE:
			_error_buffer.pop_front()

	_output_buffer.append(entry)
	if _output_buffer.size() > MAX_BUFFER_SIZE:
		_output_buffer.pop_front()


func debug_get_output(params: Dictionary) -> Variant:
	var lines: int = params.get("lines", 100)
	var type: String = params.get("type", "all")
	var include_engine_log: bool = params.get("include_engine_log", true)

	var output: Array = []

	# Read from engine log file if available
	if include_engine_log and FileAccess.file_exists("user://logs/godot.log"):
		var f := FileAccess.open("user://logs/godot.log", FileAccess.READ)
		if f:
			var all_lines: PackedStringArray = f.get_as_text().split("\n")
			f.close()
			var recent: PackedStringArray = all_lines.slice(-mini(lines, all_lines.size()))
			for l in recent:
				if not l.strip_edges().is_empty():
					output.append({"message": l, "source": "engine_log"})

	# Append MCP buffer
	match type:
		"stdout":
			for item in _output_buffer.slice(-lines):
				if not item.get("is_error", false):
					output.append(item)
		"stderr":
			output.append_array(_error_buffer.slice(-lines))
		_:
			output.append_array(_output_buffer.slice(-lines))

	return {"output": output.slice(-lines), "count": output.size()}


func debug_get_errors(params: Dictionary) -> Variant:
	var limit: int = params.get("limit", 50)
	var errors: Array = []

	# Check engine log for errors
	if FileAccess.file_exists("user://logs/godot.log"):
		var f := FileAccess.open("user://logs/godot.log", FileAccess.READ)
		if f:
			var log_text: String = f.get_as_text()
			f.close()
			var log_lines: PackedStringArray = log_text.split("\n")
			for l in log_lines:
				if "ERROR:" in l or "SCRIPT ERROR:" in l or "USER SCRIPT ERROR:" in l:
					errors.append({
						"message": l,
						"parsed_location": _parse_error_location(l),
						"source": "engine_log"
					})

	errors.append_array(_error_buffer)
	var sliced: Array = errors.slice(-limit)
	return {"errors": sliced, "count": sliced.size()}


func debug_get_warnings(_params: Dictionary) -> Variant:
	var warnings: Array = []
	for item in _output_buffer:
		var msg: String = item.get("message", "")
		if "WARNING" in msg or "WARN" in msg or "warning" in msg:
			warnings.append(item)
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


func _parse_error_location(line: String) -> Dictionary:
	# Parse common Godot error formats:
	# e.g.: res://scripts/player.gd:42 - Parse Error: ...
	# at: _ready (res://scripts/player.gd:42)
	var result: Dictionary = {"file": "", "line": 0, "column": 0}

	var at_idx: int = line.find("res://")
	if at_idx != -1:
		var rest: String = line.substr(at_idx)
		var end_idx: int = rest.find(" ")
		if end_idx == -1:
			end_idx = rest.find(")")
		var file_part: String = rest.substr(0, end_idx) if end_idx != -1 else rest
		var col_split: PackedStringArray = file_part.split(":")
		if col_split.size() >= 2:
			result["file"] = col_split[0] + ":" + col_split[1] # "res://path/to/file.gd"
			if col_split.size() >= 3 and col_split[2].is_valid_int():
				result["line"] = col_split[2].to_int()

	return result


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
