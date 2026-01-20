## ItemPartList - List of parts in current item
class_name ItemPartList
extends Control


signal part_selected(part: ItemPartData)
signal part_deleted(part: ItemPartData)


## State
var _parts: Array[ItemPartData] = []
var _selected_index: int = -1
var _items: Array[Button] = []


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var header := HBoxContainer.new()

	var label := Label.new()
	label.text = "Parts"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)

	var add_btn := Button.new()
	add_btn.text = "+"
	add_btn.custom_minimum_size = Vector2(30, 30)
	header.add_child(add_btn)

	vbox.add_child(header)

	# Scroll container for list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)


func set_parts(parts: Array[ItemPartData]) -> void:
	_parts = parts
	_rebuild_list()


func _rebuild_list() -> void:
	# Clear existing items
	for item in _items:
		item.queue_free()
	_items.clear()

	# Find scroll container's child vbox
	var scroll := get_node_or_null("VBoxContainer/ScrollContainer")
	if not scroll:
		return

	var list_vbox := scroll.get_node_or_null("ListVBox")
	if not list_vbox:
		list_vbox = VBoxContainer.new()
		list_vbox.name = "ListVBox"
		scroll.add_child(list_vbox)

	# Clear list vbox
	for child in list_vbox.get_children():
		child.queue_free()

	# Create items
	for i in range(_parts.size()):
		var part := _parts[i]
		var item := _create_part_item(part, i)
		list_vbox.add_child(item)
		_items.append(item)


func _create_part_item(part: ItemPartData, index: int) -> Button:
	var button := Button.new()
	button.text = "%d. %s" % [index + 1, ItemPartData.ShapeType.keys()[part.shape]]
	button.toggle_mode = true
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	button.toggled.connect(_on_item_toggled.bind(index))

	# Context menu on right click
	button.gui_input.connect(_on_item_input.bind(index))

	return button


func _on_item_toggled(pressed: bool, index: int) -> void:
	if pressed:
		_selected_index = index

		# Deselect others
		for i in range(_items.size()):
			if i != index:
				_items[i].button_pressed = false

		if index >= 0 and index < _parts.size():
			part_selected.emit(_parts[index])


func _on_item_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if index >= 0 and index < _parts.size():
				part_deleted.emit(_parts[index])


func select_part(part: ItemPartData) -> void:
	var index := _parts.find(part)
	if index >= 0 and index < _items.size():
		_items[index].button_pressed = true
		_selected_index = index
