## MovementTypes - Enums and data classes for movement system
class_name MovementTypes
extends RefCounted


enum Foot { LEFT, RIGHT, NONE }


enum Direction {
	FORWARD,
	FORWARD_RIGHT,
	RIGHT,
	BACKWARD_RIGHT,
	BACKWARD,
	BACKWARD_LEFT,
	LEFT,
	FORWARD_LEFT
}


class InputSnapshot:
	var raw_input: Vector2 = Vector2.ZERO
	var quantized_input: Vector2 = Vector2.ZERO
	var magnitude: float = 0.0
	var direction_angle: float = 0.0
	var is_moving: bool = false
	var timestamp: float = 0.0


class MovementState:
	var velocity: Vector3 = Vector3.ZERO
	var facing_direction: Vector3 = Vector3.FORWARD
	var is_grounded: bool = true
	var is_moving: bool = false
	var current_speed: float = 0.0
	var target_speed: float = 0.0
	var current_foot: Foot = Foot.NONE


static func direction_to_vector(dir: Direction) -> Vector2:
	match dir:
		Direction.FORWARD:
			return Vector2(0, -1)
		Direction.FORWARD_RIGHT:
			return Vector2(1, -1).normalized()
		Direction.RIGHT:
			return Vector2(1, 0)
		Direction.BACKWARD_RIGHT:
			return Vector2(1, 1).normalized()
		Direction.BACKWARD:
			return Vector2(0, 1)
		Direction.BACKWARD_LEFT:
			return Vector2(-1, 1).normalized()
		Direction.LEFT:
			return Vector2(-1, 0)
		Direction.FORWARD_LEFT:
			return Vector2(-1, -1).normalized()
	return Vector2.ZERO


static func vector_to_direction(vec: Vector2) -> Direction:
	if vec.length_squared() < 0.001:
		return Direction.FORWARD

	var angle := vec.angle()
	# Convert to 8 directions (each direction is 45 degrees)
	var index := int(round(angle / (PI / 4))) % 8
	if index < 0:
		index += 8

	# Map: 0=Right, 1=DownRight, 2=Down, etc.
	# Convert to our Direction enum
	var direction_map := [
		Direction.RIGHT,
		Direction.BACKWARD_RIGHT,
		Direction.BACKWARD,
		Direction.BACKWARD_LEFT,
		Direction.LEFT,
		Direction.FORWARD_LEFT,
		Direction.FORWARD,
		Direction.FORWARD_RIGHT
	]

	return direction_map[index]


static func opposite_foot(foot: Foot) -> Foot:
	match foot:
		Foot.LEFT:
			return Foot.RIGHT
		Foot.RIGHT:
			return Foot.LEFT
	return Foot.NONE
