## AnimationData - Frame-based animation definitions for humanoid characters
class_name AnimationData
extends RefCounted


## Animation categories
enum Category {
	IDLE,
	MOVEMENT,
	COMBAT,
	DANCE,
	EMOTE,
}


## Single keyframe for a bone
class BoneKeyframe:
	var frame: int
	var rotation: Vector3  ## Euler angles in radians
	var position_offset: Vector3
	var easing: float = 0.5  ## 0=linear, 0.5=smooth, 1=snap

	func _init(f: int = 0, rot: Vector3 = Vector3.ZERO, pos: Vector3 = Vector3.ZERO, ease: float = 0.5) -> void:
		frame = f
		rotation = rot
		position_offset = pos
		easing = ease


## Complete animation definition
class Animation:
	var name: String
	var category: Category
	var frame_count: int
	var fps: float = 30.0
	var loop: bool = true
	var tracks: Dictionary = {}  ## BodyPart -> Array[BoneKeyframe]

	func _init(n: String = "", cat: Category = Category.IDLE, frames: int = 30, looping: bool = true) -> void:
		name = n
		category = cat
		frame_count = frames
		loop = looping

	func add_keyframe(part: HumanoidTypes.BodyPart, keyframe: BoneKeyframe) -> void:
		if not tracks.has(part):
			tracks[part] = []
		tracks[part].append(keyframe)

	func get_duration() -> float:
		return frame_count / fps

	## Sample bone transform at given frame (with interpolation)
	func sample(part: HumanoidTypes.BodyPart, frame: float) -> Dictionary:
		if not tracks.has(part):
			return {"rotation": Vector3.ZERO, "position": Vector3.ZERO}

		var keyframes: Array = tracks[part]
		if keyframes.is_empty():
			return {"rotation": Vector3.ZERO, "position": Vector3.ZERO}

		# Find surrounding keyframes
		var prev_kf: BoneKeyframe = keyframes[0]
		var next_kf: BoneKeyframe = keyframes[0]

		for i in range(keyframes.size()):
			var kf: BoneKeyframe = keyframes[i]
			if kf.frame <= frame:
				prev_kf = kf
			if kf.frame >= frame and (next_kf.frame < frame or kf.frame < next_kf.frame):
				next_kf = kf
				break

		# Handle looping
		if loop and frame >= prev_kf.frame and next_kf.frame < frame:
			next_kf = keyframes[0]

		# Calculate interpolation
		var t := 0.0
		if next_kf.frame != prev_kf.frame:
			var frame_diff := next_kf.frame - prev_kf.frame
			if frame_diff < 0:
				frame_diff += frame_count
			var frame_pos := frame - prev_kf.frame
			if frame_pos < 0:
				frame_pos += frame_count
			t = frame_pos / float(frame_diff)

		# Apply easing
		t = _ease(t, next_kf.easing)

		return {
			"rotation": prev_kf.rotation.lerp(next_kf.rotation, t),
			"position": prev_kf.position_offset.lerp(next_kf.position_offset, t)
		}

	func _ease(t: float, amount: float) -> float:
		if amount <= 0.0:
			return t  # Linear
		elif amount >= 1.0:
			return 1.0 if t > 0.5 else 0.0  # Snap
		else:
			# Smoothstep-like easing
			return t * t * (3.0 - 2.0 * t)


## Animation library singleton
class AnimationLibrary:
	var animations: Dictionary = {}  ## name -> Animation

	func register(anim: Animation) -> void:
		animations[anim.name] = anim

	func get_animation(name: String) -> Animation:
		return animations.get(name)

	func get_by_category(category: Category) -> Array[Animation]:
		var result: Array[Animation] = []
		for anim in animations.values():
			if anim.category == category:
				result.append(anim)
		return result

	func get_random(category: Category) -> Animation:
		var anims := get_by_category(category)
		if anims.is_empty():
			return null
		return anims[randi() % anims.size()]


## Global animation library
static var library: AnimationLibrary = AnimationLibrary.new()


## Initialize default animations
static func init_defaults() -> void:
	_create_idle_animations()
	_create_movement_animations()
	_create_combat_animations()


# =============================================================================
# IDLE ANIMATIONS
# =============================================================================

