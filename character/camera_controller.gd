## CameraController - Manages dual camera system with smooth transitions
class_name CameraController
extends Node3D

signal camera_switched(is_top_down: bool)

@export var target: Node3D
@export var top_down_camera: Camera3D
@export var side_camera: Camera3D

## Top-down settings
@export var top_down_height: float = 15.0
@export var top_down_angle: float = -80.0  ## Degrees from horizontal

## Side camera settings
@export var side_distance: float = 8.0
@export var side_height: float = 3.0
@export var side_angle: float = -15.0  ## Degrees from horizontal

## Follow settings
@export var follow_speed: float = 5.0
@export var rotation_follow_speed: float = 3.0
@export var look_ahead_distance: float = 2.0

## Transition
@export var transition_duration: float = 0.5

var is_top_down: bool = true
var _transition_progress: float = 1.0
var _transitioning: bool = false


func _ready() -> void:
	if top_down_camera:
		top_down_camera.current = true
	if side_camera:
		side_camera.current = false


func _process(delta: float) -> void:
	if not target:
		return

	_update_cameras(delta)
	_handle_transition(delta)


func _update_cameras(delta: float) -> void:
	var target_pos := target.global_position

	# Add look-ahead based on velocity if target is CharacterBody3D
	if target is CharacterBody3D:
		var vel := (target as CharacterBody3D).velocity
		vel.y = 0
		if vel.length() > 0.1:
			target_pos += vel.normalized() * look_ahead_distance

	# Update top-down camera
	if top_down_camera:
		var top_target := target_pos + Vector3(0, top_down_height, 0)
		top_down_camera.global_position = top_down_camera.global_position.lerp(top_target, follow_speed * delta)
		top_down_camera.rotation_degrees.x = top_down_angle

	# Update side camera
	if side_camera:
		var forward := -target.global_transform.basis.z
		forward.y = 0
		forward = forward.normalized()

		var camera_offset := -forward * side_distance + Vector3(0, side_height, 0)
		var side_target := target_pos + camera_offset

		side_camera.global_position = side_camera.global_position.lerp(side_target, follow_speed * delta)

		# Look at target
		var look_target := target_pos + Vector3(0, 1, 0)
		side_camera.look_at(look_target)


func _handle_transition(delta: float) -> void:
	if not _transitioning:
		return

	_transition_progress += delta / transition_duration

	if _transition_progress >= 1.0:
		_transition_progress = 1.0
		_transitioning = false
		_finalize_transition()


func _finalize_transition() -> void:
	if top_down_camera:
		top_down_camera.current = is_top_down
	if side_camera:
		side_camera.current = not is_top_down


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("switch_camera"):
		switch_camera()


func switch_camera() -> void:
	is_top_down = not is_top_down
	_transitioning = true
	_transition_progress = 0.0
	camera_switched.emit(is_top_down)

	# Immediately switch for now (could add blend later)
	_finalize_transition()


func set_top_down(value: bool) -> void:
	if is_top_down == value:
		return
	switch_camera()


func get_active_camera() -> Camera3D:
	if is_top_down and top_down_camera:
		return top_down_camera
	elif side_camera:
		return side_camera
	return null


func set_target(new_target: Node3D) -> void:
	target = new_target
