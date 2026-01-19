## Test cases for Quant system
extends TestBase


func test_quant_creation() -> bool:
	var quant := Quant.new()
	quant.type = Quant.Type.KICK
	quant.position = 0
	quant.value = 1.0

	if not assert_equal(quant.type, Quant.Type.KICK, "Quant type should be KICK"):
		return false
	if not assert_equal(quant.position, 0, "Quant position should be 0"):
		return false
	if not assert_equal(quant.value, 1.0, "Quant value should be 1.0"):
		return false

	return true


func test_quant_types() -> bool:
	# Verify all quant types exist
	var types := [
		Quant.Type.TICK,
		Quant.Type.HIT,
		Quant.Type.KICK,
		Quant.Type.SNARE,
		Quant.Type.HAT,
		Quant.Type.ANIMATION,
		Quant.Type.MOVE_FORWARD_SPEED,
		Quant.Type.MOVE_RIGHT_SPEED,
		Quant.Type.ROTATION_SPEED,
	]

	for t in types:
		if not assert_true(t >= 0, "Quant type should be valid"):
			return false

	return true


func test_quant_position_range() -> bool:
	var quant := Quant.new()

	# Test valid positions (0-31)
	quant.position = 0
	if not assert_equal(quant.position, 0):
		return false

	quant.position = 31
	if not assert_equal(quant.position, 31):
		return false

	return true


func test_quant_value_range() -> bool:
	var quant := Quant.new()

	quant.value = 0.0
	if not assert_equal(quant.value, 0.0):
		return false

	quant.value = 1.0
	if not assert_equal(quant.value, 1.0):
		return false

	quant.value = 0.5
	if not assert_approximately(quant.value, 0.5):
		return false

	return true
