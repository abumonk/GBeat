## Test cases for Save Types
extends TestBase


func test_save_slot_creation() -> bool:
	var slot := SaveTypes.SaveSlot.new()

	if not assert_true(slot.is_empty, "New slot should be empty"):
		return false
	if not assert_equal(slot.slot_id, 0, "Default slot ID should be 0"):
		return false

	return true


func test_save_slot_serialization() -> bool:
	var slot := SaveTypes.SaveSlot.new()
	slot.slot_id = 1
	slot.player_name = "TestPlayer"
	slot.playtime_seconds = 3600.0
	slot.is_empty = false

	var dict := slot.to_dict()

	if not assert_equal(dict["slot_id"], 1):
		return false
	if not assert_equal(dict["player_name"], "TestPlayer"):
		return false
	if not assert_approximately(dict["playtime_seconds"], 3600.0):
		return false

	return true


func test_save_slot_deserialization() -> bool:
	var dict := {
		"slot_id": 2,
		"player_name": "LoadedPlayer",
		"playtime_seconds": 7200.0,
		"is_empty": false,
	}

	var slot := SaveTypes.SaveSlot.from_dict(dict)

	if not assert_equal(slot.slot_id, 2):
		return false
	if not assert_equal(slot.player_name, "LoadedPlayer"):
		return false
	if not assert_false(slot.is_empty):
		return false

	return true


func test_player_save_data() -> bool:
	var player := SaveTypes.PlayerSaveData.new()
	player.max_health = 150.0
	player.current_health = 100.0
	player.level = 5
	player.experience = 1000

	var dict := player.to_dict()
	var loaded := SaveTypes.PlayerSaveData.from_dict(dict)

	if not assert_approximately(loaded.max_health, 150.0):
		return false
	if not assert_equal(loaded.level, 5):
		return false

	return true


func test_progression_data() -> bool:
	var prog := SaveTypes.ProgressionData.new()
	prog.completed_levels.append("level_1")
	prog.completed_levels.append("level_2")

	var dict := prog.to_dict()
	var loaded := SaveTypes.ProgressionData.from_dict(dict)

	if not assert_equal(loaded.completed_levels.size(), 2):
		return false
	if not assert_array_contains(loaded.completed_levels, "level_1"):
		return false

	return true


func test_settings_data() -> bool:
	var settings := SaveTypes.SettingsData.new()
	settings.master_volume = 0.8
	settings.music_volume = 0.6
	settings.screen_shake = false

	var dict := settings.to_dict()
	var loaded := SaveTypes.SettingsData.from_dict(dict)

	if not assert_approximately(loaded.master_volume, 0.8):
		return false
	if not assert_false(loaded.screen_shake):
		return false

	return true


func test_game_statistics() -> bool:
	var stats := SaveTypes.GameStatistics.new()
	stats.total_enemies_defeated = 100
	stats.perfect_hits = 50
	stats.max_combo = 25

	var dict := stats.to_dict()
	var loaded := SaveTypes.GameStatistics.from_dict(dict)

	if not assert_equal(loaded.total_enemies_defeated, 100):
		return false
	if not assert_equal(loaded.max_combo, 25):
		return false

	return true


func test_full_game_save() -> bool:
	var save := SaveTypes.GameSaveData.new()
	save.slot_info.player_name = "Hero"
	save.player_data.level = 10
	save.statistics.perfect_hits = 100

	var dict := save.to_dict()
	var loaded := SaveTypes.GameSaveData.from_dict(dict)

	if not assert_equal(loaded.slot_info.player_name, "Hero"):
		return false
	if not assert_equal(loaded.player_data.level, 10):
		return false
	if not assert_equal(loaded.statistics.perfect_hits, 100):
		return false

	return true
