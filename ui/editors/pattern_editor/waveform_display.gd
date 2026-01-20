## WaveformDisplay - Displays audio waveform for visual reference
class_name WaveformDisplay
extends Control


## Configuration
@export var waveform_color: Color = Color(0.3, 0.8, 0.5)
@export var background_color: Color = Color(0.1, 0.1, 0.12)
@export var playhead_color: Color = Color(1.0, 1.0, 1.0)
@export var samples_per_pixel: int = 1000

## State
var _waveform_data: PackedFloat32Array
var _playhead_position: float = 0.0
var _duration: float = 0.0
var _scroll_offset: float = 0.0
var _zoom: float = 1.0


func _ready() -> void:
	clip_contents = true


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	if _waveform_data.is_empty():
		# No waveform - show placeholder
		draw_string(ThemeDB.fallback_font, Vector2(10, size.y / 2 + 5), "Load audio file...", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.5, 0.5, 0.5))
		return

	# Draw waveform
	var center_y := size.y / 2
	var half_height := size.y * 0.4

	var label_width := 80.0
	var available_width := size.x - label_width

	var points_top := PackedVector2Array()
	var points_bottom := PackedVector2Array()

	for i in range(int(available_width)):
		var data_index := int((i + _scroll_offset) * _zoom)
		if data_index >= _waveform_data.size():
			break

		var amplitude: float = _waveform_data[data_index]
		var x := label_width + i
		var y_offset := amplitude * half_height

		points_top.append(Vector2(x, center_y - y_offset))
		points_bottom.append(Vector2(x, center_y + y_offset))

	# Draw filled waveform
	if points_top.size() > 1:
		# Combine into polygon
		var polygon := PackedVector2Array()
		polygon.append_array(points_top)
		points_bottom.reverse()
		polygon.append_array(points_bottom)

		draw_colored_polygon(polygon, waveform_color)

	# Center line
	draw_line(Vector2(label_width, center_y), Vector2(size.x, center_y), Color(0.3, 0.3, 0.3), 1.0)

	# Playhead
	if _duration > 0:
		var playhead_x := label_width + (_playhead_position / _duration) * available_width - _scroll_offset
		if playhead_x >= label_width and playhead_x <= size.x:
			draw_line(Vector2(playhead_x, 0), Vector2(playhead_x, size.y), playhead_color, 2.0)


## Generate waveform from audio stream
func generate_waveform(stream: AudioStream) -> void:
	if not stream:
		return

	_duration = stream.get_length()

	# For now, create simple placeholder data
	# In a real implementation, you'd analyze the actual audio samples
	_waveform_data.clear()

	var num_samples := int(size.x * _zoom)
	for i in range(num_samples):
		# Simulate waveform with noise
		var t := float(i) / num_samples
		var amplitude := randf_range(0.2, 0.8) * (0.5 + 0.5 * sin(t * 50))
		_waveform_data.append(amplitude)

	queue_redraw()


## Set playhead position (0-1 normalized)
func set_playhead(position: float) -> void:
	_playhead_position = position * _duration
	queue_redraw()


## Set playhead by time
func set_playhead_time(time: float) -> void:
	_playhead_position = time
	queue_redraw()


## Set zoom level
func set_zoom(level: float) -> void:
	_zoom = clampf(level, 0.1, 10.0)
	queue_redraw()


## Set scroll offset
func set_scroll(offset: float) -> void:
	_scroll_offset = maxf(0, offset)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			set_zoom(_zoom * 1.1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			set_zoom(_zoom / 1.1)
		elif event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Seek to position
			var label_width := 80.0
			var click_x := event.position.x - label_width
			var available_width := size.x - label_width
			var normalized := clampf(click_x / available_width, 0, 1)
			set_playhead(normalized)

	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			set_scroll(_scroll_offset - event.relative.x)
