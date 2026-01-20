## MovementAnimComponent - Handles animation synchronization with movement
class_name MovementAnimComponent
extends Node


signal step_taken(foot: MovementTypes.Foot)
signal animation_changed(anim_name: String)


## Configuration
@export var animation_player: AnimationPlayer
@export var movement_component: BeatMovementComponent
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Animation mappings
@export var idle_animation: String = "idle"
@export var walk_animation: String = "walk"
@export var run_animation: String = "run"
@export var walk_speed_threshold: float = 2.0
@export var run_speed_threshold: float = 5.0

## State
var current_animation: String = ""
var current_foot: MovementTypes.Foot = MovementTypes.Foot.NONE
var _tick_handle: int = -1
var _step_pending: bool = false


func _ready() -> void:
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_beat)

	if movement_component:
		movement_component.movement_started.connect(_on_movement_started)
		movement_component.movement_stopped.connect(_on_movement_stopped)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(_delta: float) -> void:
	_update_animation()


func _update_animation() -> void:
	if not movement_component or not animation_player:
		return

	var speed := movement_component.get_speed()
	var target_anim := idle_animation

	if speed > run_speed_threshold:
		target_anim = run_animation
	elif speed > walk_speed_threshold:
		target_anim = walk_animation

	if target_anim != current_animation:
		_play_animation(target_anim)


func _play_animation(anim_name: String) -> void:
	if not animation_player:
		return

	if animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
		current_animation = anim_name
		animation_changed.emit(anim_name)


func _on_beat(event: SequencerEvent) -> void:
	# Handle step timing on beat
	if event.quant.type == Quant.Type.TICK:
		if movement_component and movement_component.is_moving():
			_take_step()


func _take_step() -> void:
	# Alternate feet
	current_foot = MovementTypes.opposite_foot(current_foot)
	if current_foot == MovementTypes.Foot.NONE:
		current_foot = MovementTypes.Foot.LEFT

	step_taken.emit(current_foot)


func _on_movement_started() -> void:
	current_foot = MovementTypes.Foot.NONE


func _on_movement_stopped() -> void:
	current_foot = MovementTypes.Foot.NONE
	_play_animation(idle_animation)


## Get current foot for animation blending
func get_current_foot() -> MovementTypes.Foot:
	return current_foot


## Force sync animation to beat
func sync_to_beat(beat_position: float) -> void:
	if animation_player and animation_player.is_playing():
		var anim_length := animation_player.current_animation_length
		if anim_length > 0:
			animation_player.seek(fmod(beat_position, anim_length))
