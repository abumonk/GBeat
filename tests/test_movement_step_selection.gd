## Test cases for movement step selection system
extends TestBase


func test_movement_step_definition_creation() -> bool:
	var step := MovementStepDefinition.new()
	step.package = "walk"
	step.step_name = "test_step"
	step.movement_delta = Vector3(0, 0, -1.5)

	if not assert_equal(step.package, "walk"):
		return false
	if not assert_equal(step.step_name, "test_step"):
		return false
	if not assert_approximately(step.movement_delta.z, -1.5):
		return false

	return true


func test_movement_step_factory_methods() -> bool:
	var walk_left := MovementStepDefinition.create_walk_forward_left()
	var walk_right := MovementStepDefinition.create_walk_forward_right()
	var strafe := MovementStepDefinition.create_strafe_left()
	var idle := MovementStepDefinition.create_idle()

	# Walk forward left
	if not assert_equal(walk_left.package, "walk"):
		return false
	if not assert_equal(walk_left.step_start_foot_contact, MovementStepDefinition.FootContact.RIGHT):
		return false
	if not assert_equal(walk_left.step_end_foot_contact, MovementStepDefinition.FootContact.LEFT):
		return false

	# Walk forward right (opposite feet)
	if not assert_equal(walk_right.step_start_foot_contact, MovementStepDefinition.FootContact.LEFT):
		return false
	if not assert_equal(walk_right.step_end_foot_contact, MovementStepDefinition.FootContact.RIGHT):
		return false

	# Strafe left
	if not assert_less(strafe.movement_delta.x, 0.0, "Strafe left should have negative X"):
		return false

	# Idle
	if not assert_approximately(idle.movement_delta.length(), 0.0):
		return false

	return true


func test_movement_step_direction() -> bool:
	var step := MovementStepDefinition.new()
	step.movement_delta = Vector3(1, 0, -1)

	var direction := step.get_movement_direction()

	if not assert_approximately(direction.length(), 1.0, 0.01, "Direction should be normalized"):
		return false

	return true


func test_movement_step_speed() -> bool:
	var step := MovementStepDefinition.new()
	step.movement_delta = Vector3(0, 0, -3.0)
	step.base_duration_seconds = 0.5

	var speed := step.get_movement_speed()

	# Speed = distance / time = 3.0 / 0.5 = 6.0
	if not assert_approximately(speed, 6.0, 0.01):
		return false

	return true


func test_movement_playback_plan_creation() -> bool:
	var step := MovementStepDefinition.create_walk_forward_left()
	var plan := MovementStepPlaybackPlan.from_step(step, 1.0, true)

	if not assert_equal(plan.step_name, step.step_name):
		return false
	if not assert_approximately(plan.play_rate, 1.0):
		return false
	if not assert_equal(plan.step_definition, step):
		return false

	return true


func test_movement_playback_plan_scaling() -> bool:
	var step := MovementStepDefinition.create_walk_forward_left()
	var plan_full := MovementStepPlaybackPlan.from_step(step, 1.0, true)
	var plan_half := MovementStepPlaybackPlan.from_step(step, 0.5, true)

	# Half magnitude should have half movement
	var full_length := plan_full.adjusted_movement_delta.length()
	var half_length := plan_half.adjusted_movement_delta.length()

	if not assert_approximately(half_length / full_length, 0.5, 0.01, "Half magnitude should be half movement"):
		return false

	return true


func test_movement_playback_plan_no_scaling() -> bool:
	var step := MovementStepDefinition.create_walk_forward_left()
	var plan_full := MovementStepPlaybackPlan.from_step(step, 1.0, false)
	var plan_half := MovementStepPlaybackPlan.from_step(step, 0.5, false)

	# Without scaling, movement should be the same
	if not assert_approximately(plan_full.adjusted_movement_delta.length(), plan_half.adjusted_movement_delta.length(), 0.01):
		return false

	return true


func test_movement_playback_plan_velocity() -> bool:
	var step := MovementStepDefinition.create_walk_forward_left()
	var plan := MovementStepPlaybackPlan.from_step(step, 1.0, true)

	var velocity := plan.get_velocity()
	var expected_velocity := plan.adjusted_movement_delta / plan.quantized_duration_seconds

	if not assert_approximately(velocity.length(), expected_velocity.length(), 0.01):
		return false

	return true


func test_movement_playback_plan_duration_adjustment() -> bool:
	var step := MovementStepDefinition.new()
	step.base_duration_seconds = 0.5

	var plan := MovementStepPlaybackPlan.from_step(step, 1.0)

	# Try to adjust to 0.4 seconds (within 30% tolerance)
	var success := plan.adjust_to_duration(0.4, 0.3)

	if not assert_true(success, "Should be able to adjust to 0.4s"):
		return false
	if not assert_approximately(plan.quantized_duration_seconds, 0.4, 0.01):
		return false
	# Play rate should be 0.5 / 0.4 = 1.25
	if not assert_approximately(plan.play_rate, 1.25, 0.01):
		return false

	return true


func test_movement_playback_plan_duration_out_of_range() -> bool:
	var step := MovementStepDefinition.new()
	step.base_duration_seconds = 0.5

	var plan := MovementStepPlaybackPlan.from_step(step, 1.0)

	# Try to adjust to 0.2 seconds (outside 30% tolerance - would need 2.5x rate)
	var success := plan.adjust_to_duration(0.2, 0.3)

	if not assert_false(success, "Should not adjust outside tolerance"):
		return false

	return true
