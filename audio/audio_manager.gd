## AudioManager - Manages music playback with layered tracks
class_name AudioManager
extends Node


signal layer_activated(layer_type: AudioTypes.LayerType)
signal layer_deactivated(layer_type: AudioTypes.LayerType)
signal track_changed(track: MusicTrack)
signal beat_audio_pulse()


## Configuration
@export var initial_track: MusicTrack
@export var master_volume_db: float = 0.0
@export var music_volume_db: float = 0.0
@export var sfx_volume_db: float = 0.0

## State
var current_track: MusicTrack = null
var _layer_states: Dictionary = {}  ## LayerType -> AudioLayerState
var _layer_players: Array[AudioStreamPlayer] = []
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_size: int = 16

## Sequencer sync
var _sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
var _tick_handle: int = -1


func _ready() -> void:
	_setup_audio_buses()
	_create_sfx_pool()

	# Subscribe to sequencer for beat sync
	_tick_handle = Sequencer.subscribe_to_tick(_sequencer_deck, _on_sequencer_tick)

	if initial_track:
		load_track(initial_track)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_audio_buses() -> void:
	# Create audio buses if they don't exist
	_ensure_bus_exists(AudioTypes.MUSIC_BUS, AudioTypes.MASTER_BUS)
	_ensure_bus_exists(AudioTypes.SFX_BUS, AudioTypes.MASTER_BUS)
	_ensure_bus_exists(AudioTypes.UI_BUS, AudioTypes.MASTER_BUS)


func _ensure_bus_exists(bus_name: String, parent_bus: String) -> void:
	if AudioServer.get_bus_index(bus_name) == -1:
		var idx := AudioServer.bus_count
		AudioServer.add_bus(idx)
		AudioServer.set_bus_name(idx, bus_name)
		var parent_idx := AudioServer.get_bus_index(parent_bus)
		if parent_idx >= 0:
			AudioServer.set_bus_send(idx, parent_bus)


func _create_sfx_pool() -> void:
	for i in range(_sfx_pool_size):
		var player := AudioStreamPlayer.new()
		player.bus = AudioTypes.SFX_BUS
		add_child(player)
		_sfx_pool.append(player)


## === Track Management ===

func load_track(track: MusicTrack) -> void:
	if current_track:
		stop_all_layers()

	current_track = track
	_layer_states.clear()

	# Clear old layer players
	for player in _layer_players:
		player.queue_free()
	_layer_players.clear()

	# Create players for each layer
	for layer in track.layers:
		var state := AudioTypes.AudioLayerState.new()
		state.layer_type = layer.layer_type
		state.volume_db = layer.min_volume_db
		state.target_volume_db = layer.min_volume_db
		state.is_active = false

		var player := AudioStreamPlayer.new()
		player.stream = layer.stream
		player.bus = AudioTypes.MUSIC_BUS
		player.volume_db = state.volume_db
		add_child(player)

		state.stream_player = player
		_layer_players.append(player)
		_layer_states[layer.layer_type] = state

		# Auto-start layers
		if layer.auto_start:
			activate_layer(layer.layer_type)

	track_changed.emit(track)


func play_all() -> void:
	for player in _layer_players:
		if not player.playing:
			player.play()


func stop_all_layers() -> void:
	for state in _layer_states.values():
		if state.stream_player:
			state.stream_player.stop()
			state.is_active = false


func pause_all() -> void:
	for player in _layer_players:
		player.stream_paused = true


func resume_all() -> void:
	for player in _layer_players:
		player.stream_paused = false


## === Layer Control ===

func activate_layer(layer_type: AudioTypes.LayerType, fade_time: float = -1.0) -> void:
	if not _layer_states.has(layer_type):
		return

	var state: AudioTypes.AudioLayerState = _layer_states[layer_type]
	if state.is_active:
		return

	state.is_active = true

	var layer := _get_layer_config(layer_type)
	if not layer:
		return

	var actual_fade := fade_time if fade_time >= 0 else layer.fade_in_time
	state.target_volume_db = layer.base_volume_db

	_fade_layer(state, layer.base_volume_db, actual_fade, layer.crossfade_type)

	# Start playback if not playing
	if not state.stream_player.playing:
		state.stream_player.play()

	layer_activated.emit(layer_type)


func deactivate_layer(layer_type: AudioTypes.LayerType, fade_time: float = -1.0) -> void:
	if not _layer_states.has(layer_type):
		return

	var state: AudioTypes.AudioLayerState = _layer_states[layer_type]
	if not state.is_active:
		return

	state.is_active = false

	var layer := _get_layer_config(layer_type)
	if not layer:
		return

	var actual_fade := fade_time if fade_time >= 0 else layer.fade_out_time
	state.target_volume_db = layer.min_volume_db

	_fade_layer(state, layer.min_volume_db, actual_fade, layer.crossfade_type)

	layer_deactivated.emit(layer_type)


