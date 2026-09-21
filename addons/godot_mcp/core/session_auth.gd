@tool
extends RefCounted
class_name SessionAuth

## Handles session token generation and authentication between Godot and the MCP Server.
## Writes the session key to res://.godot/mcp_session.key on startup.

const SESSION_KEY_PATH := "res://.godot/mcp_session.key"
static var _active_session_token: String = ""
static var _auth_enabled: bool = true


static func init_session(enable_auth: bool = true) -> String:
	_auth_enabled = enable_auth
	if not _auth_enabled:
		_active_session_token = ""
		return ""

	var crypto := Crypto.new()
	var random_bytes: PackedByteArray = crypto.generate_random_bytes(32)
	_active_session_token = random_bytes.hex_encode()

	# Ensure .godot directory exists
	var dir := DirAccess.open("res://")
	if dir and not dir.dir_exists_absolute("res://.godot"):
		dir.make_dir_recursive_absolute("res://.godot")

	var file := FileAccess.open(SESSION_KEY_PATH, FileAccess.WRITE)
	if file:
		file.store_string(_active_session_token)
		file.close()

	return _active_session_token


static func get_session_token() -> String:
	if _active_session_token.is_empty() and FileAccess.file_exists(SESSION_KEY_PATH):
		var file := FileAccess.open(SESSION_KEY_PATH, FileAccess.READ)
		if file:
			_active_session_token = file.get_as_text().strip_edges()
			file.close()
	return _active_session_token


static func validate_token(token: String) -> bool:
	if not _auth_enabled:
		return true
	if _active_session_token.is_empty():
		get_session_token()
	if _active_session_token.is_empty():
		# Auth disabled or key not generated
		return true
	return token == _active_session_token
