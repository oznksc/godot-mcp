@tool
extends Node
class_name TransactionManager

## Manages atomic multi-step operations and rollbacks.
## Integrates with EditorUndoRedoManager and maintains file-level backups for zero-risk changes.

var _active_transaction: Dictionary = {}
var _undo_redo: EditorUndoRedoManager


func _ready() -> void:
	if Engine.is_editor_hint():
		_undo_redo = EditorInterface.get_editor_undo_redo()


func begin_transaction(params: Dictionary) -> Dictionary:
	if not _active_transaction.is_empty():
		return {
			"error": {
				"code": -32001,
				"message": "A transaction is already active: " + _active_transaction.get("id", "")
			}
		}

	var tx_id: String = "tx_" + str(Time.get_unix_time_from_system()).replace(".", "_") + "_" + str(randi() % 10000)
	var tx_name: String = params.get("name", "MCP Atomic Operation")
	var dry_run: bool = params.get("dry_run", false)

	_active_transaction = {
		"id": tx_id,
		"name": tx_name,
		"dry_run": dry_run,
		"started_at": Time.get_datetime_string_from_system(),
		"file_backups": {},       # path -> original_content
		"created_files": [],      # [path]
		"actions": [],            # [{ action: "...", details: {...} }]
		"undo_action_created": false
	}

	if _undo_redo and not dry_run:
		_undo_redo.create_action(tx_name)
		_active_transaction["undo_action_created"] = true

	return {
		"success": true,
		"transaction_id": tx_id,
		"name": tx_name,
		"dry_run": dry_run
	}


func is_active() -> bool:
	return not _active_transaction.is_empty()


func is_dry_run() -> bool:
	return _active_transaction.get("dry_run", false)


func get_active_id() -> String:
	return _active_transaction.get("id", "")


func record_file_modify(path: String) -> void:
	if _active_transaction.is_empty():
		return

	var backups: Dictionary = _active_transaction.get("file_backups", {})
	if not backups.has(path) and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			backups[path] = file.get_as_text()
			file.close()

	_active_transaction["actions"].append({
		"type": "modify_file",
		"path": path,
		"timestamp": Time.get_datetime_string_from_system()
	})


func record_file_create(path: String) -> void:
	if _active_transaction.is_empty():
		return

	var created: Array = _active_transaction.get("created_files", [])
	if not created.has(path):
		created.append(path)

	_active_transaction["actions"].append({
		"type": "create_file",
		"path": path,
		"timestamp": Time.get_datetime_string_from_system()
	})


func record_node_action(action_type: String, details: Dictionary) -> void:
	if _active_transaction.is_empty():
		return
	_active_transaction["actions"].append({
		"type": action_type,
		"details": details,
		"timestamp": Time.get_datetime_string_from_system()
	})


func commit_transaction(params: Dictionary) -> Dictionary:
	var tx_id: String = params.get("transaction_id", "")
	if _active_transaction.is_empty() or (_active_transaction.get("id", "") != tx_id and not tx_id.is_empty()):
		return {"error": {"code": -32002, "message": "No matching active transaction found"}}

	var summary: Dictionary = {
		"transaction_id": _active_transaction["id"],
		"name": _active_transaction["name"],
		"dry_run": _active_transaction["dry_run"],
		"actions_count": _active_transaction["actions"].size(),
		"actions": _active_transaction["actions"]
	}

	if _active_transaction.get("undo_action_created", false) and _undo_redo:
		_undo_redo.commit_action()

	_active_transaction.clear()
	return {"success": true, "summary": summary}


func rollback_transaction(params: Dictionary) -> Dictionary:
	var tx_id: String = params.get("transaction_id", "")
	if _active_transaction.is_empty():
		return {"error": {"code": -32002, "message": "No active transaction to rollback"}}

	if not tx_id.is_empty() and _active_transaction.get("id", "") != tx_id:
		return {"error": {"code": -32002, "message": "Transaction ID mismatch"}}

	var restored_files: Array = []
	var deleted_files: Array = []

	# Restore modified files
	var backups: Dictionary = _active_transaction.get("file_backups", {})
	for path in backups:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file:
			file.store_string(backups[path])
			file.close()
			restored_files.append(path)

	# Delete files that were newly created in this transaction
	var created: Array = _active_transaction.get("created_files", [])
	var dir := DirAccess.open("res://")
	if dir:
		for path in created:
			if FileAccess.file_exists(path):
				dir.remove(path)
				deleted_files.append(path)

	# If UndoRedo action was created and not yet committed, discard it by aborting or undo
	if _active_transaction.get("undo_action_created", false) and _undo_redo:
		# Committing an empty/aborted action or undo
		_undo_redo.commit_action(false)

	if EditorInterface.get_resource_filesystem():
		EditorInterface.get_resource_filesystem().scan()

	var rolled_back_id: String = _active_transaction["id"]
	_active_transaction.clear()

	return {
		"success": true,
		"rolled_back_transaction": rolled_back_id,
		"restored_files": restored_files,
		"deleted_created_files": deleted_files
	}


func get_status(_params: Dictionary = {}) -> Dictionary:
	if _active_transaction.is_empty():
		return {"active": false}
	return {
		"active": true,
		"transaction_id": _active_transaction["id"],
		"name": _active_transaction["name"],
		"dry_run": _active_transaction["dry_run"],
		"actions_count": _active_transaction["actions"].size(),
		"actions": _active_transaction["actions"]
	}
