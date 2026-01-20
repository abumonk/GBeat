## BoneSelector - List of selectable bones for animation
class_name BoneSelector
extends Control


signal bone_selected(bone: String)


## State
var _bones: Array[String] = []
var _selected_bone: String = ""
var _buttons: Dictionary = {}


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var label := Label.new()
	label.text = "Bones"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "BoneList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)


func set_bones(bones: Array[String]) -> void:
	_bones = bones
	_rebuild_list()


func _rebuild_list() -> void:
	var list := get_node("VBoxContainer/ScrollContainer/BoneList")
	if not list:
		return

	# Clear
	for child in list.get_children():
		child.queue_free()
	_buttons.clear()

	# Create buttons
	for bone in _bones:
		var button := Button.new()
		button.text = bone
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.button_pressed = (bone == _selected_bone)
		button.toggled.connect(_on_bone_toggled.bind(bone))
		list.add_child(button)
		_buttons[bone] = button


func _on_bone_toggled(pressed: bool, bone: String) -> void:
	if pressed:
		_selected_bone = bone
		bone_selected.emit(bone)

		# Deselect others
		for other_bone in _buttons:
			if other_bone != bone:
				_buttons[other_bone].button_pressed = false


func select_bone(bone: String) -> void:
	if _buttons.has(bone):
		_buttons[bone].button_pressed = true
		_selected_bone = bone
