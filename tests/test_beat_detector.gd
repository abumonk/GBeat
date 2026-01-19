## Test cases for Beat Detector
extends TestBase


func test_beat_detector_creation() -> bool:
	var detector := BeatDetector.new()

	if not assert_approximately(detector.energy_threshold, 1.5):
		return false
	if not assert_approximately(detector.min_beat_interval, 0.2):
		return false
	if not assert_equal(detector.history_size, 43):
		return false

	return true


func test_beat_detector_reset() -> bool:
	var detector := BeatDetector.new()

	# Add some fake history
	detector._energy_history.append(0.5)
	detector._energy_history.append(0.6)
	detector._beat_times.append(1.0)

	detector.reset()

	if not assert_equal(detector._energy_history.size(), 0, "Energy history should be cleared"):
		return false
	if not assert_equal(detector._beat_times.size(), 0, "Beat times should be cleared"):
		return false

	return true


func test_calculate_bpm_insufficient_data() -> bool:
	var detector := BeatDetector.new()

	# With less than 4 beat times, should return 0
	detector._beat_times = [1.0, 1.5, 2.0]  # Only 3 beats

	var bpm := detector.calculate_bpm()

	if not assert_approximately(bpm, 0.0, 0.001, "Should return 0 with insufficient data"):
		return false

	return true


func test_calculate_bpm_valid_data() -> bool:
	var detector := BeatDetector.new()

	# Simulate beats at 120 BPM (0.5s intervals)
	detector._beat_times = [0.0, 0.5, 1.0, 1.5, 2.0, 2.5]

	var bpm := detector.calculate_bpm()

	# Should snap to 120 BPM
	if not assert_approximately(bpm, 120.0, 5.0, "Should calculate approximately 120 BPM"):
		return false

	return true


func test_snap_to_common_bpm() -> bool:
	var detector := BeatDetector.new()

	# Test snapping to common values
	var snapped := detector._snap_to_common_bpm(118.5)
	if not assert_approximately(snapped, 120.0, 0.001, "118.5 should snap to 120"):
		return false

	snapped = detector._snap_to_common_bpm(127.0)
	if not assert_approximately(snapped, 128.0, 0.001, "127 should snap to 128"):
		return false

	# Values far from common BPMs should not snap
	snapped = detector._snap_to_common_bpm(137.0)
	if not assert_approximately(snapped, 137.0, 0.001, "137 should not snap"):
		return false

	return true


func test_calculate_energy_empty_buffer() -> bool:
	var detector := BeatDetector.new()

	var buffer := PackedFloat32Array()
	var energy := detector._calculate_energy(buffer)

	# Empty buffer should handle gracefully
	if not assert_true(is_nan(energy) or energy == 0.0, "Empty buffer should return 0 or NaN"):
		return false

	return true


func test_calculate_energy_silence() -> bool:
	var detector := BeatDetector.new()

	var buffer := PackedFloat32Array()
	for i in range(1024):
		buffer.append(0.0)

	var energy := detector._calculate_energy(buffer)

	if not assert_approximately(energy, 0.0, 0.001, "Silent buffer should have 0 energy"):
		return false

	return true


func test_calculate_energy_full_volume() -> bool:
	var detector := BeatDetector.new()

	var buffer := PackedFloat32Array()
	for i in range(1024):
		buffer.append(1.0)

	var energy := detector._calculate_energy(buffer)

	if not assert_approximately(energy, 1.0, 0.001, "Full volume should have energy of 1.0"):
		return false

	return true
