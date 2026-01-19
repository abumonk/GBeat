## Deck - Manages playback of a Pattern with precise timing
class_name Deck
extends Node

signal quant_event(event: SequencerEvent)
signal pattern_changed(old_pattern: Pattern, new_pattern: Pattern)
signal state_changed(old_state: State, new_state: State)

enum State { IDLE, READY, PLAYING, PAUSED, QUEUED_TRANSITION }

var state: State = State.IDLE
var current_pattern: Pattern = null
var next_pattern: Pattern = null
var cursor: QuantCursor = QuantCursor.new()

var _clock_accumulator: float = 0.0
var _quant_duration: float = 0.0  ## Seconds per quant

var audio_player: AudioStreamPlayer


func _ready() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Music"
	add_child(audio_player)


func _process(delta: float) -> void:
	if state != State.PLAYING:
		return

	_clock_accumulator += delta

	while _clock_accumulator >= _quant_duration and _quant_duration > 0:
		_clock_accumulator -= _quant_duration
		_process_quant_tick()


func _process_quant_tick() -> void:
	_emit_quant_events()
	_advance_cursor()


func _emit_quant_events() -> void:
	if not current_pattern:
		return

	# Always emit a TICK event
	var tick_quant := Quant.new(Quant.Type.TICK, cursor.position, 1.0)
	var tick_event := SequencerEvent.create(self, current_pattern, tick_quant, cursor)
	quant_event.emit(tick_event)

	# Find all quants at current position
	var quants_at_position := current_pattern.get_quants_at_position(cursor.position)

	for quant in quants_at_position:
		var event := SequencerEvent.create(self, current_pattern, quant, cursor)
		quant_event.emit(event)


func _advance_cursor() -> void:
	var bar_count := current_pattern.get_bar_count() if current_pattern else 1

	cursor.position += 1
	cursor.step_count += 1

	if cursor.position >= 32:
		cursor.position = 0
		cursor.bar_index += 1

		# Check for pattern transition at bar boundary
		if state == State.QUEUED_TRANSITION and next_pattern:
			_transition_to_next_pattern()

		if cursor.bar_index >= bar_count:
			cursor.bar_index = 0
			cursor.loop_count += 1


func _transition_to_next_pattern() -> void:
	var old := current_pattern
	current_pattern = next_pattern
	next_pattern = null
	cursor.reset()
	_update_quant_duration()
	state = State.PLAYING

	# Update audio
	if current_pattern.sound:
		audio_player.stream = current_pattern.sound
		audio_player.play()

	pattern_changed.emit(old, current_pattern)


func _update_quant_duration() -> void:
	if current_pattern and current_pattern.bpm > 0:
		# 32 quants per bar, at given BPM
		# beats_per_second = BPM / 60
		# quants_per_second = beats_per_second * 8 (8 quants per beat = 32nd notes)
		var beats_per_second := current_pattern.bpm / 60.0
		var quants_per_second := beats_per_second * 8.0
		_quant_duration = 1.0 / quants_per_second
	else:
		_quant_duration = 0.0


## === Public API ===

func set_next_pattern(pattern: Pattern) -> void:
	if pattern:
		pattern.initialize()

	if state == State.IDLE:
		current_pattern = pattern
		_update_quant_duration()
		_change_state(State.READY)
	elif state == State.PLAYING:
		next_pattern = pattern
		_change_state(State.QUEUED_TRANSITION)
	else:
		next_pattern = pattern


func start() -> void:
	if state == State.IDLE:
		push_error("Cannot start deck without pattern")
		return

	cursor.reset()
	_clock_accumulator = 0.0

	if current_pattern and current_pattern.sound:
		audio_player.stream = current_pattern.sound
		audio_player.play()

	_change_state(State.PLAYING)


func stop() -> void:
	audio_player.stop()
	cursor.reset()
	_clock_accumulator = 0.0
	current_pattern = null
	next_pattern = null
	_change_state(State.IDLE)


func pause() -> void:
	if state == State.PLAYING:
		audio_player.stream_paused = true
		_change_state(State.PAUSED)


func resume() -> void:
	if state == State.PAUSED:
		audio_player.stream_paused = false
		_change_state(State.PLAYING)


func _change_state(new_state: State) -> void:
	var old_state := state
	state = new_state
	state_changed.emit(old_state, new_state)


## === Query API ===

func get_current_bpm() -> float:
	return current_pattern.bpm if current_pattern else 0.0


func get_current_position() -> int:
	return cursor.position


func get_current_bar() -> int:
	return cursor.bar_index


func get_loop_count() -> int:
	return cursor.loop_count


func get_quant_duration() -> float:
	return _quant_duration


func get_beat_duration() -> float:
	return _quant_duration * 8.0  ## 8 quants per beat


func get_bar_duration() -> float:
	return _quant_duration * 32.0  ## 32 quants per bar


func get_time_to_next_position(target_position: int) -> float:
	var current := cursor.position
	var distance := target_position - current
	if distance <= 0:
		distance += 32
	return distance * _quant_duration


func get_time_to_next_beat() -> float:
	var current := cursor.position
	var next_beat := ((current / 8) + 1) * 8
	if next_beat >= 32:
		next_beat = 0
	return get_time_to_next_position(next_beat)


func is_playing() -> bool:
	return state == State.PLAYING


func is_paused() -> bool:
	return state == State.PAUSED


func has_pattern() -> bool:
	return current_pattern != null
