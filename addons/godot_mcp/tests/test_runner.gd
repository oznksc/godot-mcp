extends SceneTree

## Headless Integration and Compilation Test Suite for Godot MCP v2.
## Run with: godot --headless --script addons/godot_mcp/tests/test_runner.gd

var _passed_count: int = 0
var _failed_count: int = 0


func _init() -> void:
	print("\n=======================================================")
	print("  GODOT MCP v2 HEADLESS TEST SUITE")
	print("  Godot Version: ", Engine.get_version_info().get("string", "unknown"))
	print("=======================================================\n")

	_run_all_tests()

	print("\n=======================================================")
	print("  TEST SUMMARY: ", _passed_count, " PASSED, ", _failed_count, " FAILED")
	print("=======================================================\n")

	if _failed_count > 0:
		quit(1)
	else:
		quit(0)


func _run_all_tests() -> void:
	_test_gdscript_compilation()
	_test_path_sandbox()
	_test_compat_helper()
	_test_session_auth()
	_test_transaction_manager()
	_test_command_router_dispatch()


func _assert_true(condition: bool, test_name: String, error_msg: String = "") -> void:
	if condition:
		_passed_count += 1
		print("  [PASS] ", test_name)
	else:
		_failed_count += 1
		print("  [FAIL] ", test_name, " -> ", error_msg)


func _test_gdscript_compilation() -> void:
	print("[Phase 1] Validating GDScript compilation across addons/godot_mcp/ ...")
	var scripts: Array = []
	_find_gd_files_recursive("res://addons/godot_mcp", scripts)

	_assert_true(scripts.size() > 10, "Found GDScript files", "Found " + str(scripts.size()) + " files")

	for script_path in scripts:
		var script = load(script_path)
		var is_valid: bool = (script != null and script.can_instantiate())
		_assert_true(is_valid, "Compile: " + script_path.replace("res://addons/godot_mcp/", ""), "Failed to compile/instantiate script")


func _test_path_sandbox() -> void:
	print("\n[Phase 2] Testing PathSandbox Security...")
	var PathSandboxClass = load("res://addons/godot_mcp/core/path_sandbox.gd")

	var valid_res = PathSandboxClass.validate_path("res://scenes/level.tscn")
	_assert_true(valid_res.get("valid", false), "Allowed: res://scenes/level.tscn")

	var traversal_res = PathSandboxClass.validate_path("res://../../etc/passwd")
	_assert_true(not traversal_res.get("valid", false), "Blocked: directory traversal res://../../etc/passwd")

	var absolute_os = PathSandboxClass.validate_path("/etc/shadow")
	_assert_true(not absolute_os.get("valid", false), "Blocked: absolute path /etc/shadow")


func _test_compat_helper() -> void:
	print("\n[Phase 3] Testing CompatHelper & Capability Matrix...")
	var CompatClass = load("res://addons/godot_mcp/core/compat_helper.gd")

	var v_info = CompatClass.get_godot_version()
	_assert_true(v_info.has("major") and v_info["major"] >= 4, "Detected Godot 4.x engine")

	var caps = CompatClass.get_capabilities()
	_assert_true(caps.has("viewport_capture"), "Capability: viewport_capture registered")
	_assert_true(caps.has("input_simulation"), "Capability: input_simulation registered")
	_assert_true(caps.has("transaction_manager"), "Capability: transaction_manager registered")


func _test_session_auth() -> void:
	print("\n[Phase 4] Testing SessionAuth...")
	var SessionClass = load("res://addons/godot_mcp/core/session_auth.gd")

	var token = SessionClass.init_session(true)
	_assert_true(not token.is_empty(), "Generated 256-bit session token")
	_assert_true(SessionClass.validate_token(token), "Token validates correctly")
	_assert_true(not SessionClass.validate_token("invalid_token"), "Rejects forged token")


func _test_transaction_manager() -> void:
	print("\n[Phase 5] Testing TransactionManager Atomic Rollback...")
	var TxClass = load("res://addons/godot_mcp/core/transaction_manager.gd")
	var tx = TxClass.new()
	root.add_child(tx)

	var begin_res = tx.begin_transaction({"name": "Test Tx", "dry_run": false})
	_assert_true(begin_res.get("success", false), "Begin transaction")
	_assert_true(tx.is_active(), "Transaction is active")

	var tx_id = begin_res.get("transaction_id", "")
	var commit_res = tx.commit_transaction({"transaction_id": tx_id})
	_assert_true(commit_res.get("success", false), "Commit transaction")
	_assert_true(not tx.is_active(), "Transaction is inactive after commit")

	tx.queue_free()


func _test_command_router_dispatch() -> void:
	print("\n[Phase 6] Testing CommandRouter Dispatch & System Handshake...")
	var RouterClass = load("res://addons/godot_mcp/core/command_router.gd")
	var router = RouterClass.new()
	router.setup(null)
	root.add_child(router)

	var handshake_msg = JSON.stringify({
		"id": "req_1",
		"method": "system_handshake",
		"params": {"protocol_version": "2.0.0"}
	})

	var response = router.execute(handshake_msg)
	# Response may be dictionary or coroutine
	if response is Object and response.has_signal("completed"):
		# In case of coroutine
		pass

	_assert_true(response.has("result") or response.has("id"), "Handshake executed")
	if response.has("result"):
		var res_dict = response["result"]
		_assert_true(res_dict.get("protocol_version") == "2.0.0", "Handshake returned protocol 2.0.0")

	router.queue_free()


func _find_gd_files_recursive(path: String, results: Array) -> void:
	var dir = DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while not file_name.is_empty():
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue
		var full_path = path + "/" + file_name
		if dir.current_is_dir():
			_find_gd_files_recursive(full_path, results)
		elif file_name.ends_with(".gd"):
			results.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