static func _create_idle_animations() -> void:
	# Standing idle with breathing
	var idle := Animation.new("idle_stand", Category.IDLE, 60, true)

	# Subtle breathing motion
	idle.add_keyframe(HumanoidTypes.BodyPart.CHEST, BoneKeyframe.new(0, Vector3(0.02, 0, 0)))
	idle.add_keyframe(HumanoidTypes.BodyPart.CHEST, BoneKeyframe.new(30, Vector3(-0.02, 0, 0)))
	idle.add_keyframe(HumanoidTypes.BodyPart.CHEST, BoneKeyframe.new(60, Vector3(0.02, 0, 0)))

	# Slight weight shift
	idle.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0, 0, 0.01)))
	idle.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(30, Vector3(0, 0, -0.01)))
	idle.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(60, Vector3(0, 0, 0.01)))

	library.register(idle)

	# Relaxed idle
	var idle_relaxed := Animation.new("idle_relaxed", Category.IDLE, 90, true)

	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3(0.05, 0, 0)))
	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(0, Vector3(0.1, 0, 0)))
	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(45, Vector3(0.1, 0.1, 0)))
	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(90, Vector3(0.1, 0, 0)))

	# Arms hanging
	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3(0.1, 0, 0.1)))
	idle_relaxed.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(0.1, 0, -0.1)))

	library.register(idle_relaxed)


# =============================================================================
# MOVEMENT ANIMATIONS
# =============================================================================

static func _create_movement_animations() -> void:
	_create_walk_animation()
	_create_run_animation()
	_create_strafe_animations()
	_create_jump_animation()
	_create_crouch_animation()


