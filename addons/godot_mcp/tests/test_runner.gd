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
	_test_project_and_input_commands()
	_test_runtime_companion_auth_and_transactions()


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
	print("\n[Phase 5] Testing TransactionManager Atomic Rollback & Dry Run...")
	var TxClass = load("res://addons/godot_mcp/core/transaction_manager.gd")
	var tx = TxClass.new()
	root.add_child(tx)

	# 1. Test basic begin / commit
	var begin_res = tx.begin_transaction({"name": "Test Tx", "dry_run": false})
	_assert_true(begin_res.get("success", false), "Begin transaction")
	_assert_true(tx.is_active(), "Transaction is active")

	var tx_id = begin_res.get("transaction_id", "")
	var commit_res = tx.commit_transaction({"transaction_id": tx_id})
	_assert_true(commit_res.get("success", false), "Commit transaction")
	_assert_true(not tx.is_active(), "Transaction is inactive after commit")

	# 2. Test REAL Rollback of created and modified files
	var test_file_path: String = "res://_test_rollback_target.tmp"
	var rollback_begin = tx.begin_transaction({"name": "Rollback Test", "dry_run": false})
	_assert_true(rollback_begin.get("success", false), "Begin rollback transaction")

	# Create file under transaction
	var f := FileAccess.open(test_file_path, FileAccess.WRITE)
	f.store_string("initial test content")
	f.close()
	tx.record_file_create(test_file_path)
	_assert_true(FileAccess.file_exists(test_file_path), "File created on disk before rollback")

	# Rollback transaction
	var rb_res = tx.rollback_transaction({"transaction_id": rollback_begin.get("transaction_id")})
	_assert_true(rb_res.get("success", false), "Rollback executed")
	_assert_true(not FileAccess.file_exists(test_file_path), "Created file deleted by rollback")
	_assert_true(not tx.is_active(), "Transaction inactive after rollback")

	# 3. Test Dry Run Simulation
	var dry_begin = tx.begin_transaction({"name": "Dry Run Test", "dry_run": true})
	_assert_true(tx.is_dry_run(), "Transaction is in dry_run mode")
	tx.commit_transaction({"transaction_id": dry_begin.get("transaction_id")})

	tx.queue_free()


func _test_command_router_dispatch() -> void:
	print("\n[Phase 6] Testing CommandRouter Dispatch & System Handshake...")
	var RouterClass = load("res://addons/godot_mcp/core/command_router.gd")
	var router = RouterClass.new()
	router.setup(null)
	root.add_child(router)

	var SessionClass = load("res://addons/godot_mcp/core/session_auth.gd")
	var valid_token = SessionClass.get_session_token()

	# 1. Test unauthorized handshake (without token)
	var unauth_msg = JSON.stringify({
		"id": "unauth_1",
		"method": "system_handshake",
		"params": {"protocol_version": "2.0.0"}
	})
	var unauth_resp = router.execute(unauth_msg)
	_assert_true(unauth_resp.has("error"), "Unauthorized handshake rejected")

	# 2. Test authorized handshake (with valid token)
	var auth_msg = JSON.stringify({
		"id": "auth_1",
		"method": "system_handshake",
		"params": {
			"protocol_version": "2.0.0",
			"session_token": valid_token
		}
	})
	var auth_resp = router.execute(auth_msg)
	_assert_true(auth_resp.has("result"), "Authorized handshake accepted")
	if auth_resp.has("result"):
		var res_dict = auth_resp["result"]
		_assert_true(res_dict.get("protocol_version") == "2.0.0", "Handshake returned protocol 2.0.0")
		_assert_true(res_dict.get("authenticated") == true, "Handshake authenticated flag is true")
		_assert_true(not res_dict.has("session_token"), "Handshake does NOT leak session token in response")

	router.queue_free()


