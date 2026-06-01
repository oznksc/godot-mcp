@tool
extends Control

var _connected: bool = false
var _status_label: Label
var _dot_label: Label


func _ready() -> void:
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.name = "StatusHBox"
	add_child(hbox)

	_dot_label = Label.new()
	_dot_label.name = "Dot"
	_dot_label.text = "●"
	_dot_label.add_theme_color_override("font_color", Color.RED)
	hbox.add_child(_dot_label)

	_status_label = Label.new()
	_status_label.name = "StatusText"
	_status_label.text = "Disconnected"
	hbox.add_child(_status_label)


func set_connected(connected: bool) -> void:
	_connected = connected
	if _connected:
		_dot_label.add_theme_color_override("font_color", Color.GREEN)
		_status_label.text = "Connected"
	else:
		_dot_label.add_theme_color_override("font_color", Color.RED)
		_status_label.text = "Disconnected"
