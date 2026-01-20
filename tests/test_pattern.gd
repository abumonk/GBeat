## Test cases for Pattern system
extends TestBase


func test_pattern_creation() -> bool:
	var pattern := Pattern.new()
	pattern.pattern_name = "test_pattern"
	pattern.bpm = 120.0

	if not assert_equal(pattern.pattern_name, "test_pattern"):
		return false
	if not assert_equal(pattern.bpm, 120.0):
		return false

	return true


func test_pattern_bpm_calculations() -> bool:
	var pattern := Pattern.new()
	pattern.bpm = 120.0

	var beat_duration: float = pattern.get_beat_duration()
	if not assert_approximately(beat_duration, 0.5, 0.001, "Beat duration at 120 BPM should be 0.5s"):
		return false

	var bar_duration: float = pattern.get_bar_duration()
	if not assert_approximately(bar_duration, 2.0, 0.001, "Bar duration at 120 BPM should be 2.0s"):
		return false

	var quant_duration: float = pattern.get_quant_duration()
	if not assert_approximately(quant_duration, 0.0625, 0.001, "Quant duration at 120 BPM should be ~0.0625s"):
		return false

	return true


func test_pattern_add_quants() -> bool:
	var pattern := Pattern.new()

	var kick := Quant.new()
	kick.type = Quant.Type.KICK
	kick.position = 0
	kick.value = 1.0

	var snare := Quant.new()
	snare.type = Quant.Type.SNARE
	snare.position = 8
	snare.value = 1.0

	pattern.quants = [kick, snare]

	if not assert_equal(pattern.quants.size(), 2, "Pattern should have 2 quants"):
		return false

	return true


func test_pattern_get_quants_by_type() -> bool:
	var pattern := Pattern.new()

	# Add multiple quants
	for i in range(4):
		var kick := Quant.new()
		kick.type = Quant.Type.KICK
		kick.position = i * 8
		pattern.quants.append(kick)

	for i in range(2):
		var snare := Quant.new()
		snare.type = Quant.Type.SNARE
		snare.position = 4 + i * 16
		pattern.quants.append(snare)

	var kicks: Array = pattern.get_quants_by_type(Quant.Type.KICK)
	var snares: Array = pattern.get_quants_by_type(Quant.Type.SNARE)

	if not assert_equal(kicks.size(), 4, "Should have 4 kicks"):
		return false
	if not assert_equal(snares.size(), 2, "Should have 2 snares"):
		return false

	return true


func test_pattern_get_quants_at_position() -> bool:
	var pattern := Pattern.new()

	# Add quants at same position
	var kick := Quant.new()
	kick.type = Quant.Type.KICK
	kick.position = 0

	var hat := Quant.new()
	hat.type = Quant.Type.HAT
	hat.position = 0

	var snare := Quant.new()
	snare.type = Quant.Type.SNARE
	snare.position = 8

	pattern.quants = [kick, hat, snare]

	var at_zero := pattern.get_quants_at_position(0)
	var at_eight := pattern.get_quants_at_position(8)

	if not assert_equal(at_zero.size(), 2, "Should have 2 quants at position 0"):
		return false
	if not assert_equal(at_eight.size(), 1, "Should have 1 quant at position 8"):
		return false

	return true


func test_pattern_json_serialization() -> bool:
	var pattern := Pattern.new()
	pattern.pattern_name = "test"
	pattern.bpm = 140.0

	var kick := Quant.new()
	kick.type = Quant.Type.KICK
	kick.position = 0
	kick.value = 1.0
	pattern.quants = [kick]

	var json: String = pattern.to_json()
	if not assert_string_contains(json, "test"):
		return false
	if not assert_string_contains(json, "140"):
		return false

	return true
