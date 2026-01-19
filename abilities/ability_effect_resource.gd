## AbilityEffectResource - Resource wrapper for ability effects
@tool
class_name AbilityEffectResource
extends Resource


@export var effect_type: AbilityTypes.EffectType = AbilityTypes.EffectType.DAMAGE
@export var value: float = 10.0
@export var duration: float = 0.0
@export var is_percentage: bool = false


func to_effect() -> AbilityTypes.AbilityEffect:
	var effect := AbilityTypes.AbilityEffect.new()
	effect.effect_type = effect_type
	effect.value = value
	effect.duration = duration
	effect.is_percentage = is_percentage
	return effect


func get_description() -> String:
	var value_str := "%d%%" % int(value) if is_percentage else str(int(value))

	match effect_type:
		AbilityTypes.EffectType.DAMAGE:
			return "Deal %s damage" % value_str
		AbilityTypes.EffectType.HEAL:
			return "Restore %s health" % value_str
		AbilityTypes.EffectType.BUFF_SPEED:
			if duration > 0:
				return "Increase speed by %s for %.1fs" % [value_str, duration]
			return "Increase speed by %s" % value_str
		AbilityTypes.EffectType.BUFF_DAMAGE:
			if duration > 0:
				return "Increase damage by %s for %.1fs" % [value_str, duration]
			return "Increase damage by %s" % value_str
		AbilityTypes.EffectType.BUFF_DEFENSE:
			if duration > 0:
				return "Reduce damage taken by %s for %.1fs" % [value_str, duration]
			return "Reduce damage taken by %s" % value_str
		AbilityTypes.EffectType.DEBUFF_ENEMY:
			return "Weaken enemies by %s" % value_str
		AbilityTypes.EffectType.SPECIAL:
			return "Special effect"

	return ""
