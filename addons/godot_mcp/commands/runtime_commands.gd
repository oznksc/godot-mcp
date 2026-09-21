@tool
extends Node


func runtime_run_project(params: Dictionary) -> Variant:
	var scene: String = params.get("scene", "")
	if scene.is_empty():
		EditorInterface.play_main_scene()
	else:
		EditorInterface.play_custom_scene(scene)
	return {"success": true, "scene": scene if not scene.is_empty() else "main_scene"}


func runtime_stop(_params: Dictionary) -> Variant:
	EditorInterface.stop_playing_scene()
	return {"success": true}


func runtime_pause(_params: Dictionary) -> Variant:
	if not EditorInterface.is_playing_scene():
		return {"error": {"code": -32602, "message": "No scene is currently playing"}}

	get_tree().paused = true
	return {"success": true}


func runtime_resume(_params: Dictionary) -> Variant:
	get_tree().paused = false
	return {"success": true}


func runtime_step(_params: Dictionary) -> Variant:
	if not EditorInterface.is_playing_scene():
		return {"error": {"code": -32602, "message": "No scene is currently playing"}}

	get_tree().paused = true
	# Step one frame by processing once
	get_tree().process_mode = Node.PROCESS_MODE_ALWAYS
	return {"success": true}


func runtime_is_playing(_params: Dictionary) -> Variant:
	var is_playing: bool = false
	if Engine.is_editor_hint() and EditorInterface != null:
		is_playing = EditorInterface.is_playing_scene()
	return {"is_playing": is_playing}


func runtime_get_status(_params: Dictionary) -> Variant:
	var is_playing: bool = false
	var playing_scene: String = ""
	if Engine.is_editor_hint() and EditorInterface != null:
		is_playing = EditorInterface.is_playing_scene()
		playing_scene = EditorInterface.get_playing_scene()
	return {
		"is_playing": is_playing,
		"playing_scene": playing_scene,
		"is_paused": get_tree().paused if get_tree() != null else false,
	}
