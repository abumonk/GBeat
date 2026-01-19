## AbilityManager - Manages ability execution and state
class_name AbilityManager
extends Node


signal ability_activated(ability_id: String)
signal ability_ready(ability_id: String)
signal ability_unlocked(ability_id: String)
signal effect_applied(target: Node, effect: AbilityTypes.AbilityEffect)


## Configuration
@export var ability_library: Array[AbilityDefinition] = []
@export var max_equipped_abilities: int = 4
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## References
@export var owner_node: Node3D

## State
var _ability_states: Dictionary = {}  ## ability_id -> AbilityState
var _equipped_abilities: Array[String] = []
var _active_buffs: Array[ActiveBuff] = []

## Sequencer
var _tick_handle: int = -1


class ActiveBuff:
	var effect: AbilityTypes.AbilityEffect
	var remaining_time: float
	var source_ability: String


func _ready() -> void:
	_initialize_abilities()
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	_update_cooldowns(delta)
	_update_buffs(delta)


func _initialize_abilities() -> void:
	for ability in ability_library:
		var state := AbilityTypes.AbilityState.new()
		state.charges = ability.max_charges
		_ability_states[ability.ability_id] = state


func _update_cooldowns(delta: float) -> void:
	for ability_id in _ability_states:
		var state: AbilityTypes.AbilityState = _ability_states[ability_id]
		if state.cooldown_remaining > 0:
			state.cooldown_remaining -= delta
			if state.cooldown_remaining <= 0:
				state.cooldown_remaining = 0
				ability_ready.emit(ability_id)


func _update_buffs(delta: float) -> void:
	var expired: Array[ActiveBuff] = []

	for buff in _active_buffs:
		buff.remaining_time -= delta
		if buff.remaining_time <= 0:
			expired.append(buff)

	for buff in expired:
		_active_buffs.erase(buff)


func _on_tick(event: SequencerEvent) -> void:
	# Check for beat-triggered abilities
	for ability_id in _equipped_abilities:
		var ability := get_ability(ability_id)
		if ability and ability.trigger_condition == AbilityTypes.TriggerCondition.ON_BEAT:
			_try_activate_reactive(ability)


## === Public API ===

func try_activate(ability_id: String, target: Node3D = null) -> bool:
	var ability := get_ability(ability_id)
	if not ability:
		return false

	var state := get_state(ability_id)
	if not state or not state.is_unlocked or not state.is_equipped:
		return false

	# Check cooldown
	if state.cooldown_remaining > 0:
		return false

	# Check charges
	if ability.max_charges > 0 and state.charges <= 0:
		return false

	# Execute ability
	_execute_ability(ability, target)

	# Apply cooldown
	state.cooldown_remaining = ability.cooldown
	if ability.max_charges > 0:
		state.charges -= 1

	ability_activated.emit(ability_id)
	return true


func _execute_ability(ability: AbilityDefinition, target: Node3D) -> void:
	# Get actual target
	var targets: Array[Node3D] = []

	match ability.target_type:
		AbilityTypes.TargetType.SELF:
			if owner_node:
				targets.append(owner_node)
		AbilityTypes.TargetType.SINGLE_ENEMY:
			if target:
				targets.append(target)
		AbilityTypes.TargetType.ALL_ENEMIES:
			targets = _get_enemies_in_range(ability.range)
		AbilityTypes.TargetType.AREA:
			var center := target.global_position if target else owner_node.global_position
			targets = _get_enemies_in_area(center, ability.area_radius)

	# Apply effects
	for effect_res in ability.effects:
		var effect_resource := effect_res as AbilityEffectResource
		if not effect_resource:
			continue

		var effect := effect_resource.to_effect()

		for t in targets:
			_apply_effect(t, effect, ability)

	# Spawn VFX
	if ability.vfx_scene:
		var vfx := ability.vfx_scene.instantiate()
		if owner_node:
			owner_node.get_parent().add_child(vfx)
			vfx.global_position = owner_node.global_position


func _apply_effect(target: Node3D, effect: AbilityTypes.AbilityEffect, ability: AbilityDefinition) -> void:
	# Apply beat multiplier if on beat
	var multiplier := 1.0
	if ability.sync_to_beat:
		multiplier = ability.beat_multiplier

	var value := effect.value * multiplier

	match effect.effect_type:
		AbilityTypes.EffectType.DAMAGE:
			if target.has_method("take_damage"):
				target.take_damage(value)
		AbilityTypes.EffectType.HEAL:
			if target.has_method("heal"):
				target.heal(value)
		AbilityTypes.EffectType.BUFF_SPEED, AbilityTypes.EffectType.BUFF_DAMAGE, AbilityTypes.EffectType.BUFF_DEFENSE:
			if effect.duration > 0:
				var buff := ActiveBuff.new()
				buff.effect = effect
				buff.remaining_time = effect.duration
				buff.source_ability = ability.ability_id
				_active_buffs.append(buff)

	effect_applied.emit(target, effect)


