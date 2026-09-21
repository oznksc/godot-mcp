@tool
extends Node

## Script commands for Godot MCP v2.
## Adds syntax diagnostics, scene-script binding analysis, and transaction-safe writing.

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const PathSandbox = preload("res://addons/godot_mcp/core/path_sandbox.gd")
var _transaction_manager: Node


func setup(tx_mgr: Node = null) -> void:
	_transaction_manager = tx_mgr


func script_create(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	var extends_class: String = params.get("extends_class", "Node")

	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}
	path = check["path"]

	if content.is_empty():
		content = "extends " + extends_class + "\n\n\n"

	if _transaction_manager:
		if _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
			_transaction_manager.record_file_create(path)
			return {"success": true, "dry_run": true, "simulated_action": "script_create", "path": path}
		elif _transaction_manager.has_method("record_file_create"):
			if FileAccess.file_exists(path):
				_transaction_manager.record_file_modify(path)
			else:
				_transaction_manager.record_file_create(path)

	var parts: PackedStringArray = path.replace("res://", "").split("/")
	if parts.size() > 1:
		var dir_path: String = "res://"
		for i in range(parts.size() - 1):
			dir_path += parts[i] + "/"
			var dir := DirAccess.open("res://")
			if dir and not dir.dir_exists_absolute(dir_path):
				dir.make_dir_recursive_absolute(dir_path)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to create file: " + path}}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "path": path}


func script_read(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}
	path = check["path"]

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to read file: " + path}}
	var content: String = file.get_as_text()
	file.close()
	return {"path": path, "content": content}


func script_write(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")

	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}
	path = check["path"]

	if _transaction_manager:
		if _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
			_transaction_manager.record_file_modify(path)
			return {"success": true, "dry_run": true, "simulated_action": "script_write", "path": path}
		elif _transaction_manager.has_method("record_file_modify"):
			if FileAccess.file_exists(path):
				_transaction_manager.record_file_modify(path)
			else:
				_transaction_manager.record_file_create(path)

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to write file: " + path}}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "path": path}


func script_attach(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var script_path: String = params.get("script_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	var check: Dictionary = PathSandbox.validate_path(script_path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}
	script_path = check["path"]

	var script: Script = load(script_path)
	if script == null:
		return {"error": {"code": -32602, "message": "Failed to load script: " + script_path}}

	node.set_script(script)
	return {"success": true, "node": node_path, "script": script_path}


func script_detach(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	node.set_script(null)
	return {"success": true, "node": node_path}


func script_validate(params: Dictionary) -> Variant:
	var content: String = params.get("content", "")
	var path: String = params.get("path", "")

	if content.is_empty() and not path.is_empty():
		var check: Dictionary = PathSandbox.validate_path(path)
		if check.get("valid", false) and FileAccess.file_exists(check["path"]):
			var f := FileAccess.open(check["path"], FileAccess.READ)
			if f:
				content = f.get_as_text()
				f.close()

	if content.is_empty():
		return {"error": {"code": -32602, "message": "Content or path is required"}}

	var script: GDScript = GDScript.new()
	script.source_code = content
	var err: Error = script.reload()

	if err != OK:
		# Extract line counts and basic structure for diagnostics
		var lines: PackedStringArray = content.split("\n")
		return {
			"valid": false,
			"error": error_string(err),
			"error_code": err,
			"line_count": lines.size()
		}

	# Basic AST inspection for warnings
	var warnings: Array = []
	if not content.contains("extends "):
		warnings.append("Missing 'extends' declaration, defaults to RefCounted")

	return {
		"valid": true,
		"warnings": warnings,
		"line_count": content.split("\n").size()
	}


func script_analyze_scene_bindings(params: Dictionary) -> Variant:
	var script_path: String = params.get("script_path", "")
	var scene_path: String = params.get("scene_path", "")

	if script_path.is_empty() or scene_path.is_empty():
		return {"error": {"code": -32602, "message": "Both script_path and scene_path are required"}}

	var check_script: Dictionary = PathSandbox.validate_path(script_path)
	var check_scene: Dictionary = PathSandbox.validate_path(scene_path)
	if not check_script.get("valid", false) or not check_scene.get("valid", false):
		return {"error": {"code": -32603, "message": "Path access denied outside sandbox"}}

	if not FileAccess.file_exists(check_script["path"]):
		return {"error": {"code": -32602, "message": "Script not found: " + script_path}}
	if not FileAccess.file_exists(check_scene["path"]):
		return {"error": {"code": -32602, "message": "Scene not found: " + scene_path}}

	var file := FileAccess.open(check_script["path"], FileAccess.READ)
	var script_text: String = file.get_as_text() if file else ""
	if file:
		file.close()

	var packed_scene: PackedScene = load(check_scene["path"])
	if packed_scene == null:
		return {"error": {"code": -32603, "message": "Failed to load scene: " + scene_path}}

	var scene_instance: Node = packed_scene.instantiate()
	if scene_instance == null:
		return {"error": {"code": -32603, "message": "Failed to instantiate scene: " + scene_path}}

	var missing_node_refs: Array = []
	var declared_signals: Array = []
	var lines: PackedStringArray = script_text.split("\n")

	for line in lines:
		var trimmed: String = line.strip_edges()

		# Check for signal declarations: signal my_signal(...)
		if trimmed.begins_with("signal "):
			var sig_name: String = trimmed.replace("signal ", "").split("(")[0].strip_edges()
			declared_signals.append(sig_name)

		# Check for @onready var x = $SomeNode
		if "$" in trimmed:
			var dollar_idx: int = trimmed.find("$")
			var node_ref: String = trimmed.substr(dollar_idx + 1).split(" ")[0].split(".")[0].strip_edges()
			node_ref = node_ref.trim_prefix("\"").trim_suffix("\"").trim_prefix("'").trim_suffix("'")
			if not node_ref.is_empty():
				var found: Node = scene_instance.get_node_or_null(node_ref)
				if found == null and node_ref != scene_instance.name:
					missing_node_refs.append(node_ref)

	scene_instance.queue_free()

	return {
		"script_path": script_path,
		"scene_path": scene_path,
		"declared_signals": declared_signals,
		"missing_node_references": missing_node_refs,
		"is_consistent": missing_node_refs.is_empty()
	}


func script_list(_params: Dictionary) -> Variant:
	var scripts: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	if efs and efs.get_filesystem():
		_find_scripts_recursive(efs.get_filesystem(), scripts)
	return {"scripts": scripts}


func _find_scripts_recursive(dir: EditorFileSystemDirectory, scripts: Array) -> void:
	if dir == null:
		return
	for i in range(dir.get_file_count()):
		var file_name: String = dir.get_file(i)
		if file_name.ends_with(".gd"):
			scripts.append(dir.get_path() + "/" + file_name)
	for i in range(dir.get_subdir_count()):
		_find_scripts_recursive(dir.get_subdir(i), scripts)
