## ComboCounter - Displays current combo count with visual flair
class_name ComboCounter
extends Control


## Configuration
@export var base_font_size: int = 32
@export var max_font_size: int = 64
@export var combo_colors: Array[Color] = [
	Color(1.0, 1.0, 1.0),      # White (1-9)
	Color(1.0, 1.0, 0.0),      # Yellow (10-24)
	Color(1.0, 0.5, 0.0),      # Orange (25-49)
	Color(1.0, 0.0, 0.5),      # Pink (50-99)
	Color(0.0, 1.0, 1.0),      # Cyan (100+)
]
@export var shake_intensity: float = 5.0
@export var pulse_scale: float = 1.3

## State
var _combo: int = 0
var _multiplier: float = 1.0
var _shake_offset: Vector2 = Vector2.ZERO
var _current_scale: float = 1.0
var _tween: Tween


func _ready() -> void:
	# Subscribe to beat for subtle pulse
	Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _draw() -> void:
	if _combo <= 0:
		return

	var font := ThemeDB.fallback_font
	var font_size := _get_font_size()
	var color := _get_combo_color()

	# Combo text
	var combo_text := "%d" % _combo
	var text_size := font.get_string_size(combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := size / 2 - text_size / 2 + _shake_offset
	pos *= _current_scale

	# Draw shadow
	draw_string(font, pos + Vector2(2, 2), combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.5))

	# Draw main text
	draw_string(font, pos, combo_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

	# Draw multiplier
	if _multiplier > 1.0:
		var mult_text := "x%.1f" % _multiplier
		var mult_size := font.get_string_size(mult_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size / 2)
		var mult_pos := Vector2(size.x / 2 - mult_size.x / 2, size.y / 2 + text_size.y / 2 + 5) + _shake_offset
		draw_string(font, mult_pos, mult_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size / 2, color.lightened(0.3))


func _get_font_size() -> int:
	var progress := clampf(float(_combo) / 100.0, 0.0, 1.0)
	return int(lerpf(base_font_size, max_font_size, progress))


func _get_combo_color() -> Color:
	if _combo < 10:
		return combo_colors[0]
	elif _combo < 25:
		return combo_colors[1]
	elif _combo < 50:
		return combo_colors[2]
	elif _combo < 100:
		return combo_colors[3]
	else:
		return combo_colors[4]


func _on_beat(event: SequencerEvent) -> void:
	if _combo > 0 and event.quant.type == Quant.Type.KICK:
		_pulse()


func _pulse() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_ELASTIC)

	_current_scale = pulse_scale
	_tween.tween_property(self, "_current_scale", 1.0, 0.3)
	_tween.tween_callback(queue_redraw)


func set_combo(combo: int, multiplier: float = 1.0) -> void:
	var previous := _combo
	_combo = combo
	_multiplier = multiplier

	# Big combo milestone effects
	if combo > previous and combo > 0:
		if combo % 10 == 0:
			_big_pulse()
		else:
			_pulse()

		# Shake on combo increase
		_shake()

	queue_redraw()


func _big_pulse() -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_ease(Tween.EASE_OUT)
	_tween.set_trans(Tween.TRANS_ELASTIC)

	_current_scale = pulse_scale * 1.5
	_tween.tween_property(self, "_current_scale", 1.0, 0.5)


func _shake() -> void:
	var intensity := minf(shake_intensity * (_combo / 50.0), shake_intensity * 2)
	_shake_offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))

	var tween := create_tween()
	tween.tween_property(self, "_shake_offset", Vector2.ZERO, 0.1)


func reset() -> void:
	_combo = 0
	_multiplier = 1.0
	_current_scale = 1.0
	_shake_offset = Vector2.ZERO
	queue_redraw()


func get_combo() -> int:
	return _combo


func get_multiplier() -> float:
	return _multiplier
