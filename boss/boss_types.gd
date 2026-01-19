## BossTypes - Enums and data classes for boss system
class_name BossTypes
extends RefCounted


enum BossState {
	INACTIVE,
	INTRO,
	FIGHTING,
	PHASE_TRANSITION,
	STAGGERED,
	DEFEATED,
}


enum PhaseTransitionType {
	IMMEDIATE,      ## Instant transition
	HEALTH_GATE,    ## At specific health thresholds
	TIMED,          ## After time elapsed
	PATTERN_COMPLETE, ## After completing a pattern
}


enum AttackPattern {
	SEQUENCE,       ## Fixed attack sequence
	RANDOM,         ## Random from pool
	ADAPTIVE,       ## Based on player behavior
	SCRIPTED,       ## Specific scripted sequence
}


class BossPhaseConfig:
	var phase_number: int = 1
	var health_threshold: float = 1.0  ## Phase starts at this health %
	var transition_type: PhaseTransitionType = PhaseTransitionType.HEALTH_GATE
	var attack_pattern: AttackPattern = AttackPattern.SEQUENCE
	var speed_multiplier: float = 1.0
	var damage_multiplier: float = 1.0
	var available_attacks: Array[String] = []
	var intro_animation: String = ""
	var music_layer: AudioTypes.LayerType = AudioTypes.LayerType.BASE


class BossAttackConfig:
	var attack_name: String = ""
	var telegraph_duration: float = 1.0
	var attack_duration: float = 0.5
	var recovery_duration: float = 0.5
	var damage: float = 20.0
	var cooldown_beats: int = 4
	var animation_name: String = ""
	var is_unblockable: bool = false
	var creates_hazard: bool = false
	var target_type: AbilityTypes.TargetType = AbilityTypes.TargetType.SINGLE_ENEMY


class BossStats:
	var max_health: float = 1000.0
	var current_health: float = 1000.0
	var stagger_threshold: float = 100.0
	var stagger_buildup: float = 0.0
	var stagger_duration: float = 5.0
	var defense: float = 0.0

	func get_health_percent() -> float:
		return current_health / max_health if max_health > 0 else 0.0

	func take_damage(amount: float) -> float:
		var actual := max(0, amount - defense)
		current_health = max(0, current_health - actual)
		return actual

	func add_stagger(amount: float) -> bool:
		stagger_buildup += amount
		if stagger_buildup >= stagger_threshold:
			stagger_buildup = 0
			return true
		return false
