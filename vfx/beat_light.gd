## BeatLight - Light that pulses to the beat
class_name BeatLight
extends Node


signal pulsed(intensity: float)


## Configuration
@export var light: Light3D
@export var base_energy: float = 1.0
@export var pulse_energy: float = 2.0
@export var base_color: Color = Color.WHITE
@export var pulse_color: Color = Color.WHITE

## Pulse settings
@export var pulse_mode: VFXTypes.PulseMode = VFXTypes.PulseMode.ON_BEAT
@export var quant_type: Quant.Type = Quant.Type.KICK
@export var pulse_duration: float = 0.15
@export var ease_type: Tween.EaseType = Tween.EASE_OUT
@export var trans_type: Tween.TransitionType = Tween.TRANS_EXPO

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## State
var _tick_handle: int = -1
var _quant_handle: int = -1
var _pulse_tween: Tween = null
var _current_intensity: float = 0.0


func _ready() -> void:
	if not light:
		push_warning("BeatLight: No light assigned")
		return

	# Set initial state
	light.light_energy = base_energy
	light.light_color = base_color

	# Subscribe based on mode
	match pulse_mode:
		VFXTypes.PulseMode.ON_BEAT, VFXTypes.PulseMode.ON_BAR:
			_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)
		VFXTypes.PulseMode.ON_QUANT:
			_quant_handle = Sequencer.subscribe(sequencer_deck, quant_type, _on_quant)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)
	if _quant_handle >= 0:
		Sequencer.unsubscribe(_quant_handle)


func _on_tick(event: SequencerEvent) -> void:
	match pulse_mode:
		VFXTypes.PulseMode.ON_BEAT:
			pulse(1.0)
		VFXTypes.PulseMode.ON_BAR:
			if event.quant_index == 0:  ## Start of bar
				pulse(1.0)


func _on_quant(event: SequencerEvent) -> void:
	pulse(event.quant.value)


func pulse(intensity: float = 1.0) -> void:
	if not light:
		return

	_current_intensity = intensity

	# Cancel existing tween
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	# Set to pulse values
	var target_energy := lerpf(base_energy, pulse_energy, intensity)
	var target_color := base_color.lerp(pulse_color, intensity)

	light.light_energy = target_energy
	light.light_color = target_color

	# Tween back to base
	_pulse_tween = create_tween()
	_pulse_tween.set_ease(ease_type)
	_pulse_tween.set_trans(trans_type)
	_pulse_tween.set_parallel(true)
	_pulse_tween.tween_property(light, "light_energy", base_energy, pulse_duration)
	_pulse_tween.tween_property(light, "light_color", base_color, pulse_duration)

	pulsed.emit(intensity)


func set_base_energy(energy: float) -> void:
	base_energy = energy
	if light and not _pulse_tween:
		light.light_energy = energy


func set_pulse_energy(energy: float) -> void:
	pulse_energy = energy


func set_colors(base: Color, pulse: Color) -> void:
	base_color = base
	pulse_color = pulse
	if light and not _pulse_tween:
		light.light_color = base
