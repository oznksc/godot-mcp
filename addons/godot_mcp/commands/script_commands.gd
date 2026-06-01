@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")


func script_create(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	var extends_class: String = params.get("extends_class", "Node")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	if content.is_empty():
		content = "extends " + extends_class + "\n\n\n"

	var dir: DirAccess = DirAccess.open("res://")
	var parts: PackedStringArray = path.replace("res://", "").split("/")
	if parts.size() > 1:
		var dir_path: String = "res://"
		for i in range(parts.size() - 1):
			dir_path += parts[i] + "/"
			if not dir.dir_exists_absolute(dir_path):
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
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to read file: " + path}}
	var content: String = file.get_as_text()
	file.close()
	return {"path": path, "content": content}


func script_write(params: Dictionary) -> Variant:
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


func script_attach(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var script_path: String = params.get("script_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

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
	if content.is_empty():
		return {"error": {"code": -32602, "message": "Content is required"}}

	var script: GDScript = GDScript.new()
	script.source_code = content
	var err: Error = script.reload()
	if err != OK:
		return {"valid": false, "error": error_string(err), "error_code": err}
	return {"valid": true}


func script_list(_params: Dictionary) -> Variant:
	var scripts: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	_find_scripts_recursive(efs.get_filesystem(), scripts)
	return {"scripts": scripts}


func _find_scripts_recursive(dir: EditorFileSystemDirectory, scripts: Array) -> void:
	for i in range(dir.get_file_count()):
		var file_name: String = dir.get_file(i)
		if file_name.ends_with(".gd"):
			scripts.append(dir.get_path() + "/" + file_name)
	for i in range(dir.get_subdir_count()):
		_find_scripts_recursive(dir.get_subdir(i), scripts)
