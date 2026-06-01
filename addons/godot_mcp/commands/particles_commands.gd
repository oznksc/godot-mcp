@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")


func particles_create(params: Dictionary) -> Variant:
	var type: String = params.get("type", "GPUParticles3D")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")
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
		"GPUParticles2D":
			node = GPUParticles2D.new()
		"GPUParticles3D":
			node = GPUParticles3D.new()
		"CPUParticles2D":
			node = CPUParticles2D.new()
		"CPUParticles3D":
			node = CPUParticles3D.new()
		_:
			return {"error": {"code": -32602, "message": "Unknown particles type: " + type}}

	node.name = node_name
	UndoRedoHelper.add_node(parent, node, node_name)
	return {"success": true, "node": node_name, "type": type}


func particles_set_material(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var material_path: String = params.get("material_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var mat: ParticleProcessMaterial = ResourceLoader.load(material_path)
	if mat == null:
		return {"error": {"code": -32603, "message": "Failed to load particle material: " + material_path}}

	if node is GPUParticles2D or node is GPUParticles3D:
		node.process_material = mat
	return {"success": true, "node": path, "material": material_path}


func particles_configure(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if params.has("amount") and node.has_method("set_amount"):
		node.amount = params["amount"]
	if params.has("lifetime") and node.has_method("set_lifetime"):
		node.lifetime = params["lifetime"]
	if params.has("one_shot") and node.has_method("set_one_shot"):
		node.one_shot = params["one_shot"]
	if params.has("emitting") and node.has_method("set_emitting"):
		node.emitting = params["emitting"]
	if params.has("explosiveness") and node.has_method("set_explosiveness_ratio"):
		node.explosiveness_ratio = params["explosiveness"]
	if params.has("randomness") and node.has_method("set_randomness_ratio"):
		node.randomness_ratio = params["randomness"]
	if params.has("fixed_fps") and node.has_method("set_fixed_fps"):
		node.fixed_fps = params["fixed_fps"]

	return {"success": true, "node": path}
