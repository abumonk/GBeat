## DebugProfiler - Performance sampling and timing analysis
class_name DebugProfiler
extends Node


signal sample_completed(name: String, duration_ms: float)


## Sample data
class ProfileSample:
	var name: String = ""
	var start_time: int = 0
	var end_time: int = 0
	var duration_us: int = 0
	var call_count: int = 0
	var total_duration_us: int = 0
	var min_duration_us: int = 9999999
	var max_duration_us: int = 0

	func get_duration_ms() -> float:
		return duration_us / 1000.0

	func get_average_ms() -> float:
		if call_count == 0:
			return 0.0
		return (total_duration_us / call_count) / 1000.0

	func get_min_ms() -> float:
		return min_duration_us / 1000.0

	func get_max_ms() -> float:
		return max_duration_us / 1000.0


## Active samples
var _active_samples: Dictionary = {}  # name -> ProfileSample
var _completed_samples: Dictionary = {}  # name -> ProfileSample (aggregated)
var _sample_history: Array[Dictionary] = []

## Settings
@export var history_size: int = 60
@export var auto_print_slow: bool = true
@export var slow_threshold_ms: float = 5.0


## Begin a named sample
func begin_sample(name: String) -> void:
	var sample := ProfileSample.new()
	sample.name = name
	sample.start_time = Time.get_ticks_usec()
	_active_samples[name] = sample


## End a named sample and return duration in milliseconds
func end_sample(name: String) -> float:
	if not _active_samples.has(name):
		push_warning("DebugProfiler: No active sample named '%s'" % name)
		return 0.0

	var sample: ProfileSample = _active_samples[name]
	sample.end_time = Time.get_ticks_usec()
	sample.duration_us = sample.end_time - sample.start_time
	_active_samples.erase(name)

	# Update aggregated stats
	_update_aggregated(sample)

	# Check for slow samples
	var duration_ms := sample.get_duration_ms()
	if auto_print_slow and duration_ms > slow_threshold_ms:
		print("DebugProfiler: SLOW '%s' took %.2fms" % [name, duration_ms])

	sample_completed.emit(name, duration_ms)
	return duration_ms


func _update_aggregated(sample: ProfileSample) -> void:
	if not _completed_samples.has(sample.name):
		_completed_samples[sample.name] = ProfileSample.new()
		_completed_samples[sample.name].name = sample.name

	var agg: ProfileSample = _completed_samples[sample.name]
	agg.call_count += 1
	agg.total_duration_us += sample.duration_us
	agg.min_duration_us = mini(agg.min_duration_us, sample.duration_us)
	agg.max_duration_us = maxi(agg.max_duration_us, sample.duration_us)
	agg.duration_us = sample.duration_us  # Last duration


## Get aggregated stats for a sample
func get_sample_stats(name: String) -> ProfileSample:
	return _completed_samples.get(name)


## Get all sample names
func get_sample_names() -> Array:
	return _completed_samples.keys()


## Reset all statistics
func reset() -> void:
	_active_samples.clear()
	_completed_samples.clear()
	_sample_history.clear()


## Reset stats for a specific sample
func reset_sample(name: String) -> void:
	_completed_samples.erase(name)


## Print all sample statistics
func print_stats() -> void:
	print("\n=== PROFILER STATS ===")
	print("%-30s %10s %10s %10s %10s %10s" % ["Name", "Calls", "Avg(ms)", "Min(ms)", "Max(ms)", "Last(ms)"])
	print("-" * 80)

	var names := get_sample_names()
	names.sort()

	for name in names:
		var sample: ProfileSample = _completed_samples[name]
		print("%-30s %10d %10.2f %10.2f %10.2f %10.2f" % [
			name,
			sample.call_count,
			sample.get_average_ms(),
			sample.get_min_ms(),
			sample.get_max_ms(),
			sample.get_duration_ms(),
		])


## Scope-based profiling helper
func scoped(name: String) -> ScopedProfile:
	return ScopedProfile.new(self, name)


## Inner class for scoped profiling
class ScopedProfile:
	var _profiler: DebugProfiler
	var _name: String

	func _init(profiler: DebugProfiler, name: String) -> void:
		_profiler = profiler
		_name = name
		_profiler.begin_sample(_name)

	func stop() -> float:
		return _profiler.end_sample(_name)


## Take a frame snapshot
func capture_frame() -> void:
	var frame_data := {
		"frame": Engine.get_process_frames(),
		"time": Time.get_ticks_msec(),
		"fps": Engine.get_frames_per_second(),
		"samples": {},
	}

	for name in _completed_samples.keys():
		var sample: ProfileSample = _completed_samples[name]
		frame_data.samples[name] = sample.get_duration_ms()

	_sample_history.append(frame_data)

	while _sample_history.size() > history_size:
		_sample_history.remove_at(0)


## Get frame history
func get_history() -> Array[Dictionary]:
	return _sample_history


## Get average FPS from history
func get_average_fps() -> float:
	if _sample_history.is_empty():
		return 0.0

	var total := 0.0
	for frame in _sample_history:
		total += frame.fps

	return total / _sample_history.size()
