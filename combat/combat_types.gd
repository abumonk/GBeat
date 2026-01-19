## CombatTypes - Enums and data classes for combat system
class_name CombatTypes
extends RefCounted


enum ActionType {
	NONE,
	LIGHT_ATTACK,
	HEAVY_ATTACK,
	BLOCK,
	DODGE,
	SPECIAL
}


enum TimingRating {
	MISS,      ## Too early or too late
	EARLY,     ## Slightly early
	LATE,      ## Slightly late
	GOOD,      ## Acceptable timing
	GREAT,     ## Good timing
	PERFECT    ## On the beat
}


enum WindowType {
	NONE,
	ATTACK,
	BLOCK,
	DODGE,
	COMBO
}


enum ComboLinkType {
	ANY,           ## Can follow any attack
	LIGHT_ONLY,    ## Must follow light attack
	HEAVY_ONLY,    ## Must follow heavy attack
	LIGHT_CHAIN,   ## Part of light combo
	HEAVY_CHAIN    ## Part of heavy combo
}


## Timing configuration for beat-synced combat
class TimingConfig:
	var perfect_window: float = 0.05   ## +/- seconds from beat
	var great_window: float = 0.1
	var good_window: float = 0.15
	var early_penalty: float = 0.2
	var late_penalty: float = 0.3


## Result of an attack with timing information
class BeatHitResult:
	var hit_actor: Node3D = null
	var target: Node3D = null
	var timing_rating: TimingRating = TimingRating.MISS
	var timing_quality: float = 0.0    ## 0-1, 1 = perfect
	var base_damage: float = 0.0
	var timing_multiplier: float = 1.0
	var combo_multiplier: float = 1.0
	var final_damage: float = 0.0
	var is_critical: bool = false
	var impact_point: Vector3 = Vector3.ZERO

	func calculate_final_damage() -> void:
		final_damage = base_damage * timing_multiplier * combo_multiplier


static func get_timing_multiplier(rating: TimingRating) -> float:
	match rating:
		TimingRating.PERFECT:
			return 1.5
		TimingRating.GREAT:
			return 1.25
		TimingRating.GOOD:
			return 1.0
		TimingRating.EARLY:
			return 0.75
		TimingRating.LATE:
			return 0.75
		TimingRating.MISS:
			return 0.5
	return 1.0


static func rating_to_string(rating: TimingRating) -> String:
	match rating:
		TimingRating.PERFECT:
			return "PERFECT!"
		TimingRating.GREAT:
			return "GREAT!"
		TimingRating.GOOD:
			return "GOOD"
		TimingRating.EARLY:
			return "EARLY"
		TimingRating.LATE:
			return "LATE"
		TimingRating.MISS:
			return "MISS"
	return ""


static func rating_to_color(rating: TimingRating) -> Color:
	match rating:
		TimingRating.PERFECT:
			return Color.GOLD
		TimingRating.GREAT:
			return Color.CYAN
		TimingRating.GOOD:
			return Color.GREEN
		TimingRating.EARLY:
			return Color.ORANGE
		TimingRating.LATE:
			return Color.ORANGE
		TimingRating.MISS:
			return Color.RED
	return Color.WHITE
