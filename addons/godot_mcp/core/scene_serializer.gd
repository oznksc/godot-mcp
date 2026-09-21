@tool
extends RefCounted
class_name SceneSerializer


static func serialize_scene(root: Node) -> Dictionary:
	if root == null:
		return {}
	return _serialize_node(root)


static func _serialize_node(node: Node) -> Dictionary:
	var result: Dictionary = {
		"name": node.name,
		"type": node.get_class(),
		"properties": _get_node_properties(node),
		"children": [],
	}

	if node.script != null:
		result["script"] = node.script.resource_path

	if node.get_groups().size() > 0:
		result["groups"] = node.get_groups()

	var meta_keys: Array = node.get_meta_list()
	if meta_keys.size() > 0:
		result["metadata"] = {}
		for key in meta_keys:
			result["metadata"][key] = node.get_meta(key)

	for child in node.get_children():
		if child.owner == node.owner or child.owner == null:
			result["children"].append(_serialize_node(child))

	return result


static func _get_node_properties(node: Node) -> Dictionary:
	# Delegate to NodeUtils to avoid duplicating get_property_list() filtering.
	# NodeUtils.get_serializable_properties() returns raw Variant values;
	# we then pass each through _serialize_value() for JSON-safe encoding.
	var raw: Dictionary = NodeUtils.get_serializable_properties(node)
	var props: Dictionary = {}
	for key in raw:
		props[key] = _serialize_value(raw[key])
	return props


static func _serialize_value(value: Variant) -> Variant:
	if value is Vector2:
		return {"x": value.x, "y": value.y}
	elif value is Vector3:
		return {"x": value.x, "y": value.y, "z": value.z}
	elif value is Color:
		return {"r": value.r, "g": value.g, "b": value.b, "a": value.a}
	elif value is NodePath:
		return str(value)
	elif value is Resource:
		return value.resource_path
	elif value is Array:
		var arr: Array = []
		for item in value:
			arr.append(_serialize_value(item))
		return arr
	elif value is Dictionary:
		var dict: Dictionary = {}
		for key in value:
			dict[str(key)] = _serialize_value(value[key])
		return dict
	return value
