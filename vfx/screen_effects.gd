## ScreenEffects - Post-processing effects synced to beat and combat
class_name ScreenEffects
extends CanvasLayer


signal effect_triggered(effect_type: VFXTypes.ScreenEffectType)


## Screen flash
@export var flash_rect: ColorRect
@export var flash_color: Color = Color(1, 1, 1, 0.5)
@export var flash_duration: float = 0.1

## Vignette
@export var vignette_rect: ColorRect
@export var vignette_base_intensity: float = 0.3
@export var vignette_pulse_intensity: float = 0.6

## Chromatic aberration (shader-based)
@export var aberration_amount: float = 0.0
@export var aberration_pulse_amount: float = 5.0

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
@export var pulse_on_beat: bool = true

## State
var _tick_handle: int = -1
var _flash_tween: Tween = null
var _vignette_tween: Tween = null
var _vignette_material: ShaderMaterial = null


func _ready() -> void:
	_setup_flash_rect()
	_setup_vignette()

	if pulse_on_beat:
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_flash_rect() -> void:
	if not flash_rect:
		flash_rect = ColorRect.new()
		flash_rect.color = Color(1, 1, 1, 0)
		flash_rect.anchors_preset = Control.PRESET_FULL_RECT
		flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(flash_rect)


func _setup_vignette() -> void:
	if not vignette_rect:
		vignette_rect = ColorRect.new()
		vignette_rect.anchors_preset = Control.PRESET_FULL_RECT
		vignette_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

		# Create vignette shader
		var shader := Shader.new()
		shader.code = _get_vignette_shader()

		_vignette_material = ShaderMaterial.new()
		_vignette_material.shader = shader
		_vignette_material.set_shader_parameter("intensity", vignette_base_intensity)
		_vignette_material.set_shader_parameter("softness", 0.5)
		_vignette_material.set_shader_parameter("color", Color(0, 0, 0))

		vignette_rect.material = _vignette_material
		add_child(vignette_rect)


func _get_vignette_shader() -> String:
	return """
shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.3;
uniform float softness : hint_range(0.0, 1.0) = 0.5;
uniform vec4 color : source_color = vec4(0.0, 0.0, 0.0, 1.0);

void fragment() {
	vec2 uv = UV - 0.5;
	float dist = length(uv);
	float vignette = smoothstep(0.5 - softness * 0.5, 0.5, dist * (1.0 + intensity));
	COLOR = vec4(color.rgb, vignette * color.a);
}
"""


func _on_tick(_event: SequencerEvent) -> void:
	pulse_vignette(0.3)


## === Flash Effects ===

func flash(color: Color = Color.WHITE, intensity: float = 0.5, duration: float = -1.0) -> void:
	if not flash_rect:
		return

	var dur := duration if duration > 0 else flash_duration

	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	flash_rect.color = Color(color.r, color.g, color.b, intensity)

	_flash_tween = create_tween()
	_flash_tween.set_ease(Tween.EASE_OUT)
	_flash_tween.set_trans(Tween.TRANS_EXPO)
	_flash_tween.tween_property(flash_rect, "color:a", 0.0, dur)

	effect_triggered.emit(VFXTypes.ScreenEffectType.FLASH)


func flash_hit(intensity: float = 0.3) -> void:
	flash(Color.WHITE, intensity, 0.08)


func flash_damage(intensity: float = 0.4) -> void:
	flash(Color.RED, intensity, 0.15)


func flash_perfect(intensity: float = 0.3) -> void:
	flash(Color(1.0, 0.8, 0.2), intensity, 0.1)


## === Vignette Effects ===

func pulse_vignette(intensity: float = 0.3, duration: float = 0.2) -> void:
	if not _vignette_material:
		return

	if _vignette_tween and _vignette_tween.is_valid():
		_vignette_tween.kill()

	var target := vignette_base_intensity + (vignette_pulse_intensity - vignette_base_intensity) * intensity

	_vignette_material.set_shader_parameter("intensity", target)

	_vignette_tween = create_tween()
	_vignette_tween.set_ease(Tween.EASE_OUT)
	_vignette_tween.set_trans(Tween.TRANS_EXPO)
	_vignette_tween.tween_method(
		func(val): _vignette_material.set_shader_parameter("intensity", val),
		target,
		vignette_base_intensity,
		duration
	)

	effect_triggered.emit(VFXTypes.ScreenEffectType.VIGNETTE)


func set_vignette_intensity(intensity: float) -> void:
	vignette_base_intensity = intensity
	if _vignette_material:
		_vignette_material.set_shader_parameter("intensity", intensity)


func set_vignette_color(color: Color) -> void:
	if _vignette_material:
		_vignette_material.set_shader_parameter("color", color)


## === Damage Vignette ===

func show_damage_vignette(health_percent: float) -> void:
	# Increase vignette intensity as health decreases
	var damage_intensity := (1.0 - health_percent) * 0.5
	set_vignette_intensity(vignette_base_intensity + damage_intensity)
	set_vignette_color(Color(0.3, 0, 0))


func clear_damage_vignette() -> void:
	set_vignette_intensity(vignette_base_intensity)
	set_vignette_color(Color(0, 0, 0))


## === Combo Effects ===

func combo_effect(combo_count: int) -> void:
	# Intensify effects with combo
	var intensity := min(combo_count / 20.0, 1.0)
	flash(Color(1.0, 0.8, 0.2), 0.1 + intensity * 0.2, 0.05)
