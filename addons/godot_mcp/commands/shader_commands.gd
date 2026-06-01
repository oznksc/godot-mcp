@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")


func shader_create(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var type: String = params.get("type", "spatial")
	var content: String = params.get("content", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	if content.is_empty():
		match type:
			"spatial":
				content = "shader_type spatial;\n\nvoid fragment() {\n\tALBEDO = vec3(1.0);\n}"
			"canvas_item":
				content = "shader_type canvas_item;\n\nvoid fragment() {\n\tCOLOR = vec4(1.0);\n}"
			"particles":
				content = "shader_type particles;\n\nvoid vertex() {\n\tVELOCITY = vec3(0.0);\n}"
			"sky":
				content = "shader_type sky;\n\nvoid sky() {\n\tCOLOR = vec4(0.5, 0.5, 1.0, 1.0);\n}"
			"fog":
				content = "shader_type fog;\n\nvoid fog() {\n\tALBEDO = vec3(1.0);\n}"

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to create shader file: " + path}}
	file.store_string(content)
	file.close()
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true, "path": path, "type": type}


func shader_read(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to read shader: " + path}}
	var content: String = file.get_as_text()
	file.close()
	return {"path": path, "content": content}


func shader_write(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var content: String = params.get("content", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return {"error": {"code": -32603, "message": "Failed to write shader: " + path}}
	file.store_string(content)
	file.close()
	return {"success": true, "path": path}


func shader_assign_material(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var shader_path: String = params.get("shader_path", "")
	var properties: Dictionary = params.get("properties", {})
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	var shader: Shader = ResourceLoader.load(shader_path)
	if shader == null:
		return {"error": {"code": -32603, "message": "Failed to load shader: " + shader_path}}

	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = shader
	for key in properties:
		mat.set_shader_parameter(key, properties[key])

	if node.has_method("set_material"):
		node.set_material(mat)
	elif node is MeshInstance3D or node is MeshInstance2D:
		node.material_override = mat

	return {"success": true, "node": node_path, "shader": shader_path}
