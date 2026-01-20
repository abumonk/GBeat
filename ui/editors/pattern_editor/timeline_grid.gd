## TimelineGrid - Grid for placing quants on a timeline
class_name TimelineGrid
extends Control


signal quant_added(position: int, type: Quant.Type)
signal quant_removed(position: int, type: Quant.Type)
signal quant_moved(from_pos: int, to_pos: int, type: Quant.Type)
signal marker_selected(marker: QuantMarker)


## Configuration
@export var lane_height: float = 30.0
@export var beat_width: float = 40.0
@export var grid_color: Color = Color(0.3, 0.3, 0.35)
@export var bar_color: Color = Color(0.5, 0.5, 0.55)
@export var beat_color: Color = Color(0.4, 0.4, 0.45)
@export var background_color: Color = Color(0.15, 0.15, 0.18)

## Quant type colors
var type_colors: Dictionary = {
	Quant.Type.TICK: Color(0.5, 0.5, 0.5),
	Quant.Type.KICK: Color(1.0, 0.3, 0.3),
	Quant.Type.SNARE: Color(0.3, 1.0, 0.3),
	Quant.Type.HAT: Color(0.3, 0.3, 1.0),
	Quant.Type.OPEN_HAT: Color(0.3, 0.5, 1.0),
	Quant.Type.ANIMATION: Color(1.0, 1.0, 0.3),
	Quant.Type.HIT: Color(1.0, 0.5, 0.0),
}

## State
var _pattern: Pattern
var _snap_division: int = 4
var _markers: Array[QuantMarker] = []
var _scroll_offset: float = 0.0
var _selected_type: Quant.Type = Quant.Type.KICK

## Lane definitions (quant types to show)
var _lanes: Array[Quant.Type] = [
	Quant.Type.KICK,
	Quant.Type.SNARE,
	Quant.Type.HAT,
	Quant.Type.ANIMATION,
	Quant.Type.HIT,
]


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), background_color)

	if not _pattern:
		return

	var total_quants := _pattern.get_total_quants()
	var total_width := (total_quants / 32.0) * 4 * beat_width

	# Draw grid lines
	_draw_grid(total_quants)

	# Draw lane labels
	_draw_lane_labels()

	# Draw markers (handled by child nodes)


func _draw_grid(total_quants: int) -> void:
	var label_width := 80.0
	var grid_start := label_width

	# Vertical lines for beats
	for i in range(total_quants + 1):
		var x := grid_start + (i / 8.0) * beat_width - _scroll_offset

		if x < grid_start or x > size.x:
			continue

		var color: Color
		var width: float

		if i % 32 == 0:
			# Bar line
			color = bar_color
			width = 2.0
		elif i % 8 == 0:
			# Beat line
			color = beat_color
			width = 1.5
		elif i % _snap_division == 0:
			# Subdivision line
			color = grid_color
			width = 1.0
		else:
			continue

		draw_line(Vector2(x, 0), Vector2(x, size.y), color, width)

		# Beat numbers
		if i % 8 == 0:
			var beat_num := i / 8 + 1
			var bar_num := (i / 32) + 1
			var beat_in_bar := (i % 32) / 8 + 1
			var label := "%d.%d" % [bar_num, beat_in_bar]
			draw_string(ThemeDB.fallback_font, Vector2(x + 2, 12), label, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.6, 0.6, 0.6))

	# Horizontal lines for lanes
	for i in range(_lanes.size() + 1):
		var y := 20 + i * lane_height
		draw_line(Vector2(grid_start, y), Vector2(size.x, y), grid_color, 1.0)


func _draw_lane_labels() -> void:
	for i in range(_lanes.size()):
		var lane_type := _lanes[i]
		var y := 20 + i * lane_height + lane_height / 2 + 4
		var color: Color = type_colors.get(lane_type, Color.WHITE)
		var label := Quant.Type.keys()[lane_type]
		draw_string(ThemeDB.fallback_font, Vector2(5, y), label, HORIZONTAL_ALIGNMENT_LEFT, 70, 11, color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.pressed:
			_handle_click(event)
	elif event is InputEventMouseMotion:
		if event.button_mask & MOUSE_BUTTON_MASK_MIDDLE:
			_scroll_offset -= event.relative.x
			_scroll_offset = maxf(0, _scroll_offset)
			_refresh_markers()
			queue_redraw()


func _handle_click(event: InputEventMouseButton) -> void:
	var label_width := 80.0

	if event.position.x < label_width:
		return

	var grid_x := event.position.x - label_width + _scroll_offset
	var grid_y := event.position.y - 20

	# Determine lane
	var lane_index := int(grid_y / lane_height)
	if lane_index < 0 or lane_index >= _lanes.size():
		return

	var lane_type := _lanes[lane_index]

	# Determine position (snapped)
	var raw_position := (grid_x / beat_width) * 8
	var snapped_position := _snap_to_grid(int(raw_position))

	if event.button_index == MOUSE_BUTTON_LEFT:
		# Add quant
		quant_added.emit(snapped_position, lane_type)
	elif event.button_index == MOUSE_BUTTON_RIGHT:
		# Remove quant
		quant_removed.emit(snapped_position, lane_type)


func _snap_to_grid(position: int) -> int:
	var snap := 32 / _snap_division
	return int(round(float(position) / snap) * snap)


## Set pattern to display
func set_pattern(pattern: Pattern) -> void:
	_pattern = pattern
	_refresh_markers()
	queue_redraw()


## Set snap division
func set_snap_division(division: int) -> void:
	_snap_division = division
	queue_redraw()


## Set selected quant type
func set_selected_type(type: Quant.Type) -> void:
	_selected_type = type


## Refresh marker positions
func _refresh_markers() -> void:
	# Clear existing markers
	for marker in _markers:
		if is_instance_valid(marker):
			marker.queue_free()
	_markers.clear()

	if not _pattern:
		return

	var label_width := 80.0

	# Create markers for each quant
	for quant in _pattern.quants:
		var lane_index := _lanes.find(quant.type)
		if lane_index < 0:
			continue

		var marker := QuantMarker.new()
		marker.quant_type = quant.type
		marker.beat_position = quant.position
		marker.color = type_colors.get(quant.type, Color.WHITE)

		var x := label_width + (quant.position / 8.0) * beat_width - _scroll_offset
		var y := 20 + lane_index * lane_height

		marker.position = Vector2(x - 8, y + 2)
		marker.custom_minimum_size = Vector2(16, lane_height - 4)
		marker.selected.connect(_on_marker_selected.bind(marker))
		marker.moved.connect(_on_marker_moved.bind(marker))

		add_child(marker)
		_markers.append(marker)


func _on_marker_selected(marker: QuantMarker) -> void:
	marker_selected.emit(marker)


func _on_marker_moved(new_pos: int, marker: QuantMarker) -> void:
	var snapped := _snap_to_grid(new_pos)
	quant_moved.emit(marker.beat_position, snapped, marker.quant_type)


## Get all markers
func get_all_markers() -> Array[QuantMarker]:
	return _markers


## Convert pixel to beat position
func pixel_to_beat(x: float) -> int:
	var label_width := 80.0
	var grid_x := x - label_width + _scroll_offset
	return int((grid_x / beat_width) * 8)


## Convert beat position to pixel
func beat_to_pixel(beat: int) -> float:
	var label_width := 80.0
	return label_width + (beat / 8.0) * beat_width - _scroll_offset
