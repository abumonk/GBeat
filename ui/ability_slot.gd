## AbilitySlot - Single ability slot with icon, cooldown, and input hint
class_name AbilitySlot
extends Control


signal activated()


## Configuration
@export var slot_index: int = 0
@export var input_key: String = "ability_1"
@export var background_color: Color = Color(0.1, 0.1, 0.15, 0.8)
@export var border_color: Color = Color(0.3, 0.3, 0.4)
@export var cooldown_color: Color = Color(0.0, 0.0, 0.0, 0.7)
@export var ready_color: Color = Color(0.0, 1.0, 0.8, 0.5)
@export var active_color: Color = Color(1.0, 1.0, 1.0)

## State
var _ability_data: Resource
var _cooldown_remaining: float = 0.0
var _cooldown_total: float = 1.0
var _is_ready: bool = true
var _flash_tween: Tween


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _input(event: InputEvent) -> void:
	if event.is_action_pressed(input_key) and _is_ready:
		activated.emit()


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)

	# Background
	draw_rect(rect, background_color)

	# Ability icon (if available)
	if _ability_data and _ability_data.get("icon"):
		var icon: Texture2D = _ability_data.icon
		var icon_rect := Rect2(Vector2(4, 4), size - Vector2(8, 8))
		draw_texture_rect(icon, icon_rect, false)
	else:
		# Placeholder
		var inner := rect.grow(-8)
		draw_rect(inner, border_color.darkened(0.3))

	# Cooldown overlay
	if not _is_ready and _cooldown_total > 0:
		var progress := _cooldown_remaining / _cooldown_total
		var cooldown_height := size.y * progress
		var cooldown_rect := Rect2(0, size.y - cooldown_height, size.x, cooldown_height)
		draw_rect(cooldown_rect, cooldown_color)

		# Cooldown text
		var font := ThemeDB.fallback_font
		var cd_text := "%.1f" % _cooldown_remaining
		var text_size := font.get_string_size(cd_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16)
		var text_pos := size / 2 - text_size / 2
		draw_string(font, text_pos, cd_text, HORIZONTAL_ALIGNMENT_CENTER, -1, 16, Color.WHITE)

	# Ready glow
	if _is_ready:
		draw_rect(rect, ready_color, false, 2.0)

	# Border
	draw_rect(rect, border_color, false, 1.0)

	# Input hint
	var font := ThemeDB.fallback_font
	var key_text := str(slot_index + 1)
	draw_string(font, Vector2(4, 14), key_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.7, 0.7, 0.7))


func _process(delta: float) -> void:
	if _cooldown_remaining > 0:
		_cooldown_remaining = maxf(0, _cooldown_remaining - delta)
		if _cooldown_remaining <= 0:
			_is_ready = true
			_flash_ready()
		queue_redraw()


func set_ability(ability_data: Resource) -> void:
	_ability_data = ability_data
	queue_redraw()


func set_cooldown(remaining: float, total: float) -> void:
	_cooldown_remaining = remaining
	_cooldown_total = total
	_is_ready = remaining <= 0
	queue_redraw()


func trigger_used() -> void:
	_is_ready = false
	_flash_used()


func _flash_used() -> void:
	if _flash_tween:
		_flash_tween.kill()

	_flash_tween = create_tween()
	var original := modulate
	modulate = active_color
	_flash_tween.tween_property(self, "modulate", original, 0.2)


func _flash_ready() -> void:
	if _flash_tween:
		_flash_tween.kill()

	_flash_tween = create_tween()
	_flash_tween.set_ease(Tween.EASE_OUT)
	_flash_tween.set_trans(Tween.TRANS_ELASTIC)

	var original_scale := scale
	scale = Vector2(1.2, 1.2)
	_flash_tween.tween_property(self, "scale", original_scale, 0.3)


func is_ready() -> bool:
	return _is_ready
