## PlayerController - Handles input capture and quantization
class_name PlayerController
extends Node

signal input_changed(snapshot: MovementTypes.InputSnapshot)

## Input settings
@export var dead_zone: float = 0.15
@export var magnitude_step: float = 0.5  ## Quantize to 0, 0.5, 1.0
@export var direction_snap_angles: int = 8  ## 8 = 45 degree increments

## Camera reference for relative input
@export var camera: Camera3D

var current_snapshot: MovementTypes.InputSnapshot = MovementTypes.InputSnapshot.new()
var _last_quantized: Vector2 = Vector2.ZERO


func _process(_delta: float) -> void:
	_capture_input()


func _capture_input() -> void:
	# Get raw input
	var raw := Vector2.ZERO
	raw.x = Input.get_axis("move_left", "move_right")
	raw.y = Input.get_axis("move_up", "move_down")

	current_snapshot.raw_input = raw
	current_snapshot.timestamp = Time.get_ticks_msec() / 1000.0

	# Apply dead zone
	if raw.length() < dead_zone:
		raw = Vector2.ZERO

	# Quantize magnitude
	var mag := raw.length()
	if mag > 0:
		mag = ceil(mag / magnitude_step) * magnitude_step
		mag = clamp(mag, 0.0, 1.0)

		# Quantize direction to N angles
		var angle: float = raw.angle()
		var step: float = TAU / direction_snap_angles
		var quantized_angle: float = round(angle / step) * step

		current_snapshot.quantized_input = Vector2.from_angle(quantized_angle) * mag
	else:
		current_snapshot.quantized_input = Vector2.ZERO

	current_snapshot.magnitude = current_snapshot.quantized_input.length()
	current_snapshot.direction_angle = current_snapshot.quantized_input.angle() if current_snapshot.magnitude > 0 else 0.0
	current_snapshot.is_moving = current_snapshot.magnitude > 0

	# Emit if changed
	if current_snapshot.quantized_input != _last_quantized:
		_last_quantized = current_snapshot.quantized_input
		input_changed.emit(current_snapshot)


## Convert input to world direction based on camera
func get_world_direction() -> Vector3:
	if not current_snapshot.is_moving:
		return Vector3.ZERO

	var input_2d := current_snapshot.quantized_input

	if camera:
		# Get camera's forward and right vectors (ignoring Y)
		var cam_forward := -camera.global_transform.basis.z
		cam_forward.y = 0
		cam_forward = cam_forward.normalized()

		var cam_right := camera.global_transform.basis.x
		cam_right.y = 0
		cam_right = cam_right.normalized()

		# Transform input to world space
		return (cam_right * input_2d.x + cam_forward * (-input_2d.y)).normalized()
	else:
		# No camera, use input directly
		return Vector3(input_2d.x, 0, input_2d.y).normalized()


func get_input_magnitude() -> float:
	return current_snapshot.magnitude


func is_moving() -> bool:
	return current_snapshot.is_moving


## Combat input helpers

func is_light_attack_pressed() -> bool:
	return Input.is_action_just_pressed("light_attack")


func is_heavy_attack_pressed() -> bool:
	return Input.is_action_just_pressed("heavy_attack")


func is_block_pressed() -> bool:
	return Input.is_action_pressed("block")


func is_dodge_pressed() -> bool:
	return Input.is_action_just_pressed("dodge")


func get_ability_input() -> int:
	## Returns 0-3 for ability slots, -1 if none
	if Input.is_action_just_pressed("ability_1"):
		return 0
	elif Input.is_action_just_pressed("ability_2"):
		return 1
	elif Input.is_action_just_pressed("ability_3"):
		return 2
	elif Input.is_action_just_pressed("ability_4"):
		return 3
	return -1
