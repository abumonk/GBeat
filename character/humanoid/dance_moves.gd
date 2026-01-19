## DanceMoves - Procedural dance animations for humanoid characters
class_name DanceMoves
extends RefCounted


enum DanceStyle {
	BOUNCE,       ## Simple up/down bounce
	SWAY,         ## Side to side sway
	ARM_PUMP,     ## Pumping arms up
	HEAD_BOB,     ## Head nodding
	TWIST,        ## Body twist
	WAVE,         ## Wave motion through body
	ROBOT,        ## Robotic movements
	JUMP,         ## Jump on beat
}


## Dance state for a character
class DanceState:
	var current_style: DanceStyle = DanceStyle.BOUNCE
	var phase: float = 0.0
	var intensity: float = 1.0
	var speed_multiplier: float = 1.0

	# Accumulated transforms per bone
	var bone_offsets: Dictionary = {}  ## BodyPart -> Vector3 position offset
	var bone_rotations: Dictionary = {}  ## BodyPart -> Vector3 euler rotation


## Apply dance animation to skeleton based on beat
static func apply_dance(skeleton: HumanoidSkeleton, state: DanceState, beat_phase: float) -> void:
	state.phase = beat_phase

	# Clear previous frame
	state.bone_offsets.clear()
	state.bone_rotations.clear()

	match state.current_style:
		DanceStyle.BOUNCE:
			_apply_bounce(skeleton, state)
		DanceStyle.SWAY:
			_apply_sway(skeleton, state)
		DanceStyle.ARM_PUMP:
			_apply_arm_pump(skeleton, state)
		DanceStyle.HEAD_BOB:
			_apply_head_bob(skeleton, state)
		DanceStyle.TWIST:
			_apply_twist(skeleton, state)
		DanceStyle.WAVE:
			_apply_wave(skeleton, state)
		DanceStyle.ROBOT:
			_apply_robot(skeleton, state)
		DanceStyle.JUMP:
			_apply_jump(skeleton, state)

	# Apply transforms to skeleton
	_apply_transforms_to_skeleton(skeleton, state)


