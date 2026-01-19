## HumanoidAnimator - Plays frame-based animations on humanoid characters
class_name HumanoidAnimator
extends Node


## Reference to the skeleton
@export var skeleton: HumanoidSkeleton

## Current animation being played
var current_animation: AnimationData.Animation
var current_frame: float = 0.0
var is_playing: bool = false
var playback_speed: float = 1.0

## Blending
var blend_animation: AnimationData.Animation
var blend_weight: float = 0.0
var blend_time: float = 0.0
var blend_duration: float = 0.2

## Callbacks
signal animation_finished(anim_name: String)
signal animation_looped(anim_name: String)
signal frame_reached(frame: int)


func _ready() -> void:
	# Initialize default animations
	AnimationData.init_defaults()


func _process(delta: float) -> void:
	if not is_playing or current_animation == null or skeleton == null:
		return

	# Update frame
	var prev_frame := int(current_frame)
	current_frame += current_animation.fps * delta * playback_speed

	# Check for frame events
	var new_frame := int(current_frame)
	if new_frame != prev_frame:
		frame_reached.emit(new_frame)

	# Handle looping/end
	if current_frame >= current_animation.frame_count:
		if current_animation.loop:
			current_frame = fmod(current_frame, current_animation.frame_count)
			animation_looped.emit(current_animation.name)
		else:
			current_frame = current_animation.frame_count - 1
			is_playing = false
			animation_finished.emit(current_animation.name)

	# Update blend
	if blend_animation != null and blend_time > 0:
		blend_weight = clampf(blend_weight + delta / blend_duration, 0.0, 1.0)
		if blend_weight >= 1.0:
			current_animation = blend_animation
			blend_animation = null
			blend_weight = 0.0
			current_frame = 0.0

	# Apply animation to skeleton
	_apply_animation()


func _apply_animation() -> void:
	if current_animation == null:
		return

	# Reset skeleton to rest pose first
	skeleton.reset_to_rest()

	# Sample all bone tracks
	for part in HumanoidTypes.BodyPart.values():
		var sample := current_animation.sample(part, current_frame)

		# Blend with transition animation if active
		if blend_animation != null and blend_weight > 0:
			var blend_sample := blend_animation.sample(part, 0)
			sample["rotation"] = sample["rotation"].lerp(blend_sample["rotation"], blend_weight)
			sample["position"] = sample["position"].lerp(blend_sample["position"], blend_weight)

		# Apply to skeleton
		var bone_idx := skeleton.get_bone_index(part)
		if bone_idx >= 0:
			var rotation: Vector3 = sample["rotation"]
			var position: Vector3 = sample["position"]

			if rotation != Vector3.ZERO:
				var quat := Quaternion.from_euler(rotation)
				var current_rot := skeleton.get_bone_pose_rotation(bone_idx)
				skeleton.set_bone_pose_rotation(bone_idx, current_rot * quat)

			if position != Vector3.ZERO:
				var current_pos := skeleton.get_bone_pose_position(bone_idx)
				skeleton.set_bone_pose_position(bone_idx, current_pos + position)


## Play an animation by name
func play(anim_name: String, blend: bool = true) -> void:
	var anim := AnimationData.library.get_animation(anim_name)
	if anim == null:
		push_warning("Animation not found: " + anim_name)
		return

	if blend and current_animation != null and current_animation.name != anim_name:
		blend_animation = anim
		blend_weight = 0.0
		blend_time = blend_duration
	else:
		current_animation = anim
		current_frame = 0.0
		blend_animation = null
		blend_weight = 0.0

	is_playing = true


## Play a random animation from category
func play_random(category: AnimationData.Category, blend: bool = true) -> void:
	var anim := AnimationData.library.get_random(category)
	if anim != null:
		play(anim.name, blend)


## Stop current animation
func stop() -> void:
	is_playing = false


## Pause current animation
func pause() -> void:
	is_playing = false


## Resume paused animation
func resume() -> void:
	if current_animation != null:
		is_playing = true


## Seek to specific frame
func seek(frame: float) -> void:
	if current_animation != null:
		current_frame = clampf(frame, 0, current_animation.frame_count - 1)
		_apply_animation()


## Get current animation name
func get_current_animation() -> String:
	if current_animation != null:
		return current_animation.name
	return ""


## Check if specific animation is playing
func is_animation_playing(anim_name: String) -> bool:
	return is_playing and current_animation != null and current_animation.name == anim_name


## Get animation duration in seconds
func get_duration(anim_name: String) -> float:
	var anim := AnimationData.library.get_animation(anim_name)
	if anim != null:
		return anim.get_duration()
	return 0.0


## Get available animations
func get_animation_list() -> Array[String]:
	var result: Array[String] = []
	for name in AnimationData.library.animations.keys():
		result.append(name)
	return result


## Get animations by category
func get_animations_by_category(category: AnimationData.Category) -> Array[String]:
	var result: Array[String] = []
	var anims := AnimationData.library.get_by_category(category)
	for anim in anims:
		result.append(anim.name)
	return result
