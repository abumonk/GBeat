## ResourceBar - Stylized progress bar for health/mana/stamina
class_name ResourceBar
extends ProgressBar


## Configuration
@export var bar_color: Color = Color(0.2, 0.8, 0.3)
@export var background_color: Color = Color(0.1, 0.1, 0.15)
@export var border_color: Color = Color(0.3, 0.3, 0.4)
@export var damage_color: Color = Color(1.0, 0.2, 0.2)
@export var heal_color: Color = Color(0.2, 1.0, 0.5)
@export var pulse_on_beat: bool = true
@export var low_threshold: float = 0.25  # Flash when below this percentage

## State
var _previous_value: float = 0.0
var _damage_overlay: float = 0.0
var _is_low: bool = false
var _pulse_intensity: float = 0.0
var _tick_handle: int = -1


func _ready() -> void:
	_previous_value = value

	if pulse_on_beat:
		_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAW:
		_custom_draw()


func _custom_draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Background
	draw_rect(rect, background_color)

	# Damage overlay (shows recent damage)
	if _damage_overlay > 0:
		var damage_width := size.x * (_damage_overlay / max_value)
		var current_width := size.x * (value / max_value)
		var damage_rect := Rect2(current_width, 0, damage_width, size.y)
		draw_rect(damage_rect, damage_color)

	# Main bar
	var fill_width := size.x * (value / max_value)
	var fill_rect := Rect2(0, 0, fill_width, size.y)

	var fill_color := bar_color
	if _is_low:
		fill_color = bar_color.lerp(damage_color, 0.5 + sin(Time.get_ticks_msec() * 0.01) * 0.5)

	# Pulse effect
	if _pulse_intensity > 0:
		fill_color = fill_color.lightened(_pulse_intensity * 0.3)

	draw_rect(fill_rect, fill_color)

	# Segment lines
	var segments := 10
	for i in range(1, segments):
		var x := size.x * (float(i) / segments)
		draw_line(Vector2(x, 0), Vector2(x, size.y), border_color.darkened(0.2), 1.0)

	# Border
	draw_rect(rect, border_color, false, 1.0)

	# Value text (optional)
	var font := ThemeDB.fallback_font
	var text := "%d/%d" % [int(value), int(max_value)]
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12)
	var text_pos := Vector2(size.x / 2 - text_size.x / 2, size.y / 2 + 4)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 12, Color.WHITE)


func _on_beat(event: SequencerEvent) -> void:
	if _is_low and event.quant.type == Quant.Type.KICK:
		_pulse_intensity = 0.5
		var tween := create_tween()
		tween.tween_property(self, "_pulse_intensity", 0.0, 0.1)
		tween.tween_callback(queue_redraw)
		queue_redraw()


func set_value_animated(new_value: float) -> void:
	var old_value := value

	if new_value < old_value:
		# Damage - show overlay
		_damage_overlay = old_value - new_value
		var tween := create_tween()
		tween.tween_property(self, "_damage_overlay", 0.0, 0.5)
		tween.tween_callback(queue_redraw)

		# Flash red
		_flash_color(damage_color)
	elif new_value > old_value:
		# Heal - flash green
		_flash_color(heal_color)

	value = new_value
	_previous_value = new_value
	_is_low = (value / max_value) < low_threshold
	queue_redraw()


func _flash_color(color: Color) -> void:
	var original := bar_color
	bar_color = color

	var tween := create_tween()
	tween.tween_property(self, "bar_color", original, 0.2)
	tween.tween_callback(queue_redraw)
