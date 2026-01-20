## CameraController - Manages dual camera system with smooth transitions and blending
class_name CameraController
extends Node3D

signal camera_switched(is_top_down: bool)
signal camera_blend_started(from_top_down: bool, to_top_down: bool)
signal camera_blend_completed()

@export var target: Node3D
@export var top_down_camera: Camera3D
@export var side_camera: Camera3D

## Blend camera (used for smooth transitions)
@export var blend_camera: Camera3D

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

## Transition settings
@export var transition_duration: float = 0.5
@export var use_smooth_blend: bool = true
@export var blend_ease: Tween.EaseType = Tween.EASE_IN_OUT
@export var blend_trans: Tween.TransitionType = Tween.TRANS_CUBIC

## Camera mode enum
enum CameraMode { TOP_DOWN, SIDE }

var current_mode: CameraMode = CameraMode.TOP_DOWN
var is_top_down: bool = true  ## Deprecated, use current_mode
var _transition_progress: float = 1.0
var _transitioning: bool = false

## Blend state
var _blend_from_transform: Transform3D
var _blend_to_transform: Transform3D
var _blend_tween: Tween


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
	var was_top_down := is_top_down
	is_top_down = not is_top_down
	current_mode = CameraMode.TOP_DOWN if is_top_down else CameraMode.SIDE

	if use_smooth_blend and blend_camera:
		_start_smooth_blend(was_top_down, is_top_down)
	else:
		_transitioning = true
		_transition_progress = 0.0
		_finalize_transition()

	camera_switched.emit(is_top_down)


func switch_to_mode(mode: CameraMode) -> void:
	if current_mode == mode:
		return

	var was_top_down := is_top_down
	current_mode = mode
	is_top_down = (mode == CameraMode.TOP_DOWN)

	if use_smooth_blend and blend_camera:
		_start_smooth_blend(was_top_down, is_top_down)
	else:
		_transitioning = true
		_transition_progress = 0.0
		_finalize_transition()

	camera_switched.emit(is_top_down)


func _start_smooth_blend(from_top_down: bool, to_top_down: bool) -> void:
	# Kill existing tween
	if _blend_tween and _blend_tween.is_valid():
		_blend_tween.kill()

	# Get source and target cameras
	var from_camera: Camera3D = top_down_camera if from_top_down else side_camera
	var to_camera: Camera3D = top_down_camera if to_top_down else side_camera

	if not from_camera or not to_camera or not blend_camera:
		_finalize_transition()
		return

	# Store transforms
	_blend_from_transform = from_camera.global_transform
	_blend_to_transform = to_camera.global_transform

	# Setup blend camera
	blend_camera.global_transform = _blend_from_transform
	blend_camera.current = true
	from_camera.current = false
	to_camera.current = false

	_transitioning = true
	_transition_progress = 0.0

	camera_blend_started.emit(from_top_down, to_top_down)

	# Create blend tween
	_blend_tween = create_tween()
	_blend_tween.set_ease(blend_ease)
	_blend_tween.set_trans(blend_trans)

	_blend_tween.tween_method(_update_blend, 0.0, 1.0, transition_duration)
	_blend_tween.tween_callback(_complete_blend)


func _update_blend(progress: float) -> void:
	_transition_progress = progress

	if not blend_camera:
		return

	# Interpolate transform
	var blended_transform := _blend_from_transform.interpolate_with(_blend_to_transform, progress)
	blend_camera.global_transform = blended_transform


func _complete_blend() -> void:
	_transitioning = false
	_transition_progress = 1.0

	# Switch to final camera
	_finalize_transition()

	# Disable blend camera
	if blend_camera:
		blend_camera.current = false

	camera_blend_completed.emit()


func set_top_down(value: bool) -> void:
	if is_top_down == value:
		return
	switch_camera()


func get_active_camera() -> Camera3D:
	if _transitioning and blend_camera:
		return blend_camera
	if is_top_down and top_down_camera:
		return top_down_camera
	elif side_camera:
		return side_camera
	return null


func get_current_mode() -> CameraMode:
	return current_mode


func is_blending() -> bool:
	return _transitioning


func get_blend_progress() -> float:
	return _transition_progress


func set_target(new_target: Node3D) -> void:
	target = new_target


## Get forward vector from current active camera (for input transformation)
func get_camera_forward() -> Vector3:
	var cam := get_active_camera()
	if not cam:
		return Vector3.FORWARD

	var forward := -cam.global_transform.basis.z
	forward.y = 0
	return forward.normalized()


## Get right vector from current active camera
func get_camera_right() -> Vector3:
	var cam := get_active_camera()
	if not cam:
		return Vector3.RIGHT

	var right := cam.global_transform.basis.x
	right.y = 0
	return right.normalized()


## Transform input direction based on camera orientation
func transform_input_to_world(input_2d: Vector2) -> Vector3:
	var forward := get_camera_forward()
	var right := get_camera_right()
	return (right * input_2d.x + forward * -input_2d.y).normalized() * input_2d.length()
