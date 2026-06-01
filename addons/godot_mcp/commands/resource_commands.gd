@tool
extends Node


func resource_get_info(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to load resource: " + path}}

	return {
		"path": path,
		"type": res.get_class(),
		"resource_name": res.resource_name,
		"resource_path": res.resource_path,
		"resource_local_to_scene": res.resource_local_to_scene,
	}


func resource_set_property(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to load resource: " + path}}

	res.set(property, value)
	return {"success": true, "path": path, "property": property}


func resource_save(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to load resource: " + path}}

	var err: Error = ResourceSaver.save(path, res)
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save resource: " + error_string(err)}}
	return {"success": true, "path": path}


func resource_load(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to load resource: " + path}}

	return {
		"path": path,
		"type": res.get_class(),
		"resource_name": res.resource_name,
	}


func resource_create(params: Dictionary) -> Variant:
	var type: String = params.get("type", "")
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	if type.is_empty():
		return {"error": {"code": -32602, "message": "Type is required"}}

	if not ClassDB.class_exists(type):
		return {"error": {"code": -32602, "message": "Unknown resource type: " + type}}

	var res: RefCounted = ClassDB.instantiate(type)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to create resource of type: " + type}}

	for key in properties:
		res.set(key, properties[key])

	if not path.is_empty():
		var err: Error = ResourceSaver.save(path, res)
		if err != OK:
			return {"error": {"code": -32603, "message": "Failed to save resource: " + error_string(err)}}

	return {"success": true, "type": type, "path": path}


func resource_list_by_type(params: Dictionary) -> Variant:
	var type: String = params.get("type", "")
	if type.is_empty():
		return {"error": {"code": -32602, "message": "Type is required"}}

	var resources: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	_find_resources_by_type(efs.get_filesystem(), type, resources)
	return {"resources": resources, "type": type}


func _find_resources_by_type(dir: EditorFileSystemDirectory, type: String, resources: Array) -> void:
	for i in range(dir.get_file_count()):
		var file_type: String = dir.get_file_type(i)
		if file_type == type:
			resources.append(dir.get_path() + "/" + dir.get_file(i))
	for i in range(dir.get_subdir_count()):
		_find_resources_by_type(dir.get_subdir(i), type, resources)
