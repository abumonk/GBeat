## MusicLayer - Resource defining a music layer
@tool
class_name MusicLayer
extends Resource


@export var layer_name: String = ""
@export var layer_type: AudioTypes.LayerType = AudioTypes.LayerType.BASE
@export var stream: AudioStream

## Volume settings
@export_range(-80.0, 6.0) var base_volume_db: float = 0.0
@export_range(-80.0, 6.0) var min_volume_db: float = -80.0
@export_range(-80.0, 6.0) var max_volume_db: float = 6.0

## Crossfade settings
@export var fade_in_time: float = 0.5
@export var fade_out_time: float = 0.5
@export var crossfade_type: AudioTypes.CrossfadeType = AudioTypes.CrossfadeType.EQUAL_POWER

## Activation conditions
@export var auto_start: bool = false
@export var loop: bool = true

## Beat sync
@export var sync_to_beat: bool = true
@export var start_on_bar: bool = true  ## Start at beginning of bar


func get_duration() -> float:
	if stream:
		return stream.get_length()
	return 0.0
