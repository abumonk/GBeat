## AnalyticsManager - Event tracking and telemetry
## Stub implementation - replace with actual analytics backend
class_name AnalyticsManager
extends Node


signal event_tracked(event_name: String)


## Analytics state
var is_enabled: bool = true
var session_id: String = ""
var session_start_time: float = 0.0

## Event buffer for batching
var _event_buffer: Array[Dictionary] = []
var _flush_interval: float = 30.0
var _flush_timer: float = 0.0

## User properties
var _user_properties: Dictionary = {}


func _ready() -> void:
	_start_session()


func _process(delta: float) -> void:
	if not is_enabled:
		return

	_flush_timer += delta
	if _flush_timer >= _flush_interval:
		_flush_timer = 0.0
		_flush_events()


func _start_session() -> void:
	session_id = "%d_%d" % [Time.get_ticks_msec(), randi()]
	session_start_time = Time.get_unix_time_from_system()

	track_event("session_start", {
		"platform": OS.get_name(),
		"version": ProjectSettings.get_setting("application/config/version", "1.0.0"),
	})


func _exit_tree() -> void:
	var session_duration := Time.get_unix_time_from_system() - session_start_time
	track_event("session_end", {
		"duration_seconds": session_duration,
	})
	_flush_events()


## === Event Tracking ===

func track_event(event_name: String, properties: Dictionary = {}) -> void:
	if not is_enabled:
		return

	var event := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"properties": properties,
		"user_properties": _user_properties.duplicate(),
	}

	_event_buffer.append(event)
	event_tracked.emit(event_name)

	# STUB: In production, events would be sent to analytics backend
	print("Analytics: %s - %s" % [event_name, properties])


## === Common Event Helpers ===

func track_level_start(level_id: String, difficulty: String = "normal") -> void:
	track_event("level_start", {
		"level_id": level_id,
		"difficulty": difficulty,
	})


func track_level_complete(level_id: String, score: int, time_seconds: float, deaths: int = 0) -> void:
	track_event("level_complete", {
		"level_id": level_id,
		"score": score,
		"time_seconds": time_seconds,
		"deaths": deaths,
	})


func track_level_fail(level_id: String, reason: String, progress_percent: float) -> void:
	track_event("level_fail", {
		"level_id": level_id,
		"reason": reason,
		"progress_percent": progress_percent,
	})


func track_enemy_defeated(enemy_type: String, timing_rating: String) -> void:
	track_event("enemy_defeated", {
		"enemy_type": enemy_type,
		"timing_rating": timing_rating,
	})


func track_boss_defeated(boss_id: String, time_seconds: float, damage_taken: float) -> void:
	track_event("boss_defeated", {
		"boss_id": boss_id,
		"time_seconds": time_seconds,
		"damage_taken": damage_taken,
	})


func track_ability_used(ability_id: String) -> void:
	track_event("ability_used", {
		"ability_id": ability_id,
	})


func track_item_purchased(item_id: String, currency_type: String, amount: int) -> void:
	track_event("item_purchased", {
		"item_id": item_id,
		"currency_type": currency_type,
		"amount": amount,
	})


func track_achievement_unlocked(achievement_id: String) -> void:
	track_event("achievement_unlocked", {
		"achievement_id": achievement_id,
	})


func track_settings_changed(setting_name: String, old_value: Variant, new_value: Variant) -> void:
	track_event("settings_changed", {
		"setting": setting_name,
		"old_value": str(old_value),
		"new_value": str(new_value),
	})


func track_error(error_type: String, error_message: String, context: Dictionary = {}) -> void:
	var props := {
		"error_type": error_type,
		"error_message": error_message,
	}
	props.merge(context)
	track_event("error", props)


## === User Properties ===

func set_user_property(key: String, value: Variant) -> void:
	_user_properties[key] = value


func set_user_id(user_id: String) -> void:
	set_user_property("user_id", user_id)


func set_user_properties(properties: Dictionary) -> void:
	for key in properties.keys():
		_user_properties[key] = properties[key]


## === Control ===

func enable() -> void:
	is_enabled = true


func disable() -> void:
	is_enabled = false
	_event_buffer.clear()


func _flush_events() -> void:
	if _event_buffer.is_empty():
		return

	# STUB: In production, send events to analytics backend
	print("Analytics: Flushing %d events" % _event_buffer.size())
	_event_buffer.clear()


func get_session_duration() -> float:
	return Time.get_unix_time_from_system() - session_start_time
