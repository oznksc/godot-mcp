@tool
extends Node
class_name UndoRedoHelper


static func get_undo_redo() -> EditorUndoRedoManager:
	return EditorInterface.get_editor_undo_redo()


static func add_node(parent: Node, node: Node, node_name: String = "") -> void:
	var ur: EditorUndoRedoManager = get_undo_redo()
	ur.create_action("Add Node: " + node_name if not node_name.is_empty() else node.name)
	ur.add_do_method(parent, "add_child", node)
	ur.add_do_property(node, "owner", parent.owner if parent.owner else parent)
	ur.add_do_reference(node)
	ur.add_undo_method(parent, "remove_child", node)
	ur.commit_action()


static func remove_node(node: Node) -> void:
	var ur: EditorUndoRedoManager = get_undo_redo()
	var parent: Node = node.get_parent()
	if parent == null:
		return
	ur.create_action("Remove Node: " + node.name)
	ur.add_do_method(parent, "remove_child", node)
	ur.add_undo_method(parent, "add_child", node)
	ur.add_undo_method(node, "set_owner", node.owner)
	ur.commit_action()


static func rename_node(node: Node, new_name: String) -> void:
	var ur: EditorUndoRedoManager = get_undo_redo()
	var old_name: String = node.name
	ur.create_action("Rename Node: " + old_name + " -> " + new_name)
	ur.add_do_property(node, "name", new_name)
	ur.add_undo_property(node, "name", old_name)
	ur.commit_action()


static func set_property(node: Node, property: String, value: Variant) -> void:
	var ur: EditorUndoRedoManager = get_undo_redo()
	var old_value: Variant = node.get(property)
	ur.create_action("Set Property: " + property)
	ur.add_do_property(node, property, value)
	ur.add_undo_property(node, property, old_value)
	ur.commit_action()
