@tool
extends RefCounted
class_name CompatHelper

## Compatibility layer across Godot 4.4 – 4.8+
## Provides engine capability detection, version negotiation, and API abstractions.

const PROTOCOL_VERSION := "2.0.0"


static func get_godot_version() -> Dictionary:
	var info: Dictionary = Engine.get_version_info()
	return {
		"major": info.get("major", 4),
		"minor": info.get("minor", 0),
		"patch": info.get("patch", 0),
		"status": info.get("status", "unknown"),
		"build": info.get("build", "official"),
		"string": info.get("string", "4.x"),
		"mono": ClassDB.class_exists("CSharpScript"),
	}


static func is_version_at_least(req_major: int, req_minor: int, req_patch: int = 0) -> bool:
	var info: Dictionary = Engine.get_version_info()
	var cur_major: int = info.get("major", 0)
	var cur_minor: int = info.get("minor", 0)
	var cur_patch: int = info.get("patch", 0)

	if cur_major > req_major:
		return true
	if cur_major < req_major:
		return false
	if cur_minor > req_minor:
		return true
	if cur_minor < req_minor:
		return false
	return cur_patch >= req_patch


static func get_capabilities() -> Array:
	var caps: Array = [
		"viewport_capture",
		"input_simulation",
		"playtest_runner",
		"remote_debugger",
		"transaction_manager",
		"script_diagnostics",
		"undo_redo_manager",
		"sandbox_enforcement"
	]

	if ClassDB.class_exists("CSharpScript"):
		caps.append("mono_csharp")

	if is_version_at_least(4, 4):
		caps.append("godot_4_4_plus")

	if is_version_at_least(4, 7):
		caps.append("godot_4_7_plus")

	return caps


static func get_handshake_payload(session_token: String = "") -> Dictionary:
	return {
		"protocol_version": PROTOCOL_VERSION,
		"engine": get_godot_version(),
		"capabilities": get_capabilities(),
		"project_name": ProjectSettings.get_setting("application/config/name", "Godot Project"),
		"session_token": session_token,
		"os": OS.get_name(),
		"editor_pid": OS.get_process_id(),
	}
