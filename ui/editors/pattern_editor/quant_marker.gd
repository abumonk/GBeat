## QuantMarker - Draggable marker representing a quant on the timeline
class_name QuantMarker
extends Control


signal selected()
signal moved(new_position: int)
signal deleted()


## Data
var quant_type: Quant.Type = Quant.Type.KICK
var beat_position: int = 0
var color: Color = Color.WHITE

## State
var _is_selected: bool = false
var _is_dragging: bool = false
var _drag_start: Vector2


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Background
	var bg_color := color
	if _is_selected:
		bg_color = color.lightened(0.3)

	draw_rect(rect, bg_color)

	# Border
	var border_color := Color.WHITE if _is_selected else color.darkened(0.3)
	draw_rect(rect, border_color, false, 2.0 if _is_selected else 1.0)

	# Diamond shape in center
	var center := size / 2
	var diamond_size := min(size.x, size.y) * 0.3
	var points := PackedVector2Array([
		center + Vector2(0, -diamond_size),
		center + Vector2(diamond_size, 0),
		center + Vector2(0, diamond_size),
		center + Vector2(-diamond_size, 0),
	])
	draw_colored_polygon(points, Color.WHITE if not _is_selected else color)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				_is_dragging = true
				_drag_start = event.position
				selected.emit()
			else:
				_is_dragging = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			deleted.emit()

	elif event is InputEventMouseMotion and _is_dragging:
		# Calculate new position
		var delta := event.position - _drag_start
		if abs(delta.x) > 10:
			var parent := get_parent() as TimelineGrid
			if parent:
				var new_x := global_position.x + delta.x
				var new_beat := parent.pixel_to_beat(new_x)
				moved.emit(new_beat)


func set_selected(selected: bool) -> void:
	_is_selected = selected
	queue_redraw()


func is_selected() -> bool:
	return _is_selected
