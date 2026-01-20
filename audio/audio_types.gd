## AudioTypes - Enums and data classes for audio system
class_name AudioTypes
extends RefCounted


enum LayerType {
	BASE,       ## Always playing base track
	PERCUSSION, ## Drum/beat layer
	MELODY,     ## Melodic elements
	BASS,       ## Bass layer
	COMBAT,     ## Combat intensity layer
	AMBIENT,    ## Ambient/atmospheric
	STINGER,    ## One-shot musical phrases
}


enum SFXCategory {
	UI,
	COMBAT_PLAYER,
	COMBAT_ENEMY,
	MOVEMENT,
	ENVIRONMENT,
	FEEDBACK,    ## Timing feedback sounds
}


## Music state for dynamic mixing
enum MusicState {
	EXPLORATION,
	COMBAT,
	COMBAT_INTENSE,
	BOSS,
	VICTORY,
	DEFEAT
}


## Frequency bands for spectrum analysis
enum FrequencyBand {
	SUB_BASS,    ## 20-60 Hz
	BASS,        ## 60-250 Hz
	LOW_MID,     ## 250-500 Hz
	MID,         ## 500-2000 Hz
	HIGH_MID,    ## 2000-4000 Hz
	PRESENCE,    ## 4000-6000 Hz
	BRILLIANCE   ## 6000-20000 Hz
}


enum CrossfadeType {
	LINEAR,
	EQUAL_POWER,
	S_CURVE,
}


class AudioLayerState:
	var layer_type: LayerType = LayerType.BASE
	var volume_db: float = 0.0
	var target_volume_db: float = 0.0
	var is_active: bool = false
	var stream_player: AudioStreamPlayer = null
	var fade_tween: Tween = null


class BeatSyncedSFX:
	var stream: AudioStream
	var category: SFXCategory
	var volume_db: float = 0.0
	var pitch_variance: float = 0.0
	var quantize_to_beat: bool = true
	var priority: int = 0


## Constants for audio configuration
const MASTER_BUS := "Master"
const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"
const UI_BUS := "UI"

const DEFAULT_FADE_TIME := 0.5
const BEAT_QUANTIZE_THRESHOLD := 0.1  ## Max time offset for beat quantization