func _test_project_and_input_commands() -> void:
	print("\n[Phase 7] Testing Input Map & Command Sandbox Integrity...")
	var ProjectCmdClass = load("res://addons/godot_mcp/commands/project_commands.gd")
	var project_cmd = ProjectCmdClass.new()
	root.add_child(project_cmd)

	# 1. Configure input map action
	var conf_res = project_cmd.project_configure_input_map({
		"action": "test_mcp_fire",
		"deadzone": 0.3,
		"replace": true,
		"events": [
			{"type": "key", "keycode": KEY_SPACE},
			{"type": "mouse", "button_index": MOUSE_BUTTON_LEFT}
		]
	})
	_assert_true(conf_res.get("success", false), "Configure input map action 'test_mcp_fire'")
	_assert_true(conf_res.get("events_count", 0) == 2, "Events count configured is 2")

	# 2. Get input map
	var get_res = project_cmd.project_get_input_map({})
	var imap = get_res.get("input_map", {})
	_assert_true(imap.has("test_mcp_fire"), "Input map contains 'test_mcp_fire'")
	if imap.has("test_mcp_fire"):
		var act_info = imap["test_mcp_fire"]
		_assert_true(act_info.get("events", []).size() >= 2, "Action 'test_mcp_fire' has at least 2 events")

	# 3. Autoload sandbox validation
	var bad_autoload = project_cmd.project_setup_autoload({
		"name": "BadAutoload",
		"path": "res://../../etc/passwd"
	})
	_assert_true(bad_autoload.has("error"), "Autoload blocked traversal path")

	# Clean up input action
	if InputMap.has_action("test_mcp_fire"):
		InputMap.erase_action("test_mcp_fire")
	ProjectSettings.set_setting("input/test_mcp_fire", null)
	ProjectSettings.save()
	project_cmd.queue_free()

	# 4. Resource Sandbox validation
	var ResCmdClass = load("res://addons/godot_mcp/commands/resource_commands.gd")
	var res_cmd = ResCmdClass.new()
	root.add_child(res_cmd)
	var bad_res = res_cmd.resource_get_info({"path": "res://../../etc/shadow"})
	_assert_true(bad_res.has("error"), "Resource command blocked traversal path")
	res_cmd.queue_free()

	# 5. Shader Sandbox validation
	var ShaderCmdClass = load("res://addons/godot_mcp/commands/shader_commands.gd")
	var shader_cmd = ShaderCmdClass.new()
	root.add_child(shader_cmd)
	var bad_shader = shader_cmd.shader_create({"path": "/tmp/malicious.gdshader"})
	_assert_true(bad_shader.has("error"), "Shader command blocked outside path")
	shader_cmd.queue_free()


func _test_runtime_companion_auth_and_transactions() -> void:
	print("\n[Phase 8] Testing Runtime Companion Auth, Viewport Typing & Expanded Transactions...")
	var SessionClass = load("res://addons/godot_mcp/core/session_auth.gd")
	var valid_token = SessionClass.get_session_token()

	# 1. Viewport type safety test
	var ViewportCmdClass = load("res://addons/godot_mcp/commands/viewport_commands.gd")
	var vp_cmd = ViewportCmdClass.new()
	root.add_child(vp_cmd)
	var vp_res = vp_cmd.viewport_capture_editor({})
	_assert_true(vp_res is Dictionary, "Viewport capture editor returns valid Dictionary (no type mismatch)")
	vp_cmd.queue_free()

	# 2. Expanded Transaction Manager Dry Run & Rollback on Resources and Shaders
	var TxClass = load("res://addons/godot_mcp/core/transaction_manager.gd")
	var tx = TxClass.new()
	root.add_child(tx)

	var ResCmdClass = load("res://addons/godot_mcp/commands/resource_commands.gd")
	var res_cmd = ResCmdClass.new()
	res_cmd.setup(tx)
	root.add_child(res_cmd)

	var ShaderCmdClass = load("res://addons/godot_mcp/commands/shader_commands.gd")
	var shader_cmd = ShaderCmdClass.new()
	shader_cmd.setup(tx)
	root.add_child(shader_cmd)

	# Start dry run transaction
	var dry_tx = tx.begin_transaction({"name": "Multi-module Dry Run", "dry_run": true})
	var dry_path_res: String = "res://_dry_test.tres"
	var dry_path_shader: String = "res://_dry_test.gdshader"

	var r_res = res_cmd.resource_create({"type": "Resource", "path": dry_path_res})
	_assert_true(r_res.get("dry_run", false), "Resource creation honors dry_run")
	_assert_true(not FileAccess.file_exists(dry_path_res), "Resource not written to disk during dry_run")

	var s_res = shader_cmd.shader_create({"path": dry_path_shader})
	_assert_true(s_res.get("dry_run", false), "Shader creation honors dry_run")
	_assert_true(not FileAccess.file_exists(dry_path_shader), "Shader not written to disk during dry_run")

	tx.commit_transaction({"transaction_id": dry_tx.get("transaction_id")})

	# 3. Real Rollback of Shader Creation
	var real_tx = tx.begin_transaction({"name": "Shader Rollback", "dry_run": false})
	var real_shader_path: String = "res://_rollback_test.gdshader"
	var create_res = shader_cmd.shader_create({"path": real_shader_path, "content": "shader_type spatial;"})
	_assert_true(create_res.get("success", false), "Shader created under active transaction")
	_assert_true(FileAccess.file_exists(real_shader_path), "Shader file exists on disk before rollback")

	tx.rollback_transaction({"transaction_id": real_tx.get("transaction_id")})
	_assert_true(not FileAccess.file_exists(real_shader_path), "Shader file deleted by atomic rollback")

	res_cmd.queue_free()
	shader_cmd.queue_free()
	tx.queue_free()


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
