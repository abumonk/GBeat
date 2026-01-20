## BeatReactiveAudioComponent - Plays sound events in response to gameplay with beat synchronization
class_name BeatReactiveAudioComponent
extends Node

signal event_played(event_name: String)
signal event_queued(event_name: String)

## Audio event library - maps event names to audio configurations
@export var audio_events: Dictionary = {}  # event_name: String -> BeatAudioEvent

## Playback settings
@export var max_simultaneous_sounds: int = 8
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Audio players pool
var _players: Array[AudioStreamPlayer] = []

## Queued events waiting for beat sync
var _queued_events: Array[BeatAudioEvent] = []
var _queued_event_names: Array[String] = []

## Tick subscription
var _tick_handle: int = -1


func _ready() -> void:
	# Create player pool
	for i in range(max_simultaneous_sounds):
		var player := AudioStreamPlayer.new()
		player.bus = AudioTypes.SFX_BUS
		add_child(player)
		_players.append(player)

	# Subscribe to tick for beat-synced playback
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _on_tick(event: SequencerEvent) -> void:
	# Play queued beat-synced events on tick
	for i in range(_queued_events.size()):
		var audio_event := _queued_events[i]
		var event_name := _queued_event_names[i]
		_play_event_now(audio_event)
		event_played.emit(event_name)

	_queued_events.clear()
	_queued_event_names.clear()


## Play an event by name
func play_event(event_name: String) -> void:
	var audio_event := audio_events.get(event_name) as BeatAudioEvent
	if not audio_event:
		push_warning("BeatReactiveAudioComponent: Unknown event '%s'" % event_name)
		return

	if audio_event.sync_to_beat:
		_queued_events.append(audio_event)
		_queued_event_names.append(event_name)
		event_queued.emit(event_name)
	else:
		_play_event_now(audio_event)
		event_played.emit(event_name)


## Play an audio event directly
func play_audio_event(audio_event: BeatAudioEvent, event_name: String = "") -> void:
	if audio_event.sync_to_beat:
		_queued_events.append(audio_event)
		_queued_event_names.append(event_name)
		event_queued.emit(event_name)
	else:
		_play_event_now(audio_event)
		event_played.emit(event_name)


## Play an audio event immediately (bypass beat sync)
func play_event_immediate(event_name: String) -> void:
	var audio_event := audio_events.get(event_name) as BeatAudioEvent
	if not audio_event:
		push_warning("BeatReactiveAudioComponent: Unknown event '%s'" % event_name)
		return

	_play_event_now(audio_event)
	event_played.emit(event_name)


## Internal: play the event now
func _play_event_now(audio_event: BeatAudioEvent) -> void:
	var player := _get_available_player(audio_event.priority)
	if not player:
		return

	player.stream = audio_event.sound

	# Apply pitch variation
	if audio_event.pitch_variation > 0:
		player.pitch_scale = 1.0 + randf_range(-audio_event.pitch_variation, audio_event.pitch_variation)
	else:
		player.pitch_scale = 1.0

	# Apply volume
	player.volume_db = linear_to_db(audio_event.volume_multiplier)

	player.play()


## Get an available player from the pool
func _get_available_player(priority: int) -> AudioStreamPlayer:
	# First try to find an idle player
	for player in _players:
		if not player.playing:
			return player

	# All busy - could implement priority stealing here
	# For now, just return the first player
	return _players[0] if _players.size() > 0 else null


## Stop all playing sounds
func stop_all() -> void:
	for player in _players:
		player.stop()
	_queued_events.clear()
	_queued_event_names.clear()


## Register an audio event
func register_event(event_name: String, audio_event: BeatAudioEvent) -> void:
	audio_events[event_name] = audio_event


## Create and register an event from parameters
func register_event_simple(event_name: String, sound: AudioStream, sync_to_beat: bool = true, volume: float = 1.0, pitch_variation: float = 0.0) -> void:
	var audio_event := BeatAudioEvent.new()
	audio_event.sound = sound
	audio_event.sync_to_beat = sync_to_beat
	audio_event.volume_multiplier = volume
	audio_event.pitch_variation = pitch_variation
	audio_events[event_name] = audio_event


## Check if an event is registered
func has_event(event_name: String) -> bool:
	return audio_events.has(event_name)


## Get number of queued events
func get_queued_count() -> int:
	return _queued_events.size()


## Clear all queued events without playing
func clear_queued() -> void:
	_queued_events.clear()
	_queued_event_names.clear()
