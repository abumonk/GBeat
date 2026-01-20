## BeatAudioEvent - Configuration for a beat-synced audio event
@tool
class_name BeatAudioEvent
extends Resource

## The audio stream to play
@export var sound: AudioStream

## Whether to sync playback to beat boundaries
@export var sync_to_beat: bool = true

## Pitch variation range (+/- this value)
@export_range(0.0, 0.5) var pitch_variation: float = 0.0

## Volume multiplier (1.0 = full volume)
@export_range(0.0, 2.0) var volume_multiplier: float = 1.0

## Priority for player stealing (higher = more important)
@export_range(0, 10) var priority: int = 0

## Optional: delay before playing (in beats)
@export_range(0.0, 4.0) var beat_delay: float = 0.0