static func _create_walk_animation() -> void:
	var walk := Animation.new("walk", Category.MOVEMENT, 30, true)

	# Pelvis bob and sway
	walk.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0, 0, 0.03), Vector3(0, 0.02, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(8, Vector3(0, 0, 0), Vector3(0, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3(0, 0, -0.03), Vector3(0, 0.02, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(23, Vector3(0, 0, 0), Vector3(0, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(30, Vector3(0, 0, 0.03), Vector3(0, 0.02, 0)))

	# Left leg forward, right back
	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3(-0.4, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(15, Vector3(0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(30, Vector3(-0.4, 0, 0)))

	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3(0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(15, Vector3(-0.4, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(30, Vector3(0.3, 0, 0)))

	# Knee bends
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(0, Vector3(0.2, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(8, Vector3(0.6, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(15, Vector3(0.1, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(30, Vector3(0.2, 0, 0)))

	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(0, Vector3(0.1, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(15, Vector3(0.2, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(23, Vector3(0.6, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(30, Vector3(0.1, 0, 0)))

	# Arm swing (opposite to legs)
	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3(0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(15, Vector3(-0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(30, Vector3(0.3, 0, 0)))

	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(-0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(15, Vector3(0.3, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(30, Vector3(-0.3, 0, 0)))

	# Elbow bend during swing
	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(0, Vector3(0.2, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(15, Vector3(0.4, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(30, Vector3(0.2, 0, 0)))

	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3(0.4, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(15, Vector3(0.2, 0, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(30, Vector3(0.4, 0, 0)))

	# Spine counter-rotation
	walk.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3(0, -0.1, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(15, Vector3(0, 0.1, 0)))
	walk.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(30, Vector3(0, -0.1, 0)))

	library.register(walk)


static func _create_run_animation() -> void:
	var run := Animation.new("run", Category.MOVEMENT, 20, true)

	# More pronounced pelvis movement
	run.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0.05, 0, 0.05), Vector3(0, 0.05, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(5, Vector3(0, 0, 0), Vector3(0, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(10, Vector3(0.05, 0, -0.05), Vector3(0, 0.05, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3(0, 0, 0), Vector3(0, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(20, Vector3(0.05, 0, 0.05), Vector3(0, 0.05, 0)))

	# Bigger leg strides
	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3(-0.7, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(10, Vector3(0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(20, Vector3(-0.7, 0, 0)))

	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3(0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(10, Vector3(-0.7, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(20, Vector3(0.5, 0, 0)))

	# Higher knee lift
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(0, Vector3(0.3, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(5, Vector3(1.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(10, Vector3(0.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(20, Vector3(0.3, 0, 0)))

	run.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(0, Vector3(0.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(10, Vector3(0.3, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(15, Vector3(1.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(20, Vector3(0.2, 0, 0)))

	# Aggressive arm pump
	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3(0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(10, Vector3(-0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(20, Vector3(0.5, 0, 0)))

	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(-0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(10, Vector3(0.5, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(20, Vector3(-0.5, 0, 0)))

	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(0, Vector3(0.8, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(10, Vector3(1.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(20, Vector3(0.8, 0, 0)))

	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3(1.2, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(10, Vector3(0.8, 0, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(20, Vector3(1.2, 0, 0)))

	# Forward lean
	run.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3(0.15, -0.15, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(10, Vector3(0.15, 0.15, 0)))
	run.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(20, Vector3(0.15, -0.15, 0)))

	library.register(run)


static func _create_strafe_animations() -> void:
	# Strafe left
	var strafe_l := Animation.new("strafe_left", Category.MOVEMENT, 24, true)

	strafe_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0, 0, 0.1)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(12, Vector3(0, 0, 0.05)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(24, Vector3(0, 0, 0.1)))

	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3(0, 0, -0.3)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(12, Vector3(-0.2, 0, -0.1)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(24, Vector3(0, 0, -0.3)))

	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3(-0.2, 0, 0.2)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(12, Vector3(0, 0, 0.1)))
	strafe_l.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(24, Vector3(-0.2, 0, 0.2)))

	library.register(strafe_l)

	# Strafe right (mirror)
	var strafe_r := Animation.new("strafe_right", Category.MOVEMENT, 24, true)

	strafe_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0, 0, -0.1)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(12, Vector3(0, 0, -0.05)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(24, Vector3(0, 0, -0.1)))

	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3(0, 0, 0.3)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(12, Vector3(-0.2, 0, 0.1)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(24, Vector3(0, 0, 0.3)))

	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3(-0.2, 0, -0.2)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(12, Vector3(0, 0, -0.1)))
	strafe_r.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(24, Vector3(-0.2, 0, -0.2)))

	library.register(strafe_r)


static func _create_jump_animation() -> void:
	var jump := Animation.new("jump", Category.MOVEMENT, 45, false)

	# Crouch before jump (anticipation)
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(8, Vector3.ZERO, Vector3(0, -0.15, 0)))

	# Jump up
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3.ZERO, Vector3(0, 0.3, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(25, Vector3.ZERO, Vector3(0, 0.35, 0)))

	# Fall down
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(35, Vector3.ZERO, Vector3(0, 0.1, 0)))

	# Land
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(40, Vector3.ZERO, Vector3(0, -0.1, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(45, Vector3.ZERO, Vector3.ZERO))

	# Legs during jump
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3.ZERO))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(8, Vector3(0.4, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(15, Vector3(-0.2, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(35, Vector3(-0.1, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(40, Vector3(0.3, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(45, Vector3.ZERO))

	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(8, Vector3(0.4, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(15, Vector3(-0.2, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(35, Vector3(-0.1, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(40, Vector3(0.3, 0, 0)))
	jump.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(45, Vector3.ZERO))

	# Arms raise during jump
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3(0.1, 0, 0.1)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(15, Vector3(-0.8, 0, -0.3)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(25, Vector3(-0.6, 0, -0.2)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(40, Vector3(0.2, 0, 0.2)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(45, Vector3(0.1, 0, 0.1)))

	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(0.1, 0, -0.1)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(15, Vector3(-0.8, 0, 0.3)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(25, Vector3(-0.6, 0, 0.2)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(40, Vector3(0.2, 0, -0.2)))
	jump.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(45, Vector3(0.1, 0, -0.1)))

	library.register(jump)


static func _create_crouch_animation() -> void:
	var crouch := Animation.new("crouch", Category.MOVEMENT, 15, false)

	crouch.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	crouch.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3(0.1, 0, 0), Vector3(0, -0.4, 0)))

	crouch.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3.ZERO))
	crouch.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(15, Vector3(0.8, 0, 0)))

	crouch.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	crouch.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(15, Vector3(0.8, 0, 0)))

	crouch.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(0, Vector3.ZERO))
	crouch.add_keyframe(HumanoidTypes.BodyPart.CALF_L, BoneKeyframe.new(15, Vector3(1.2, 0, 0)))

	crouch.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(0, Vector3.ZERO))
	crouch.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(15, Vector3(1.2, 0, 0)))

	library.register(crouch)


# =============================================================================
# COMBAT ANIMATIONS
# =============================================================================

static func _create_combat_animations() -> void:
	_create_punch_animations()
	_create_kick_animations()
	_create_block_animation()
	_create_hit_reactions()
	_create_dodge_animations()


static func _create_punch_animations() -> void:
	# Quick jab
	var jab := Animation.new("punch_jab", Category.COMBAT, 12, false)

	# Wind up
	jab.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(0.2, 0, -0.3)))
	jab.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3(0.8, 0, 0)))

	# Extend punch
	jab.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(4, Vector3(-1.4, 0, 0.2)))
	jab.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(4, Vector3(0.1, 0, 0)))

	# Hold
	jab.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(6, Vector3(-1.4, 0, 0.2)))
	jab.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(6, Vector3(0.1, 0, 0)))

	# Return
	jab.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(12, Vector3(0.2, 0, -0.3)))
	jab.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(12, Vector3(0.8, 0, 0)))

	# Body rotation
	jab.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3(0, 0.1, 0)))
	jab.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(4, Vector3(0, -0.2, 0)))
	jab.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(12, Vector3(0, 0.1, 0)))

	library.register(jab)

	# Cross punch (stronger)
	var cross := Animation.new("punch_cross", Category.COMBAT, 18, false)

	# Big wind up
	cross.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(0.3, 0.2, -0.5)))
	cross.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3(1.0, 0, 0)))
	cross.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3(0, 0.3, 0)))

	# Extend with rotation
	cross.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(6, Vector3(-1.5, 0, 0.3)))
	cross.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(6, Vector3(0.05, 0, 0)))
	cross.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(6, Vector3(0, -0.4, 0)))

	# Hold
	cross.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(10, Vector3(-1.5, 0, 0.3)))
	cross.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(10, Vector3(0, -0.4, 0)))

	# Return
	cross.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(18, Vector3(0.2, 0, -0.3)))
	cross.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(18, Vector3(0.8, 0, 0)))
	cross.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(18, Vector3.ZERO))

	library.register(cross)

	# Uppercut
	var uppercut := Animation.new("punch_uppercut", Category.COMBAT, 20, false)

	# Low start
	uppercut.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3(0, -0.1, 0)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3(0.4, 0, -0.2)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3(1.4, 0, 0)))

	# Explosive upward
	uppercut.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(6, Vector3.ZERO, Vector3(0, 0.1, 0)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(6, Vector3(-1.8, 0, 0.2)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(6, Vector3(0.5, 0, 0)))

	# Extended position
	uppercut.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(10, Vector3.ZERO, Vector3(0, 0.05, 0)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(10, Vector3(-2.0, 0, 0.1)))

	# Return
	uppercut.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(20, Vector3.ZERO, Vector3.ZERO))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(20, Vector3(0.2, 0, -0.3)))
	uppercut.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(20, Vector3(0.8, 0, 0)))

	library.register(uppercut)


static func _create_kick_animations() -> void:
	# Front kick
	var front_kick := Animation.new("kick_front", Category.COMBAT, 20, false)

	# Chamber
	front_kick.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(6, Vector3(-0.8, 0, 0)))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(0, Vector3.ZERO))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(6, Vector3(1.2, 0, 0)))

	# Extend
	front_kick.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(10, Vector3(-1.3, 0, 0)))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(10, Vector3(0.2, 0, 0)))

	# Hold
	front_kick.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(14, Vector3(-1.3, 0, 0)))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(14, Vector3(0.2, 0, 0)))

	# Return
	front_kick.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(20, Vector3.ZERO))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(20, Vector3.ZERO))

	# Counter balance with arms
	front_kick.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3.ZERO))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(10, Vector3(-0.5, 0, -0.3)))
	front_kick.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(20, Vector3.ZERO))

	library.register(front_kick)

	# Roundhouse kick
	var roundhouse := Animation.new("kick_roundhouse", Category.COMBAT, 25, false)

	# Pivot and chamber
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3(0, 0, 0)))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(8, Vector3(0, 0.5, 0)))

	roundhouse.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(8, Vector3(-0.6, -0.3, 0.8)))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(0, Vector3.ZERO))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(8, Vector3(1.0, 0, 0)))

	# Swing through
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(14, Vector3(0, 1.0, 0)))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(14, Vector3(-0.3, -0.5, 1.2)))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(14, Vector3(0.3, 0, 0)))

	# Recovery
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(25, Vector3.ZERO))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(25, Vector3.ZERO))
	roundhouse.add_keyframe(HumanoidTypes.BodyPart.CALF_R, BoneKeyframe.new(25, Vector3.ZERO))

	library.register(roundhouse)


