## AnimationEditor - Visual editor for creating character animations
class_name AnimationEditor
extends Control


signal animation_saved(animation: CharacterAnimation)
signal animation_loaded(animation: CharacterAnimation)


## Configuration
@export var default_fps: float = 30.0
@export var default_frame_count: int = 30

## UI References
var toolbar: HBoxContainer
var character_viewport: SubViewportContainer
var timeline_panel: AnimationTimeline
var bone_selector: BoneSelector
var properties_panel: KeyframePropertiesPanel
var animation_list: AnimationListPanel

## 3D Preview
var preview_viewport: SubViewport
var preview_camera: Camera3D
var preview_character: Node3D

## State
var current_animation: CharacterAnimation
var selected_bone: String = ""
var current_frame: int = 0
var is_playing: bool = false
var playback_speed: float = 1.0

## Editing
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []


func _ready() -> void:
	_setup_ui()
	_setup_3d_preview()
	new_animation()


func _process(delta: float) -> void:
	if is_playing and current_animation:
		current_frame += int(delta * current_animation.fps * playback_speed)
		if current_frame >= current_animation.frame_count:
			if current_animation.loop:
				current_frame = 0
			else:
				current_frame = current_animation.frame_count - 1
				stop_playback()

		_update_preview_pose()
		timeline_panel.set_playhead(current_frame)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		_handle_shortcut(event)


func _setup_ui() -> void:
	var main_split := HSplitContainer.new()
	main_split.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_split)

	# Left panel - Animation list and bone selector
	var left_panel := VBoxContainer.new()
	left_panel.custom_minimum_size.x = 200

	animation_list = AnimationListPanel.new()
	animation_list.custom_minimum_size.y = 150
	animation_list.animation_selected.connect(_on_animation_selected)
	left_panel.add_child(animation_list)

	bone_selector = BoneSelector.new()
	bone_selector.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bone_selector.bone_selected.connect(_on_bone_selected)
	left_panel.add_child(bone_selector)

	main_split.add_child(left_panel)

	# Center panel - Preview and timeline
	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Toolbar
	toolbar = _create_toolbar()
	center_panel.add_child(toolbar)

	# 3D Preview
	character_viewport = SubViewportContainer.new()
	character_viewport.size_flags_vertical = Control.SIZE_EXPAND_FILL
	character_viewport.stretch = true
	center_panel.add_child(character_viewport)

	# Timeline
	timeline_panel = AnimationTimeline.new()
	timeline_panel.custom_minimum_size.y = 200
	timeline_panel.keyframe_added.connect(_on_keyframe_added)
	timeline_panel.keyframe_removed.connect(_on_keyframe_removed)
	timeline_panel.keyframe_selected.connect(_on_keyframe_selected)
	timeline_panel.playhead_moved.connect(_on_playhead_moved)
	center_panel.add_child(timeline_panel)

	main_split.add_child(center_panel)

	# Right panel - Keyframe properties
	properties_panel = KeyframePropertiesPanel.new()
	properties_panel.custom_minimum_size.x = 250
	properties_panel.property_changed.connect(_on_property_changed)
	main_split.add_child(properties_panel)


func _create_toolbar() -> HBoxContainer:
	var tb := HBoxContainer.new()
	tb.custom_minimum_size.y = 40

	var new_btn := Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(new_animation)
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

	# Playback controls
	var prev_btn := Button.new()
	prev_btn.text = "◄"
	prev_btn.pressed.connect(previous_frame)
	tb.add_child(prev_btn)

	var play_btn := Button.new()
	play_btn.text = "▶"
	play_btn.toggle_mode = true
	play_btn.toggled.connect(_on_play_toggled)
	tb.add_child(play_btn)

	var next_btn := Button.new()
	next_btn.text = "►"
	next_btn.pressed.connect(next_frame)
	tb.add_child(next_btn)

	tb.add_child(_create_separator())

	# Frame info
	var frame_label := Label.new()
	frame_label.text = "Frame:"
	tb.add_child(frame_label)

	var frame_spinbox := SpinBox.new()
	frame_spinbox.min_value = 0
	frame_spinbox.max_value = 999
	frame_spinbox.value_changed.connect(func(val): seek_frame(int(val)))
	tb.add_child(frame_spinbox)

	tb.add_child(_create_separator())

	# FPS
	var fps_label := Label.new()
	fps_label.text = "FPS:"
	tb.add_child(fps_label)

	var fps_spinbox := SpinBox.new()
	fps_spinbox.min_value = 1
	fps_spinbox.max_value = 120
	fps_spinbox.value = 30
	fps_spinbox.value_changed.connect(_on_fps_changed)
	tb.add_child(fps_spinbox)

	# Insert keyframe button
	tb.add_child(_create_separator())

	var key_btn := Button.new()
	key_btn.text = "◆ Insert Key"
	key_btn.pressed.connect(insert_keyframe)
	tb.add_child(key_btn)

	return tb


