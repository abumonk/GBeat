## SaveTypes - Data structures for save system
class_name SaveTypes
extends RefCounted


## Save slot data
class SaveSlot:
	var slot_id: int = 0
	var player_name: String = "Player"
	var playtime_seconds: float = 0.0
	var save_date: String = ""
	var current_level: String = ""
	var completion_percent: float = 0.0
	var is_empty: bool = true

	func to_dict() -> Dictionary:
		return {
			"slot_id": slot_id,
			"player_name": player_name,
			"playtime_seconds": playtime_seconds,
			"save_date": save_date,
			"current_level": current_level,
			"completion_percent": completion_percent,
			"is_empty": is_empty,
		}

	static func from_dict(data: Dictionary) -> SaveSlot:
		var slot := SaveSlot.new()
		slot.slot_id = data.get("slot_id", 0)
		slot.player_name = data.get("player_name", "Player")
		slot.playtime_seconds = data.get("playtime_seconds", 0.0)
		slot.save_date = data.get("save_date", "")
		slot.current_level = data.get("current_level", "")
		slot.completion_percent = data.get("completion_percent", 0.0)
		slot.is_empty = data.get("is_empty", true)
		return slot


## Complete game save data
class GameSaveData:
	var version: int = 1
	var slot_info: SaveSlot = SaveSlot.new()
	var player_data: PlayerSaveData = PlayerSaveData.new()
	var progression_data: ProgressionData = ProgressionData.new()
	var settings_data: SettingsData = SettingsData.new()
	var statistics: GameStatistics = GameStatistics.new()

	func to_dict() -> Dictionary:
		return {
			"version": version,
			"slot_info": slot_info.to_dict(),
			"player_data": player_data.to_dict(),
			"progression_data": progression_data.to_dict(),
			"settings_data": settings_data.to_dict(),
			"statistics": statistics.to_dict(),
		}

	static func from_dict(data: Dictionary) -> GameSaveData:
		var save := GameSaveData.new()
		save.version = data.get("version", 1)
		save.slot_info = SaveSlot.from_dict(data.get("slot_info", {}))
		save.player_data = PlayerSaveData.from_dict(data.get("player_data", {}))
		save.progression_data = ProgressionData.from_dict(data.get("progression_data", {}))
		save.settings_data = SettingsData.from_dict(data.get("settings_data", {}))
		save.statistics = GameStatistics.from_dict(data.get("statistics", {}))
		return save


## Player character data
class PlayerSaveData:
	var max_health: float = 100.0
	var current_health: float = 100.0
	var unlocked_abilities: Array[String] = []
	var equipped_abilities: Array[String] = []
	var experience: int = 0
	var level: int = 1
	var currency: int = 0

	func to_dict() -> Dictionary:
		return {
			"max_health": max_health,
			"current_health": current_health,
			"unlocked_abilities": unlocked_abilities,
			"equipped_abilities": equipped_abilities,
			"experience": experience,
			"level": level,
			"currency": currency,
		}

	static func from_dict(data: Dictionary) -> PlayerSaveData:
		var player := PlayerSaveData.new()
		player.max_health = data.get("max_health", 100.0)
		player.current_health = data.get("current_health", 100.0)
		player.unlocked_abilities = Array(data.get("unlocked_abilities", []), TYPE_STRING, "", null)
		player.equipped_abilities = Array(data.get("equipped_abilities", []), TYPE_STRING, "", null)
		player.experience = data.get("experience", 0)
		player.level = data.get("level", 1)
		player.currency = data.get("currency", 0)
		return player


## Game progression data
class ProgressionData:
	var completed_levels: Array[String] = []
	var unlocked_levels: Array[String] = []
	var boss_defeats: Dictionary = {}  ## boss_id -> times_defeated
	var collectibles: Dictionary = {}  ## level_id -> Array of collectible_ids
	var checkpoints: Dictionary = {}   ## level_id -> checkpoint_id

	func to_dict() -> Dictionary:
		return {
			"completed_levels": completed_levels,
			"unlocked_levels": unlocked_levels,
			"boss_defeats": boss_defeats,
			"collectibles": collectibles,
			"checkpoints": checkpoints,
		}

	static func from_dict(data: Dictionary) -> ProgressionData:
		var prog := ProgressionData.new()
		prog.completed_levels = Array(data.get("completed_levels", []), TYPE_STRING, "", null)
		prog.unlocked_levels = Array(data.get("unlocked_levels", []), TYPE_STRING, "", null)
		prog.boss_defeats = data.get("boss_defeats", {})
		prog.collectibles = data.get("collectibles", {})
		prog.checkpoints = data.get("checkpoints", {})
		return prog


## Game settings (also saved globally)
class SettingsData:
	var master_volume: float = 1.0
	var music_volume: float = 0.8
	var sfx_volume: float = 1.0
	var screen_shake: bool = true
	var visual_effects: bool = true
	var beat_assist: bool = false
	var colorblind_mode: int = 0  ## 0=off, 1=deuteranopia, 2=protanopia, 3=tritanopia

	func to_dict() -> Dictionary:
		return {
			"master_volume": master_volume,
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"screen_shake": screen_shake,
			"visual_effects": visual_effects,
			"beat_assist": beat_assist,
			"colorblind_mode": colorblind_mode,
		}

	static func from_dict(data: Dictionary) -> SettingsData:
		var settings := SettingsData.new()
		settings.master_volume = data.get("master_volume", 1.0)
		settings.music_volume = data.get("music_volume", 0.8)
		settings.sfx_volume = data.get("sfx_volume", 1.0)
		settings.screen_shake = data.get("screen_shake", true)
		settings.visual_effects = data.get("visual_effects", true)
		settings.beat_assist = data.get("beat_assist", false)
		settings.colorblind_mode = data.get("colorblind_mode", 0)
		return settings


## Game statistics for tracking achievements
class GameStatistics:
	var total_enemies_defeated: int = 0
	var total_damage_dealt: float = 0.0
	var total_damage_taken: float = 0.0
	var perfect_hits: int = 0
	var great_hits: int = 0
	var good_hits: int = 0
	var misses: int = 0
	var max_combo: int = 0
	var deaths: int = 0
	var total_playtime: float = 0.0

	func to_dict() -> Dictionary:
		return {
			"total_enemies_defeated": total_enemies_defeated,
			"total_damage_dealt": total_damage_dealt,
			"total_damage_taken": total_damage_taken,
			"perfect_hits": perfect_hits,
			"great_hits": great_hits,
			"good_hits": good_hits,
			"misses": misses,
			"max_combo": max_combo,
			"deaths": deaths,
			"total_playtime": total_playtime,
		}

	static func from_dict(data: Dictionary) -> GameStatistics:
		var stats := GameStatistics.new()
		stats.total_enemies_defeated = data.get("total_enemies_defeated", 0)
		stats.total_damage_dealt = data.get("total_damage_dealt", 0.0)
		stats.total_damage_taken = data.get("total_damage_taken", 0.0)
		stats.perfect_hits = data.get("perfect_hits", 0)
		stats.great_hits = data.get("great_hits", 0)
		stats.good_hits = data.get("good_hits", 0)
		stats.misses = data.get("misses", 0)
		stats.max_combo = data.get("max_combo", 0)
		stats.deaths = data.get("deaths", 0)
		stats.total_playtime = data.get("total_playtime", 0.0)
		return stats
