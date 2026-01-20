## PatternToolbar - Toolbar for pattern editor with file/playback controls
class_name PatternToolbar
extends HBoxContainer


signal load_pressed()
signal save_pressed()
signal play_toggled(playing: bool)
signal bpm_changed(bpm: float)
signal bars_changed(bars: int)
signal snap_changed(snap: int)


## UI Elements
var load_button: Button
var save_button: Button
var play_button: Button
var stop_button: Button
var bpm_spinbox: SpinBox
var bars_spinbox: SpinBox
var snap_option: OptionButton

## State
var _is_playing: bool = false


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	# File buttons
	load_button = Button.new()
	load_button.text = "Load"
	load_button.pressed.connect(func(): load_pressed.emit())
	add_child(load_button)

	save_button = Button.new()
	save_button.text = "Save"
	save_button.pressed.connect(func(): save_pressed.emit())
	add_child(save_button)

	# Separator
	add_child(_create_separator())

	# Playback buttons
	play_button = Button.new()
	play_button.text = "▶ Play"
	play_button.toggle_mode = true
	play_button.toggled.connect(_on_play_toggled)
	add_child(play_button)

	stop_button = Button.new()
	stop_button.text = "■ Stop"
	stop_button.pressed.connect(_on_stop_pressed)
	add_child(stop_button)

	# Separator
	add_child(_create_separator())

	# BPM
	var bpm_label := Label.new()
	bpm_label.text = "BPM:"
	add_child(bpm_label)

	bpm_spinbox = SpinBox.new()
	bpm_spinbox.min_value = 60
	bpm_spinbox.max_value = 240
	bpm_spinbox.value = 120
	bpm_spinbox.step = 1
	bpm_spinbox.value_changed.connect(func(val): bpm_changed.emit(val))
	add_child(bpm_spinbox)

	# Bars
	var bars_label := Label.new()
	bars_label.text = "Bars:"
	add_child(bars_label)

	bars_spinbox = SpinBox.new()
	bars_spinbox.min_value = 1
	bars_spinbox.max_value = 64
	bars_spinbox.value = 4
	bars_spinbox.step = 1
	bars_spinbox.value_changed.connect(func(val): bars_changed.emit(int(val)))
	add_child(bars_spinbox)

	# Separator
	add_child(_create_separator())

	# Snap
	var snap_label := Label.new()
	snap_label.text = "Snap:"
	add_child(snap_label)

	snap_option = OptionButton.new()
	snap_option.add_item("1/1", 1)
	snap_option.add_item("1/2", 2)
	snap_option.add_item("1/4", 4)
	snap_option.add_item("1/8", 8)
	snap_option.add_item("1/16", 16)
	snap_option.add_item("1/32", 32)
	snap_option.select(2)  # Default 1/4
	snap_option.item_selected.connect(_on_snap_selected)
	add_child(snap_option)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(spacer)


func _create_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 20
	return sep


func _on_play_toggled(pressed: bool) -> void:
	_is_playing = pressed
	play_button.text = "❚❚ Pause" if pressed else "▶ Play"
	play_toggled.emit(pressed)


func _on_stop_pressed() -> void:
	_is_playing = false
	play_button.button_pressed = false
	play_button.text = "▶ Play"
	play_toggled.emit(false)


func _on_snap_selected(index: int) -> void:
	var snap := snap_option.get_item_id(index)
	snap_changed.emit(snap)


## Public setters
func set_playing(playing: bool) -> void:
	_is_playing = playing
	play_button.button_pressed = playing
	play_button.text = "❚❚ Pause" if playing else "▶ Play"


func set_bpm(bpm: float) -> void:
	bpm_spinbox.value = bpm


func set_bars(bars: int) -> void:
	bars_spinbox.value = bars


func set_snap(snap: int) -> void:
	for i in range(snap_option.item_count):
		if snap_option.get_item_id(i) == snap:
			snap_option.select(i)
			break