func _create_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 20
	return sep


func _setup_3d_preview() -> void:
	preview_viewport = SubViewport.new()
	preview_viewport.size = Vector2i(400, 400)
	preview_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	character_viewport.add_child(preview_viewport)

	# Camera
	preview_camera = Camera3D.new()
	preview_camera.position = Vector3(0, 1, 3)
	preview_camera.look_at(Vector3(0, 1, 0))
	preview_viewport.add_child(preview_camera)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -45, 0)
	preview_viewport.add_child(light)

	# Character placeholder
	preview_character = _create_preview_character()
	preview_viewport.add_child(preview_character)

	# Environment
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.2, 0.2, 0.25)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.environment = environment
	preview_viewport.add_child(env)

	# Floor grid
	var grid := _create_grid()
	preview_viewport.add_child(grid)


func _create_preview_character() -> Node3D:
	# Simple stick figure for preview
	var root := Node3D.new()

	# Body parts as simple shapes
	var parts := {
		"Pelvis": {"pos": Vector3(0, 1, 0), "size": Vector3(0.3, 0.2, 0.15)},
		"Spine": {"pos": Vector3(0, 1.3, 0), "size": Vector3(0.25, 0.3, 0.12)},
		"Chest": {"pos": Vector3(0, 1.6, 0), "size": Vector3(0.35, 0.25, 0.15)},
		"Head": {"pos": Vector3(0, 1.95, 0), "size": Vector3(0.2, 0.25, 0.2)},
		"Arm_L": {"pos": Vector3(-0.35, 1.5, 0), "size": Vector3(0.08, 0.4, 0.08)},
		"Arm_R": {"pos": Vector3(0.35, 1.5, 0), "size": Vector3(0.08, 0.4, 0.08)},
		"Leg_L": {"pos": Vector3(-0.1, 0.5, 0), "size": Vector3(0.1, 0.5, 0.1)},
		"Leg_R": {"pos": Vector3(0.1, 0.5, 0), "size": Vector3(0.1, 0.5, 0.1)},
	}

	for bone_name in parts:
		var part_data: Dictionary = parts[bone_name]
		var mesh := MeshInstance3D.new()
		mesh.name = bone_name
		var box := BoxMesh.new()
		box.size = part_data.size
		mesh.mesh = box
		mesh.position = part_data.pos

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.4, 0.6, 0.8)
		mesh.material_override = mat

		root.add_child(mesh)

	return root


func _create_grid() -> MeshInstance3D:
	var grid := MeshInstance3D.new()
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(10, 10)
	grid.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.3, 0.35)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.5
	grid.material_override = mat

	return grid


func _handle_shortcut(event: InputEventKey) -> void:
	if event.ctrl_pressed:
		match event.keycode:
			KEY_Z:
				undo()
			KEY_Y:
				redo()
			KEY_S:
				save_animation("")
			KEY_C:
				_copy_keyframe()
			KEY_V:
				_paste_keyframe()
	else:
		match event.keycode:
			KEY_SPACE:
				toggle_playback()
			KEY_LEFT:
				previous_frame()
			KEY_RIGHT:
				next_frame()
			KEY_K:
				insert_keyframe()
			KEY_DELETE:
				delete_keyframe()
			KEY_HOME:
				seek_frame(0)
			KEY_END:
				if current_animation:
					seek_frame(current_animation.frame_count - 1)


## Create new animation
func new_animation() -> void:
	current_animation = CharacterAnimation.new()
	current_animation.name = "new_animation"
	current_animation.frame_count = default_frame_count
	current_animation.fps = default_fps

	current_frame = 0
	selected_bone = ""

	_refresh_display()
	undo_stack.clear()
	redo_stack.clear()


## Save animation
func save_animation(path: String) -> void:
	if path.is_empty():
		path = "res://resources/animations/%s.tres" % current_animation.name

	ResourceSaver.save(current_animation, path)
	animation_saved.emit(current_animation)


