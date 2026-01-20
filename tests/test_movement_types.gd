## Test cases for Movement Types
extends TestBase


func test_movement_state_creation() -> bool:
	var state := MovementTypes.MovementState.new()

	if not assert_equal(state.velocity, Vector3.ZERO, "Initial velocity should be zero"):
		return false
	if not assert_false(state.is_moving, "Initial state should not be moving"):
		return false
	if not assert_true(state.is_grounded, "Initial state should be grounded"):
		return false

	return true


func test_movement_state_update() -> bool:
	var state := MovementTypes.MovementState.new()

	state.velocity = Vector3(5, 0, 0)
	state.current_speed = 5.0
	state.is_moving = true

	if not assert_approximately(state.current_speed, 5.0):
		return false
	if not assert_true(state.is_moving):
		return false

	return true


func test_input_snapshot_creation() -> bool:
	var input := MovementTypes.InputSnapshot.new()

	if not assert_equal(input.raw_input, Vector2.ZERO, "Initial raw_input should be zero"):
		return false
	if not assert_equal(input.magnitude, 0.0, "Initial magnitude should be zero"):
		return false

	return true


func test_input_snapshot_quantized() -> bool:
	var input := MovementTypes.InputSnapshot.new()

	input.quantized_input = Vector2(1, 1).normalized()
	input.magnitude = 1.0

	if not assert_approximately(input.quantized_input.length(), 1.0, 0.001, "Normalized input should have length 1"):
		return false

	return true


func test_facing_direction_vector() -> bool:
	var state := MovementTypes.MovementState.new()

	state.facing_direction = Vector3(0, 0, -1)  # Forward

	if not assert_approximately(state.facing_direction.length(), 1.0, 0.001):
		return false
	if not assert_approximately(state.facing_direction.z, -1.0, 0.001):
		return false

	return true
