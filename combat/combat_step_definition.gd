## CombatStepDefinition - Defines a combat action (attack, block, dodge)
class_name CombatStepDefinition
extends Resource

@export var step_name: String = ""
@export var action_type: CombatTypes.ActionType = CombatTypes.ActionType.LIGHT_ATTACK

## Animation
@export var animation_name: String = ""
@export var animation_speed: float = 1.0

## Timing (in beats/quants)
@export var startup_quants: int = 2      ## Frames before active
@export var active_quants: int = 4       ## Active hitbox frames
@export var recovery_quants: int = 4     ## Frames after active

## Damage
@export var base_damage: float = 10.0
@export var knockback_force: float = 5.0

## Hitbox
@export var hitbox_offset: Vector3 = Vector3(0, 1, 1)
@export var hitbox_half_extent: Vector3 = Vector3(0.5, 0.5, 0.5)

## Combo
@export var combo_link_type: CombatTypes.ComboLinkType = CombatTypes.ComboLinkType.ANY
@export var can_cancel_into: Array[String] = []  ## Step names this can cancel into

## Movement during attack
@export var forward_movement: float = 1.0  ## Distance to move forward
@export var movement_curve: Curve  ## Movement over duration

## Range
@export var attack_range: float = 2.0
@export var optimal_range_min: float = 0.5
@export var optimal_range_max: float = 2.0


func get_total_quants() -> int:
	return startup_quants + active_quants + recovery_quants


func get_total_duration(quant_duration: float) -> float:
	return get_total_quants() * quant_duration


func is_in_range(distance: float) -> bool:
	return distance <= attack_range


func get_range_quality(distance: float) -> float:
	if distance < optimal_range_min:
		return 0.5  ## Too close
	elif distance > optimal_range_max:
		return 0.0  ## Too far
	else:
		return 1.0  ## Optimal
