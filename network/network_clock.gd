## NetworkClock - Synchronizes time across networked players
class_name NetworkClock
extends Node


signal time_synced(offset: float)
signal latency_updated(rtt: float)


## Sync settings
@export var sync_interval: float = 1.0
@export var sample_count: int = 5
@export var outlier_threshold: float = 2.0  # Standard deviations

## Time sync state
var server_time_offset: float = 0.0
var round_trip_time: float = 0.0
var is_synced: bool = false

## Internal
var _sync_samples: Array[float] = []
var _rtt_samples: Array[float] = []
var _sync_timer: float = 0.0
var _pending_sync_time: int = 0


func _ready() -> void:
	if not multiplayer.is_server():
		_sync_timer = sync_interval


func _process(delta: float) -> void:
	if multiplayer.is_server():
		return

	_sync_timer -= delta
	if _sync_timer <= 0:
		_sync_timer = sync_interval
		_request_time_sync()


func _request_time_sync() -> void:
	_pending_sync_time = Time.get_ticks_msec()
	_request_server_time.rpc_id(1)


@rpc("any_peer", "reliable")
func _request_server_time() -> void:
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()
	var server_time := Time.get_ticks_msec()
	_respond_server_time.rpc_id(sender, server_time)


@rpc("authority", "reliable")
func _respond_server_time(server_time: int) -> void:
	var now := Time.get_ticks_msec()
	var rtt := now - _pending_sync_time

	# Calculate offset
	# Server time when message was sent is approximately: server_time
	# Server time now is approximately: server_time + rtt/2
	var estimated_server_time := server_time + rtt / 2
	var offset := float(estimated_server_time - now)

	# Add samples
	_rtt_samples.append(rtt)
	_sync_samples.append(offset)

	# Keep sample count limited
	while _rtt_samples.size() > sample_count:
		_rtt_samples.remove_at(0)
	while _sync_samples.size() > sample_count:
		_sync_samples.remove_at(0)

	# Calculate averages (with outlier rejection)
	round_trip_time = _calculate_average_filtered(_rtt_samples)
	server_time_offset = _calculate_average_filtered(_sync_samples)

	is_synced = _sync_samples.size() >= sample_count

	latency_updated.emit(round_trip_time)
	time_synced.emit(server_time_offset)


func _calculate_average_filtered(samples: Array) -> float:
	if samples.is_empty():
		return 0.0

	if samples.size() < 3:
		# Not enough samples for filtering
		var sum := 0.0
		for s in samples:
			sum += s
		return sum / samples.size()

	# Calculate mean and std dev
	var sum := 0.0
	for s in samples:
		sum += s
	var mean := sum / samples.size()

	var variance := 0.0
	for s in samples:
		variance += (s - mean) * (s - mean)
	variance /= samples.size()
	var std_dev := sqrt(variance)

	# Filter outliers and recalculate
	var filtered_sum := 0.0
	var filtered_count := 0
	for s in samples:
		if abs(s - mean) <= outlier_threshold * std_dev:
			filtered_sum += s
			filtered_count += 1

	if filtered_count == 0:
		return mean

	return filtered_sum / filtered_count


## Get synchronized network time in milliseconds
func get_network_time() -> int:
	if multiplayer.is_server():
		return Time.get_ticks_msec()
	return Time.get_ticks_msec() + int(server_time_offset)


## Get synchronized network time in seconds
func get_network_time_seconds() -> float:
	return get_network_time() / 1000.0


## Get one-way latency estimate
func get_latency() -> float:
	return round_trip_time / 2.0


## Get round-trip time
func get_rtt() -> float:
	return round_trip_time


## Check if time is synchronized
func is_time_synced() -> bool:
	return is_synced or multiplayer.is_server()


## Force immediate sync
func force_sync() -> void:
	if not multiplayer.is_server():
		_request_time_sync()


## Get time offset from server
func get_offset() -> float:
	return server_time_offset
