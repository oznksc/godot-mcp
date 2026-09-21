@tool
extends Node

const PathSandbox = preload("res://addons/godot_mcp/core/path_sandbox.gd")

## File management commands for Godot MCP v2 with PathSandbox and Transaction safety.

var _transaction_manager: Node


func setup(tx_mgr: Node = null) -> void:
	_transaction_manager = tx_mgr


func file_list_dir(params: Dictionary) -> Variant:
	var path: String = params.get("path", "res://")
	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}

	path = check["path"]
	var entries: Array = []
	var dir: DirAccess = DirAccess.open(path)
	if dir == null:
		return {"error": {"code": -32603, "message": "Failed to open directory: " + path}}

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while not file_name.is_empty():
		var entry: Dictionary = {"name": file_name, "is_dir": dir.current_is_dir()}
		entries.append(entry)
		file_name = dir.get_next()
	dir.list_dir_end()
	return {"path": path, "entries": entries}


func file_read(params: Dictionary) -> Variant:
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


func file_write(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}

	path = check["path"]

	# Transaction backup and dry-run check
	if _transaction_manager:
		if _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
			_transaction_manager.record_file_modify(path)
			return {"success": true, "dry_run": true, "simulated_action": "file_write", "path": path}
		elif _transaction_manager.has_method("record_file_modify"):
			if FileAccess.file_exists(path):
				_transaction_manager.record_file_modify(path)
			else:
				_transaction_manager.record_file_create(path)

	# Ensure parent directory exists
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
		return {"error": {"code": -32603, "message": "Failed to write file: " + path}}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "path": path}


func file_delete(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var check: Dictionary = PathSandbox.validate_path(path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}

	path = check["path"]

	# Transaction backup and dry-run check
	if _transaction_manager:
		if _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
			_transaction_manager.record_file_modify(path)
			return {"success": true, "dry_run": true, "simulated_action": "file_delete", "path": path}
		elif _transaction_manager.has_method("record_file_modify"):
			_transaction_manager.record_file_modify(path)

	var dir: DirAccess = DirAccess.open("res://")
	if dir == null:
		return {"error": {"code": -32603, "message": "Failed to access res://"}}

	var err: Error = dir.remove(path)
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to delete file: " + error_string(err)}}
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "deleted": path}


func file_rename(params: Dictionary) -> Variant:
	var old_path: String = params.get("old_path", "")
	var new_path: String = params.get("new_path", "")

	var check_old: Dictionary = PathSandbox.validate_path(old_path)
	var check_new: Dictionary = PathSandbox.validate_path(new_path)
	if not check_old.get("valid", false):
		return {"error": {"code": -32603, "message": check_old.get("error", "Access denied")}}
	if not check_new.get("valid", false):
		return {"error": {"code": -32603, "message": check_new.get("error", "Access denied")}}

	old_path = check_old["path"]
	new_path = check_new["path"]

	if _transaction_manager:
		if _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
			return {"success": true, "dry_run": true, "simulated_action": "file_rename", "old_path": old_path, "new_path": new_path}
		elif _transaction_manager.has_method("record_file_modify"):
			_transaction_manager.record_file_modify(old_path)
			_transaction_manager.record_file_create(new_path)

	var dir: DirAccess = DirAccess.open("res://")
	if dir == null:
		return {"error": {"code": -32603, "message": "Failed to access res://"}}

	var err: Error = dir.rename(old_path, new_path)
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to rename file: " + error_string(err)}}
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "old_path": old_path, "new_path": new_path}


func file_search(params: Dictionary) -> Variant:
	var query: String = params.get("query", "")
	var search_path: String = params.get("path", "res://")
	var type_filter: String = params.get("type", "")
	var content_search: bool = params.get("content_search", false)

	var check: Dictionary = PathSandbox.validate_path(search_path)
	if not check.get("valid", false):
		return {"error": {"code": -32603, "message": check.get("error", "Access denied")}}

	search_path = check["path"]
	if query.is_empty():
		return {"error": {"code": -32602, "message": "Query is required"}}

	var results: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	_search_recursive(efs.get_filesystem(), query, type_filter, content_search, results)
	return {"results": results, "count": results.size()}


func _search_recursive(dir: EditorFileSystemDirectory, query: String, type_filter: String, content_search: bool, results: Array) -> void:
	if dir == null:
		return
	for i in range(dir.get_file_count()):
		var file_name: String = dir.get_file(i)
		var file_path: String = dir.get_path() + "/" + file_name

		if not type_filter.is_empty() and not file_name.ends_with(type_filter):
			continue

		if content_search:
			if file_name.ends_with(".gd") or file_name.ends_with(".tscn") or file_name.ends_with(".tres"):
				var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
				if file:
					var text: String = file.get_as_text()
					file.close()
					if text.contains(query):
						results.append(file_path)
		else:
			if file_name.contains(query):
				results.append(file_path)

	for i in range(dir.get_subdir_count()):
		_search_recursive(dir.get_subdir(i), query, type_filter, content_search, results)