static func _create_block_animation() -> void:
	var block := Animation.new("block_high", Category.COMBAT, 10, false)

	# Arms up to guard
	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(5, Vector3(-1.2, 0, -0.5)))
	block.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_L, BoneKeyframe.new(5, Vector3(1.5, 0, 0)))

	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(5, Vector3(-1.2, 0, 0.5)))
	block.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.LOWER_ARM_R, BoneKeyframe.new(5, Vector3(1.5, 0, 0)))

	# Hold block
	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(10, Vector3(-1.2, 0, -0.5)))
	block.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(10, Vector3(-1.2, 0, 0.5)))

	# Slight crouch
	block.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(5, Vector3(0.2, 0, 0)))
	block.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	block.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(5, Vector3(0.2, 0, 0)))

	library.register(block)


static func _create_hit_reactions() -> void:
	# Hit from front
	var hit_front := Animation.new("hit_front", Category.COMBAT, 20, false)

	# Recoil back
	hit_front.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(4, Vector3(-0.2, 0, 0), Vector3(0, 0, -0.1)))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(12, Vector3(-0.1, 0, 0), Vector3(0, 0, -0.05)))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(20, Vector3.ZERO, Vector3.ZERO))

	hit_front.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3.ZERO))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(4, Vector3(-0.3, 0, 0)))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(20, Vector3.ZERO))

	hit_front.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(0, Vector3.ZERO))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(4, Vector3(-0.4, 0, 0)))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(8, Vector3(0.1, 0, 0)))
	hit_front.add_keyframe(HumanoidTypes.BodyPart.HEAD, BoneKeyframe.new(20, Vector3.ZERO))

	library.register(hit_front)

	# Stagger
	var stagger := Animation.new("stagger", Category.COMBAT, 30, false)

	stagger.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	stagger.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(5, Vector3(-0.3, 0, 0.1), Vector3(0, 0, -0.15)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3(-0.2, 0, -0.05), Vector3(0, 0, 0)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(25, Vector3(-0.1, 0, 0.02), Vector3(0, 0, 0)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(30, Vector3.ZERO, Vector3.ZERO))

	stagger.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3.ZERO))
	stagger.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(5, Vector3(-0.4, 0, 0.2)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(30, Vector3.ZERO))

	# Arms flail
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(0, Vector3.ZERO))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(5, Vector3(0.3, 0, -0.5)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(15, Vector3(-0.2, 0, -0.3)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_L, BoneKeyframe.new(30, Vector3.ZERO))

	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(0, Vector3.ZERO))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(5, Vector3(0.4, 0, 0.6)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(15, Vector3(-0.1, 0, 0.3)))
	stagger.add_keyframe(HumanoidTypes.BodyPart.UPPER_ARM_R, BoneKeyframe.new(30, Vector3.ZERO))

	library.register(stagger)


