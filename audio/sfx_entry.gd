## SFXEntry - Individual sound effect configuration
@tool
class_name SFXEntry
extends Resource


@export var sfx_name: String = ""
@export var category: AudioTypes.SFXCategory = AudioTypes.SFXCategory.UI

## Audio
@export var stream: AudioStream
@export var variations: Array[AudioStream] = []

## Playback settings
@export_range(-80.0, 6.0) var volume_db: float = 0.0
@export_range(0.5, 2.0) var pitch_scale: float = 1.0
@export_range(0.0, 0.5) var pitch_variance: float = 0.0
@export_range(0.0, 0.5) var volume_variance: float = 0.0

## Beat sync
@export var quantize_to_beat: bool = false
@export var beat_offset: float = 0.0  ## Offset from beat in seconds

## Priority (higher = more important, won't be interrupted)
@export_range(0, 10) var priority: int = 5

## Cooldown to prevent spam
@export var min_interval: float = 0.0


## Get random stream (main or variation)
func get_random_stream() -> AudioStream:
	if variations.is_empty():
		return stream

	var all_streams: Array[AudioStream] = [stream]
	all_streams.append_array(variations)
	return all_streams[randi() % all_streams.size()]


## Get randomized pitch
func get_randomized_pitch() -> float:
	return pitch_scale + randf_range(-pitch_variance, pitch_variance)


## Get randomized volume
func get_randomized_volume() -> float:
	return volume_db + randf_range(-volume_variance, volume_variance)


## Create BeatSyncedSFX from this entry
func to_beat_synced_sfx() -> AudioTypes.BeatSyncedSFX:
	var sfx := AudioTypes.BeatSyncedSFX.new()
	sfx.stream = get_random_stream()
	sfx.category = category
	sfx.volume_db = get_randomized_volume()
	sfx.pitch_variance = pitch_variance
	sfx.quantize_to_beat = quantize_to_beat
	sfx.priority = priority
	return sfx
