## KeyframePropertiesPanel - Property editor for selected keyframe
class_name KeyframePropertiesPanel
extends Control


signal property_changed(property: String, value: Variant)


var _current_keyframe: Keyframe


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "PropsVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	var label := Label.new()
	label.text = "Keyframe Properties"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)


func set_keyframe(keyframe: Keyframe) -> void:
	_current_keyframe = keyframe
	_rebuild_ui()


func clear() -> void:
	_current_keyframe = null
	_clear_ui()


func _clear_ui() -> void:
	var vbox := get_node_or_null("ScrollContainer/PropsVBox")
	if not vbox:
		return

	for i in range(vbox.get_child_count() - 1, 0, -1):
		vbox.get_child(i).queue_free()


func _rebuild_ui() -> void:
	_clear_ui()

	if not _current_keyframe:
		return

	var vbox := get_node("ScrollContainer/PropsVBox")

	# Frame (read-only)
	_add_label(vbox, "Frame: %d" % _current_keyframe.frame)

	# Position
	_add_vector3_editor(vbox, "Position", "position", _current_keyframe.position)

	# Rotation
	_add_vector3_editor(vbox, "Rotation (deg)", "rotation",
		Vector3(
			rad_to_deg(_current_keyframe.rotation.x),
			rad_to_deg(_current_keyframe.rotation.y),
			rad_to_deg(_current_keyframe.rotation.z)
		)
	)

	# Scale
	_add_vector3_editor(vbox, "Scale", "scale", _current_keyframe.scale)

	# Easing
	_add_easing_editor(vbox)


func _add_label(parent: Control, text: String) -> void:
	var label := Label.new()
	label.text = text
	parent.add_child(label)


func _add_vector3_editor(parent: Control, label_text: String, property: String, value: Vector3) -> void:
	var label := Label.new()
	label.text = label_text
	parent.add_child(label)

	var hbox := HBoxContainer.new()

	for i in range(3):
		var axis := ["X", "Y", "Z"][i]
		var spinbox := SpinBox.new()
		spinbox.min_value = -100
		spinbox.max_value = 100
		spinbox.step = 0.01
		spinbox.value = value[i]
		spinbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spinbox.prefix = axis + ":"

		var prop := property
		var axis_idx := i
		spinbox.value_changed.connect(func(val):
			_on_vector3_changed(val, prop, axis_idx)
		)

		hbox.add_child(spinbox)

	parent.add_child(hbox)


func _add_easing_editor(parent: Control) -> void:
	var hbox := HBoxContainer.new()

	var label := Label.new()
	label.text = "Easing:"
	label.custom_minimum_size.x = 60
	hbox.add_child(label)

	var option := OptionButton.new()
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for ease_type in Keyframe.EasingType.values():
		option.add_item(Keyframe.EasingType.keys()[ease_type])

	option.select(_current_keyframe.easing)
	option.item_selected.connect(_on_easing_changed)
	hbox.add_child(option)

	parent.add_child(hbox)


func _on_vector3_changed(value: float, property: String, axis: int) -> void:
	if not _current_keyframe:
		return

	var current: Vector3 = _current_keyframe.get(property)

	# Convert rotation back to radians
	if property == "rotation":
		value = deg_to_rad(value)

	current[axis] = value
	property_changed.emit(property, current)


func _on_easing_changed(index: int) -> void:
	property_changed.emit("easing", index as Keyframe.EasingType)
