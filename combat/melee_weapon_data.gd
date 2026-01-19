## MeleeWeaponData - Defines a melee weapon's properties
class_name MeleeWeaponData
extends Resource

@export var weapon_name: String = ""
@export var description: String = ""
@export var icon: Texture2D

## Combat modifiers
@export var damage_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var range_multiplier: float = 1.0
@export var knockback_multiplier: float = 1.0

## Attack steps for this weapon
@export var light_attacks: Array[CombatStepDefinition] = []
@export var heavy_attacks: Array[CombatStepDefinition] = []
@export var special_attack: CombatStepDefinition

## Visual
@export var mesh: Mesh
@export var trail_color: Color = Color.WHITE


func get_all_steps() -> Array[CombatStepDefinition]:
	var all_steps: Array[CombatStepDefinition] = []
	all_steps.append_array(light_attacks)
	all_steps.append_array(heavy_attacks)
	if special_attack:
		all_steps.append(special_attack)
	return all_steps


func apply_modifiers_to_step(step: CombatStepDefinition) -> CombatStepDefinition:
	## Creates a modified copy of the step with weapon modifiers applied
	var modified := step.duplicate() as CombatStepDefinition
	modified.base_damage *= damage_multiplier
	modified.attack_range *= range_multiplier
	modified.knockback_force *= knockback_multiplier
	modified.animation_speed *= speed_multiplier
	return modified
