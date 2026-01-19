## SaveManager - Handles saving and loading game data
class_name SaveManager
extends Node


signal save_completed(slot_id: int, success: bool)
signal load_completed(slot_id: int, success: bool)
signal slot_deleted(slot_id: int)


const SAVE_DIR := "user://saves/"
const SETTINGS_FILE := "user://settings.cfg"
const MAX_SLOTS := 3
const SAVE_VERSION := 1


## Currently loaded save data
var current_save: SaveTypes.GameSaveData = null
var current_slot: int = -1

## Global settings (independent of save slots)
var global_settings: SaveTypes.SettingsData = SaveTypes.SettingsData.new()


func _ready() -> void:
	_ensure_save_directory()
	load_global_settings()


func _ensure_save_directory() -> void:
	var dir := DirAccess.open("user://")
	if dir and not dir.dir_exists("saves"):
		dir.make_dir("saves")


## === Slot Management ===

func get_slot_info(slot_id: int) -> SaveTypes.SaveSlot:
	var path := _get_save_path(slot_id)

	if not FileAccess.file_exists(path):
		var empty := SaveTypes.SaveSlot.new()
		empty.slot_id = slot_id
		empty.is_empty = true
		return empty

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file: %s" % path)
		return SaveTypes.SaveSlot.new()

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("SaveManager: Failed to parse save file: %s" % json.get_error_message())
		return SaveTypes.SaveSlot.new()

	var save := SaveTypes.GameSaveData.from_dict(json.data)
	return save.slot_info


func get_all_slot_info() -> Array[SaveTypes.SaveSlot]:
	var slots: Array[SaveTypes.SaveSlot] = []
	for i in range(MAX_SLOTS):
		slots.append(get_slot_info(i))
	return slots


func delete_slot(slot_id: int) -> bool:
	var path := _get_save_path(slot_id)

	if FileAccess.file_exists(path):
		var dir := DirAccess.open(SAVE_DIR)
		if dir:
			var error := dir.remove(_get_save_filename(slot_id))
			if error == OK:
				slot_deleted.emit(slot_id)
				return true

	return false


## === Save/Load ===

func save_game(slot_id: int) -> bool:
	if not current_save:
		current_save = SaveTypes.GameSaveData.new()

	# Update slot info
	current_save.slot_info.slot_id = slot_id
	current_save.slot_info.save_date = Time.get_datetime_string_from_system()
	current_save.slot_info.is_empty = false
	current_save.version = SAVE_VERSION

	var path := _get_save_path(slot_id)
	var file := FileAccess.open(path, FileAccess.WRITE)

	if not file:
		push_error("SaveManager: Failed to create save file: %s" % path)
		save_completed.emit(slot_id, false)
		return false

	var json := JSON.stringify(current_save.to_dict(), "\t")
	file.store_string(json)
	file.close()

	current_slot = slot_id
	save_completed.emit(slot_id, true)
	return true


func load_game(slot_id: int) -> bool:
	var path := _get_save_path(slot_id)

	if not FileAccess.file_exists(path):
		push_error("SaveManager: Save file not found: %s" % path)
		load_completed.emit(slot_id, false)
		return false

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Failed to open save file: %s" % path)
		load_completed.emit(slot_id, false)
		return false

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("SaveManager: Failed to parse save file: %s" % json.get_error_message())
		load_completed.emit(slot_id, false)
		return false

	current_save = SaveTypes.GameSaveData.from_dict(json.data)
	current_slot = slot_id

	# Handle version migration if needed
	if current_save.version < SAVE_VERSION:
		_migrate_save(current_save.version, SAVE_VERSION)

	load_completed.emit(slot_id, true)
	return true


func create_new_game(slot_id: int, player_name: String = "Player") -> bool:
	current_save = SaveTypes.GameSaveData.new()
	current_save.slot_info.player_name = player_name
	current_save.slot_info.slot_id = slot_id
	current_slot = slot_id
	return save_game(slot_id)


## === Global Settings ===

func save_global_settings() -> void:
	var config := ConfigFile.new()

	config.set_value("audio", "master_volume", global_settings.master_volume)
	config.set_value("audio", "music_volume", global_settings.music_volume)
	config.set_value("audio", "sfx_volume", global_settings.sfx_volume)

	config.set_value("gameplay", "screen_shake", global_settings.screen_shake)
	config.set_value("gameplay", "visual_effects", global_settings.visual_effects)
	config.set_value("gameplay", "beat_assist", global_settings.beat_assist)

	config.set_value("accessibility", "colorblind_mode", global_settings.colorblind_mode)

	config.save(SETTINGS_FILE)


func load_global_settings() -> void:
	var config := ConfigFile.new()
	var error := config.load(SETTINGS_FILE)

	if error != OK:
		# Use defaults
		return

	global_settings.master_volume = config.get_value("audio", "master_volume", 1.0)
	global_settings.music_volume = config.get_value("audio", "music_volume", 0.8)
	global_settings.sfx_volume = config.get_value("audio", "sfx_volume", 1.0)

	global_settings.screen_shake = config.get_value("gameplay", "screen_shake", true)
	global_settings.visual_effects = config.get_value("gameplay", "visual_effects", true)
	global_settings.beat_assist = config.get_value("gameplay", "beat_assist", false)

	global_settings.colorblind_mode = config.get_value("accessibility", "colorblind_mode", 0)


## === Data Access ===

func get_player_data() -> SaveTypes.PlayerSaveData:
	if current_save:
		return current_save.player_data
	return SaveTypes.PlayerSaveData.new()


func get_progression_data() -> SaveTypes.ProgressionData:
	if current_save:
		return current_save.progression_data
	return SaveTypes.ProgressionData.new()


func get_statistics() -> SaveTypes.GameStatistics:
	if current_save:
		return current_save.statistics
	return SaveTypes.GameStatistics.new()


func update_playtime(delta: float) -> void:
	if current_save:
		current_save.slot_info.playtime_seconds += delta
		current_save.statistics.total_playtime += delta


func record_hit(rating: CombatTypes.TimingRating) -> void:
	if not current_save:
		return

	match rating:
		CombatTypes.TimingRating.PERFECT:
			current_save.statistics.perfect_hits += 1
		CombatTypes.TimingRating.GREAT:
			current_save.statistics.great_hits += 1
		CombatTypes.TimingRating.GOOD:
			current_save.statistics.good_hits += 1
		CombatTypes.TimingRating.MISS:
			current_save.statistics.misses += 1


func record_combo(combo: int) -> void:
	if current_save and combo > current_save.statistics.max_combo:
		current_save.statistics.max_combo = combo


func record_enemy_defeat() -> void:
	if current_save:
		current_save.statistics.total_enemies_defeated += 1


func record_damage(dealt: float, taken: float) -> void:
	if current_save:
		current_save.statistics.total_damage_dealt += dealt
		current_save.statistics.total_damage_taken += taken


func record_death() -> void:
	if current_save:
		current_save.statistics.deaths += 1


## === Utility ===

func _get_save_path(slot_id: int) -> String:
	return SAVE_DIR + _get_save_filename(slot_id)


func _get_save_filename(slot_id: int) -> String:
	return "save_%d.json" % slot_id


func _migrate_save(from_version: int, to_version: int) -> void:
	# Handle save migrations between versions
	# For now, no migrations needed
	current_save.version = to_version


func has_active_save() -> bool:
	return current_save != null and current_slot >= 0


func quick_save() -> bool:
	if has_active_save():
		return save_game(current_slot)
	return false
