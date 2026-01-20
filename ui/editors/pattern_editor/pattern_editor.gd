## PatternEditor - Visual editor for creating beat patterns
class_name PatternEditor
extends Control


signal pattern_saved(pattern: Pattern)
signal pattern_loaded(pattern: Pattern)


## Configuration
@export var default_bpm: float = 120.0
@export var default_bars: int = 4
@export var snap_divisions: Array[int] = [1, 2, 4, 8, 16, 32]

## UI References
var toolbar: PatternToolbar
var waveform_display: WaveformDisplay
var timeline_grid: TimelineGrid
var quant_palette: QuantPalette
var properties_panel: Control

## State
var current_pattern: Pattern
var audio_stream: AudioStream
var audio_player: AudioStreamPlayer
var is_playing: bool = false
var current_snap_index: int = 2  # Default 1/4

## Editing
var selected_quant_type: Quant.Type = Quant.Type.KICK
var selected_markers: Array[QuantMarker] = []
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []


func _ready() -> void:
	_setup_ui()
	_setup_audio()
	new_pattern()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event.is_action_pressed("ui_cancel"):
		_deselect_all()
	elif event is InputEventKey and event.pressed:
		_handle_keyboard_shortcut(event)


func _setup_ui() -> void:
	# Create main layout
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	# Toolbar
	toolbar = PatternToolbar.new()
	toolbar.custom_minimum_size.y = 40
	toolbar.load_pressed.connect(_on_load_pressed)
	toolbar.save_pressed.connect(_on_save_pressed)
	toolbar.play_toggled.connect(_on_play_toggled)
	toolbar.bpm_changed.connect(_on_bpm_changed)
	toolbar.bars_changed.connect(_on_bars_changed)
	toolbar.snap_changed.connect(_on_snap_changed)
	vbox.add_child(toolbar)

	# Waveform display
	waveform_display = WaveformDisplay.new()
	waveform_display.custom_minimum_size.y = 80
	vbox.add_child(waveform_display)

	# Timeline grid
	timeline_grid = TimelineGrid.new()
	timeline_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	timeline_grid.quant_added.connect(_on_quant_added)
	timeline_grid.quant_removed.connect(_on_quant_removed)
	timeline_grid.quant_moved.connect(_on_quant_moved)
	timeline_grid.marker_selected.connect(_on_marker_selected)
	vbox.add_child(timeline_grid)

	# Bottom panel with palette
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size.y = 60

	quant_palette = QuantPalette.new()
	quant_palette.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	quant_palette.type_selected.connect(_on_quant_type_selected)
	bottom.add_child(quant_palette)

	vbox.add_child(bottom)


func _setup_audio() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.finished.connect(_on_audio_finished)
	add_child(audio_player)


func _handle_keyboard_shortcut(event: InputEventKey) -> void:
	if event.ctrl_pressed:
		match event.keycode:
			KEY_Z:
				undo()
			KEY_Y:
				redo()
			KEY_S:
				save_pattern("")
			KEY_A:
				_select_all()
			KEY_C:
				_copy_selection()
			KEY_V:
				_paste_selection()
	else:
		match event.keycode:
			KEY_SPACE:
				toggle_playback()
			KEY_DELETE:
				_delete_selection()
			KEY_BRACKETLEFT:
				_decrease_snap()
			KEY_BRACKETRIGHT:
				_increase_snap()
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7, KEY_8, KEY_9:
				var index := event.keycode - KEY_1
				if index < Quant.Type.size():
					selected_quant_type = index as Quant.Type
					quant_palette.select_type(selected_quant_type)


## Create new empty pattern
func new_pattern() -> void:
	current_pattern = Pattern.new()
	current_pattern.bpm = default_bpm
	current_pattern.pattern_name = "New Pattern"

	# Add default ticks
	for i in range(default_bars * 32):
		if i % 8 == 0:
			var tick := Quant.new()
			tick.type = Quant.Type.TICK
			tick.position = i
			tick.value = 1.0
			current_pattern.quants.append(tick)

	_refresh_display()
	undo_stack.clear()
	redo_stack.clear()


