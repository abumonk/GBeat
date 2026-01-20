## StyleSystem - Tracks combat style and variety
class_name StyleSystem
extends Node


signal style_score_changed(score: float, rank: String)
signal style_rank_changed(old_rank: String, new_rank: String)
signal variety_bonus(bonus: float, reason: String)
signal spam_penalty(penalty: float, attack: String)


## Configuration
@export var decay_rate: float = 50.0  # Points per second
@export var min_variety_window: int = 5  # Actions to track
@export var spam_threshold: int = 3  # Same attack in a row = spam

## Style ranks and thresholds
const RANKS = {
	"D": {"min": 0, "color": Color(0.5, 0.5, 0.5)},
	"C": {"min": 500, "color": Color(0.3, 0.6, 0.3)},
	"B": {"min": 1500, "color": Color(0.3, 0.5, 0.8)},
	"A": {"min": 3500, "color": Color(0.8, 0.5, 0.8)},
	"S": {"min": 6000, "color": Color(1.0, 0.8, 0.0)},
	"SS": {"min": 10000, "color": Color(1.0, 0.5, 0.0)},
	"SSS": {"min": 15000, "color": Color(1.0, 0.0, 0.0)},
}

## Action point values
const ACTION_POINTS = {
	"light": 50,
	"heavy": 100,
	"dodge": 75,
	"parry": 150,
	"counter": 200,
	"ability": 125,
	"finisher": 500,
}

## State
var style_score: float = 0.0
var style_rank: String = "D"
var action_history: Array[String] = []
var consecutive_same: int = 0
var last_action: String = ""


func _process(delta: float) -> void:
	# Decay score over time
	if style_score > 0:
		style_score -= decay_rate * delta
		style_score = maxf(0, style_score)
		_update_rank()


## Register an action
func register_action(action_type: String, timing_bonus: float = 1.0) -> float:
	var base_points: float = ACTION_POINTS.get(action_type, 50)
	var final_points := base_points * timing_bonus

	# Track consecutive same actions
	if action_type == last_action:
		consecutive_same += 1
	else:
		consecutive_same = 1
		last_action = action_type

	# Apply spam penalty
	if consecutive_same >= spam_threshold:
		var penalty := 0.5  # 50% reduction
		final_points *= penalty
		spam_penalty.emit(penalty, action_type)
	else:
		# Apply variety bonus
		action_history.append(action_type)
		if action_history.size() > min_variety_window:
			action_history.pop_front()

		var variety := _calculate_variety()
		if variety > 0.5:
			var bonus := 1.0 + (variety * 0.5)
			final_points *= bonus
			variety_bonus.emit(bonus, "High variety!")

	# Apply current rank multiplier
	var rank_mult := _get_rank_multiplier()
	final_points *= rank_mult

	# Add to score
	style_score += final_points
	_update_rank()

	return final_points


## Calculate variety from history
func _calculate_variety() -> float:
	if action_history.size() < 3:
		return 0.0

	var unique := {}
	for action in action_history:
		unique[action] = true

	return float(unique.size()) / action_history.size()


## Get multiplier based on current rank
func _get_rank_multiplier() -> float:
	match style_rank:
		"D":
			return 1.0
		"C":
			return 1.1
		"B":
			return 1.2
		"A":
			return 1.3
		"S":
			return 1.5
		"SS":
			return 1.75
		"SSS":
			return 2.0
	return 1.0


## Update rank based on score
func _update_rank() -> void:
	var new_rank := "D"

	for rank in ["SSS", "SS", "S", "A", "B", "C", "D"]:
		if style_score >= RANKS[rank].min:
			new_rank = rank
			break

	if new_rank != style_rank:
		var old_rank := style_rank
		style_rank = new_rank
		style_rank_changed.emit(old_rank, new_rank)

	style_score_changed.emit(style_score, style_rank)


## Get rank color
func get_rank_color() -> Color:
	return RANKS[style_rank].color


## Get info
func get_info() -> Dictionary:
	return {
		"score": style_score,
		"rank": style_rank,
		"color": get_rank_color(),
		"variety": _calculate_variety(),
	}


## Reset
func reset() -> void:
	style_score = 0.0
	style_rank = "D"
	action_history.clear()
	consecutive_same = 0
	last_action = ""


## Penalty for getting hit
func apply_hit_penalty(damage: float) -> void:
	var penalty := damage * 10  # Lose 10 style points per damage
	style_score = maxf(0, style_score - penalty)
	_update_rank()
