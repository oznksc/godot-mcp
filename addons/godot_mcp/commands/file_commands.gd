@tool
extends Node


func file_list_dir(params: Dictionary) -> Variant:
	var path: String = params.get("path", "res://")
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
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to read file: " + path}}
	var content: String = file.get_as_text()
	file.close()
	return {"path": path, "content": content}


func file_write(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to write file: " + path}}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "path": path}


func file_delete(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

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
	if old_path.is_empty() or new_path.is_empty():
		return {"error": {"code": -32602, "message": "Both old_path and new_path are required"}}

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
	if query.is_empty():
		return {"error": {"code": -32602, "message": "Query is required"}}

	var results: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	_search_recursive(efs.get_filesystem(), query, type_filter, content_search, results)
	return {"results": results, "count": results.size()}


func _search_recursive(dir: EditorFileSystemDirectory, query: String, type_filter: String, content_search: bool, results: Array) -> void:
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