## Load audio file
func load_audio(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("PatternEditor: Audio file not found: %s" % path)
		return

	audio_stream = load(path)
	audio_player.stream = audio_stream
	current_pattern.audio_file = path

	waveform_display.generate_waveform(audio_stream)


## Save pattern
func save_pattern(path: String) -> void:
	if path.is_empty():
		# Use default path
		path = "res://resources/patterns/%s.tres" % current_pattern.pattern_name.to_snake_case()

	current_pattern.rebuild_cache()
	ResourceSaver.save(current_pattern, path)
	pattern_saved.emit(current_pattern)


## Load pattern
func load_pattern(path: String) -> void:
	if not ResourceLoader.exists(path):
		push_error("PatternEditor: Pattern not found: %s" % path)
		return

	current_pattern = load(path)
	_refresh_display()
	pattern_loaded.emit(current_pattern)

	if current_pattern.audio_file:
		load_audio(current_pattern.audio_file)


## Toggle playback
func toggle_playback() -> void:
	if is_playing:
		stop_playback()
	else:
		start_playback()


func start_playback() -> void:
	is_playing = true
	if audio_player.stream:
		audio_player.play()
	toolbar.set_playing(true)


func stop_playback() -> void:
	is_playing = false
	audio_player.stop()
	toolbar.set_playing(false)


## Undo/Redo
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


func _save_undo_state() -> void:
	undo_stack.append(_get_current_state())
	redo_stack.clear()

	# Limit undo stack size
	if undo_stack.size() > 50:
		undo_stack.pop_front()


func _get_current_state() -> Dictionary:
	var quants_data := []
	for q in current_pattern.quants:
		quants_data.append({
			"type": q.type,
			"position": q.position,
			"value": q.value
		})
	return {"quants": quants_data, "bpm": current_pattern.bpm}


func _restore_state(state: Dictionary) -> void:
	current_pattern.quants.clear()
	for q_data in state.quants:
		var q := Quant.new()
		q.type = q_data.type
		q.position = q_data.position
		q.value = q_data.value
		current_pattern.quants.append(q)
	current_pattern.bpm = state.bpm
	_refresh_display()


## Refresh all displays
func _refresh_display() -> void:
	toolbar.set_bpm(current_pattern.bpm)
	timeline_grid.set_pattern(current_pattern)
	timeline_grid.set_snap_division(snap_divisions[current_snap_index])


## Signal handlers
func _on_load_pressed() -> void:
	# TODO: File dialog
	pass


func _on_save_pressed() -> void:
	save_pattern("")


func _on_play_toggled(playing: bool) -> void:
	if playing:
		start_playback()
	else:
		stop_playback()


func _on_bpm_changed(bpm: float) -> void:
	_save_undo_state()
	current_pattern.bpm = bpm


func _on_bars_changed(bars: int) -> void:
	# Adjust pattern length
	pass


func _on_snap_changed(snap: int) -> void:
	current_snap_index = snap_divisions.find(snap)
	timeline_grid.set_snap_division(snap)


func _on_quant_type_selected(type: Quant.Type) -> void:
	selected_quant_type = type


func _on_quant_added(position: int, type: Quant.Type) -> void:
	_save_undo_state()

	var quant := Quant.new()
	quant.type = type
	quant.position = position
	quant.value = 1.0
	current_pattern.quants.append(quant)
	current_pattern.rebuild_cache()

	_refresh_display()


func _on_quant_removed(position: int, type: Quant.Type) -> void:
	_save_undo_state()

	for i in range(current_pattern.quants.size() - 1, -1, -1):
		var q := current_pattern.quants[i]
		if q.position == position and q.type == type:
			current_pattern.quants.remove_at(i)
			break

	current_pattern.rebuild_cache()
	_refresh_display()


func _on_quant_moved(from_pos: int, to_pos: int, type: Quant.Type) -> void:
	_save_undo_state()

	for q in current_pattern.quants:
		if q.position == from_pos and q.type == type:
			q.position = to_pos
			break

	current_pattern.rebuild_cache()
	_refresh_display()


func _on_marker_selected(marker: QuantMarker) -> void:
	if not Input.is_key_pressed(KEY_SHIFT):
		_deselect_all()
	selected_markers.append(marker)
	marker.set_selected(true)


func _on_audio_finished() -> void:
	if is_playing:
		audio_player.play()  # Loop


## Selection helpers
func _deselect_all() -> void:
	for marker in selected_markers:
		if is_instance_valid(marker):
			marker.set_selected(false)
	selected_markers.clear()


func _select_all() -> void:
	_deselect_all()
	for marker in timeline_grid.get_all_markers():
		selected_markers.append(marker)
		marker.set_selected(true)


func _delete_selection() -> void:
	if selected_markers.is_empty():
		return

	_save_undo_state()

	for marker in selected_markers:
		_on_quant_removed(marker.beat_position, marker.quant_type)

	selected_markers.clear()


func _copy_selection() -> void:
	# TODO: Implement clipboard
	pass


func _paste_selection() -> void:
	# TODO: Implement clipboard
	pass


func _decrease_snap() -> void:
	current_snap_index = maxi(0, current_snap_index - 1)
	timeline_grid.set_snap_division(snap_divisions[current_snap_index])
	toolbar.set_snap(snap_divisions[current_snap_index])


func _increase_snap() -> void:
	current_snap_index = mini(snap_divisions.size() - 1, current_snap_index + 1)
	timeline_grid.set_snap_division(snap_divisions[current_snap_index])
	toolbar.set_snap(snap_divisions[current_snap_index])
