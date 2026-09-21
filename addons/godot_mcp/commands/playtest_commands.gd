@tool
extends Node

const MCPRuntimeBridge = preload("res://addons/godot_mcp/core/mcp_runtime_bridge.gd")

## Autonomous Playtest Runner for Godot MCP v2.
## Executes scripted gameplay flows, captures frames, asserts properties, and detects errors.

var _input_commands: Node
var _viewport_commands: Node
var _debug_commands: Node


func setup(input_cmds: Node, viewport_cmds: Node, debug_cmds: Node) -> void:
	_input_commands = input_cmds
	_viewport_commands = viewport_cmds
	_debug_commands = debug_cmds


func playtest_run_flow(params: Dictionary) -> Variant:
	var scene_path: String = params.get("scene", "")
	var steps: Array = params.get("steps", [])
	var auto_stop: bool = params.get("auto_stop", true)
	var wait_initial_seconds: float = float(params.get("wait_initial_seconds", 1.0))

	# 1. Start scene if not already playing
	if not EditorInterface.is_playing_scene():
		if scene_path.is_empty():
			EditorInterface.play_main_scene()
		else:
			EditorInterface.play_custom_scene(scene_path)

	# Allow engine to spin up
	if wait_initial_seconds > 0.0:
		await get_tree().create_timer(wait_initial_seconds).timeout

	var step_results: Array = []
	var screenshots: Array = []
	var assertions: Array = []
	var all_passed: bool = true

	for i in range(steps.size()):
		var step: Dictionary = steps[i]
		var step_type: String = step.get("type", "wait").to_lower()
		var step_record: Dictionary = {"index": i, "type": step_type, "status": "ok"}

		match step_type:
			"wait":
				var seconds: float = float(step.get("seconds", 1.0))
				await get_tree().create_timer(seconds).timeout
				step_record["duration"] = seconds

			"key":
				var key: String = step.get("key", "")
				var duration: float = float(step.get("duration", 0.1))
				_input_commands.input_simulate_key({"key": key, "pressed": true})
				if duration > 0.0:
					await get_tree().create_timer(duration).timeout
				_input_commands.input_simulate_key({"key": key, "pressed": false})
				step_record["key"] = key
				step_record["duration"] = duration

			"action":
				var action: String = step.get("action", "")
				var duration: float = float(step.get("duration", 0.1))
				var strength: float = float(step.get("strength", 1.0))
				_input_commands.input_simulate_action({"action": action, "pressed": true, "strength": strength})
				if duration > 0.0:
					await get_tree().create_timer(duration).timeout
				_input_commands.input_simulate_action({"action": action, "pressed": false})
				step_record["action"] = action
				step_record["duration"] = duration

			"mouse":
				var action_m: String = step.get("action", "click")
				var pos: Array = step.get("position", [0.0, 0.0])
				_input_commands.input_simulate_mouse({"action": action_m, "position": pos})
				step_record["position"] = pos

			"screenshot":
				var tag: String = step.get("tag", "step_" + str(i))
				var cap: Variant = _viewport_commands.viewport_capture_game({})
				if cap is Dictionary and cap.has("base64"):
					screenshots.append({"tag": tag, "data": cap["base64"], "width": cap.get("width"), "height": cap.get("height")})
					step_record["screenshot_tag"] = tag
				else:
					step_record["status"] = "screenshot_failed"

			"assert_node":
				var node_path: String = step.get("node_path", "")
				var property: String = step.get("property", "")
				var expected = step.get("expected", null)

				var pass_check := false
				var actual_val = null

				if EditorInterface.is_playing_scene():
					var rt_props: Dictionary = MCPRuntimeBridge.query_runtime("get_node_properties", {"path": node_path})
					if rt_props.has("properties") and rt_props["properties"].has(property):
						actual_val = rt_props["properties"][property]

				if actual_val == null:
					var root: Node = get_tree().root
					var target_node: Node = root.get_node_or_null(node_path) if root else null
					if target_node:
						actual_val = target_node.get(property)

				if actual_val != null:
					if step.has("expected"):
						pass_check = (actual_val == expected)
					elif step.has("min"):
						pass_check = (float(actual_val) >= float(step["min"]))
					elif step.has("max"):
						pass_check = (float(actual_val) <= float(step["max"]))
					else:
						pass_check = true
				else:
					pass_check = false

				if not pass_check:
					all_passed = false

				var assertion_entry := {
					"step": i,
					"node_path": node_path,
					"property": property,
					"passed": pass_check,
					"actual": str(actual_val),
					"expected": str(expected) if expected != null else ""
				}
				assertions.append(assertion_entry)
				step_record["assertion"] = assertion_entry

		step_results.append(step_record)

	# Check for errors during playtest
	var error_report: Variant = _debug_commands.debug_get_errors({"limit": 20})
	var error_list: Array = []
	if error_report is Dictionary and error_report.has("errors"):
		error_list = error_report["errors"]

	if auto_stop and EditorInterface.is_playing_scene():
		EditorInterface.stop_playing_scene()

	return {
		"success": true,
		"all_assertions_passed": all_passed,
		"steps_executed": step_results.size(),
		"steps": step_results,
		"screenshots_count": screenshots.size(),
		"screenshots": screenshots,
		"assertions": assertions,
		"errors_encountered": error_list
	}
