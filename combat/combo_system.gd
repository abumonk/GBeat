## ComboSystem - Manages combo chains, multipliers, and style
class_name ComboSystem
extends Node


signal combo_changed(combo: int, multiplier: float)
signal combo_broken()
signal combo_milestone(milestone: int)
signal timing_result(rating: String, accuracy: float)
signal style_rank_changed(rank: String, score: float)
signal finisher_available(finisher_type: String)


## Configuration
@export var combo_timeout: float = 2.0
@export var perfect_window: float = 0.05  # 50ms
@export var great_window: float = 0.1     # 100ms
@export var good_window: float = 0.2      # 200ms

## Multipliers
@export var perfect_multiplier: float = 2.0
@export var great_multiplier: float = 1.5
@export var good_multiplier: float = 1.0
@export var base_combo_multiplier: float = 0.1  # Per combo hit

## Milestones
@export var combo_milestones: Array[int] = [10, 25, 50, 100, 200, 500]

## State
var current_combo: int = 0
var combo_multiplier: float = 1.0
var style_score: float = 0.0
var style_rank: String = "D"
var perfect_streak: int = 0
var attack_history: Array[String] = []
var _combo_timer: float = 0.0
var _is_combo_active: bool = false


## Style ranks
const STYLE_RANKS = {
	"D": 0,
	"C": 1000,
	"B": 3000,
	"A": 6000,
	"S": 10000,
	"SS": 15000,
	"SSS": 25000,
}


func _process(delta: float) -> void:
	if _is_combo_active:
		_combo_timer -= delta
		if _combo_timer <= 0:
			break_combo()

	# Decay style score over time
	if style_score > 0:
		style_score -= delta * 100
		style_score = maxf(0, style_score)
		_update_style_rank()


## Register a successful hit
func register_hit(timing_offset: float, attack_type: String = "light") -> void:
	var rating := _get_timing_rating(timing_offset)
	var multiplier := _get_timing_multiplier(rating)
	var accuracy := 1.0 - (abs(timing_offset) / good_window)

	# Increment combo
	current_combo += 1
	_is_combo_active = true
	_combo_timer = combo_timeout

	# Update combo multiplier
	combo_multiplier = 1.0 + (current_combo * base_combo_multiplier)
	combo_multiplier *= multiplier

	# Track perfect streak
	if rating == "PERFECT":
		perfect_streak += 1
	else:
		perfect_streak = 0

	# Add to attack history for variety tracking
	attack_history.append(attack_type)
	if attack_history.size() > 10:
		attack_history.pop_front()

	# Calculate style points
	var style_points := _calculate_style_points(rating, attack_type)
	style_score += style_points

	# Emit signals
	combo_changed.emit(current_combo, combo_multiplier)
	timing_result.emit(rating, accuracy)

	# Check milestones
	_check_milestones()

	# Check finisher availability
	_check_finisher_availability()

	_update_style_rank()


## Register a miss
func register_miss() -> void:
	timing_result.emit("MISS", 0.0)
	break_combo()


## Break the combo
func break_combo() -> void:
	if current_combo > 0:
		combo_broken.emit()

	current_combo = 0
	combo_multiplier = 1.0
	perfect_streak = 0
	_is_combo_active = false
	attack_history.clear()

	combo_changed.emit(0, 1.0)


## Get timing rating from offset
func _get_timing_rating(offset: float) -> String:
	var abs_offset := abs(offset)

	if abs_offset <= perfect_window:
		return "PERFECT"
	elif abs_offset <= great_window:
		return "GREAT"
	elif abs_offset <= good_window:
		if offset < 0:
			return "EARLY"
		else:
			return "LATE"
	else:
		return "MISS"


## Get multiplier for timing rating
func _get_timing_multiplier(rating: String) -> float:
	match rating:
		"PERFECT":
			return perfect_multiplier
		"GREAT":
			return great_multiplier
		"GOOD", "EARLY", "LATE":
			return good_multiplier
		_:
			return 0.0


## Calculate style points
func _calculate_style_points(rating: String, attack_type: String) -> float:
	var base_points := 100.0

	# Rating bonus
	match rating:
		"PERFECT":
			base_points *= 3.0
		"GREAT":
			base_points *= 2.0
		"GOOD", "EARLY", "LATE":
			base_points *= 1.0

	# Combo bonus
	base_points *= 1.0 + (current_combo * 0.05)

	# Perfect streak bonus
	if perfect_streak > 5:
		base_points *= 1.5

	# Variety bonus (using different attacks)
	var variety := _calculate_variety()
	base_points *= 1.0 + (variety * 0.5)

	return base_points


## Calculate attack variety
func _calculate_variety() -> float:
	if attack_history.size() < 3:
		return 0.0

	var unique_attacks := {}
	for attack in attack_history:
		unique_attacks[attack] = true

	return float(unique_attacks.size()) / attack_history.size()


## Check combo milestones
func _check_milestones() -> void:
	for milestone in combo_milestones:
		if current_combo == milestone:
			combo_milestone.emit(milestone)
			break


## Check if finisher is available
func _check_finisher_availability() -> void:
	if current_combo >= 10 and perfect_streak >= 3:
		finisher_available.emit("perfect_finish")
	elif current_combo >= 25:
		finisher_available.emit("combo_finish")
	elif style_rank in ["S", "SS", "SSS"]:
		finisher_available.emit("style_finish")


## Update style rank
func _update_style_rank() -> void:
	var new_rank := "D"

	for rank in ["SSS", "SS", "S", "A", "B", "C", "D"]:
		if style_score >= STYLE_RANKS[rank]:
			new_rank = rank
			break

	if new_rank != style_rank:
		style_rank = new_rank
		style_rank_changed.emit(style_rank, style_score)


## Get current combo info
func get_combo_info() -> Dictionary:
	return {
		"combo": current_combo,
		"multiplier": combo_multiplier,
		"perfect_streak": perfect_streak,
		"style_score": style_score,
		"style_rank": style_rank,
	}


## Reset all state
func reset() -> void:
	current_combo = 0
	combo_multiplier = 1.0
	style_score = 0.0
	style_rank = "D"
	perfect_streak = 0
	attack_history.clear()
	_combo_timer = 0.0
	_is_combo_active = false
