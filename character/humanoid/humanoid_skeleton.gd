## HumanoidSkeleton - Generates procedural skeleton for humanoid characters
class_name HumanoidSkeleton
extends Skeleton3D


## Configuration
var proportions: HumanoidTypes.BodyProportions = HumanoidTypes.BodyProportions.default()

## Bone indices for easy access
var bone_indices: Dictionary = {}  ## BodyPart -> bone_index


func _ready() -> void:
	build_skeleton()


func build_skeleton() -> void:
	clear_bones()
	bone_indices.clear()

	var height := proportions.height

	# Calculate segment lengths
	var head_height := height * 0.12 * proportions.head_scale
	var neck_height := height * 0.03
	var torso_height := height * proportions.torso_length
	var leg_height := height * proportions.leg_length

	var torso_segment := torso_height / 4.0
	var upper_leg := leg_height * 0.5
	var lower_leg := leg_height * 0.45
	var foot_height := leg_height * 0.05

	var arm_length := height * proportions.arm_length
	var upper_arm := arm_length * 0.5
	var lower_arm := arm_length * 0.4
	var hand_length := arm_length * 0.1

	# Create bones
	# Pelvis (root)
	_add_bone_at(HumanoidTypes.BodyPart.PELVIS, "Pelvis", -1,
		Vector3(0, leg_height, 0), Vector3.ZERO)

	# Spine
	_add_bone_at(HumanoidTypes.BodyPart.SPINE_LOWER, "SpineLower",
		HumanoidTypes.BodyPart.PELVIS,
		Vector3(0, torso_segment, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.SPINE_UPPER, "SpineUpper",
		HumanoidTypes.BodyPart.SPINE_LOWER,
		Vector3(0, torso_segment, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.CHEST, "Chest",
		HumanoidTypes.BodyPart.SPINE_UPPER,
		Vector3(0, torso_segment, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.NECK, "Neck",
		HumanoidTypes.BodyPart.CHEST,
		Vector3(0, torso_segment, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.HEAD, "Head",
		HumanoidTypes.BodyPart.NECK,
		Vector3(0, neck_height, 0), Vector3.ZERO)

	# Left Arm
	var shoulder_offset := proportions.shoulder_width * 0.5
	_add_bone_at(HumanoidTypes.BodyPart.SHOULDER_L, "ShoulderL",
		HumanoidTypes.BodyPart.CHEST,
		Vector3(-shoulder_offset, torso_segment * 0.8, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.UPPER_ARM_L, "UpperArmL",
		HumanoidTypes.BodyPart.SHOULDER_L,
		Vector3(-0.05, 0, 0), Vector3(0, 0, deg_to_rad(10)))

	_add_bone_at(HumanoidTypes.BodyPart.LOWER_ARM_L, "LowerArmL",
		HumanoidTypes.BodyPart.UPPER_ARM_L,
		Vector3(0, -upper_arm, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.HAND_L, "HandL",
		HumanoidTypes.BodyPart.LOWER_ARM_L,
		Vector3(0, -lower_arm, 0), Vector3.ZERO)

	# Right Arm
	_add_bone_at(HumanoidTypes.BodyPart.SHOULDER_R, "ShoulderR",
		HumanoidTypes.BodyPart.CHEST,
		Vector3(shoulder_offset, torso_segment * 0.8, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.UPPER_ARM_R, "UpperArmR",
		HumanoidTypes.BodyPart.SHOULDER_R,
		Vector3(0.05, 0, 0), Vector3(0, 0, deg_to_rad(-10)))

	_add_bone_at(HumanoidTypes.BodyPart.LOWER_ARM_R, "LowerArmR",
		HumanoidTypes.BodyPart.UPPER_ARM_R,
		Vector3(0, -upper_arm, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.HAND_R, "HandR",
		HumanoidTypes.BodyPart.LOWER_ARM_R,
		Vector3(0, -lower_arm, 0), Vector3.ZERO)

	# Left Leg
	var hip_offset := proportions.hip_width * 0.5
	_add_bone_at(HumanoidTypes.BodyPart.THIGH_L, "ThighL",
		HumanoidTypes.BodyPart.PELVIS,
		Vector3(-hip_offset, 0, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.CALF_L, "CalfL",
		HumanoidTypes.BodyPart.THIGH_L,
		Vector3(0, -upper_leg, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.FOOT_L, "FootL",
		HumanoidTypes.BodyPart.CALF_L,
		Vector3(0, -lower_leg, 0), Vector3(deg_to_rad(-90), 0, 0))

	# Right Leg
	_add_bone_at(HumanoidTypes.BodyPart.THIGH_R, "ThighR",
		HumanoidTypes.BodyPart.PELVIS,
		Vector3(hip_offset, 0, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.CALF_R, "CalfR",
		HumanoidTypes.BodyPart.THIGH_R,
		Vector3(0, -upper_leg, 0), Vector3.ZERO)

	_add_bone_at(HumanoidTypes.BodyPart.FOOT_R, "FootR",
		HumanoidTypes.BodyPart.CALF_R,
		Vector3(0, -lower_leg, 0), Vector3(deg_to_rad(-90), 0, 0))


func _add_bone_at(part: HumanoidTypes.BodyPart, bone_name: String, parent_part, position: Vector3, rotation: Vector3) -> int:
	var parent_idx: int = -1
	if parent_part is int and parent_part >= 0:
		parent_idx = parent_part
	elif parent_part is HumanoidTypes.BodyPart:
		parent_idx = bone_indices.get(parent_part, -1)

	var bone_idx := add_bone(bone_name)
	bone_indices[part] = bone_idx

	if parent_idx >= 0:
		set_bone_parent(bone_idx, parent_idx)

	var rest := Transform3D()
	rest.origin = position
	if rotation != Vector3.ZERO:
		rest.basis = Basis.from_euler(rotation)

	set_bone_rest(bone_idx, rest)
	set_bone_pose_position(bone_idx, position)
	if rotation != Vector3.ZERO:
		set_bone_pose_rotation(bone_idx, Quaternion.from_euler(rotation))

	return bone_idx


func get_bone_index(part: HumanoidTypes.BodyPart) -> int:
	return bone_indices.get(part, -1)


func set_proportions(new_proportions: HumanoidTypes.BodyProportions) -> void:
	proportions = new_proportions
	build_skeleton()


## Reset all bones to their rest pose
func reset_to_rest() -> void:
	for i in range(get_bone_count()):
		var rest := get_bone_rest(i)
		set_bone_pose_position(i, rest.origin)
		set_bone_pose_rotation(i, Quaternion(rest.basis))
		set_bone_pose_scale(i, Vector3.ONE)