func set_layer_volume(layer_type: AudioTypes.LayerType, volume_db: float) -> void:
	if not _layer_states.has(layer_type):
		return

	var state: AudioTypes.AudioLayerState = _layer_states[layer_type]
	var layer := _get_layer_config(layer_type)
	if layer:
		volume_db = clamp(volume_db, layer.min_volume_db, layer.max_volume_db)

	state.volume_db = volume_db
	state.target_volume_db = volume_db
	if state.stream_player:
		state.stream_player.volume_db = volume_db


func is_layer_active(layer_type: AudioTypes.LayerType) -> bool:
	if _layer_states.has(layer_type):
		return _layer_states[layer_type].is_active
	return false


func _get_layer_config(layer_type: AudioTypes.LayerType) -> MusicLayer:
	if current_track:
		return current_track.get_layer(layer_type)
	return null


func _fade_layer(state: AudioTypes.AudioLayerState, target_db: float, duration: float, fade_type: AudioTypes.CrossfadeType) -> void:
	# Cancel existing tween
	if state.fade_tween and state.fade_tween.is_valid():
		state.fade_tween.kill()

	if duration <= 0:
		state.volume_db = target_db
		if state.stream_player:
			state.stream_player.volume_db = target_db
		return

	state.fade_tween = create_tween()

	match fade_type:
		AudioTypes.CrossfadeType.LINEAR:
			state.fade_tween.tween_property(state.stream_player, "volume_db", target_db, duration)
		AudioTypes.CrossfadeType.EQUAL_POWER:
			# Equal power crossfade approximation
			state.fade_tween.tween_property(state.stream_player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT)
		AudioTypes.CrossfadeType.S_CURVE:
			state.fade_tween.tween_property(state.stream_player, "volume_db", target_db, duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	state.fade_tween.tween_callback(func(): state.volume_db = target_db)


## === SFX Playback ===

func play_sfx(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := _get_available_sfx_player()
	if player:
		player.stream = stream
		player.volume_db = volume_db + sfx_volume_db
		player.pitch_scale = pitch_scale
		player.play()


func play_sfx_at_position(stream: AudioStream, position: Vector3, volume_db: float = 0.0) -> void:
	# For 3D positional audio, would need AudioStreamPlayer3D
	# For now, just play normally
	play_sfx(stream, volume_db)


func play_beat_synced_sfx(sfx: AudioTypes.BeatSyncedSFX) -> void:
	if sfx.quantize_to_beat:
		# Queue to play on next beat
		_queue_sfx_for_beat(sfx)
	else:
		var pitch := 1.0 + randf_range(-sfx.pitch_variance, sfx.pitch_variance)
		play_sfx(sfx.stream, sfx.volume_db, pitch)


var _queued_sfx: Array[AudioTypes.BeatSyncedSFX] = []

func _queue_sfx_for_beat(sfx: AudioTypes.BeatSyncedSFX) -> void:
	_queued_sfx.append(sfx)


func _get_available_sfx_player() -> AudioStreamPlayer:
	for player in _sfx_pool:
		if not player.playing:
			return player

	# All busy, return first (will interrupt)
	return _sfx_pool[0] if _sfx_pool.size() > 0 else null


## === Sequencer Sync ===

func _on_sequencer_tick(event: SequencerEvent) -> void:
	# Play queued beat-synced SFX
	for sfx in _queued_sfx:
		var pitch := 1.0 + randf_range(-sfx.pitch_variance, sfx.pitch_variance)
		play_sfx(sfx.stream, sfx.volume_db, pitch)
	_queued_sfx.clear()

	# Emit beat pulse for visual sync
	if event.quant.type == Quant.Type.KICK or event.quant.type == Quant.Type.TICK:
		beat_audio_pulse.emit()


## === Volume Control ===

func set_master_volume(volume_db: float) -> void:
	master_volume_db = volume_db
	var idx := AudioServer.get_bus_index(AudioTypes.MASTER_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)


func set_music_volume(volume_db: float) -> void:
	music_volume_db = volume_db
	var idx := AudioServer.get_bus_index(AudioTypes.MUSIC_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)


func set_sfx_volume(volume_db: float) -> void:
	sfx_volume_db = volume_db
	var idx := AudioServer.get_bus_index(AudioTypes.SFX_BUS)
	if idx >= 0:
		AudioServer.set_bus_volume_db(idx, volume_db)


## === Queries ===

func get_playback_position() -> float:
	if _layer_players.size() > 0 and _layer_players[0].playing:
		return _layer_players[0].get_playback_position()
	return 0.0


func get_current_track() -> MusicTrack:
	return current_track


func get_bpm() -> float:
	if current_track:
		return current_track.bpm
	return 120.0