static func _create_dodge_animations() -> void:
	# Dodge left
	var dodge_l := Animation.new("dodge_left", Category.COMBAT, 15, false)

	dodge_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	dodge_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(5, Vector3(0, 0, 0.3), Vector3(0, 0, -0.3)))
	dodge_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(10, Vector3(0, 0, 0.2), Vector3(0, 0, -0.2)))
	dodge_l.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3.ZERO, Vector3.ZERO))

	dodge_l.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3.ZERO))
	dodge_l.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(5, Vector3(0, 0, 0.4)))
	dodge_l.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(15, Vector3.ZERO))

	library.register(dodge_l)

	# Dodge right
	var dodge_r := Animation.new("dodge_right", Category.COMBAT, 15, false)

	dodge_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	dodge_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(5, Vector3(0, 0, -0.3), Vector3(0, 0, 0.3)))
	dodge_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(10, Vector3(0, 0, -0.2), Vector3(0, 0, 0.2)))
	dodge_r.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(15, Vector3.ZERO, Vector3.ZERO))

	dodge_r.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(0, Vector3.ZERO))
	dodge_r.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(5, Vector3(0, 0, -0.4)))
	dodge_r.add_keyframe(HumanoidTypes.BodyPart.SPINE_UPPER, BoneKeyframe.new(15, Vector3.ZERO))

	library.register(dodge_r)

	# Backstep
	var backstep := Animation.new("dodge_back", Category.COMBAT, 18, false)

	backstep.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(0, Vector3.ZERO, Vector3.ZERO))
	backstep.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(6, Vector3(-0.1, 0, 0), Vector3(0, 0, -0.25)))
	backstep.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(12, Vector3(-0.05, 0, 0), Vector3(0, 0, -0.15)))
	backstep.add_keyframe(HumanoidTypes.BodyPart.PELVIS, BoneKeyframe.new(18, Vector3.ZERO, Vector3.ZERO))

	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(0, Vector3.ZERO))
	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(6, Vector3(0.4, 0, 0)))
	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_L, BoneKeyframe.new(18, Vector3.ZERO))

	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(0, Vector3.ZERO))
	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(3, Vector3(-0.3, 0, 0)))
	backstep.add_keyframe(HumanoidTypes.BodyPart.THIGH_R, BoneKeyframe.new(18, Vector3.ZERO))

	library.register(backstep)
