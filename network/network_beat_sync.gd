## NetworkBeatSync - Synchronizes beat timing across networked players
class_name NetworkBeatSync
extends Node


signal beat_synced()
signal desync_detected(amount: float)


@export var network_clock: NetworkClock
@export var max_desync_tolerance: float = 0.05  # 50ms
@export var correction_speed: float = 0.1
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Sync state
var beat_offset: float = 0.0
var is_synced: bool = false
var last_server_beat: int = 0
var last_server_beat_time: float = 0.0

## Internal
var _tick_handle: int = -1
var _sync_interval: float = 0.5
var _sync_timer: float = 0.0


func _ready() -> void:
	if multiplayer.is_server():
		# Server sends beat sync to clients
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_server_tick)
	else:
		_sync_timer = _sync_interval


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	if multiplayer.is_server():
		return

	# Request sync periodically
	_sync_timer -= delta
	if _sync_timer <= 0:
		_sync_timer = _sync_interval
		_request_beat_sync.rpc_id(1)

	# Apply gradual correction
	if abs(beat_offset) > 0.001:
		var correction := beat_offset * correction_speed * delta
		_apply_offset_correction(correction)


func _on_server_tick(event: SequencerEvent) -> void:
	if not multiplayer.is_server():
		return

	# Broadcast beat position to all clients on bar boundaries
	if event.quant.type == Quant.Type.TICK and event.quant.position == 0:
		var server_time := 0.0
		if network_clock:
			server_time = network_clock.get_network_time_seconds()
		else:
			server_time = Time.get_ticks_msec() / 1000.0

		var beat_info := {
			"bar": event.bar_index,
			"position": event.quant.position,
			"time": server_time,
			"bpm": _get_current_bpm(),
		}

		_broadcast_beat_sync.rpc(beat_info)


@rpc("any_peer", "reliable")
func _request_beat_sync() -> void:
	if not multiplayer.is_server():
		return

	var sender := multiplayer.get_remote_sender_id()
	var deck := Sequencer.get_deck(sequencer_deck)

	if deck:
		var server_time := 0.0
		if network_clock:
			server_time = network_clock.get_network_time_seconds()
		else:
			server_time = Time.get_ticks_msec() / 1000.0

		var beat_info := {
			"bar": deck.get_current_bar(),
			"position": deck.get_current_position(),
			"time": server_time,
			"bpm": deck.current_pattern.bpm if deck.current_pattern else 120.0,
		}

		_respond_beat_sync.rpc_id(sender, beat_info)


@rpc("authority", "unreliable")
func _broadcast_beat_sync(beat_info: Dictionary) -> void:
	_process_beat_sync(beat_info)


@rpc("authority", "reliable")
func _respond_beat_sync(beat_info: Dictionary) -> void:
	_process_beat_sync(beat_info)


func _process_beat_sync(beat_info: Dictionary) -> void:
	var server_beat_time: float = beat_info.get("time", 0.0)
	var server_bar: int = beat_info.get("bar", 0)
	var server_position: int = beat_info.get("position", 0)
	var server_bpm: float = beat_info.get("bpm", 120.0)

	# Get local time (adjusted by network clock if available)
	var local_time := 0.0
	if network_clock:
		local_time = network_clock.get_network_time_seconds()
	else:
		local_time = Time.get_ticks_msec() / 1000.0

	# Calculate where we should be based on server info
	var time_since_sync := local_time - server_beat_time
	var beat_duration := 60.0 / server_bpm
	var expected_beats := time_since_sync / beat_duration

	# Get local beat position
	var deck := Sequencer.get_deck(sequencer_deck)
	if not deck:
		return

	var local_bar := deck.get_current_bar()
	var local_position := deck.get_current_position()

	# Calculate desync
	var server_total_beats := server_bar * 32 + server_position + expected_beats * 32
	var local_total_beats := local_bar * 32.0 + local_position

	var desync_beats := server_total_beats - local_total_beats
	var desync_time := desync_beats * beat_duration / 32.0

	# Check if desync is significant
	if abs(desync_time) > max_desync_tolerance:
		beat_offset = desync_time
		desync_detected.emit(desync_time)
		is_synced = false
	else:
		beat_offset = desync_time * 0.5  # Gradual correction for small desyncs
		is_synced = true
		beat_synced.emit()

	last_server_beat = server_bar * 32 + server_position
	last_server_beat_time = server_beat_time


func _apply_offset_correction(correction: float) -> void:
	# This would ideally adjust the sequencer timing
	# For now, we track the offset and systems can query it
	beat_offset -= correction


func _get_current_bpm() -> float:
	var deck := Sequencer.get_deck(sequencer_deck)
	if deck and deck.current_pattern:
		return deck.current_pattern.bpm
	return 120.0


## Get current beat offset from server
func get_beat_offset() -> float:
	return beat_offset


## Get synchronized beat time
func get_synced_beat_time() -> float:
	return Sequencer.get_current_beat_time(sequencer_deck) + beat_offset


## Check if beat is synchronized
func is_beat_synced() -> bool:
	return is_synced or multiplayer.is_server()


## Force immediate sync
func force_sync() -> void:
	if not multiplayer.is_server():
		_request_beat_sync.rpc_id(1)
