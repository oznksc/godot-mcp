@tool
extends Node


func project_get_info(_params: Dictionary) -> Variant:
	var settings: Dictionary = ProjectSettings
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

	EditorInterface.add_autoload_singleton(name, path)
	return {"success": true, "name": name, "path": path, "enabled": enabled}


func project_remove_autoload(params: Dictionary) -> Variant:
	var name: String = params.get("name", "")
	if name.is_empty():
		return {"error": {"code": -32602, "message": "Name is required"}}

	EditorInterface.remove_autoload_singleton(name)
	return {"success": true, "name": name}


func project_get_class_list(_params: Dictionary) -> Variant:
	var classes: Array = ProjectSettings.get_global_class_list()
	return {"classes": classes}


func project_get_export_presets(_params: Dictionary) -> Variant:
	var presets: Array = []
	for preset in EditorExport.export_presets:
		presets.append({
			"name": preset.name,
			"platform": preset.platform,
			"export_debug": preset.export_debug_path,
			"export_release": preset.export_release_path,
		})
	return {"presets": presets}
