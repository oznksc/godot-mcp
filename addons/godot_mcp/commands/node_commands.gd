@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")
var _transaction_manager: Node


func setup(tx_mgr: Node = null) -> void:
	_transaction_manager = tx_mgr


func node_add(params: Dictionary) -> Variant:
	var type: String = params.get("type", "Node2D")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")

	if _transaction_manager and _transaction_manager.has_method("is_dry_run") and _transaction_manager.is_dry_run():
		_transaction_manager.record_node_action("node_add", {"type": type, "name": node_name, "parent": parent_path})
		return {"success": true, "dry_run": true, "simulated_action": "node_add", "type": type, "name": node_name}

	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	var node: Node
	if ClassDB.class_exists(type):
		node = ClassDB.instantiate(type)
	else:
		return {"error": {"code": -32602, "message": "Unknown node type: " + type}}

	node.name = node_name
	UndoRedoHelper.add_node(parent, node, node_name)
	if _transaction_manager and _transaction_manager.has_method("record_node_action"):
		_transaction_manager.record_node_action("node_add", {"type": type, "name": node_name, "parent": parent_path})
	return {"success": true, "node": node_name, "type": type, "parent": parent_path if not parent_path.is_empty() else root.name}


func node_remove(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	UndoRedoHelper.remove_node(node)
	return {"success": true, "removed": path}


func node_rename(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var new_name: String = params.get("new_name", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	UndoRedoHelper.rename_node(node, new_name)
	return {"success": true, "old_name": node.name, "new_name": new_name}


func node_move(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var new_parent_path: String = params.get("new_parent", "")
	var index: int = params.get("index", -1)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var new_parent: Node = root.get_node_or_null(new_parent_path)
	if new_parent == null:
		return {"error": {"code": -32602, "message": "New parent not found: " + new_parent_path}}

	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("Move Node")
	ur.add_do_method(node.get_parent(), "remove_child", node)
	ur.add_do_method(new_parent, "add_child", node)
	if index >= 0:
		ur.add_do_method(new_parent, "move_child", node, index)
	ur.add_undo_method(new_parent, "remove_child", node)
	ur.add_undo_method(node.get_parent(), "add_child", node)
	ur.commit_action()
	return {"success": true, "moved": path, "to": new_parent_path}


func node_duplicate(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var new_name: String = params.get("new_name", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var duplicate: Node = node.duplicate()
	if not new_name.is_empty():
		duplicate.name = new_name

	UndoRedoHelper.add_node(node.get_parent(), duplicate, duplicate.name)
	return {"success": true, "duplicated": path, "new_name": str(duplicate.name)}


func node_get_properties(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	# Delegate to shared helper to avoid duplicating get_property_list() logic.
	# Result includes type annotation for the MCP response schema.
	var raw: Dictionary = NodeUtils.get_serializable_properties(node)
	var props: Dictionary = {}
	for prop_name in raw:
		props[prop_name] = {"type": typeof(raw[prop_name]), "value": raw[prop_name]}
	return {"node": path, "properties": props}


func node_set_property(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var property: String = params.get("property", "")
	var value: Variant = params.get("value")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	UndoRedoHelper.set_property(node, property, value)
	return {"success": true, "node": path, "property": property}


func node_set_properties(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var properties: Dictionary = params.get("properties", {})
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	for key in properties:
		UndoRedoHelper.set_property(node, key, properties[key])
	return {"success": true, "node": path, "properties_set": properties.keys()}


func node_find(params: Dictionary) -> Variant:
	var name: String = params.get("name", "")
	var recursive: bool = params.get("recursive", true)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var results: Array = NodeUtils.find_nodes_by_name(root, name, recursive)
	var paths: Array = []
	for node in results:
		paths.append(root.get_path_to(node))
	return {"matches": paths}


func node_find_by_type(params: Dictionary) -> Variant:
	var type: String = params.get("type", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var results: Array = NodeUtils.find_nodes_by_type(root, type)
	var paths: Array = []
	for node in results:
		paths.append(root.get_path_to(node))
	return {"matches": paths, "count": paths.size()}


func node_get_children(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var recursive: bool = params.get("recursive", false)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var children: Array = []
	if recursive:
		_collect_children_recursive(node, children, 0)
	else:
		for child in node.get_children():
			children.append({"name": str(child.name), "type": child.get_class(), "depth": 0})
	return {"node": path, "children": children}


func _collect_children_recursive(node: Node, children: Array, depth: int) -> void:
	for child in node.get_children():
		children.append({"name": str(child.name), "type": child.get_class(), "depth": depth})
		_collect_children_recursive(child, children, depth + 1)


func node_get_parent(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var parent: Node = node.get_parent()
	if parent == null:
		return {"node": path, "parent": null}
	return {"node": path, "parent": {"name": str(parent.name), "type": parent.get_class(), "path": str(root.get_path_to(parent))}}


func node_set_groups(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var groups: Array = params.get("groups", [])
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	for group in groups:
		if not node.is_in_group(group):
			node.add_to_group(group)
	return {"success": true, "groups": node.get_groups()}


func node_get_groups(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	return {"node": path, "groups": node.get_groups()}


func node_set_meta(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var key: String = params.get("key", "")
	var value: Variant = params.get("value")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	node.set_meta(key, value)
	return {"success": true, "node": path, "key": key}


func node_get_meta(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var key: String = params.get("key", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	if key.is_empty():
		var all_meta: Dictionary = {}
		for meta_key in node.get_meta_list():
			all_meta[meta_key] = node.get_meta(meta_key)
		return {"node": path, "metadata": all_meta}
	return {"node": path, "key": key, "value": node.get_meta(key)}
