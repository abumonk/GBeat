## BeatQuartzBridge - Bridges beat detection with sequencer timing
class_name BeatQuartzBridge
extends Node

signal on_beat_phase_update(phase: float)
signal timing_grade_calculated(grade: CombatTypes.TimingRating)
signal beat_synced()

## Beat detection component (optional - can work from sequencer only)
@export var beat_detection: Node  # BeatDetector or BeatDetectionComponent

## Sequencer settings
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Timing tolerance for "on beat" detection
@export var on_beat_tolerance: float = 0.1  # seconds

## Auto sync options
@export var auto_sync_bpm: bool = false
@export var bpm_sync_threshold: float = 5.0  # BPM difference to trigger sync

## State
var current_bpm: float = 120.0
var time_to_next_beat: float = 0.0
var time_since_last_beat: float = 0.0
var beat_phase: float = 0.0  # 0-1 normalized (0 = on beat, 0.5 = off beat)
var is_on_beat: bool = false

## Beat timing history for smoothing
var _beat_duration: float = 0.5
var _tick_handle: int = -1


func _ready() -> void:
	# Calculate initial beat duration
	_beat_duration = 60.0 / current_bpm

	# Subscribe to sequencer for accurate timing
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_sequencer_tick)

	# Connect to beat detection if available
	if beat_detection and beat_detection.has_signal("beat_detected"):
		beat_detection.beat_detected.connect(_on_beat_detected)
	if beat_detection and beat_detection.has_signal("bpm_changed"):
		beat_detection.bpm_changed.connect(_on_bpm_changed)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	_update_beat_phase(delta)


func _update_beat_phase(delta: float) -> void:
	time_since_last_beat += delta

	# Update beat phase
	beat_phase = fmod(time_since_last_beat, _beat_duration) / _beat_duration
	time_to_next_beat = _beat_duration - fmod(time_since_last_beat, _beat_duration)

	# Determine if on beat
	is_on_beat = time_to_next_beat < on_beat_tolerance or time_since_last_beat < on_beat_tolerance

	on_beat_phase_update.emit(beat_phase)


func _on_sequencer_tick(event: SequencerEvent) -> void:
	# Reset timing on sequencer tick
	if event.quant.type == Quant.Type.TICK:
		time_since_last_beat = 0.0
		is_on_beat = true
		beat_synced.emit()


func _on_beat_detected(intensity: float) -> void:
	# When beat detection finds a beat, we can use it to refine timing
	# But sequencer is the source of truth
	pass


func _on_bpm_changed(new_bpm: float) -> void:
	if auto_sync_bpm and abs(new_bpm - current_bpm) > bpm_sync_threshold:
		sync_to_bpm(new_bpm)


## Sync to a specific BPM
func sync_to_bpm(bpm: float) -> void:
	current_bpm = bpm
	_beat_duration = 60.0 / bpm

	# Update sequencer deck's pattern BPM
	var deck := Sequencer.get_deck(sequencer_deck)
	if deck and deck.current_pattern:
		deck.current_pattern.bpm = bpm


## Connect to a beat detection component
func connect_to_detection(detection: Node) -> void:
	# Disconnect from old
	if beat_detection:
		if beat_detection.has_signal("beat_detected") and beat_detection.beat_detected.is_connected(_on_beat_detected):
			beat_detection.beat_detected.disconnect(_on_beat_detected)
		if beat_detection.has_signal("bpm_changed") and beat_detection.bpm_changed.is_connected(_on_bpm_changed):
			beat_detection.bpm_changed.disconnect(_on_bpm_changed)

	# Connect to new
	beat_detection = detection
	if beat_detection:
		if beat_detection.has_signal("beat_detected"):
			beat_detection.beat_detected.connect(_on_beat_detected)
		if beat_detection.has_signal("bpm_changed"):
			beat_detection.bpm_changed.connect(_on_bpm_changed)


## Set BPM manually
func set_bpm(bpm: float) -> void:
	current_bpm = bpm
	_beat_duration = 60.0 / bpm


## Get timing grade for the current moment
func get_timing_grade() -> CombatTypes.TimingRating:
	# Distance from nearest beat
	var distance := min(time_since_last_beat, time_to_next_beat)
	var normalized := distance / (_beat_duration / 2.0)

	# Convert to quality (1 = perfect, 0 = worst)
	var quality := 1.0 - normalized

	var grade: CombatTypes.TimingRating
	if quality >= 0.95:
		grade = CombatTypes.TimingRating.PERFECT
	elif quality >= 0.85:
		grade = CombatTypes.TimingRating.GREAT
	elif quality >= 0.65:
		grade = CombatTypes.TimingRating.GOOD
	elif time_since_last_beat < time_to_next_beat:
		grade = CombatTypes.TimingRating.LATE
	else:
		grade = CombatTypes.TimingRating.EARLY

	timing_grade_calculated.emit(grade)
	return grade


## Get beat timing quality as a 0-1 value (1 = perfect)
func get_timing_quality() -> float:
	var distance := min(time_since_last_beat, time_to_next_beat)
	return 1.0 - clamp(distance / (_beat_duration / 2.0), 0.0, 1.0)


## Get beat phase (0 = on beat, 0.5 = off beat)
func get_beat_phase() -> float:
	return beat_phase


## Get time remaining until next beat
func get_time_to_next_beat() -> float:
	return time_to_next_beat


## Get time since last beat
func get_time_since_last_beat() -> float:
	return time_since_last_beat


## Check if currently on beat
func is_currently_on_beat() -> bool:
	return is_on_beat


## Get current BPM
func get_bpm() -> float:
	return current_bpm


## Get beat duration in seconds
func get_beat_duration() -> float:
	return _beat_duration
