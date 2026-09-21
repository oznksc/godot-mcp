@tool
extends Node

const PathSandbox = preload("res://addons/godot_mcp/core/path_sandbox.gd")


func import_reimport(params: Dictionary) -> Variant:
	var files: Array = params.get("files", [])
	if files.is_empty():
		return {"error": {"code": -32602, "message": "Files list is required"}}

	EditorInterface.get_resource_filesystem().reimport_files(files)
	return {"success": true, "files": files, "count": files.size()}


func import_get_settings(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	# Get import metadata
	var meta_path: String = path + ".import"
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "No import settings found for: " + path}}
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null:
		return {"error": {"code": -32603, "message": "Failed to parse import settings"}}

	return {"path": path, "settings": parsed}


func import_set_settings(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var settings: Dictionary = params.get("settings", {})
	if path.is_empty():
		return {"error": {"code": -32602, "message": "Path is required"}}

	var meta_path: String = path + ".import"
	var file: FileAccess = FileAccess.open(meta_path, FileAccess.READ)
	if file == null:
		return {"error": {"code": -32603, "message": "No import settings found for: " + path}}
	var content: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(content)
	if parsed == null or not parsed is Dictionary:
		return {"error": {"code": -32603, "message": "Failed to parse existing import settings"}}

	# Merge settings
	for key in settings:
		parsed[key] = settings[key]

	var write_file: FileAccess = FileAccess.open(meta_path, FileAccess.WRITE)
	if write_file == null:
		return {"error": {"code": -32603, "message": "Failed to write import settings"}}
	write_file.store_string(JSON.stringify(parsed, "\t"))
	write_file.close()

	# Trigger reimport
	EditorInterface.get_resource_filesystem().reimport_files([path])
	return {"success": true, "path": path}


func export_run(params: Dictionary) -> Variant:
	var preset: String = params.get("preset", "")
	var output_path: String = params.get("output_path", "")
	var debug: bool = params.get("debug", false)
	if preset.is_empty():
		return {"error": {"code": -32602, "message": "Preset name is required"}}

	var preset_found := false
	var target_preset: Dictionary = {}
	for item in _load_export_presets():
		if item["name"] == preset:
			preset_found = true
			target_preset = item
			break

	if not preset_found:
		return {"error": {"code": -32602, "message": "Export preset not found: " + preset}}

	if output_path.is_empty():
		output_path = target_preset.get("export_path", "")

	if output_path.is_empty():
		return {"error": {"code": -32602, "message": "Output path is required"}}

	var export_flag: String = "--export-debug" if debug else "--export-release"
	var godot_bin: String = OS.get_executable_path()
	var args: PackedStringArray = ["--headless", export_flag, preset, output_path]

	var output: Array = []
	var exit_code: int = OS.execute(godot_bin, args, output, true)

	if exit_code != 0:
		return {
			"error": {
				"code": -32603,
				"message": "Export failed with exit code " + str(exit_code) + ": " + "\n".join(output)
			}
		}

	return {
		"success": true,
		"preset": preset,
		"output_path": output_path,
		"debug": debug,
		"cli_output": output
	}


func export_get_presets(_params: Dictionary) -> Variant:
	return {"presets": _load_export_presets()}


func _load_export_presets() -> Array:
	var config := ConfigFile.new()
	if config.load("res://export_presets.cfg") != OK:
		return []
	var presets: Array = []
	for section in config.get_sections():
		if section.begins_with("preset.") and not section.contains(".options"):
			presets.append({
				"name": config.get_value(section, "name", ""),
				"platform": config.get_value(section, "platform", ""),
				"export_path": config.get_value(section, "export_path", ""),
			})
	return presets
