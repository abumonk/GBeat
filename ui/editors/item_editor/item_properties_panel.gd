## ItemPropertiesPanel - Property editor for selected item part
class_name ItemPropertiesPanel
extends Control


signal property_changed(property: String, value: Variant)


## State
var _current_part: ItemPartData
var _editors: Dictionary = {}


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "PropertiesVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var label := Label.new()
	label.text = "Properties"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)


func set_part(part: ItemPartData) -> void:
	_current_part = part
	_rebuild_editors()


func clear() -> void:
	_current_part = null
	_clear_editors()


func _clear_editors() -> void:
	var vbox := get_node_or_null("ScrollContainer/PropertiesVBox")
	if not vbox:
		return

	# Keep header, remove rest
	for i in range(vbox.get_child_count() - 1, 0, -1):
		vbox.get_child(i).queue_free()

	_editors.clear()


func _rebuild_editors() -> void:
	_clear_editors()

	if not _current_part:
		return

	var vbox := get_node("ScrollContainer/PropertiesVBox")

	# Shape (read-only)
	_add_label(vbox, "Shape: %s" % ItemPartData.ShapeType.keys()[_current_part.shape])

	# Size
	_add_vector3_editor(vbox, "Size", "size", _current_part.size)

	# Position
	_add_vector3_editor(vbox, "Position", "position", _current_part.position)

	# Rotation
	_add_vector3_editor(vbox, "Rotation", "rotation", _current_part.rotation)

	# Color
	_add_color_editor(vbox, "Color", "color_override", _current_part.color_override)

	# Use category color
	_add_bool_editor(vbox, "Use Category Color", "use_category_color", _current_part.use_category_color)


func _add_label(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)


func _add_vector3_editor(parent: Control, label_text: String, property: String, value: Vector3) -> void:
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)

	for i in range(3):
		var axis := ["X", "Y", "Z"][i]
		var spinbox := SpinBox.new()
		spinbox.min_value = -10
		spinbox.max_value = 10
		spinbox.step = 0.01
		spinbox.value = value[i]
		spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spinbox.prefix = axis + ":"
		spinbox.value_changed.connect(_on_vector3_changed.bind(property, i))
		hbox.add_child(spinbox)

	parent.add_child(hbox)
	_editors[property] = hbox


func _add_color_editor(parent: Control, label_text: String, property: String, value: Color) -> void:
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size.x = 80
	hbox.add_child(label)

	var picker := ColorPickerButton.new()
	picker.color = value
	picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	picker.color_changed.connect(_on_color_changed.bind(property))
	hbox.add_child(picker)

	parent.add_child(hbox)
	_editors[property] = picker


func _add_bool_editor(parent: Control, label_text: String, property: String, value: bool) -> void:
	var check := CheckButton.new()
	check.text = label_text
	check.button_pressed = value
	check.toggled.connect(_on_bool_changed.bind(property))
	parent.add_child(check)
	_editors[property] = check


func _on_vector3_changed(value: float, property: String, axis: int) -> void:
	if not _current_part:
		return

	var current: Vector3 = _current_part.get(property)
	current[axis] = value
	property_changed.emit(property, current)


func _on_color_changed(color: Color, property: String) -> void:
	property_changed.emit(property, color)


func _on_bool_changed(pressed: bool, property: String) -> void:
	property_changed.emit(property, pressed)
