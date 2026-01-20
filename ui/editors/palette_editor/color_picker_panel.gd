## ColorPickerPanel - HSV color picker with hex input
class_name ColorPickerPanel
extends Control


signal color_changed(color: Color)


var _picker: ColorPicker
var _current_color: Color = Color.WHITE


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var label := Label.new()
	label.text = "Color Picker"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	_picker = ColorPicker.new()
	_picker.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_picker.color_changed.connect(_on_color_changed)
	vbox.add_child(_picker)


func set_color(color: Color) -> void:
	_current_color = color
	_picker.color = color


func get_color() -> Color:
	return _current_color


func _on_color_changed(color: Color) -> void:
	_current_color = color
	color_changed.emit(color)
