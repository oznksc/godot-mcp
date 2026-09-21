@tool
extends RefCounted
class_name PathSandbox

## PathSandbox guarantees that all file and resource access remains within the Godot project.
## Prevents directory traversal attacks (e.g. res://../../) and access to sensitive OS files.

static func validate_path(path: String, allow_user: bool = false) -> Dictionary:
	if path.is_empty():
		return {"valid": false, "error": "Path cannot be empty"}

	var clean_path: String = path.strip_edges().replace("\\", "/")

	# Must begin with res:// or optionally user://
	var is_res: bool = clean_path.begins_with("res://")
	var is_user: bool = allow_user and clean_path.begins_with("user://")

	if not is_res and not is_user:
		# If relative without scheme, default prefixing to res://
		if not clean_path.begins_with("/") and not clean_path.contains("://"):
			clean_path = "res://" + clean_path
			is_res = true
		else:
			return {"valid": false, "error": "Access denied: path must be within res://" + (" or user://" if allow_user else "")}

	# Check for directory traversal sequences
	var parts: PackedStringArray = clean_path.split("/")
	var depth: int = 0
	for part in parts:
		if part == "..":
			depth -= 1
			if depth < 0:
				return {"valid": false, "error": "Access denied: directory traversal ('..') outside project boundary"}
		elif not part.is_empty() and part != "." and part != "res:" and part != "user:":
			depth += 1

	# Canonicalize global path check
	var global_path: String = ProjectSettings.globalize_path(clean_path).replace("\\", "/")
	var project_root: String = ProjectSettings.globalize_path("res://").replace("\\", "/")
	if not project_root.ends_with("/"):
		project_root += "/"

	if is_res and not global_path.begins_with(project_root) and global_path != project_root.trim_suffix("/"):
		return {"valid": false, "error": "Access denied: resolved path escapes project root: " + clean_path}

	return {"valid": true, "path": clean_path, "global_path": global_path}


static func is_path_safe(path: String, allow_user: bool = false) -> bool:
	var result: Dictionary = validate_path(path, allow_user)
	return result.get("valid", false)
