## BeatIndicator - Visual metronome/beat pulse indicator
class_name BeatIndicator
extends Control


## Configuration
@export var idle_color: Color = Color(0.3, 0.3, 0.4)
@export var pulse_color: Color = Color(1.0, 0.2, 0.6)
@export var beat_colors: Dictionary = {
	"kick": Color(1.0, 0.2, 0.2),
	"snare": Color(0.2, 1.0, 0.2),
	"hat": Color(0.2, 0.2, 1.0),
}
@export var pulse_duration: float = 0.15
@export var indicator_count: int = 4

## State
var _indicators: Array[float] = []  # Current intensity for each indicator
var _current_beat: int = 0
var _tween: Tween


func _ready() -> void:
	_indicators.resize(indicator_count)
	_indicators.fill(0.0)


func _draw() -> void:
	var indicator_size := size.x / indicator_count
	var padding := 2.0

	for i in range(indicator_count):
		var rect := Rect2(
			i * indicator_size + padding,
			padding,
			indicator_size - padding * 2,
			size.y - padding * 2
		)

		var intensity: float = _indicators[i]
		var color := idle_color.lerp(pulse_color, intensity)

		# Draw indicator
		draw_rect(rect, color)

		# Border for current beat
		if i == _current_beat % indicator_count:
			draw_rect(rect, Color.WHITE, false, 1.0)


func pulse(intensity: float = 1.0) -> void:
	var index := _current_beat % indicator_count
	_indicators[index] = intensity

	# Animate decay
	var tween := create_tween()
	tween.tween_method(
		func(val: float):
			_indicators[index] = val
			queue_redraw(),
		intensity,
		0.0,
		pulse_duration
	)

	_current_beat += 1
	queue_redraw()


func pulse_type(type: String, intensity: float = 1.0) -> void:
	if beat_colors.has(type):
		var original := pulse_color
		pulse_color = beat_colors[type]
		pulse(intensity)
		pulse_color = original
	else:
		pulse(intensity)


func set_beat(beat: int) -> void:
	_current_beat = beat
	queue_redraw()


func reset() -> void:
	_current_beat = 0
	_indicators.fill(0.0)
	queue_redraw()
