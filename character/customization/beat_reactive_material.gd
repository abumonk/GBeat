## BeatReactiveMaterial - Material that pulses with the beat
class_name BeatReactiveMaterial
extends CustomMaterial


signal beat_pulsed()


## Beat reaction settings
@export_group("Beat Reaction")
@export var pulse_on_beat: bool = true
@export var react_to_quant: Quant.Type = Quant.Type.KICK
@export_range(0.0, 2.0) var pulse_intensity: float = 0.5
@export var pulse_duration: float = 0.15

## What property to pulse
@export_enum("emission_strength", "metallic", "roughness") var pulse_property: String = "emission_strength"

## Sequencer settings
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Internal state
var _tick_handle: int = -1
var _base_value: float = 0.0
var _pulse_tween: Tween = null
var _is_registered: bool = false


func register_with_sequencer() -> void:
	if _is_registered:
		return

	# Store base value
	_base_value = get(pulse_property)

	# Subscribe to sequencer
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)
	_is_registered = true


func unregister_from_sequencer() -> void:
	if not _is_registered:
		return

	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)
		_tick_handle = -1

	_is_registered = false


func _on_tick(event: SequencerEvent) -> void:
	if not pulse_on_beat:
		return

	if event.quant.type == react_to_quant:
		_pulse(event.quant.value)


func _pulse(intensity_multiplier: float = 1.0) -> void:
	var current_value: float = get(pulse_property)
	var pulse_amount := pulse_intensity * intensity_multiplier

	# Calculate target value
	var target_value := current_value + pulse_amount

	# Clamp based on property
	match pulse_property:
		"emission_strength":
			target_value = clampf(target_value, 0.0, 16.0)
		"metallic", "roughness":
			target_value = clampf(target_value, 0.0, 1.0)

	# Cancel existing tween
	if _pulse_tween:
		_pulse_tween.kill()

	# Create pulse animation
	_pulse_tween = Engine.get_main_loop().create_tween()
	_pulse_tween.set_trans(Tween.TRANS_EXPO)
	_pulse_tween.set_ease(Tween.EASE_OUT)

	# Quick rise
	_pulse_tween.tween_property(self, pulse_property, target_value, pulse_duration * 0.2)
	# Slow fall back
	_pulse_tween.tween_property(self, pulse_property, _base_value, pulse_duration * 0.8)

	beat_pulsed.emit()


func trigger_pulse(intensity: float = 1.0) -> void:
	_pulse(intensity)


func set_base_value(value: float) -> void:
	_base_value = value
	set(pulse_property, value)


func get_base_value() -> float:
	return _base_value


func serialize() -> Dictionary:
	var data := super.serialize()
	data["pulse_on_beat"] = pulse_on_beat
	data["react_to_quant"] = react_to_quant
	data["pulse_intensity"] = pulse_intensity
	data["pulse_duration"] = pulse_duration
	data["pulse_property"] = pulse_property
	return data


static func deserialize_reactive(data: Dictionary) -> BeatReactiveMaterial:
	var mat := BeatReactiveMaterial.new()

	# Base material properties
	mat.base_color = Color.html(data.get("base_color", "#ffffff"))
	var pattern_path: String = data.get("pattern_path", "")
	if pattern_path and ResourceLoader.exists(pattern_path):
		mat.pattern = load(pattern_path)
	mat.pattern_scale = data.get("pattern_scale", 1.0)
	mat.pattern_color = Color.html(data.get("pattern_color", "#000000"))
	mat.metallic = data.get("metallic", 0.0)
	mat.roughness = data.get("roughness", 0.5)
	mat.specular = data.get("specular", 0.5)
	mat.emission_enabled = data.get("emission_enabled", false)
	mat.emission_color = Color.html(data.get("emission_color", "#ffffff"))
	mat.emission_strength = data.get("emission_strength", 1.0)

	# Reactive properties
	mat.pulse_on_beat = data.get("pulse_on_beat", true)
	mat.react_to_quant = data.get("react_to_quant", Quant.Type.KICK)
	mat.pulse_intensity = data.get("pulse_intensity", 0.5)
	mat.pulse_duration = data.get("pulse_duration", 0.15)
	mat.pulse_property = data.get("pulse_property", "emission_strength")

	return mat


## Factory methods
static func create_beat_glow(color: Color, intensity: float = 2.0) -> BeatReactiveMaterial:
	var mat := BeatReactiveMaterial.new()
	mat.base_color = color
	mat.emission_enabled = true
	mat.emission_color = color
	mat.emission_strength = 0.5
	mat.pulse_on_beat = true
	mat.pulse_property = "emission_strength"
	mat.pulse_intensity = intensity
	return mat


static func create_beat_flash(color: Color) -> BeatReactiveMaterial:
	var mat := BeatReactiveMaterial.new()
	mat.base_color = color
	mat.metallic = 0.0
	mat.roughness = 0.5
	mat.pulse_on_beat = true
	mat.pulse_property = "metallic"
	mat.pulse_intensity = 0.8
	return mat


static func create_snare_reactive(color: Color) -> BeatReactiveMaterial:
	var mat := create_beat_glow(color)
	mat.react_to_quant = Quant.Type.SNARE
	return mat


static func create_hat_reactive(color: Color) -> BeatReactiveMaterial:
	var mat := create_beat_glow(color, 1.0)
	mat.react_to_quant = Quant.Type.HAT
	mat.pulse_duration = 0.1
	return mat
