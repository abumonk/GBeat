## AnimationTimeline - Timeline display for animation keyframes
class_name AnimationTimeline
extends Control


signal keyframe_added(bone: String, frame: int)
signal keyframe_removed(bone: String, frame: int)
signal keyframe_selected(bone: String, frame: int)
signal playhead_moved(frame: int)


## Configuration
@export var frame_width: float = 10.0
@export var track_height: float = 25.0
@export var header_height: float = 30.0
@export var label_width: float = 100.0

## Colors
@export var background_color: Color = Color(0.15, 0.15, 0.18)
@export var track_color: Color = Color(0.2, 0.2, 0.22)
@export var track_alt_color: Color = Color(0.18, 0.18, 0.2)
@export var grid_color: Color = Color(0.3, 0.3, 0.32)
@export var beat_color: Color = Color(0.4, 0.4, 0.42)
@export var playhead_color: Color = Color(1.0, 0.3, 0.3)
@export var keyframe_color: Color = Color(1.0, 0.8, 0.2)
@export var selected_keyframe_color: Color = Color(0.3, 0.8, 1.0)

## State
var _animation: CharacterAnimation
var _selected_bone: String = ""
var _playhead_frame: int = 0
var _scroll_offset: float = 0.0
var _bone_order: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	if not _animation:
		return

	# Draw header
	_draw_header()

	# Draw tracks
	_draw_tracks()

	# Draw keyframes
	_draw_keyframes()

	# Draw playhead
	_draw_playhead()


func _draw_header() -> void:
	# Frame numbers
	var frame_count := _animation.frame_count
	var start_frame := int(_scroll_offset / frame_width)
	var visible_frames := int((size.x - label_width) / frame_width) + 2

	for i in range(visible_frames):
		var frame := start_frame + i
		if frame >= frame_count:
			break

		var x := label_width + frame * frame_width - _scroll_offset

		# Beat markers (every 8 frames at 30fps ~ 1 beat at 120bpm)
		if frame % 8 == 0:
			draw_line(Vector2(x, 0), Vector2(x, size.y), beat_color, 1.0)
			draw_string(ThemeDB.fallback_font, Vector2(x + 2, 15), str(frame), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))
		elif frame % 4 == 0:
			draw_line(Vector2(x, header_height), Vector2(x, size.y), grid_color, 1.0)


func _draw_tracks() -> void:
	for i in range(_bone_order.size()):
		var y := header_height + i * track_height
		var color := track_color if i % 2 == 0 else track_alt_color

		# Track background
		draw_rect(Rect2(label_width, y, size.x - label_width, track_height), color)

		# Bone label
		var bone := _bone_order[i]
		var label_color := Color.WHITE if bone == _selected_bone else Color(0.7, 0.7, 0.7)
		draw_string(ThemeDB.fallback_font, Vector2(5, y + track_height / 2 + 4), bone, HORIZONTAL_ALIGNMENT_LEFT, int(label_width - 10), 11, label_color)

		# Selection highlight
		if bone == _selected_bone:
			draw_rect(Rect2(0, y, label_width, track_height), Color(0.3, 0.5, 0.8, 0.3))


func _draw_keyframes() -> void:
	if not _animation:
		return

	for bone in _animation.tracks:
		var track_index := _bone_order.find(bone)
		if track_index < 0:
			continue

		var y := header_height + track_index * track_height + track_height / 2

		for keyframe in _animation.tracks[bone]:
			var x := label_width + keyframe.frame * frame_width - _scroll_offset

			if x < label_width or x > size.x:
				continue

			var color := selected_keyframe_color if bone == _selected_bone else keyframe_color

			# Diamond shape
			var diamond_size := 6.0
			var points := PackedVector2Array([
				Vector2(x, y - diamond_size),
				Vector2(x + diamond_size, y),
				Vector2(x, y + diamond_size),
				Vector2(x - diamond_size, y),
			])
			draw_colored_polygon(points, color)


func _draw_playhead() -> void:
	var x := label_width + _playhead_frame * frame_width - _scroll_offset

	if x >= label_width and x <= size.x:
		draw_line(Vector2(x, 0), Vector2(x, size.y), playhead_color, 2.0)

		# Playhead handle
		var handle_points := PackedVector2Array([
			Vector2(x - 6, 0),
			Vector2(x + 6, 0),
			Vector2(x, 10),
		])
		draw_colored_polygon(handle_points, playhead_color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_handle_click(event)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_LEFT:
			# Drag playhead
			var frame := _pixel_to_frame(event.position.x)
			playhead_moved.emit(frame)
		elif event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_scroll_offset -= event.relative.x
			_scroll_offset = maxf(0, _scroll_offset)
			queue_redraw()


func _handle_click(event: InputEventMouseButton) -> void:
	var frame := _pixel_to_frame(event.position.x)
	var track_index := _pixel_to_track(event.position.y)

	if event.position.y < header_height:
		# Click in header - move playhead
		playhead_moved.emit(frame)
	elif track_index >= 0 and track_index < _bone_order.size():
		var bone := _bone_order[track_index]

		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.double_click:
				# Double click - add keyframe
				keyframe_added.emit(bone, frame)
			else:
				# Single click - select
				keyframe_selected.emit(bone, frame)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			# Right click - remove keyframe
			keyframe_removed.emit(bone, frame)


func _pixel_to_frame(x: float) -> int:
	return int((x - label_width + _scroll_offset) / frame_width)


func _pixel_to_track(y: float) -> int:
	return int((y - header_height) / track_height)


## Set animation to display
func set_animation(animation: CharacterAnimation) -> void:
	_animation = animation
	_bone_order = animation.get_animated_bones() if animation else []
	queue_redraw()


## Set selected bone
func set_selected_bone(bone: String) -> void:
	_selected_bone = bone
	queue_redraw()


## Set playhead position
func set_playhead(frame: int) -> void:
	_playhead_frame = frame
	queue_redraw()


## Add bone track
func add_bone_track(bone: String) -> void:
	if bone not in _bone_order:
		_bone_order.append(bone)
		queue_redraw()
