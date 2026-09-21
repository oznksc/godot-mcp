@tool
extends Node

## Viewport and Screenshot capture commands for Godot MCP v2.
## Enables AI visual feedback, UI layout inspection, and debug draw visualization.


func viewport_capture_editor(params: Dictionary) -> Variant:
	var view: String = params.get("view", "main").to_lower()
	var max_width: int = params.get("max_width", 1280)
	var max_height: int = params.get("max_height", 720)

	var target_viewport: Viewport = null
	if Engine.is_editor_hint() and EditorInterface != null:
		if view == "2d" and EditorInterface.has_method("get_editor_viewport_2d"):
			target_viewport = EditorInterface.get_editor_viewport_2d()
		elif view == "3d" and EditorInterface.has_method("get_editor_viewport_3d"):
			target_viewport = EditorInterface.get_editor_viewport_3d(0)

		if target_viewport == null and EditorInterface.has_method("get_base_control"):
			var base_ctrl: Control = EditorInterface.get_base_control()
			if base_ctrl:
				target_viewport = base_ctrl.get_viewport()

	if target_viewport == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			target_viewport = tree.root

	if target_viewport == null:
		return {"error": {"code": -32603, "message": "Could not access editor viewport"}}

	return _capture_viewport_to_dict(target_viewport, max_width, max_height, view)


const MCPRuntimeBridge = preload("res://addons/godot_mcp/core/mcp_runtime_bridge.gd")


func viewport_capture_game(params: Dictionary) -> Variant:
	if not EditorInterface.is_playing_scene():
		return {"error": {"code": -32602, "message": "No game is currently running"}}

	var max_width: int = params.get("max_width", 1280)
	var max_height: int = params.get("max_height", 720)

	var rt_res: Dictionary = await MCPRuntimeBridge.query_runtime("capture_viewport", {
		"max_width": max_width,
		"max_height": max_height
	})
	if not rt_res.has("error") and rt_res.has("base64"):
		return rt_res

	var root_vp: Viewport = null
	var tree := Engine.get_main_loop() as SceneTree
	if tree != null:
		root_vp = tree.root

	if root_vp == null:
		return {"error": {"code": -32603, "message": "Could not access running game root viewport"}}

	return _capture_viewport_to_dict(root_vp, max_width, max_height, "game")


func viewport_set_debug_draw(params: Dictionary) -> Variant:
	var mode: String = params.get("mode", "normal").to_lower()
	var vp: Viewport = null
	if Engine.is_editor_hint() and EditorInterface != null:
		if EditorInterface.has_method("get_editor_viewport_3d"):
			vp = EditorInterface.get_editor_viewport_3d(0)
		if vp == null and EditorInterface.has_method("get_base_control"):
			var base_ctrl: Control = EditorInterface.get_base_control()
			if base_ctrl:
				vp = base_ctrl.get_viewport()

	if vp == null:
		var tree := Engine.get_main_loop() as SceneTree
		if tree != null:
			vp = tree.root

	if vp == null:
		return {"error": {"code": -32603, "message": "Viewport not accessible"}}

	match mode:
		"wireframe":
			vp.debug_draw = Viewport.DEBUG_DRAW_WIREFRAME
		"overdraw":
			vp.debug_draw = Viewport.DEBUG_DRAW_OVERDRAW
		"unshaded":
			vp.debug_draw = Viewport.DEBUG_DRAW_UNSHADED
		"lighting":
			vp.debug_draw = Viewport.DEBUG_DRAW_LIGHTING
		"normal_buffer":
			vp.debug_draw = Viewport.DEBUG_DRAW_NORMAL_BUFFER
		"collision":
			get_tree().debug_collisions_hint = true
		"navigation":
			get_tree().debug_navigation_hint = true
		"normal", "disabled":
			vp.debug_draw = Viewport.DEBUG_DRAW_DISABLED
			get_tree().debug_collisions_hint = false
			get_tree().debug_navigation_hint = false
		_:
			return {"error": {"code": -32602, "message": "Unsupported debug draw mode: " + mode}}

	return {"success": true, "mode": mode}


func _capture_viewport_to_dict(vp: Viewport, max_w: int, max_h: int, view_name: String) -> Dictionary:
	var tex: ViewportTexture = vp.get_texture()
	var img: Image = null
	if tex != null:
		img = tex.get_image()

	if img == null or img.is_empty():
		RenderingServer.force_draw(false)
		if tex != null:
			img = tex.get_image()

	if img == null or img.is_empty():
		return {"error": {"code": -32603, "message": "Failed to capture viewport texture image"}}

	var orig_w: int = img.get_width()
	var orig_h: int = img.get_height()

	# Scale down if requested bounds exceeded
	var target_w: int = orig_w
	var target_h: int = orig_h
	if orig_w > max_w or orig_h > max_h:
		var scale_w: float = float(max_w) / float(orig_w)
		var scale_h: float = float(max_h) / float(orig_h)
		var scale: float = minf(scale_w, scale_h)
		target_w = int(orig_w * scale)
		target_h = int(orig_h * scale)
		img.resize(target_w, target_h, Image.INTERPOLATE_BILINEAR)

	var png_buffer: PackedByteArray = img.save_png_to_buffer()
	var base64_str: String = Marshalls.raw_to_base64(png_buffer)

	return {
		"view": view_name,
		"format": "png",
		"width": target_w,
		"height": target_h,
		"original_width": orig_w,
		"original_height": orig_h,
		"base64": base64_str
	}
