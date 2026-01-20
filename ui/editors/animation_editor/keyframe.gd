## Keyframe - Single keyframe in animation
class_name Keyframe
extends Resource


enum EasingType {
	LINEAR,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT,
	BOUNCE,
	ELASTIC,
}


@export var frame: int = 0
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO
@export var scale: Vector3 = Vector3.ONE
@export var easing: EasingType = EasingType.LINEAR


## Convert to Transform3D
func to_transform() -> Transform3D:
	var basis := Basis.from_euler(rotation)
	basis = basis.scaled(scale)
	return Transform3D(basis, position)


## Interpolate to another keyframe
func interpolate_to(other: Keyframe, t: float) -> Transform3D:
	var eased_t := _apply_easing(t)

	var pos := position.lerp(other.position, eased_t)
	var rot := rotation.lerp(other.rotation, eased_t)
	var scl := scale.lerp(other.scale, eased_t)

	var basis := Basis.from_euler(rot)
	basis = basis.scaled(scl)
	return Transform3D(basis, pos)


func _apply_easing(t: float) -> float:
	match easing:
		EasingType.LINEAR:
			return t
		EasingType.EASE_IN:
			return t * t
		EasingType.EASE_OUT:
			return 1.0 - (1.0 - t) * (1.0 - t)
		EasingType.EASE_IN_OUT:
			if t < 0.5:
				return 2 * t * t
			else:
				return 1 - pow(-2 * t + 2, 2) / 2
		EasingType.BOUNCE:
			return _bounce_ease_out(t)
		EasingType.ELASTIC:
			return _elastic_ease_out(t)

	return t


func _bounce_ease_out(t: float) -> float:
	var n1 := 7.5625
	var d1 := 2.75

	if t < 1 / d1:
		return n1 * t * t
	elif t < 2 / d1:
		t -= 1.5 / d1
		return n1 * t * t + 0.75
	elif t < 2.5 / d1:
		t -= 2.25 / d1
		return n1 * t * t + 0.9375
	else:
		t -= 2.625 / d1
		return n1 * t * t + 0.984375


func _elastic_ease_out(t: float) -> float:
	var c4 := (2 * PI) / 3

	if t == 0:
		return 0
	elif t == 1:
		return 1
	else:
		return pow(2, -10 * t) * sin((t * 10 - 0.75) * c4) + 1


## Duplicate keyframe
func duplicate_keyframe() -> Keyframe:
	var kf := Keyframe.new()
	kf.frame = frame
	kf.position = position
	kf.rotation = rotation
	kf.scale = scale
	kf.easing = easing
	return kf
