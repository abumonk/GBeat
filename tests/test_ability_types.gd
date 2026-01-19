## Test cases for Ability Types
extends TestBase


func test_ability_categories() -> bool:
	var categories := [
		AbilityTypes.AbilityCategory.PASSIVE,
		AbilityTypes.AbilityCategory.ACTIVE,
		AbilityTypes.AbilityCategory.REACTIVE,
	]

	if not assert_equal(categories.size(), 3, "Should have 3 ability categories"):
		return false

	return true


func test_trigger_conditions() -> bool:
	var conditions := [
		AbilityTypes.TriggerCondition.NONE,
		AbilityTypes.TriggerCondition.ON_PERFECT_HIT,
		AbilityTypes.TriggerCondition.ON_COMBO_THRESHOLD,
		AbilityTypes.TriggerCondition.ON_LOW_HEALTH,
		AbilityTypes.TriggerCondition.ON_BEAT,
		AbilityTypes.TriggerCondition.ON_DAMAGE_TAKEN,
		AbilityTypes.TriggerCondition.ON_ENEMY_DEFEAT,
	]

	if not assert_equal(conditions.size(), 7, "Should have 7 trigger conditions"):
		return false

	return true


func test_effect_types() -> bool:
	var effects := [
		AbilityTypes.EffectType.DAMAGE,
		AbilityTypes.EffectType.HEAL,
		AbilityTypes.EffectType.BUFF_SPEED,
		AbilityTypes.EffectType.BUFF_DAMAGE,
		AbilityTypes.EffectType.BUFF_DEFENSE,
		AbilityTypes.EffectType.DEBUFF_ENEMY,
		AbilityTypes.EffectType.SPECIAL,
	]

	if not assert_equal(effects.size(), 7, "Should have 7 effect types"):
		return false

	return true


func test_ability_effect_creation() -> bool:
	var effect := AbilityTypes.AbilityEffect.new()
	effect.effect_type = AbilityTypes.EffectType.DAMAGE
	effect.value = 25.0
	effect.duration = 0.0
	effect.is_percentage = false

	if not assert_equal(effect.effect_type, AbilityTypes.EffectType.DAMAGE):
		return false
	if not assert_approximately(effect.value, 25.0):
		return false

	return true


func test_ability_effect_serialization() -> bool:
	var effect := AbilityTypes.AbilityEffect.new()
	effect.effect_type = AbilityTypes.EffectType.BUFF_SPEED
	effect.value = 20.0
	effect.duration = 5.0
	effect.is_percentage = true

	var dict := effect.to_dict()

	if not assert_approximately(dict["value"], 20.0):
		return false
	if not assert_approximately(dict["duration"], 5.0):
		return false
	if not assert_true(dict["is_percentage"]):
		return false

	return true


func test_ability_effect_deserialization() -> bool:
	var dict := {
		"effect_type": AbilityTypes.EffectType.HEAL,
		"value": 50.0,
		"duration": 0.0,
		"is_percentage": false,
	}

	var effect := AbilityTypes.AbilityEffect.from_dict(dict)

	if not assert_equal(effect.effect_type, AbilityTypes.EffectType.HEAL):
		return false
	if not assert_approximately(effect.value, 50.0):
		return false

	return true


func test_ability_state() -> bool:
	var state := AbilityTypes.AbilityState.new()

	if not assert_false(state.is_unlocked, "Should start locked"):
		return false
	if not assert_false(state.is_equipped, "Should start unequipped"):
		return false
	if not assert_equal(state.level, 1, "Should start at level 1"):
		return false

	state.is_unlocked = true
	state.is_equipped = true
	state.cooldown_remaining = 5.0

	if not assert_true(state.is_unlocked):
		return false
	if not assert_approximately(state.cooldown_remaining, 5.0):
		return false

	return true
