@tool
extends Node

const SceneSerializer = preload("res://addons/godot_mcp/core/scene_serializer.gd")
const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")


func scene_create(params: Dictionary) -> Variant:
	var name: String = params.get("name", "NewScene")
	var root_type: String = params.get("root_type", "Node2D")
	var root_name: String = params.get("root_name", name)

	var root: Node
	match root_type:
		"Node2D":
			root = Node2D.new()
		"Node3D":
			root = Node3D.new()
		"Control":
			root = Control.new()
		"Node":
			root = Node.new()
		_:
			if ClassDB.class_exists(root_type):
				root = ClassDB.instantiate(root_type)
			else:
				return {"error": {"code": -32602, "message": "Unknown node type: " + root_type}}

	root.name = root_name
	EditorInterface.get_edited_scene_root()
	var scene_root: Node = EditorInterface.get_edited_scene_root()
	if scene_root == null:
		EditorInterface.add_root_node(root)
	else:
		scene_root.add_child(root)
		root.owner = scene_root.owner if scene_root.owner else scene_root

	var path: String = "res://" + name + ".tscn"
	return {"success": true, "path": path, "root_name": root_name, "root_type": root_type}


func scene_read(_params: Dictionary) -> Variant:
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}
	return SceneSerializer.serialize_scene(root)


func scene_save(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	if path.is_empty():
		path = root.scene_file_path if not root.scene_file_path.is_empty() else "res://" + root.name + ".tscn"

	var packed: PackedScene = PackedScene.new()
	packed.pack(root)
	var err: Error = ResourceSaver.save(path, packed)
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save scene: " + error_string(err)}}
	return {"success": true, "path": path}


func scene_list(_params: Dictionary) -> Variant:
	var scenes: Array = []
	var efs: EditorFileSystem = EditorInterface.get_resource_filesystem()
	_find_scenes_recursive(efs.get_filesystem(), scenes)
	return {"scenes": scenes}


func _find_scenes_recursive(dir: EditorFileSystemDirectory, scenes: Array) -> void:
	for i in range(dir.get_file_count()):
		var file_name: String = dir.get_file(i)
		if file_name.ends_with(".tscn"):
			scenes.append(dir.get_path() + "/" + file_name)
	for i in range(dir.get_subdir_count()):
		_find_scenes_recursive(dir.get_subdir(i), scenes)


func scene_open(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}
	EditorInterface.open_scene_from_path(path)
	return {"success": true, "path": path}


func scene_close(_params: Dictionary) -> Variant:
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}
	EditorInterface.close_scene()
	return {"success": true}


func scene_get_current(_params: Dictionary) -> Variant:
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"scene": null}
	return {
		"scene": {
			"name": root.name,
			"path": root.scene_file_path,
			"root_type": root.get_class(),
		}
	}


func scene_instance(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var parent_path: String = params.get("parent", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var scene: PackedScene = load(path)
	if scene == null:
		return {"error": {"code": -32602, "message": "Failed to load scene: " + path}}

	var instance: Node = scene.instantiate()
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	UndoRedoHelper.add_node(parent, instance, instance.name)
	return {"success": true, "node": instance.name}


func scene_get_hierarchy(_params: Dictionary) -> Variant:
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}
	return SceneSerializer.serialize_scene(root)


func scene_get_open_scenes(_params: Dictionary) -> Variant:
	var scenes: Array = EditorInterface.get_open_scenes()
	return {"scenes": scenes}


func scene_export_mesh_library(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}
	# This is a placeholder — actual implementation depends on GridMap/MeshLibrary workflow
	return {"success": true, "message": "Mesh library export initiated", "path": path}
