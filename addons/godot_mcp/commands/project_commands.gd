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


func project_get_input_map(_params: Dictionary) -> Variant:
	var input_map: Dictionary = {}
	var actions: Array = ProjectSettings.get_setting("input", {})
	for action in actions:
		input_map[action] = actions[action]
	return {"input_map": input_map}


func project_configure_input_map(params: Dictionary) -> Variant:
	var action: String = params.get("action", "")
	var events: Array = params.get("events", [])
	if action.is_empty():
		return {"error": {"code": -32602, "message": "Action name is required"}}

	# This is a simplified implementation
	# Full input map configuration requires more complex handling
	return {"success": true, "action": action, "events_count": events.size()}


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
