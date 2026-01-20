## FinisherSystem - Manages special finishing moves
class_name FinisherSystem
extends Node


signal finisher_available(type: String)
signal finisher_executed(type: String, damage: float)
signal finisher_failed(type: String)


## Finisher types
enum FinisherType {
	COMBO_FINISHER,      # High combo count
	PERFECT_FINISHER,    # Perfect timing streak
	STYLE_FINISHER,      # High style rank
	BOSS_FINISHER,       # Staggered boss
	CHAIN_FINISHER,      # Completed combo chain
}

## Configuration
@export var combo_threshold: int = 25
@export var perfect_streak_threshold: int = 5
@export var style_rank_threshold: String = "S"

## Finisher data
@export var finisher_damage_multiplier: float = 3.0
@export var finisher_style_bonus: float = 2000.0
@export var finisher_invincibility_duration: float = 1.0

## State
var available_finishers: Dictionary = {}
var is_executing: bool = false


func _ready() -> void:
	pass


## Check if finisher conditions are met
func check_conditions(combo: int, perfect_streak: int, style_rank: String, boss_staggered: bool = false) -> void:
	available_finishers.clear()

	# Combo finisher
	if combo >= combo_threshold:
		available_finishers[FinisherType.COMBO_FINISHER] = {
			"damage_mult": 2.5 + (combo / 100.0),
			"style_bonus": 1000.0 + (combo * 10),
		}
		finisher_available.emit("combo")

	# Perfect finisher
	if perfect_streak >= perfect_streak_threshold:
		available_finishers[FinisherType.PERFECT_FINISHER] = {
			"damage_mult": 3.0 + (perfect_streak * 0.2),
			"style_bonus": 1500.0 + (perfect_streak * 100),
		}
		finisher_available.emit("perfect")

	# Style finisher
	var style_ranks := ["D", "C", "B", "A", "S", "SS", "SSS"]
	if style_ranks.find(style_rank) >= style_ranks.find(style_rank_threshold):
		available_finishers[FinisherType.STYLE_FINISHER] = {
			"damage_mult": 2.0 + style_ranks.find(style_rank) * 0.5,
			"style_bonus": 2000.0,
		}
		finisher_available.emit("style")

	# Boss finisher
	if boss_staggered:
		available_finishers[FinisherType.BOSS_FINISHER] = {
			"damage_mult": 5.0,
			"style_bonus": 5000.0,
		}
		finisher_available.emit("boss")


## Execute a finisher
func execute_finisher(type: FinisherType, base_damage: float) -> Dictionary:
	if not available_finishers.has(type):
		finisher_failed.emit(FinisherType.keys()[type])
		return {"success": false}

	is_executing = true

	var finisher_data: Dictionary = available_finishers[type]
	var final_damage := base_damage * finisher_data.damage_mult
	var style_bonus: float = finisher_data.style_bonus

	finisher_executed.emit(FinisherType.keys()[type], final_damage)

	# Clear used finisher
	available_finishers.erase(type)

	# Brief delay for animation
	await get_tree().create_timer(0.5).timeout
	is_executing = false

	return {
		"success": true,
		"damage": final_damage,
		"style_bonus": style_bonus,
		"type": FinisherType.keys()[type],
	}


## Try to execute best available finisher
func try_best_finisher(base_damage: float) -> Dictionary:
	# Priority order
	var priority := [
		FinisherType.BOSS_FINISHER,
		FinisherType.PERFECT_FINISHER,
		FinisherType.STYLE_FINISHER,
		FinisherType.COMBO_FINISHER,
	]

	for type in priority:
		if available_finishers.has(type):
			return await execute_finisher(type, base_damage)

	return {"success": false}


## Check if any finisher is available
func has_finisher() -> bool:
	return not available_finishers.is_empty()


## Get available finisher types
func get_available_types() -> Array:
	return available_finishers.keys()


## Cancel finisher execution
func cancel() -> void:
	is_executing = false


## Reset
func reset() -> void:
	available_finishers.clear()
	is_executing = false
