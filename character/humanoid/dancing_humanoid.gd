## DancingHumanoid - Humanoid character that dances to the beat
class_name DancingHumanoid
extends Node3D


signal dance_style_changed(style: DanceMoves.DanceStyle)


## Configuration
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
@export var auto_change_style: bool = true
@export var style_change_bars: int = 4

## Character
var humanoid: HumanoidCharacter
var dance_state: DanceMoves.DanceState

## State
var _tick_handle: int = -1
var _animation_handle: int = -1
var _beat_count: int = 0
var _current_beat_phase: float = 0.0


func _ready() -> void:
	_create_humanoid()
	_setup_dance_state()
	_subscribe_to_sequencer()


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)
	if _animation_handle >= 0:
		Sequencer.unsubscribe(_animation_handle)


func _create_humanoid() -> void:
	humanoid = HumanoidCharacter.new()
	humanoid.randomize_on_ready = true
	humanoid.auto_generate = true
	add_child(humanoid)


func _setup_dance_state() -> void:
	dance_state = DanceMoves.DanceState.new()
	dance_state.current_style = DanceMoves.random_style()
	dance_state.intensity = randf_range(0.7, 1.0)


func _subscribe_to_sequencer() -> void:
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)
	_animation_handle = Sequencer.subscribe(sequencer_deck, Quant.Type.ANIMATION, _on_animation)


func _process(delta: float) -> void:
	if not humanoid or not humanoid.skeleton:
		return

	# Get current beat phase from sequencer
	var deck := Sequencer.get_deck(sequencer_deck)
	if deck and deck.is_playing():
		_current_beat_phase = deck.get_beat_phase()

	# Apply dance animation
	DanceMoves.apply_dance(humanoid.skeleton, dance_state, _current_beat_phase)


func _on_tick(event: SequencerEvent) -> void:
	_beat_count += 1

	# Change style every N bars (32 quants per bar)
	if auto_change_style and _beat_count >= style_change_bars * 32:
		_beat_count = 0
		change_dance_style(DanceMoves.random_style())


func _on_animation(event: SequencerEvent) -> void:
	# Could trigger specific moves on animation quants
	pass


## === Public API ===

func set_dance_style(style: DanceMoves.DanceStyle) -> void:
	dance_state.current_style = style
	dance_style_changed.emit(style)


func change_dance_style(new_style: DanceMoves.DanceStyle) -> void:
	if new_style != dance_state.current_style:
		set_dance_style(new_style)


func set_intensity(intensity: float) -> void:
	dance_state.intensity = clamp(intensity, 0.0, 2.0)


func get_humanoid() -> HumanoidCharacter:
	return humanoid


func randomize_appearance() -> void:
	if humanoid:
		humanoid.randomize_appearance()
		humanoid.generate()
