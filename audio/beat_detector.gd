## BeatDetector - Analyzes audio for beat detection and BPM estimation
class_name BeatDetector
extends RefCounted


signal beat_detected(time: float, strength: float)
signal bpm_calculated(bpm: float)


## Analysis settings
var energy_threshold: float = 1.5  ## Energy spike threshold for beat detection
var min_beat_interval: float = 0.2  ## Minimum time between beats (300 BPM max)
var history_size: int = 43  ## ~1 second at 44100Hz with 1024 buffer

## State
var _energy_history: Array[float] = []
var _last_beat_time: float = 0.0
var _beat_times: Array[float] = []
var _max_beat_history: int = 16


## Analyze audio buffer for beats
## Returns true if beat detected
func analyze_buffer(buffer: PackedFloat32Array, sample_rate: int, current_time: float) -> bool:
	if buffer.is_empty():
		return false

	# Calculate energy of current buffer
	var energy := _calculate_energy(buffer)

	# Add to history
	_energy_history.append(energy)
	if _energy_history.size() > history_size:
		_energy_history.pop_front()

	# Need enough history
	if _energy_history.size() < history_size:
		return false

	# Calculate average and variance
	var average := _calculate_average(_energy_history)
	var variance := _calculate_variance(_energy_history, average)

	# Dynamic threshold based on variance
	var threshold := average + energy_threshold * sqrt(variance)

	# Check for beat
	var time_since_last := current_time - _last_beat_time
	if energy > threshold and time_since_last > min_beat_interval:
		_last_beat_time = current_time

		# Calculate strength (0-1)
		var strength: float = clamp((energy - average) / (threshold - average + 0.001), 0.0, 1.0)

		# Record beat time for BPM calculation
		_beat_times.append(current_time)
		if _beat_times.size() > _max_beat_history:
			_beat_times.pop_front()

		beat_detected.emit(current_time, strength)
		return true

	return false


## Calculate estimated BPM from detected beats
func calculate_bpm() -> float:
	if _beat_times.size() < 4:
		return 0.0

	# Calculate intervals between beats
	var intervals: Array[float] = []
	for i in range(1, _beat_times.size()):
		var interval := _beat_times[i] - _beat_times[i - 1]
		if interval > 0.1 and interval < 2.0:  ## Filter out outliers
			intervals.append(interval)

	if intervals.is_empty():
		return 0.0

	# Calculate median interval
	intervals.sort()
	var median_idx := intervals.size() / 2
	var median_interval := intervals[median_idx]

	# Convert to BPM
	var bpm := 60.0 / median_interval

	# Round to common BPM values
	bpm = _snap_to_common_bpm(bpm)

	bpm_calculated.emit(bpm)
	return bpm


func _calculate_energy(buffer: PackedFloat32Array) -> float:
	var sum := 0.0
	for sample in buffer:
		sum += sample * sample
	return sum / buffer.size()


func _calculate_average(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0.0
	for v in values:
		sum += v
	return sum / values.size()


func _calculate_variance(values: Array[float], mean: float) -> float:
	if values.is_empty():
		return 0.0
	var sum := 0.0
	for v in values:
		var diff := v - mean
		sum += diff * diff
	return sum / values.size()


func _snap_to_common_bpm(bpm_value: float) -> float:
	# Common BPM values in music
	var common_bpms: Array[float] = [60.0, 70.0, 80.0, 85.0, 90.0, 95.0, 100.0, 105.0, 110.0, 115.0, 120.0, 125.0, 128.0, 130.0, 135.0, 140.0, 145.0, 150.0, 160.0, 170.0, 175.0, 180.0]

	var closest: float = common_bpms[0]
	var min_diff: float = abs(bpm_value - closest)

	for common: float in common_bpms:
		var diff: float = abs(bpm_value - common)
		if diff < min_diff:
			min_diff = diff
			closest = common

	# Only snap if within 5 BPM
	if min_diff < 5.0:
		return closest
	return round(bpm_value)


func reset() -> void:
	_energy_history.clear()
	_beat_times.clear()
	_last_beat_time = 0.0