func _try_activate_reactive(ability: AbilityDefinition) -> void:
	# For reactive abilities that trigger on conditions
	var state := get_state(ability.ability_id)
	if not state or state.cooldown_remaining > 0:
		return

	_execute_ability(ability, null)
	state.cooldown_remaining = ability.cooldown


func _get_enemies_in_range(range_dist: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	if not owner_node:
		return result

	# Find all enemies in range (would use actual enemy group in real implementation)
	var enemies := get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy is Node3D:
			var dist := owner_node.global_position.distance_to(enemy.global_position)
			if dist <= range_dist:
				result.append(enemy)

	return result


func _get_enemies_in_area(center: Vector3, radius: float) -> Array[Node3D]:
	var result: Array[Node3D] = []
	var enemies := get_tree().get_nodes_in_group("enemies")

	for enemy in enemies:
		if enemy is Node3D:
			var dist := center.distance_to(enemy.global_position)
			if dist <= radius:
				result.append(enemy)

	return result


## === State Management ===

func unlock_ability(ability_id: String) -> bool:
	var state := get_state(ability_id)
	if not state or state.is_unlocked:
		return false

	state.is_unlocked = true
	ability_unlocked.emit(ability_id)
	return true


func equip_ability(ability_id: String) -> bool:
	var state := get_state(ability_id)
	if not state or not state.is_unlocked:
		return false

	if _equipped_abilities.size() >= max_equipped_abilities:
		return false

	if ability_id not in _equipped_abilities:
		_equipped_abilities.append(ability_id)
		state.is_equipped = true

	return true


func unequip_ability(ability_id: String) -> bool:
	var state := get_state(ability_id)
	if not state:
		return false

	_equipped_abilities.erase(ability_id)
	state.is_equipped = false
	return true


## === Queries ===

func get_ability(ability_id: String) -> AbilityDefinition:
	for ability in ability_library:
		if ability.ability_id == ability_id:
			return ability
	return null


func get_state(ability_id: String) -> AbilityTypes.AbilityState:
	return _ability_states.get(ability_id)


func get_equipped_abilities() -> Array[String]:
	return _equipped_abilities.duplicate()


func get_unlocked_abilities() -> Array[String]:
	var result: Array[String] = []
	for ability_id in _ability_states:
		var state: AbilityTypes.AbilityState = _ability_states[ability_id]
		if state.is_unlocked:
			result.append(ability_id)
	return result


func is_ability_ready(ability_id: String) -> bool:
	var state := get_state(ability_id)
	if not state:
		return false
	return state.is_unlocked and state.is_equipped and state.cooldown_remaining <= 0


func get_total_buff_value(effect_type: AbilityTypes.EffectType) -> float:
	var total := 0.0
	for buff in _active_buffs:
		if buff.effect.effect_type == effect_type:
			total += buff.effect.value
	return total


## === Event Triggers ===

func on_perfect_hit() -> void:
	_check_trigger(AbilityTypes.TriggerCondition.ON_PERFECT_HIT, 1.0)


func on_combo_reached(combo: int) -> void:
	_check_trigger(AbilityTypes.TriggerCondition.ON_COMBO_THRESHOLD, float(combo))


func on_low_health(health_percent: float) -> void:
	_check_trigger(AbilityTypes.TriggerCondition.ON_LOW_HEALTH, health_percent)


func on_damage_taken(damage: float) -> void:
	_check_trigger(AbilityTypes.TriggerCondition.ON_DAMAGE_TAKEN, damage)


func on_enemy_defeat() -> void:
	_check_trigger(AbilityTypes.TriggerCondition.ON_ENEMY_DEFEAT, 1.0)


func _check_trigger(condition: AbilityTypes.TriggerCondition, value: float) -> void:
	for ability_id in _equipped_abilities:
		var ability := get_ability(ability_id)
		if not ability or ability.trigger_condition != condition:
			continue

		# Check trigger value
		var should_trigger := false
		match condition:
			AbilityTypes.TriggerCondition.ON_COMBO_THRESHOLD:
				should_trigger = value >= ability.trigger_value
			AbilityTypes.TriggerCondition.ON_LOW_HEALTH:
				should_trigger = value <= ability.trigger_value
			_:
				should_trigger = true

		if should_trigger:
			_try_activate_reactive(ability)
