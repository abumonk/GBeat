## AbilityTypes - Enums and data classes for ability system
class_name AbilityTypes
extends RefCounted


enum AbilityCategory {
	PASSIVE,     ## Always active
	ACTIVE,      ## Triggered by player
	REACTIVE,    ## Triggered by events
}


enum TriggerCondition {
	NONE,
	ON_PERFECT_HIT,
	ON_COMBO_THRESHOLD,
	ON_LOW_HEALTH,
	ON_BEAT,
	ON_DAMAGE_TAKEN,
	ON_ENEMY_DEFEAT,
}


enum TargetType {
	SELF,
	SINGLE_ENEMY,
	ALL_ENEMIES,
	AREA,
}


enum EffectType {
	DAMAGE,
	HEAL,
	BUFF_SPEED,
	BUFF_DAMAGE,
	BUFF_DEFENSE,
	DEBUFF_ENEMY,
	SPECIAL,
}


class AbilityEffect:
	var effect_type: EffectType = EffectType.DAMAGE
	var value: float = 0.0
	var duration: float = 0.0
	var is_percentage: bool = false

	func to_dict() -> Dictionary:
		return {
			"effect_type": effect_type,
			"value": value,
			"duration": duration,
			"is_percentage": is_percentage,
		}

	static func from_dict(data: Dictionary) -> AbilityEffect:
		var effect := AbilityEffect.new()
		effect.effect_type = data.get("effect_type", EffectType.DAMAGE)
		effect.value = data.get("value", 0.0)
		effect.duration = data.get("duration", 0.0)
		effect.is_percentage = data.get("is_percentage", false)
		return effect


class AbilityState:
	var is_unlocked: bool = false
	var is_equipped: bool = false
	var cooldown_remaining: float = 0.0
	var charges: int = 0
	var level: int = 1
