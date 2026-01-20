## CharacterAnimation - Resource for storing animation data
class_name CharacterAnimation
extends Resource


enum AnimationType {
	MOVEMENT,
	COMBAT,
	DANCE,
	EMOTE,
	IDLE,
}


@export var name: String = ""
@export var type: AnimationType = AnimationType.MOVEMENT
@export var frame_count: int = 30
@export var fps: float = 30.0
@export var loop: bool = true
@export var tracks: Dictionary = {}  # bone_name -> Array[Keyframe]


## Get duration in seconds
func get_duration() -> float:
	return frame_count / fps


## Sample bone transform at frame
func sample_bone(bone: String, frame: float) -> Transform3D:
	if not tracks.has(bone):
		return Transform3D.IDENTITY

	var keyframes: Array = tracks[bone]
	if keyframes.is_empty():
		return Transform3D.IDENTITY

	# Find surrounding keyframes
	var prev_kf: Keyframe = null
	var next_kf: Keyframe = null

	for kf in keyframes:
		if kf.frame <= frame:
			prev_kf = kf
		if kf.frame >= frame and next_kf == null:
			next_kf = kf

	if prev_kf == null:
		prev_kf = keyframes[0]
	if next_kf == null:
		next_kf = keyframes[keyframes.size() - 1]

	if prev_kf == next_kf or prev_kf.frame == next_kf.frame:
		return prev_kf.to_transform()

	# Interpolate
	var t := (frame - prev_kf.frame) / (next_kf.frame - prev_kf.frame)
	return prev_kf.interpolate_to(next_kf, t)


## Set keyframe for bone
func set_keyframe(bone: String, keyframe: Keyframe) -> void:
	if not tracks.has(bone):
		tracks[bone] = []

	var keyframes: Array = tracks[bone]

	# Replace existing keyframe at same frame
	for i in range(keyframes.size()):
		if keyframes[i].frame == keyframe.frame:
			keyframes[i] = keyframe
			return

	# Insert new keyframe
	keyframes.append(keyframe)

	# Sort by frame
	keyframes.sort_custom(func(a, b): return a.frame < b.frame)


## Remove keyframe
func remove_keyframe(bone: String, frame: int) -> void:
	if not tracks.has(bone):
		return

	var keyframes: Array = tracks[bone]
	for i in range(keyframes.size() - 1, -1, -1):
		if keyframes[i].frame == frame:
			keyframes.remove_at(i)
			return


## Get keyframe at frame
func get_keyframe(bone: String, frame: int) -> Keyframe:
	if not tracks.has(bone):
		return null

	for kf in tracks[bone]:
		if kf.frame == frame:
			return kf

	return null


## Get all keyframes for bone
func get_bone_keyframes(bone: String) -> Array:
	return tracks.get(bone, [])


## Get all bones with keyframes
func get_animated_bones() -> Array[String]:
	var bones: Array[String] = []
	for bone in tracks.keys():
		bones.append(bone)
	return bones
