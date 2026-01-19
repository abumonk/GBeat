## MusicTrack - Collection of layers forming a complete track
@tool
class_name MusicTrack
extends Resource


@export var track_name: String = ""
@export var bpm: float = 120.0
@export var time_signature_numerator: int = 4
@export var time_signature_denominator: int = 4

## Layers
@export var layers: Array[MusicLayer] = []

## Associated pattern for sequencer sync
@export var sequencer_pattern: Pattern

## Metadata
@export var artist: String = ""
@export var duration_bars: int = 4


func get_layer(layer_type: AudioTypes.LayerType) -> MusicLayer:
	for layer in layers:
		if layer.layer_type == layer_type:
			return layer
	return null


func get_layers_by_type(layer_type: AudioTypes.LayerType) -> Array[MusicLayer]:
	var result: Array[MusicLayer] = []
	for layer in layers:
		if layer.layer_type == layer_type:
			result.append(layer)
	return result


func get_beat_duration() -> float:
	return 60.0 / bpm


func get_bar_duration() -> float:
	return get_beat_duration() * time_signature_numerator
