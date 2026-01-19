## TimingIndicator - Visual feedback for action timing
class_name TimingIndicator
extends Control


signal indicator_shown(rating: CombatTypes.TimingRating)


## Configuration
@export var show_duration: float = 0.8
@export var rise_distance: float = 50.0
@export var scale_punch: float = 1.5

## Labels for each rating
@export var perfect_text: String = "PERFECT!"
@export var great_text: String = "GREAT!"
@export var good_text: String = "GOOD"
@export var early_text: String = "EARLY"
@export var late_text: String = "LATE"
@export var miss_text: String = "MISS"

## Colors
@export var perfect_color: Color = Color(1.0, 0.8, 0.0)    ## Gold
@export var great_color: Color = Color(0.2, 1.0, 0.4)      ## Green
@export var good_color: Color = Color(0.4, 0.8, 1.0)       ## Blue
@export var early_color: Color = Color(0.8, 0.5, 0.2)      ## Orange
@export var late_color: Color = Color(0.8, 0.5, 0.2)       ## Orange
@export var miss_color: Color = Color(0.6, 0.2, 0.2)       ## Dark red

## UI elements
var _label: Label
var _show_tween: Tween = null


func _ready() -> void:
	_setup_label()
	visible = false


func _setup_label() -> void:
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.add_theme_font_size_override("font_size", 32)
	add_child(_label)

	# Center in control
	_label.anchors_preset = Control.PRESET_CENTER
	_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_label.grow_vertical = Control.GROW_DIRECTION_BOTH


func show_rating(rating: CombatTypes.TimingRating, screen_position: Vector2 = Vector2.ZERO) -> void:
	if _show_tween and _show_tween.is_valid():
		_show_tween.kill()

	# Set text and color
	_label.text = _get_text_for_rating(rating)
	_label.add_theme_color_override("font_color", _get_color_for_rating(rating))

	# Position
	if screen_position != Vector2.ZERO:
		global_position = screen_position
	else:
		# Center on screen
		global_position = get_viewport_rect().size / 2

	# Reset state
	visible = true
	modulate.a = 1.0
	scale = Vector3.ONE if is_inside_tree() else Vector3.ONE
	_label.scale = Vector2.ONE

	# Animate
	_show_tween = create_tween()
	_show_tween.set_parallel(true)

	# Scale punch
	_show_tween.tween_property(_label, "scale", Vector2.ONE * scale_punch, 0.1).set_ease(Tween.EASE_OUT)
	_show_tween.chain().tween_property(_label, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_IN_OUT)

	# Rise up
	var start_pos := position
	_show_tween.tween_property(self, "position:y", position.y - rise_distance, show_duration).set_ease(Tween.EASE_OUT)

	# Fade out
	_show_tween.tween_property(self, "modulate:a", 0.0, show_duration).set_ease(Tween.EASE_IN).set_delay(show_duration * 0.5)

	# Hide when done
	_show_tween.chain().tween_callback(func():
		visible = false
		position = start_pos
	)

	indicator_shown.emit(rating)


func show_combo(combo_count: int, screen_position: Vector2 = Vector2.ZERO) -> void:
	if _show_tween and _show_tween.is_valid():
		_show_tween.kill()

	# Set text with combo count
	_label.text = "%d COMBO!" % combo_count

	# Color based on combo level
	var color: Color
	if combo_count >= 50:
		color = perfect_color
	elif combo_count >= 25:
		color = great_color
	elif combo_count >= 10:
		color = good_color
	else:
		color = Color.WHITE

	_label.add_theme_color_override("font_color", color)

	# Position
	if screen_position != Vector2.ZERO:
		global_position = screen_position
	else:
		global_position = get_viewport_rect().size / 2

	# Reset and animate
	visible = true
	modulate.a = 1.0
	_label.scale = Vector2.ONE

	_show_tween = create_tween()

	# Bigger scale punch for higher combos
	var punch := scale_punch + (combo_count / 50.0) * 0.5
	_show_tween.tween_property(_label, "scale", Vector2.ONE * punch, 0.15).set_ease(Tween.EASE_OUT)
	_show_tween.tween_property(_label, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_IN_OUT)
	_show_tween.parallel().tween_property(self, "position:y", position.y - rise_distance, show_duration)
	_show_tween.parallel().tween_property(self, "modulate:a", 0.0, show_duration).set_delay(0.3)
	_show_tween.tween_callback(func(): visible = false)


func _get_text_for_rating(rating: CombatTypes.TimingRating) -> String:
	match rating:
		CombatTypes.TimingRating.PERFECT:
			return perfect_text
		CombatTypes.TimingRating.GREAT:
			return great_text
		CombatTypes.TimingRating.GOOD:
			return good_text
		CombatTypes.TimingRating.EARLY:
			return early_text
		CombatTypes.TimingRating.LATE:
			return late_text
		CombatTypes.TimingRating.MISS:
			return miss_text
	return ""


func _get_color_for_rating(rating: CombatTypes.TimingRating) -> Color:
	match rating:
		CombatTypes.TimingRating.PERFECT:
			return perfect_color
		CombatTypes.TimingRating.GREAT:
			return great_color
		CombatTypes.TimingRating.GOOD:
			return good_color
		CombatTypes.TimingRating.EARLY:
			return early_color
		CombatTypes.TimingRating.LATE:
			return late_color
		CombatTypes.TimingRating.MISS:
			return miss_color
	return Color.WHITE
