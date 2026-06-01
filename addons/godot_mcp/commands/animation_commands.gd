@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")


func animation_create(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var anim_name: String = params.get("anim_name", "")
	var duration: float = params.get("duration", 1.0)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null:
		return {"error": {"code": -32602, "message": "Node not found: " + node_path}}

	if not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "Node is not an AnimationPlayer: " + node_path}}

	var anim: Animation = Animation.new()
	anim.length = duration
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(anim_name, anim)
	node.add_animation_library("", lib)
	return {"success": true, "animation": anim_name, "duration": duration}


func animation_list_keys(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var anim_name: String = params.get("anim_name", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null or not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "AnimationPlayer not found: " + node_path}}

	var anim: Animation = node.get_animation(anim_name)
	if anim == null:
		return {"error": {"code": -32602, "message": "Animation not found: " + anim_name}}

	var tracks: Array = []
	for i in range(anim.get_track_count()):
		var track_info: Dictionary = {
			"index": i,
			"type": anim.track_get_type(i),
			"path": str(anim.track_get_path(i)),
			"key_count": anim.track_get_key_count(i),
		}
		tracks.append(track_info)
	return {"animation": anim_name, "tracks": tracks, "duration": anim.length}


func animation_add_keyframe(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var anim_name: String = params.get("anim_name", "")
	var track_type: String = params.get("track_type", "property")
	var target_path: String = params.get("target_path", "")
	var time: float = params.get("time", 0.0)
	var value: Variant = params.get("value")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null or not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "AnimationPlayer not found: " + node_path}}

	var anim: Animation = node.get_animation(anim_name)
	if anim == null:
		return {"error": {"code": -32602, "message": "Animation not found: " + anim_name}}

	# Find or create track
	var track_idx: int = -1
	for i in range(anim.get_track_count()):
		if str(anim.track_get_path(i)) == target_path:
			track_idx = i
			break

	if track_idx == -1:
		track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, target_path)

	# Determine key type based on value
	var key: Variant
	match typeof(value):
		TYPE_DICTIONARY:
			key = value  # Assume it's already formatted
		TYPE_VECTOR2:
			key = {"value": value}
		TYPE_VECTOR3:
			key = {"value": value}
		TYPE_COLOR:
			key = {"value": value}
		_:
			key = {"value": value}

	anim.track_insert_key(track_idx, time, key)
	return {"success": true, "track_index": track_idx, "time": time}


func animation_remove_keyframe(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var anim_name: String = params.get("anim_name", "")
	var track_index: int = params.get("track_index", 0)
	var time: float = params.get("time", 0.0)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null or not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "AnimationPlayer not found: " + node_path}}

	var anim: Animation = node.get_animation(anim_name)
	if anim == null:
		return {"error": {"code": -32602, "message": "Animation not found: " + anim_name}}

	if track_index < 0 or track_index >= anim.get_track_count():
		return {"error": {"code": -32602, "message": "Invalid track index"}}

	anim.track_remove_key_at_time(track_index, time)
	return {"success": true, "track_index": track_index, "time": time}


func animation_set_length(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var anim_name: String = params.get("anim_name", "")
	var duration: float = params.get("duration", 1.0)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null or not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "AnimationPlayer not found: " + node_path}}

	var anim: Animation = node.get_animation(anim_name)
	if anim == null:
		return {"error": {"code": -32602, "message": "Animation not found: " + anim_name}}

	anim.length = duration
	return {"success": true, "animation": anim_name, "length": duration}


func animation_get_library(params: Dictionary) -> Variant:
	var node_path: String = params.get("node_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(node_path)
	if node == null or not node is AnimationPlayer:
		return {"error": {"code": -32602, "message": "AnimationPlayer not found: " + node_path}}

	var libs: Dictionary = {}
	for lib_name in node.get_animation_library_list():
		var lib: AnimationLibrary = node.get_animation_library(lib_name)
		var anims: Array = lib.get_animation_list()
		libs[lib_name] = anims
	return {"node": node_path, "libraries": libs}
