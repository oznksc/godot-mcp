@tool
extends Node

const NodeUtils = preload("res://addons/godot_mcp/core/node_utils.gd")
const UndoRedoHelper = preload("res://addons/godot_mcp/core/undo_redo_helper.gd")


func ui_create_control(params: Dictionary) -> Variant:
	var type: String = params.get("type", "Button")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	var node: Node
	match type:
		"Button":
			node = Button.new()
		"Label":
			node = Label.new()
		"LineEdit":
			node = LineEdit.new()
		"TextEdit":
			node = TextEdit.new()
		"ProgressBar":
			node = ProgressBar.new()
		"TextureRect":
			node = TextureRect.new()
		"CheckBox":
			node = CheckBox.new()
		"OptionButton":
			node = OptionButton.new()
		"RichTextLabel":
			node = RichTextLabel.new()
		"Panel":
			node = Panel.new()
		"PanelContainer":
			node = PanelContainer.new()
		_:
			if ClassDB.class_exists(type):
				node = ClassDB.instantiate(type)
			else:
				return {"error": {"code": -32602, "message": "Unknown control type: " + type}}

	node.name = node_name
	UndoRedoHelper.add_node(parent, node, node_name)
	return {"success": true, "node": node_name, "type": type}


func ui_create_container(params: Dictionary) -> Variant:
	var type: String = params.get("type", "VBoxContainer")
	var node_name: String = params.get("name", type)
	var parent_path: String = params.get("parent", "")
	var columns: int = params.get("columns", 1)
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var parent: Node = root
	if not parent_path.is_empty():
		parent = root.get_node_or_null(parent_path)
		if parent == null:
			return {"error": {"code": -32602, "message": "Parent not found: " + parent_path}}

	var node: Node
	match type:
		"HBoxContainer":
			node = HBoxContainer.new()
		"VBoxContainer":
			node = VBoxContainer.new()
		"GridContainer":
			node = GridContainer.new()
			node.columns = columns
		"FlowContainer":
			node = FlowContainer.new()
		"CenterContainer":
			node = CenterContainer.new()
		"ScrollContainer":
			node = ScrollContainer.new()
		_:
			return {"error": {"code": -32602, "message": "Unknown container type: " + type}}

	node.name = node_name
	UndoRedoHelper.add_node(parent, node, node_name)
	return {"success": true, "node": node_name, "type": type}


func ui_set_anchors(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var preset: String = params.get("preset", "FullRect")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null or not node is Control:
		return {"error": {"code": -32602, "message": "Control node not found: " + path}}

	match preset:
		"FullRect":
			node.set_anchors_preset(Control.PRESET_FULL_RECT)
		"TopLeft":
			node.set_anchors_preset(Control.PRESET_TOP_LEFT)
		"TopRight":
			node.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		"BottomLeft":
			node.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		"BottomRight":
			node.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		"Center":
			node.set_anchors_preset(Control.PRESET_CENTER)
		"CenterLeft":
			node.set_anchors_preset(Control.PRESET_CENTER_LEFT)
		"CenterRight":
			node.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
		"TopCenter":
			node.set_anchors_preset(Control.PRESET_CENTER_TOP)
		"BottomCenter":
			node.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
		"LeftWide":
			node.set_anchors_preset(Control.PRESET_LEFT_WIDE)
		"RightWide":
			node.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
		"TopWide":
			node.set_anchors_preset(Control.PRESET_TOP_WIDE)
		"BottomWide":
			node.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		"VCenterWide":
			node.set_anchors_preset(Control.PRESET_VCENTER_WIDE)
		"HCenterWide":
			node.set_anchors_preset(Control.PRESET_HCENTER_WIDE)

	# Apply custom offsets if provided
	if params.has("offset_left"):
		node.offset_left = params["offset_left"]
	if params.has("offset_top"):
		node.offset_top = params["offset_top"]
	if params.has("offset_right"):
		node.offset_right = params["offset_right"]
	if params.has("offset_bottom"):
		node.offset_bottom = params["offset_bottom"]

	return {"success": true, "node": path, "preset": preset}


func ui_set_theme(params: Dictionary) -> Variant:
	var path: String = params.get("path", "")
	var theme_path: String = params.get("theme_path", "")
	var root: Node = NodeUtils.get_scene_root()
	if root == null:
		return {"error": {"code": -32602, "message": "No scene is currently open"}}

	var node: Node = root.get_node_or_null(path)
	if node == null or not node is Control:
		return {"error": {"code": -32602, "message": "Control node not found: " + path}}

	var theme: Theme = ResourceLoader.load(theme_path)
	if theme == null:
		return {"error": {"code": -32603, "message": "Failed to load theme: " + theme_path}}

	node.theme = theme
	return {"success": true, "node": path, "theme": theme_path}
