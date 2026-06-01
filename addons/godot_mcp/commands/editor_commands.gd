@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")


func editor_get_state(_params: Dictionary) -> Variant:
	var root: Node = NodeUtils.get_scene_root()
	return {
		"is_playing": EditorInterface.is_playing_scene(),
		"playing_scene": EditorInterface.get_playing_scene(),
		"current_scene": root.scene_file_path if root else null,
		"open_scenes": EditorInterface.get_open_scenes(),
		"active_screen": _get_active_screen(),
	}


func _get_active_screen() -> String:
	var main_screen: Control = EditorInterface.get_editor_main_screen()
	if main_screen == null:
		return "unknown"
	# Check which tab is visible
	return "2D"  # Default fallback


func editor_set_main_screen(params: Dictionary) -> Variant:
	var screen: String = params.get("screen", "2D")
	EditorInterface.set_main_screen_editor(screen)
	return {"success": true, "screen": screen}


func editor_inspect_node(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	EditorInterface.inspect_object(node)
	return {"success": true, "inspected": path}


func editor_inspect_resource(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var res: Resource = ResourceLoader.load(path)
	if res == null:
		return {"error": {"code": -32603, "message": "Failed to load resource: " + path}}

	EditorInterface.edit_resource(res)
	return {"success": true, "inspected": path}


func editor_get_selection(_params: Dictionary) -> Variant:
	var selection: EditorSelection = EditorInterface.get_selection()
	var selected_nodes: Array = selection.get_selected_nodes()
	var paths: Array = []
	var root: Node = NodeUtils.get_scene_root()
	if root:
		for node in selected_nodes:
			paths.append(root.get_path_to(node))
	return {"selected": paths}


func editor_select_node(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + path}}

	var selection: EditorSelection = EditorInterface.get_selection()
	selection.clear()
	selection.add_node(node)
	EditorInterface.edit_node(node)
	return {"success": true, "selected": path}


func editor_open_script(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var line: int = params.get("line", 0)
	var column: int = params.get("column", 0)
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var script: Script = ResourceLoader.load(path)
	if script == null:
		return {"error": {"code": -32603, "message": "Failed to load script: " + path}}

	EditorInterface.edit_script(script, line, column)
	return {"success": true, "opened": path}


func editor_rescan_filesystem(_params: Dictionary) -> Variant:
	EditorInterface.get_resource_filesystem().scan()
	return {"success": true}


func editor_restart(params: Dictionary) -> Variant:
	var save: bool = params.get("save", true)
	if save:
		EditorInterface.save_all_scenes()
	EditorInterface.restart_editor()
	return {"success": true}
