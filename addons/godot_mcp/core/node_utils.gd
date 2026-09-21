@tool
extends RefCounted
class_name NodeUtils


static func find_node_by_path(root: Node, path: String) -> Node:
	if path.is_empty():
		return root
	return root.get_node_or_null(path)


static func find_nodes_by_name(root: Node, name: String, recursive: bool = true) -> Array:
	var results: Array = []
	_find_recursive(root, name, recursive, results)
	return results


static func _find_recursive(node: Node, name: String, recursive: bool, results: Array) -> void:
	for child in node.get_children():
		if child.name == name:
			results.append(child)
		if recursive:
			_find_recursive(child, name, recursive, results)


static func find_nodes_by_type(root: Node, type_name: String) -> Array:
	var results: Array = []
	_find_by_type_recursive(root, type_name, results)
	return results


static func _find_by_type_recursive(node: Node, type_name: String, results: Array) -> void:
	for child in node.get_children():
		if child.is_class(type_name):
			results.append(child)
		_find_by_type_recursive(child, type_name, results)


static func get_scene_root() -> Node:
	return EditorInterface.get_edited_scene_root()


static func ensure_scene_open() -> Node:
	var root: Node = get_scene_root()
	if root == null:
		return null
	return root


## Returns a Dictionary of all storage-relevant properties for a node,
## skipping internal/private names. Shared by scene_serializer and node_commands
## to avoid duplicated get_property_list() iteration logic.
static func get_serializable_properties(node: Node) -> Dictionary:
	var props: Dictionary = {}
	for prop in node.get_property_list():
		var prop_name: String = prop["name"]
		if prop_name.begins_with("_") or prop_name in ["script", "metadata"]:
			continue
		if prop["usage"] & PROPERTY_USAGE_STORAGE:
			var value: Variant = node.get(prop_name)
			if value != null:
				props[prop_name] = value
	return props
