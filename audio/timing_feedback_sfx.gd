## TimingFeedbackSFX - Plays feedback sounds based on timing rating
class_name TimingFeedbackSFX
extends Node


@export var perfect_sound: AudioStream
@export var great_sound: AudioStream
@export var good_sound: AudioStream
@export var early_sound: AudioStream
@export var late_sound: AudioStream
@export var miss_sound: AudioStream

@export var combo_milestone_sound: AudioStream
@export var combo_break_sound: AudioStream

@export_range(-80.0, 6.0) var volume_db: float = 0.0

var _audio_player: AudioStreamPlayer


func _ready() -> void:
	_audio_player = AudioStreamPlayer.new()
	_audio_player.bus = AudioTypes.SFX_BUS
	add_child(_audio_player)


func play_timing_feedback(rating: CombatTypes.TimingRating) -> void:
	var stream: AudioStream = null

	match rating:
		CombatTypes.TimingRating.PERFECT:
			stream = perfect_sound
		CombatTypes.TimingRating.GREAT:
			stream = great_sound
		CombatTypes.TimingRating.GOOD:
			stream = good_sound
		CombatTypes.TimingRating.EARLY:
			stream = early_sound
		CombatTypes.TimingRating.LATE:
			stream = late_sound
		CombatTypes.TimingRating.MISS:
			stream = miss_sound

	if stream:
		_play_sound(stream)


func play_combo_milestone(combo_count: int) -> void:
	if combo_milestone_sound:
		# Pitch up slightly for higher combos
		var pitch := 1.0 + (combo_count / 100.0)
		_play_sound(combo_milestone_sound, pitch)


func play_combo_break() -> void:
	if combo_break_sound:
		_play_sound(combo_break_sound)


func _play_sound(stream: AudioStream, pitch: float = 1.0) -> void:
	_audio_player.stream = stream
	_audio_player.volume_db = volume_db
	_audio_player.pitch_scale = pitch
	_audio_player.play()
