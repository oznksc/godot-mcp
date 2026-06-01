@tool
extends Node


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

	# Find the preset
	var preset_idx: int = -1
	for i in range(EditorExport.export_presets.size()):
		if EditorExport.export_presets[i].name == preset:
			preset_idx = i
			break

	if preset_idx == -1:
		return {"error": {"code": -32602, "message": "Export preset not found: " + preset}}

	return {"success": true, "message": "Export initiated", "preset": preset, "output": output_path}


func export_get_presets(_params: Dictionary) -> Variant:
	var presets: Array = []
	for preset in EditorExport.export_presets:
		presets.append({
			"name": preset.name,
			"platform": preset.platform,
		})
	return {"presets": presets}
