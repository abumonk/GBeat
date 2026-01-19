## BeatMovementComponent - Handles beat-synchronized movement
class_name BeatMovementComponent
extends Node

signal movement_started()
signal movement_stopped()
signal velocity_changed(velocity: Vector3)

## Configuration
@export var base_speed: float = 5.0
@export var acceleration: float = 20.0
@export var deceleration: float = 30.0
@export var rotation_speed: float = 10.0
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Reference to character
@export var character: CharacterBody3D
@export var controller: PlayerController

## State
var state: MovementTypes.MovementState = MovementTypes.MovementState.new()
var _target_velocity: Vector3 = Vector3.ZERO
var _target_facing: Vector3 = Vector3.FORWARD

## Quant subscriptions
var _forward_speed_handle: int = -1
var _right_speed_handle: int = -1
var _rotation_handle: int = -1

## Speed multipliers from pattern
var _pattern_forward_speed: float = 1.0
var _pattern_right_speed: float = 1.0
var _pattern_rotation_speed: float = 1.0


func _ready() -> void:
	# Subscribe to movement quants
	_forward_speed_handle = Sequencer.subscribe(
		sequencer_deck,
		Quant.Type.MOVE_FORWARD_SPEED,
		_on_forward_speed_quant
	)
	_right_speed_handle = Sequencer.subscribe(
		sequencer_deck,
		Quant.Type.MOVE_RIGHT_SPEED,
		_on_right_speed_quant
	)
	_rotation_handle = Sequencer.subscribe(
		sequencer_deck,
		Quant.Type.ROTATION_SPEED,
		_on_rotation_quant
	)


func _exit_tree() -> void:
	if _forward_speed_handle >= 0:
		Sequencer.unsubscribe(_forward_speed_handle)
	if _right_speed_handle >= 0:
		Sequencer.unsubscribe(_right_speed_handle)
	if _rotation_handle >= 0:
		Sequencer.unsubscribe(_rotation_handle)


func _physics_process(delta: float) -> void:
	if not character or not controller:
		return

	_update_target_velocity()
	_apply_movement(delta)
	_apply_rotation(delta)
	_update_state()


func _update_target_velocity() -> void:
	if controller.is_moving():
		var world_dir := controller.get_world_direction()
		var speed := base_speed * controller.get_input_magnitude()

		# Apply pattern speed modifiers
		var forward := -character.global_transform.basis.z
		var right := character.global_transform.basis.x

		var forward_component := world_dir.dot(forward)
		var right_component := world_dir.dot(right)

		forward_component *= _pattern_forward_speed
		right_component *= _pattern_right_speed

		_target_velocity = (forward * forward_component + right * right_component).normalized() * speed
		_target_facing = world_dir
	else:
		_target_velocity = Vector3.ZERO


func _apply_movement(delta: float) -> void:
	var current := character.velocity
	current.y = 0  # Ignore vertical for ground movement

	if _target_velocity.length_squared() > 0.01:
		# Accelerate towards target
		character.velocity.x = move_toward(current.x, _target_velocity.x, acceleration * delta)
		character.velocity.z = move_toward(current.z, _target_velocity.z, acceleration * delta)
	else:
		# Decelerate
		character.velocity.x = move_toward(current.x, 0, deceleration * delta)
		character.velocity.z = move_toward(current.z, 0, deceleration * delta)

	# Apply gravity
	if not character.is_on_floor():
		character.velocity.y -= 9.8 * delta
	else:
		character.velocity.y = 0

	character.move_and_slide()

	velocity_changed.emit(character.velocity)


func _apply_rotation(delta: float) -> void:
	if _target_facing.length_squared() < 0.01:
		return

	var current_forward := -character.global_transform.basis.z
	current_forward.y = 0
	current_forward = current_forward.normalized()

	var target := _target_facing
	target.y = 0
	target = target.normalized()

	var angle_diff := current_forward.signed_angle_to(target, Vector3.UP)

	var rot_amount := rotation_speed * _pattern_rotation_speed * delta
	rot_amount = min(rot_amount, abs(angle_diff))

	if angle_diff != 0:
		character.rotate_y(sign(angle_diff) * rot_amount)


func _update_state() -> void:
	var horizontal_vel := Vector2(character.velocity.x, character.velocity.z)
	var was_moving := state.is_moving

	state.velocity = character.velocity
	state.facing_direction = -character.global_transform.basis.z
	state.is_grounded = character.is_on_floor()
	state.current_speed = horizontal_vel.length()
	state.is_moving = state.current_speed > 0.1

	if state.is_moving and not was_moving:
		movement_started.emit()
	elif not state.is_moving and was_moving:
		movement_stopped.emit()


## Quant event handlers

func _on_forward_speed_quant(event: SequencerEvent) -> void:
	_pattern_forward_speed = event.quant.value


func _on_right_speed_quant(event: SequencerEvent) -> void:
	_pattern_right_speed = event.quant.value


func _on_rotation_quant(event: SequencerEvent) -> void:
	_pattern_rotation_speed = event.quant.value


## Public API

func get_velocity() -> Vector3:
	return state.velocity


func get_speed() -> float:
	return state.current_speed


func is_moving() -> bool:
	return state.is_moving


func get_facing_direction() -> Vector3:
	return state.facing_direction


func set_base_speed(speed: float) -> void:
	base_speed = speed
