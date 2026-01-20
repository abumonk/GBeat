## Test cases for Audio Types
extends TestBase


func test_layer_types() -> bool:
	var types := [
		AudioTypes.LayerType.BASE,
		AudioTypes.LayerType.PERCUSSION,
		AudioTypes.LayerType.MELODY,
		AudioTypes.LayerType.BASS,
		AudioTypes.LayerType.COMBAT,
		AudioTypes.LayerType.AMBIENT,
		AudioTypes.LayerType.STINGER,
	]

	if not assert_equal(types.size(), 7, "Should have 7 layer types"):
		return false

	return true


func test_sfx_categories() -> bool:
	var categories := [
		AudioTypes.SFXCategory.UI,
		AudioTypes.SFXCategory.COMBAT_PLAYER,
		AudioTypes.SFXCategory.COMBAT_ENEMY,
		AudioTypes.SFXCategory.MOVEMENT,
		AudioTypes.SFXCategory.ENVIRONMENT,
		AudioTypes.SFXCategory.FEEDBACK,
	]

	if not assert_equal(categories.size(), 6, "Should have 6 SFX categories"):
		return false

	return true


func test_crossfade_types() -> bool:
	var types := [
		AudioTypes.CrossfadeType.LINEAR,
		AudioTypes.CrossfadeType.EQUAL_POWER,
		AudioTypes.CrossfadeType.S_CURVE,
	]

	if not assert_equal(types.size(), 3, "Should have 3 crossfade types"):
		return false

	return true


func test_audio_layer_state() -> bool:
	var state := AudioTypes.AudioLayerState.new()

	if not assert_equal(state.layer_type, AudioTypes.LayerType.BASE, "Default should be BASE"):
		return false
	if not assert_approximately(state.volume_db, 0.0):
		return false
	if not assert_false(state.is_active, "Should start inactive"):
		return false

	state.is_active = true
	state.volume_db = -6.0

	if not assert_true(state.is_active):
		return false
	if not assert_approximately(state.volume_db, -6.0):
		return false

	return true


func test_beat_synced_sfx() -> bool:
	var sfx := AudioTypes.BeatSyncedSFX.new()

	sfx.category = AudioTypes.SFXCategory.COMBAT_PLAYER
	sfx.volume_db = -3.0
	sfx.pitch_variance = 0.1
	sfx.quantize_to_beat = true
	sfx.priority = 5

	if not assert_equal(sfx.category, AudioTypes.SFXCategory.COMBAT_PLAYER):
		return false
	if not assert_approximately(sfx.volume_db, -3.0):
		return false
	if not assert_true(sfx.quantize_to_beat):
		return false

	return true


func test_audio_bus_constants() -> bool:
	if not assert_equal(AudioTypes.MASTER_BUS, "Master"):
		return false
	if not assert_equal(AudioTypes.MUSIC_BUS, "Music"):
		return false
	if not assert_equal(AudioTypes.SFX_BUS, "SFX"):
		return false
	if not assert_equal(AudioTypes.UI_BUS, "UI"):
		return false

	return true


func test_default_fade_time() -> bool:
	if not assert_approximately(AudioTypes.DEFAULT_FADE_TIME, 0.5):
		return false

	return true


func test_beat_quantize_threshold() -> bool:
	if not assert_approximately(AudioTypes.BEAT_QUANTIZE_THRESHOLD, 0.1):
		return false

	return true


func test_music_state_enum() -> bool:
	var states := [
		AudioTypes.MusicState.EXPLORATION,
		AudioTypes.MusicState.COMBAT,
		AudioTypes.MusicState.COMBAT_INTENSE,
		AudioTypes.MusicState.BOSS,
		AudioTypes.MusicState.VICTORY,
		AudioTypes.MusicState.DEFEAT,
	]

	if not assert_equal(states.size(), 6, "Should have 6 music states"):
		return false

	return true


func test_frequency_band_enum() -> bool:
	var bands := [
		AudioTypes.FrequencyBand.SUB_BASS,
		AudioTypes.FrequencyBand.BASS,
		AudioTypes.FrequencyBand.LOW_MID,
		AudioTypes.FrequencyBand.MID,
		AudioTypes.FrequencyBand.HIGH_MID,
		AudioTypes.FrequencyBand.PRESENCE,
		AudioTypes.FrequencyBand.BRILLIANCE,
	]

	if not assert_equal(bands.size(), 7, "Should have 7 frequency bands"):
		return false

	return true
