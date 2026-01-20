## BodyMorphController - Applies body customization to character meshes
class_name BodyMorphController
extends Node


signal customization_applied()
signal blend_transition_complete()


@export var mesh_instance: MeshInstance3D
@export var skeleton: Skeleton3D
@export var customization: BodyCustomization

## Transition settings
@export var transition_duration: float = 0.3
@export var auto_apply: bool = true

## Internal state
var _target_customization: BodyCustomization = null
var _transition_tween: Tween = null
var _current_blend_values: Dictionary = {}


func _ready() -> void:
	if not customization:
		customization = BodyCustomization.new()

	_current_blend_values = customization.get_all_blend_values()

	if auto_apply:
		apply_customization()


func apply_customization() -> void:
	if not mesh_instance:
		push_warning("BodyMorphController: No mesh_instance assigned")
		return

	var blend_values := customization.get_all_blend_values()

	for blend_name in blend_values.keys():
		_apply_blend_shape(blend_name, blend_values[blend_name])

	# Also apply skeleton scaling for properties that affect bone length
	if skeleton:
		_apply_skeleton_scaling()

	_current_blend_values = blend_values
	customization_applied.emit()


func _apply_blend_shape(shape_name: String, value: float) -> void:
	var mesh := mesh_instance.mesh
	if not mesh:
		return

	var idx := mesh.get_blend_shape_count()
	for i in range(idx):
		if mesh.get_blend_shape_name(i) == shape_name:
			mesh_instance.set_blend_shape_value(i, value)
			return

	# Blend shape not found - this is fine, not all meshes have all shapes


func _apply_skeleton_scaling() -> void:
	if not skeleton:
		return

	# Apply height by scaling root bone
	var root_idx := skeleton.find_bone("Root")
	if root_idx >= 0:
		var height_scale := customization.height
		skeleton.set_bone_pose_scale(root_idx, Vector3(1.0, height_scale, 1.0))

	# Apply limb lengths by scaling bone chains
	_scale_bone_chain("UpperArm_L", "Hand_L", customization.arm_length)
	_scale_bone_chain("UpperArm_R", "Hand_R", customization.arm_length)
	_scale_bone_chain("UpperLeg_L", "Foot_L", customization.leg_length)
	_scale_bone_chain("UpperLeg_R", "Foot_R", customization.leg_length)


func _scale_bone_chain(start_bone: String, end_bone: String, scale_factor: float) -> void:
	var start_idx := skeleton.find_bone(start_bone)
	if start_idx < 0:
		return

	# Scale the bone length by adjusting pose
	var current_scale := skeleton.get_bone_pose_scale(start_idx)
	current_scale.y = scale_factor
	skeleton.set_bone_pose_scale(start_idx, current_scale)


func set_customization(new_customization: BodyCustomization, animate: bool = true) -> void:
	if animate and transition_duration > 0:
		transition_to(new_customization)
	else:
		customization.copy_from(new_customization)
		apply_customization()


func transition_to(target: BodyCustomization) -> void:
	_target_customization = target

	if _transition_tween:
		_transition_tween.kill()

	_transition_tween = create_tween()
	_transition_tween.tween_method(_update_transition, 0.0, 1.0, transition_duration)
	_transition_tween.tween_callback(_on_transition_complete)


func _update_transition(weight: float) -> void:
	if not _target_customization:
		return

	customization.lerp_to(_target_customization, weight)
	apply_customization()


func _on_transition_complete() -> void:
	if _target_customization:
		customization.copy_from(_target_customization)
		_target_customization = null

	_transition_tween = null
	blend_transition_complete.emit()


func apply_preset(preset_name: String, animate: bool = true) -> void:
	var preset: BodyCustomization

	match preset_name.to_lower():
		"default":
			preset = BodyCustomization.create_default()
		"athletic":
			preset = BodyCustomization.create_athletic()
		"compact":
			preset = BodyCustomization.create_compact()
		"slender":
			preset = BodyCustomization.create_slender()
		"heroic":
			preset = BodyCustomization.create_heroic()
		_:
			push_warning("BodyMorphController: Unknown preset '%s'" % preset_name)
			return

	set_customization(preset, animate)


func randomize_customization(variance: float = 0.15, animate: bool = true) -> void:
	var random := BodyCustomization.new()

	random.height = randf_range(1.0 - variance, 1.0 + variance)
	random.body_width = randf_range(1.0 - variance, 1.0 + variance)
	random.body_depth = randf_range(1.0 - variance, 1.0 + variance)
	random.head_size = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)
	random.head_width = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)
	random.shoulder_width = randf_range(1.0 - variance, 1.0 + variance)
	random.chest_size = randf_range(1.0 - variance, 1.0 + variance)
	random.waist_size = randf_range(1.0 - variance, 1.0 + variance)
	random.hip_width = randf_range(1.0 - variance, 1.0 + variance)
	random.arm_length = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)
	random.arm_thickness = randf_range(1.0 - variance, 1.0 + variance)
	random.hand_size = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)
	random.leg_length = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)
	random.leg_thickness = randf_range(1.0 - variance, 1.0 + variance)
	random.foot_size = randf_range(1.0 - variance * 0.5, 1.0 + variance * 0.5)

	set_customization(random, animate)


func reset_to_default(animate: bool = true) -> void:
	apply_preset("default", animate)


func get_customization() -> BodyCustomization:
	return customization


func is_transitioning() -> bool:
	return _transition_tween != null and _transition_tween.is_running()