static func _apply_bounce(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var bounce := abs(sin(state.phase * TAU)) * 0.1 * state.intensity

	# Pelvis bounces
	state.bone_offsets[HumanoidTypes.BodyPart.PELVIS] = Vector3(0, bounce, 0)

	# Knees bend slightly
	var knee_bend := sin(state.phase * TAU) * 0.2 * state.intensity
	state.bone_rotations[HumanoidTypes.BodyPart.THIGH_L] = Vector3(knee_bend, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.THIGH_R] = Vector3(knee_bend, 0, 0)

	# Arms sway opposite
	var arm_sway := sin(state.phase * TAU + PI) * 0.3 * state.intensity
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(arm_sway, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(-arm_sway, 0, 0)


static func _apply_sway(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var sway := sin(state.phase * TAU) * 0.15 * state.intensity

	# Body sways side to side
	state.bone_rotations[HumanoidTypes.BodyPart.PELVIS] = Vector3(0, 0, sway)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_LOWER] = Vector3(0, 0, sway * 0.5)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_UPPER] = Vector3(0, 0, -sway * 0.3)

	# Head counters
	state.bone_rotations[HumanoidTypes.BodyPart.HEAD] = Vector3(0, 0, -sway * 0.5)

	# Arms swing
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(0, 0, sway * 2)
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(0, 0, sway * 2)


static func _apply_arm_pump(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var pump := max(0, sin(state.phase * TAU * 2)) * state.intensity

	# Arms pump up
	var arm_angle := -PI * 0.4 * pump
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(arm_angle, 0, -0.3)
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(arm_angle, 0, 0.3)

	# Elbows bend
	var elbow_bend := pump * 0.5
	state.bone_rotations[HumanoidTypes.BodyPart.LOWER_ARM_L] = Vector3(elbow_bend, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.LOWER_ARM_R] = Vector3(elbow_bend, 0, 0)

	# Slight bounce
	state.bone_offsets[HumanoidTypes.BodyPart.PELVIS] = Vector3(0, pump * 0.05, 0)


static func _apply_head_bob(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var bob := sin(state.phase * TAU * 2) * 0.2 * state.intensity

	# Head nods
	state.bone_rotations[HumanoidTypes.BodyPart.HEAD] = Vector3(bob, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.NECK] = Vector3(bob * 0.5, 0, 0)

	# Shoulders move slightly
	var shoulder := sin(state.phase * TAU) * 0.1 * state.intensity
	state.bone_rotations[HumanoidTypes.BodyPart.SHOULDER_L] = Vector3(0, 0, shoulder)
	state.bone_rotations[HumanoidTypes.BodyPart.SHOULDER_R] = Vector3(0, 0, -shoulder)


static func _apply_twist(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var twist := sin(state.phase * TAU) * 0.4 * state.intensity

	# Body twists
	state.bone_rotations[HumanoidTypes.BodyPart.PELVIS] = Vector3(0, -twist, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_LOWER] = Vector3(0, twist * 0.3, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_UPPER] = Vector3(0, twist * 0.5, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.CHEST] = Vector3(0, twist * 0.7, 0)

	# Arms follow twist
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(-twist * 0.5, twist, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(twist * 0.5, twist, 0)


static func _apply_wave(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	var wave_speed := 3.0

	# Wave travels up the body
	var pelvis_phase := state.phase * wave_speed
	var spine_phase := pelvis_phase - 0.1
	var chest_phase := pelvis_phase - 0.2
	var head_phase := pelvis_phase - 0.3

	var wave_amount := 0.15 * state.intensity

	state.bone_rotations[HumanoidTypes.BodyPart.PELVIS] = Vector3(sin(pelvis_phase * TAU) * wave_amount, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_LOWER] = Vector3(sin(spine_phase * TAU) * wave_amount, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.SPINE_UPPER] = Vector3(sin(chest_phase * TAU) * wave_amount, 0, 0)
	state.bone_rotations[HumanoidTypes.BodyPart.HEAD] = Vector3(sin(head_phase * TAU) * wave_amount * 0.5, 0, 0)


static func _apply_robot(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	# Quantized, snappy movements
	var step := floor(state.phase * 4) / 4.0
	var sub_step := fmod(state.phase * 4, 1.0)
	var snap := smoothstep(0.0, 0.3, sub_step) * state.intensity

	var pose := int(step * 4) % 4

	match pose:
		0:  # Arms out
			state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(0, 0, -PI * 0.4 * snap)
			state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(0, 0, PI * 0.4 * snap)
		1:  # Arms up
			state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(-PI * 0.5 * snap, 0, 0)
			state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(-PI * 0.5 * snap, 0, 0)
		2:  # Lean left
			state.bone_rotations[HumanoidTypes.BodyPart.SPINE_UPPER] = Vector3(0, 0, 0.3 * snap)
			state.bone_rotations[HumanoidTypes.BodyPart.HEAD] = Vector3(0, 0, -0.3 * snap)
		3:  # Lean right
			state.bone_rotations[HumanoidTypes.BodyPart.SPINE_UPPER] = Vector3(0, 0, -0.3 * snap)
			state.bone_rotations[HumanoidTypes.BodyPart.HEAD] = Vector3(0, 0, 0.3 * snap)


static func _apply_jump(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	# Jump at the start of each beat
	var jump_phase := fmod(state.phase, 0.5) * 2.0  # 0-1 per half beat
	var jump_height := sin(jump_phase * PI) * 0.2 * state.intensity

	state.bone_offsets[HumanoidTypes.BodyPart.PELVIS] = Vector3(0, jump_height, 0)

	# Arms go up during jump
	if jump_phase < 0.5:
		var arm_up := jump_phase * 2.0 * state.intensity
		state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_L] = Vector3(-PI * 0.3 * arm_up, 0, -0.2)
		state.bone_rotations[HumanoidTypes.BodyPart.UPPER_ARM_R] = Vector3(-PI * 0.3 * arm_up, 0, 0.2)


static func _apply_transforms_to_skeleton(skeleton: HumanoidSkeleton, state: DanceState) -> void:
	for part in state.bone_offsets:
		var bone_idx := skeleton.get_bone_index(part)
		if bone_idx >= 0:
			var current_pos := skeleton.get_bone_pose_position(bone_idx)
			var offset: Vector3 = state.bone_offsets[part]
			skeleton.set_bone_pose_position(bone_idx, current_pos + offset)

	for part in state.bone_rotations:
		var bone_idx := skeleton.get_bone_index(part)
		if bone_idx >= 0:
			var rotation: Vector3 = state.bone_rotations[part]
			var quat := Quaternion.from_euler(rotation)
			var current_rot := skeleton.get_bone_pose_rotation(bone_idx)
			skeleton.set_bone_pose_rotation(bone_idx, current_rot * quat)


## Get random dance style
static func random_style() -> DanceStyle:
	return randi() % DanceStyle.size() as DanceStyle
