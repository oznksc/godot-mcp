@tool
extends Control

var _log_text: RichTextLabel
var _max_lines: int = 500


func _ready() -> void:
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.name = "LogVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	var toolbar: HBoxContainer = HBoxContainer.new()
	vbox.add_child(toolbar)

	var clear_btn: Button = Button.new()
	clear_btn.text = "Clear"
	clear_btn.pressed.connect(_on_clear_pressed)
	toolbar.add_child(clear_btn)

	_log_text = RichTextLabel.new()
	_log_text.name = "LogText"
	_log_text.bbcode_enabled = true
	_log_text.scroll_following = true
	_log_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_log_text)


func add_log(message: String) -> void:
	var timestamp: String = Time.get_time_string_from_system()
	_log_text.append_text("[color=gray]" + timestamp + "[/color] " + message + "\n")

	# Trim old lines
	if _log_text.get_paragraph_count() > _max_lines:
		_log_text.clear()
		_log_text.append_text("[color=gray]Log cleared (too many lines)[/color]\n")


func _on_clear_pressed() -> void:
	_log_text.clear()
