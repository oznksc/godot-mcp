@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")


func lighting_create(params: Dictionary) -> Variant:
	var type: String = params.get("type", "DirectionalLight3D")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")
	var color: String = params.get("color", "#ffffff")
	var energy: float = params.get("energy", 1.0)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	var node: Node
	match type:
		"DirectionalLight2D":
			node = DirectionalLight2D.new()
		"PointLight2D":
			node = PointLight2D.new()
		"DirectionalLight3D":
			node = DirectionalLight3D.new()
		"OmniLight3D":
			node = OmniLight3D.new()
		"SpotLight3D":
			node = SpotLight3D.new()
		_:
			return {"error": {"code": -32602, "message": "Unknown light type: " + type}}

	node.name = node_name
	node.light_energy = energy
	if not color.is_empty():
		node.light_color = Color.html(color)

	UndoRedoHelper.add_node(parent, node, node_name)
	return {"success": true, "node": node_name, "type": type}


func lighting_set_properties(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if params.has("color"):
		node.light_color = Color.html(params["color"])
	if params.has("energy"):
		node.light_energy = params["energy"]
	if params.has("shadow_enabled") and node.has_method("set_shadow_enabled"):
		node.shadow_enabled = params["shadow_enabled"]
	if params.has("indirect_energy") and node.has_method("set_indirect_energy"):
		node.indirect_energy = params["indirect_energy"]

	return {"success": true, "node": path}


func lighting_create_environment(params: Dictionary) -> Variant:
	var path: String = params.get("path", "res://default_environment.tres")
	var properties: Dictionary = params.get("properties", {})

	var env: Environment = Environment.new()
	for key in properties:
		env.set(key, properties[key])

	var err: Error = ResourceSaver.save(env, path)
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save environment: " + error_string(err)}}
	return {"success": true, "path": path}


func lighting_configure_world(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var environment_path: String = params.get("environment_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	var env: Environment = ResourceLoader.load(environment_path)
	if env == null:
		return {"error": {"code": -32603, "message": "Failed to load environment: " + environment_path}}

	if node is WorldEnvironment:
		node.environment = env
	return {"success": true, "node": node_path, "environment": environment_path}