## Load animation
func load_animation(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	current_animation = load(path)
	current_frame = 0
	_refresh_display()
	animation_loaded.emit(current_animation)


## Playback controls
func toggle_playback() -> void:
	if is_playing:
		stop_playback()
	else:
		start_playback()


func start_playback() -> void:
	is_playing = true


func stop_playback() -> void:
	is_playing = false


func seek_frame(frame: int) -> void:
	current_frame = clampi(frame, 0, current_animation.frame_count - 1 if current_animation else 0)
	_update_preview_pose()
	timeline_panel.set_playhead(current_frame)


func next_frame() -> void:
	seek_frame(current_frame + 1)


func previous_frame() -> void:
	seek_frame(current_frame - 1)


## Keyframe editing
func insert_keyframe() -> void:
	if selected_bone.is_empty() or not current_animation:
		return

	_save_undo_state()

	var bone_node := preview_character.get_node_or_null(selected_bone)
	if not bone_node:
		return

	var keyframe := Keyframe.new()
	keyframe.frame = current_frame
	keyframe.position = bone_node.position
	keyframe.rotation = bone_node.rotation

	current_animation.set_keyframe(selected_bone, keyframe)
	_refresh_display()


func delete_keyframe() -> void:
	if selected_bone.is_empty() or not current_animation:
		return

	_save_undo_state()
	current_animation.remove_keyframe(selected_bone, current_frame)
	_refresh_display()


func _update_preview_pose() -> void:
	if not current_animation or not preview_character:
		return

	for bone_name in current_animation.tracks:
		var bone_node := preview_character.get_node_or_null(bone_name)
		if bone_node:
			var transform := current_animation.sample_bone(bone_name, float(current_frame))
			bone_node.transform = transform


func _refresh_display() -> void:
	if current_animation:
		timeline_panel.set_animation(current_animation)
		timeline_panel.set_selected_bone(selected_bone)
		bone_selector.set_bones(_get_bone_names())

	_update_preview_pose()


func _get_bone_names() -> Array[String]:
	var names: Array[String] = []
	for child in preview_character.get_children():
		names.append(child.name)
	return names


## Signal handlers
func _on_animation_selected(anim: CharacterAnimation) -> void:
	current_animation = anim
	current_frame = 0
	_refresh_display()


func _on_bone_selected(bone: String) -> void:
	selected_bone = bone
	timeline_panel.set_selected_bone(bone)

	# Highlight bone in preview
	for child in preview_character.get_children():
		var mat := child.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.8, 0.4, 0.2) if child.name == bone else Color(0.4, 0.6, 0.8)


func _on_keyframe_added(bone: String, frame: int) -> void:
	selected_bone = bone
	current_frame = frame
	insert_keyframe()


func _on_keyframe_removed(bone: String, frame: int) -> void:
	selected_bone = bone
	current_frame = frame
	delete_keyframe()


func _on_keyframe_selected(bone: String, frame: int) -> void:
	selected_bone = bone
	seek_frame(frame)

	var keyframe := current_animation.get_keyframe(bone, frame)
	if keyframe:
		properties_panel.set_keyframe(keyframe)


func _on_playhead_moved(frame: int) -> void:
	seek_frame(frame)


func _on_property_changed(property: String, value: Variant) -> void:
	# Update keyframe property
	var keyframe := current_animation.get_keyframe(selected_bone, current_frame)
	if keyframe:
		_save_undo_state()
		keyframe.set(property, value)
		_update_preview_pose()


func _on_fps_changed(fps: float) -> void:
	if current_animation:
		current_animation.fps = fps


func _on_play_toggled(pressed: bool) -> void:
	if pressed:
		start_playback()
	else:
		stop_playback()


func _on_load_pressed() -> void:
	pass


func _on_save_pressed() -> void:
	save_animation("")


## Clipboard
var _clipboard_keyframe: Keyframe

func _copy_keyframe() -> void:
	var kf := current_animation.get_keyframe(selected_bone, current_frame)
	if kf:
		_clipboard_keyframe = kf.duplicate()


func _paste_keyframe() -> void:
	if _clipboard_keyframe and not selected_bone.is_empty():
		_save_undo_state()
		var new_kf := _clipboard_keyframe.duplicate()
		new_kf.frame = current_frame
		current_animation.set_keyframe(selected_bone, new_kf)
		_refresh_display()


## Undo/Redo
func _save_undo_state() -> void:
	undo_stack.append(current_animation.duplicate())
	redo_stack.clear()


func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(current_animation.duplicate())
	current_animation = undo_stack.pop_back()
	_refresh_display()


func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(current_animation.duplicate())
	current_animation = redo_stack.pop_back()
	_refresh_display()
