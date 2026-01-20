## TimingIndicator - Shows timing feedback (Perfect, Great, Good, Miss)
class_name TimingIndicator
extends Control


## Configuration
@export var rating_colors: Dictionary = {
	"PERFECT": Color(1.0, 1.0, 0.0),    # Gold
	"GREAT": Color(0.0, 1.0, 0.5),      # Green
	"GOOD": Color(0.0, 0.8, 1.0),       # Cyan
	"EARLY": Color(1.0, 0.5, 0.0),      # Orange
	"LATE": Color(1.0, 0.3, 0.3),       # Red
	"MISS": Color(0.5, 0.5, 0.5),       # Gray
}
@export var rating_sizes: Dictionary = {
	"PERFECT": 48,
	"GREAT": 40,
	"GOOD": 32,
	"EARLY": 28,
	"LATE": 28,
	"MISS": 24,
}
@export var display_duration: float = 0.5
@export var float_distance: float = 30.0

## State
var _current_rating: String = ""
var _current_accuracy: float = 0.0
var _display_alpha: float = 0.0
var _float_offset: float = 0.0
var _tween: Tween


func _draw() -> void:
	if _current_rating.is_empty() or _display_alpha <= 0:
		return

	var font := ThemeDB.fallback_font
	var font_size: int = rating_sizes.get(_current_rating, 32)
	var color: Color = rating_colors.get(_current_rating, Color.WHITE)
	color.a = _display_alpha

	var text_size := font.get_string_size(_current_rating, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var pos := Vector2(size.x / 2 - text_size.x / 2, size.y / 2 - _float_offset)

	# Shadow
	draw_string(font, pos + Vector2(2, 2), _current_rating, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, _display_alpha * 0.5))

	# Main text
	draw_string(font, pos, _current_rating, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, color)

	# Accuracy bar (optional)
	if _current_accuracy > 0 and _current_rating != "MISS":
		var bar_width := 100.0
		var bar_height := 4.0
		var bar_x := size.x / 2 - bar_width / 2
		var bar_y := pos.y + 10

		# Background
		draw_rect(Rect2(bar_x, bar_y, bar_width, bar_height), Color(0.2, 0.2, 0.2, _display_alpha))

		# Fill
		var fill_width := bar_width * _current_accuracy
		draw_rect(Rect2(bar_x, bar_y, fill_width, bar_height), Color(color.r, color.g, color.b, _display_alpha))


func show_rating(rating: String, accuracy: float = 1.0) -> void:
	_current_rating = rating.to_upper()
	_current_accuracy = accuracy

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.set_parallel(true)

	# Fade in quickly
	_display_alpha = 0.0
	_tween.tween_property(self, "_display_alpha", 1.0, 0.05)

	# Float up
	_float_offset = 0.0
	_tween.tween_property(self, "_float_offset", float_distance, display_duration).set_ease(Tween.EASE_OUT)

	# Fade out
	_tween.chain().tween_property(self, "_display_alpha", 0.0, 0.2)

	# Redraw during animation
	_tween.set_parallel(false)
	_tween.tween_callback(queue_redraw).set_delay(0.01)

	queue_redraw()


func show_perfect() -> void:
	show_rating("PERFECT", 1.0)


func show_great() -> void:
	show_rating("GREAT", 0.85)


func show_good() -> void:
	show_rating("GOOD", 0.7)


func show_miss() -> void:
	show_rating("MISS", 0.0)


func show_early() -> void:
	show_rating("EARLY", 0.5)


func show_late() -> void:
	show_rating("LATE", 0.5)
