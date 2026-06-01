@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")


func physics_set_collision_shape(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var shape_type: String = params.get("shape_type", "Rectangle")
	var shape_props: Dictionary = params.get("shape_properties", {})
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	# Ensure CollisionShape2D/3D exists
	var is_3d: bool = node is Node3D
	var shape_node: Node = null

	for child in node.get_children():
		if (is_3d and child is CollisionShape3D) or (not is_3d and child is CollisionShape2D):
			shape_node = child
			break

	if shape_node == null:
		if is_3d:
			shape_node = CollisionShape3D.new()
		else:
			shape_node = CollisionShape2D.new()
		shape_node.name = "CollisionShape"
		UndoRedoHelper.add_node(node, shape_node, "CollisionShape")

	# Create shape resource
	var shape: Shape2D = null
	var shape3: Shape3D = null
	match shape_type:
		"Rectangle":
			if is_3d:
				shape3 = BoxShape3D.new()
				shape3.size = shape_props.get("size", Vector3(1, 1, 1))
			else:
				shape = RectangleShape2D.new()
				shape.size = shape_props.get("size", Vector2(1, 1))
		"Circle":
			shape = CircleShape2D.new()
			shape.radius = shape_props.get("radius", 0.5)
		"Capsule":
			if is_3d:
				shape3 = CapsuleShape3D.new()
				shape3.radius = shape_props.get("radius", 0.5)
				shape3.height = shape_props.get("height", 2.0)
			else:
				shape = CapsuleShape2D.new()
				shape.radius = shape_props.get("radius", 0.5)
				shape.height = shape_props.get("height", 2.0)
		"Sphere":
			shape3 = SphereShape3D.new()
			shape3.radius = shape_props.get("radius", 0.5)
		"Box":
			shape3 = BoxShape3D.new()
			shape3.size = shape_props.get("size", Vector3(1, 1, 1))

	if is_3d and shape3:
		shape_node.shape = shape3
	elif shape:
		shape_node.shape = shape

	return {"success": true, "node": node_path, "shape_type": shape_type}


func physics_set_collision_layer(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var layer: int = params.get("layer", 1)
	var mask: int = params.get("mask", 1)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if node.has_method("set_collision_layer"):
		node.collision_layer = layer
		node.collision_mask = mask
	return {"success": true, "node": path, "layer": layer, "mask": mask}


func physics_configure_material(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var bounce: float = params.get("bounce", 0.0)
	var friction: float = params.get("friction", 1.0)
	var absorbent: bool = params.get("absorbent", false)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var mat: PhysicsMaterial = PhysicsMaterial.new()
	mat.bounce = bounce
	mat.friction = friction
	mat.absorbent = absorbent

	if node.has_method("set_physics_material_override"):
		node.physics_material_override = mat
	return {"success": true, "node": path}


func physics_get_body_state(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var state: Dictionary = {}
	if node is CharacterBody3D:
		state = {"velocity": node.velocity, "is_on_floor": node.is_on_floor(), "is_on_wall": node.is_on_wall()}
	elif node is CharacterBody2D:
		state = {"velocity": node.velocity, "is_on_floor": node.is_on_floor(), "is_on_wall": node.is_on_wall()}
	elif node is RigidBody3D:
		state = {"linear_velocity": node.linear_velocity, "angular_velocity": node.angular_velocity, "sleeping": node.sleeping}
	elif node is RigidBody2D:
		state = {"linear_velocity": node.linear_velocity, "angular_velocity": node.angular_velocity, "sleeping": node.sleeping}
	return {"node": path, "state": state}
