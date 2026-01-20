## AnimationListPanel - List of animations for selection
class_name AnimationListPanel
extends Control


signal animation_selected(animation: CharacterAnimation)
signal new_animation_requested()


var _animations: Array[CharacterAnimation] = []
var _buttons: Array[Button] = []


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var header := HBoxContainer.new()

	var label := Label.new()
	label.text = "Animations"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	var new_btn := Button.new()
	new_btn.text = "+"
	new_btn.custom_minimum_size = Vector2(30, 30)
	new_btn.pressed.connect(func(): new_animation_requested.emit())
	header.add_child(new_btn)

	vbox.add_child(header)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "AnimList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)


func set_animations(animations: Array[CharacterAnimation]) -> void:
	_animations = animations
	_rebuild_list()


func add_animation(animation: CharacterAnimation) -> void:
	_animations.append(animation)
	_rebuild_list()


func _rebuild_list() -> void:
	var list := get_node_or_null("VBoxContainer/ScrollContainer/AnimList")
	if not list:
		return

	for child in list.get_children():
		child.queue_free()
	_buttons.clear()

	for anim in _animations:
		var button := Button.new()
		button.text = anim.name if anim.name else "Unnamed"
		button.toggle_mode = true
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_animation_pressed.bind(anim))
		list.add_child(button)
		_buttons.append(button)


func _on_animation_pressed(animation: CharacterAnimation) -> void:
	animation_selected.emit(animation)

	# Deselect others
	for button in _buttons:
		if button.button_pressed:
			var idx := _buttons.find(button)
			if idx >= 0 and idx < _animations.size() and _animations[idx] != animation:
				button.button_pressed = false
