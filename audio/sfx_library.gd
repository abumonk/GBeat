## SFXLibrary - Manages and provides access to sound effects
@tool
class_name SFXLibrary
extends Resource


@export var library_name: String = ""

## SFX entries by category
@export var combat_player: Array[SFXEntry] = []
@export var combat_enemy: Array[SFXEntry] = []
@export var movement: Array[SFXEntry] = []
@export var ui: Array[SFXEntry] = []
@export var environment: Array[SFXEntry] = []
@export var feedback: Array[SFXEntry] = []

## Cached lookup
var _by_name: Dictionary = {}


func _init() -> void:
	_build_cache()


func _build_cache() -> void:
	_by_name.clear()

	for entry in combat_player:
		_by_name[entry.sfx_name] = entry
	for entry in combat_enemy:
		_by_name[entry.sfx_name] = entry
	for entry in movement:
		_by_name[entry.sfx_name] = entry
	for entry in ui:
		_by_name[entry.sfx_name] = entry
	for entry in environment:
		_by_name[entry.sfx_name] = entry
	for entry in feedback:
		_by_name[entry.sfx_name] = entry


func get_sfx(sfx_name: String) -> SFXEntry:
	if _by_name.is_empty():
		_build_cache()
	return _by_name.get(sfx_name)


func get_random_from_category(category: AudioTypes.SFXCategory) -> SFXEntry:
	var entries := _get_category_array(category)
	if entries.is_empty():
		return null
	return entries[randi() % entries.size()]


func _get_category_array(category: AudioTypes.SFXCategory) -> Array[SFXEntry]:
	match category:
		AudioTypes.SFXCategory.COMBAT_PLAYER:
			return combat_player
		AudioTypes.SFXCategory.COMBAT_ENEMY:
			return combat_enemy
		AudioTypes.SFXCategory.MOVEMENT:
			return movement
		AudioTypes.SFXCategory.UI:
			return ui
		AudioTypes.SFXCategory.ENVIRONMENT:
			return environment
		AudioTypes.SFXCategory.FEEDBACK:
			return feedback
	return []
