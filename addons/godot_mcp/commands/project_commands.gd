@tool
extends Node


func project_get_info(_params: Dictionary) -> Variant:
	return {
		"name": ProjectSettings.get_setting("application/config/name", "Unnamed"),
		"version": ProjectSettings.get_setting("application/config/version", ""),
		"config_version": ProjectSettings.get_setting("config_version", 0),
		"path": ProjectSettings.globalize_path("res://"),
		"features": ProjectSettings.get_setting("config/features", []),
	}


func project_get_settings(_params: Dictionary) -> Variant:
	var settings: Dictionary = {}
	for prop in ProjectSettings.get_property_list():
		if prop["usage"] & PROPERTY_USAGE_STORAGE:
			settings[prop["name"]] = ProjectSettings.get(prop["name"])
	return {"settings": settings}


func project_update_setting(params: Dictionary) -> Variant:
	var setting: String = params.get("setting", "")
	var value: Variant = params.get("value")
	if setting.is_empty():
		return {"error": {"code": -32602, "message": "Setting path is required"}}

	ProjectSettings.set(setting, value)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save project settings: " + error_string(err)}}
	return {"success": true, "setting": setting}


const PathSandbox = preload("res://addons/godot_mcp/core/path_sandbox.gd")


func project_get_input_map(_params: Dictionary) -> Variant:
	var input_map: Dictionary = {}
	var actions: Array = InputMap.get_actions()
	for action in actions:
		var action_str: String = str(action)
		var events_list: Array = []
		for ev in InputMap.action_get_events(action):
			var ev_info: Dictionary = {}
			if ev is InputEventKey:
				ev_info = {
					"type": "Key",
					"keycode": ev.keycode,
					"physical_keycode": ev.physical_keycode,
					"key_label": OS.get_keycode_string(ev.keycode if ev.keycode != 0 else ev.physical_keycode)
				}
			elif ev is InputEventMouseButton:
				ev_info = {
					"type": "MouseButton",
					"button_index": ev.button_index
				}
			elif ev is InputEventJoypadButton:
				ev_info = {
					"type": "JoypadButton",
					"button_index": ev.button_index
				}
			elif ev is InputEventJoypadMotion:
				ev_info = {
					"type": "JoypadMotion",
					"axis": ev.axis,
					"axis_value": ev.axis_value
				}
			else:
				ev_info = {
					"type": ev.get_class()
				}
			events_list.append(ev_info)

		input_map[action_str] = {
			"deadzone": InputMap.action_get_deadzone(action),
			"events": events_list
		}
	return {"input_map": input_map}


func project_configure_input_map(params: Dictionary) -> Variant:
	var action: String = params.get("action", "")
	var events: Array = params.get("events", [])
	var deadzone: float = params.get("deadzone", 0.5)
	var replace: bool = params.get("replace", true)

	if action.is_empty():
		return {"error": {"code": -32602, "message": "Action name is required"}}

	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)

	if replace:
		InputMap.action_erase_events(action)

	var event_objects: Array = []
	for ev_data in events:
		if not ev_data is Dictionary:
			continue
		var ev_type: String = str(ev_data.get("type", "")).to_lower()
		var ev: InputEvent = null

		if ev_type.contains("key"):
			var key_ev := InputEventKey.new()
			if ev_data.has("keycode"):
				var kc = ev_data["keycode"]
				if typeof(kc) == TYPE_STRING:
					key_ev.keycode = OS.find_keycode_from_string(kc)
				else:
					key_ev.keycode = int(kc)
			if ev_data.has("physical_keycode"):
				var pkc = ev_data["physical_keycode"]
				if typeof(pkc) == TYPE_STRING:
					key_ev.physical_keycode = OS.find_keycode_from_string(pkc)
				else:
					key_ev.physical_keycode = int(pkc)
			ev = key_ev
		elif ev_type.contains("mouse"):
			var mouse_ev := InputEventMouseButton.new()
			if ev_data.has("button_index"):
				mouse_ev.button_index = int(ev_data["button_index"])
			ev = mouse_ev
		elif ev_type.contains("joybutton") or ev_type.contains("joypadbutton"):
			var joy_btn := InputEventJoypadButton.new()
			if ev_data.has("button_index"):
				joy_btn.button_index = int(ev_data["button_index"])
			ev = joy_btn
		elif ev_type.contains("joyaxis") or ev_type.contains("joypadmotion"):
			var joy_motion := InputEventJoypadMotion.new()
			if ev_data.has("axis"):
				joy_motion.axis = int(ev_data["axis"])
			if ev_data.has("axis_value"):
				joy_motion.axis_value = float(ev_data["axis_value"])
			ev = joy_motion

		if ev != null:
			InputMap.action_add_event(action, ev)
			event_objects.append(ev)

	# Save into ProjectSettings so it persists across restarts
	var setting_dict := {
		"deadzone": deadzone,
		"events": event_objects
	}
	ProjectSettings.set_setting("input/" + action, setting_dict)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save project settings: " + error_string(err)}}

	return {"success": true, "action": action, "events_count": event_objects.size()}


func project_get_collision_layers(_params: Dictionary) -> Variant:
	var layers: Dictionary = {}
	for i in range(1, 33):
		var layer_name: String = ProjectSettings.get_setting("layer_names/2d_physics/layer_" + str(i), "")
		if not layer_name.is_empty():
			layers["layer_" + str(i)] = layer_name
	return {"collision_layers": layers}


func project_setup_autoload(params: Dictionary) -> Variant:
	var name: String = params.get("name", "")
	var path: String = params.get("path", "")
	var enabled: bool = params.get("enabled", true)
	if name.is_empty() or path.is_empty():
		return {"error": {"code": -32602, "message": "Name and path are required"}}

	if not PathSandbox.is_path_safe(path):
		return {"error": {"code": -32001, "message": "Path traversal or invalid path: " + path}}

	ProjectSettings.set_setting("autoload/" + name, ("*" if enabled else "") + path)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to save autoload: " + error_string(err)}}
	return {"success": true, "name": name, "path": path, "enabled": enabled}


func project_remove_autoload(params: Dictionary) -> Variant:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"error": {"code": -32602, "message": "Name is required"}}

	ProjectSettings.set_setting("autoload/" + name, null)
	var err: Error = ProjectSettings.save()
	if err != OK:
		return {"error": {"code": -32603, "message": "Failed to remove autoload: " + error_string(err)}}
	return {"success": true, "name": name}


func project_get_class_list(_params: Dictionary) -> Variant:
	var classes: Array = ProjectSettings.get_global_class_list()
	return {"classes": classes}


func project_get_export_presets(_params: Dictionary) -> Variant:
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		return {"presets": []}
	var presets: Array = []
	for section in config.get_sections():
		if section.begins_with("preset.") and not section.contains(".options"):
			presets.append({
				"name": config.get_value(section, "name", ""),
				"platform": config.get_value(section, "platform", ""),
				"export_path": config.get_value(section, "export_path", ""),
			})
	return {"presets": presets}
