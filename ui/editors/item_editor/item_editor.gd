## ItemEditor - Visual editor for creating character items
class_name ItemEditor
extends Control


signal item_saved(item: ItemDefinition)
signal item_loaded(item: ItemDefinition)


## Configuration
@export var preview_rotation_speed: float = 30.0

## UI References
var toolbar: HBoxContainer
var shape_library: ShapeLibrary
var preview_3d: SubViewportContainer
var preview_viewport: SubViewport
var preview_camera: Camera3D
var preview_character: Node3D
var preview_item: Node3D
var part_list: ItemPartList
var properties_panel: ItemPropertiesPanel

## State
var current_item: ItemDefinition
var selected_part: ItemPartData
var auto_rotate: bool = true

## Editing
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []


func _ready() -> void:
	_setup_ui()
	_setup_3d_preview()
	new_item()


func _process(delta: float) -> void:
	if auto_rotate and preview_item:
		preview_item.rotate_y(deg_to_rad(preview_rotation_speed * delta))


func _setup_ui() -> void:
	var main_split := HSplitContainer.new()
	main_split.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_split)

	# Left panel - Shape library and part list
	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size.x = 200

	shape_library = ShapeLibrary.new()
	shape_library.custom_minimum_size.y = 200
	shape_library.shape_selected.connect(_on_shape_selected)
	left_panel.add_child(shape_library)

	part_list = ItemPartList.new()
	part_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	part_list.part_selected.connect(_on_part_selected)
	part_list.part_deleted.connect(_on_part_deleted)
	left_panel.add_child(part_list)

	main_split.add_child(left_panel)

	# Center - 3D preview
	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Toolbar
	toolbar = _create_toolbar()
	center_panel.add_child(toolbar)

	# 3D viewport
	preview_3d = SubViewportContainer.new()
	preview_3d.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_3d.stretch = true
	center_panel.add_child(preview_3d)

	main_split.add_child(center_panel)

	# Right panel - Properties
	properties_panel = ItemPropertiesPanel.new()
	properties_panel.custom_minimum_size.x = 250
	properties_panel.property_changed.connect(_on_property_changed)
	main_split.add_child(properties_panel)


func _create_toolbar() -> HBoxContainer:
	var tb := HBoxContainer.new()
	tb.custom_minimum_size.y = 40

	var new_btn := Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(new_item)
	tb.add_child(new_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_on_load_pressed)
	tb.add_child(load_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	tb.add_child(save_btn)

	tb.add_child(_create_separator())

	var slot_label := Label.new()
	slot_label.text = "Slot:"
	tb.add_child(slot_label)

	var slot_option := OptionButton.new()
	for slot in HumanoidTypes.ClothingSlot.values():
		slot_option.add_item(HumanoidTypes.ClothingSlot.keys()[slot])
	slot_option.item_selected.connect(_on_slot_changed)
	tb.add_child(slot_option)

	tb.add_child(_create_separator())

	var rotate_check := CheckButton.new()
	rotate_check.text = "Auto Rotate"
	rotate_check.button_pressed = true
	rotate_check.toggled.connect(func(pressed): auto_rotate = pressed)
	tb.add_child(rotate_check)

	return tb


func _create_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 20
	return sep


func _setup_3d_preview() -> void:
	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(400, 400)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	preview_3d.add_child(preview_viewport)

	# Camera
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0, 1, 3)
	preview_camera.look_at(Vector3(0, 0.5, 0))
	preview_viewport.add_child(preview_camera)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -45, 0)
	preview_viewport.add_child(light)

	# Item container
	preview_item = Node3D.new()
	preview_viewport.add_child(preview_item)

	# Environment
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.2, 0.2, 0.25)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment = environment
	preview_viewport.add_child(env)


## Create new item
func new_item() -> void:
	current_item = ItemDefinition.new()
	current_item.name = "New Item"
	current_item.slot = HumanoidTypes.ClothingSlot.HEAD

	selected_part = null
	_refresh_display()
	undo_stack.clear()
	redo_stack.clear()


## Add part to item
func add_part(shape: ItemPartData.ShapeType) -> void:
	_save_undo_state()

	var part := ItemPartData.new()
	part.shape = shape
	part.size = Vector3(0.3, 0.3, 0.3)
	current_item.parts.append(part)

	_refresh_display()
	_select_part(part)


## Remove part from item
func remove_part(part: ItemPartData) -> void:
	_save_undo_state()

	var index := current_item.parts.find(part)
	if index >= 0:
		current_item.parts.remove_at(index)

	if selected_part == part:
		selected_part = null

	_refresh_display()


## Save item
func save_item(path: String) -> void:
	if path.is_empty():
		path = "res://resources/items/%s.tres" % current_item.name.to_snake_case()

	ResourceSaver.save(current_item, path)
	item_saved.emit(current_item)


## Load item
func load_item(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	current_item = load(path)
	selected_part = null
	_refresh_display()
	item_loaded.emit(current_item)


## Refresh all displays
func _refresh_display() -> void:
	part_list.set_parts(current_item.parts)
	_rebuild_preview()

	if selected_part:
		properties_panel.set_part(selected_part)
	else:
		properties_panel.clear()


## Rebuild 3D preview
func _rebuild_preview() -> void:
	# Clear existing meshes
	for child in preview_item.get_children():
		child.queue_free()

	# Create meshes for each part
	for part in current_item.parts:
		var mesh_instance := _create_part_mesh(part)
		preview_item.add_child(mesh_instance)


func _create_part_mesh(part: ItemPartData) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = ItemMeshGenerator.create_shape_mesh(part)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = part.color_override if not part.use_category_color else Color(0.5, 0.5, 0.6)
	mesh_instance.material_override = mat

	mesh_instance.position = part.position
	mesh_instance.rotation = part.rotation
	mesh_instance.scale = Vector3.ONE

	return mesh_instance


func _select_part(part: ItemPartData) -> void:
	selected_part = part
	part_list.select_part(part)
	properties_panel.set_part(part)


## Signal handlers
func _on_shape_selected(shape: ItemPartData.ShapeType) -> void:
	add_part(shape)


func _on_part_selected(part: ItemPartData) -> void:
	_select_part(part)


func _on_part_deleted(part: ItemPartData) -> void:
	remove_part(part)


func _on_property_changed(property: String, value: Variant) -> void:
	if not selected_part:
		return

	_save_undo_state()
	selected_part.set(property, value)
	_refresh_display()


func _on_slot_changed(index: int) -> void:
	current_item.slot = index as HumanoidTypes.ClothingSlot


func _on_load_pressed() -> void:
	# TODO: File dialog
	pass


func _on_save_pressed() -> void:
	save_item("")


## Undo/Redo
func _save_undo_state() -> void:
	var state := {"parts": []}
	for part in current_item.parts:
		state.parts.append(part.duplicate())
	undo_stack.append(state)
	redo_stack.clear()


func undo() -> void:
	if undo_stack.is_empty():
		return

	var state := undo_stack.pop_back()
	redo_stack.append(_get_current_state())
	_restore_state(state)


func redo() -> void:
	if redo_stack.is_empty():
		return

	var state := redo_stack.pop_back()
	undo_stack.append(_get_current_state())
	_restore_state(state)


func _get_current_state() -> Dictionary:
	var state := {"parts": []}
	for part in current_item.parts:
		state.parts.append(part.duplicate())
	return state


func _restore_state(state: Dictionary) -> void:
	current_item.parts.clear()
	for part in state.parts:
		current_item.parts.append(part)
	_refresh_display()
