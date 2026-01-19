## BossAttack - Resource defining a boss attack
@tool
class_name BossAttack
extends Resource


@export var attack_name: String = ""
@export_multiline var description: String = ""

## Timing (in quants/beats)
@export var telegraph_quants: int = 8  ## Warning time before attack
@export var startup_quants: int = 2
@export var active_quants: int = 4
@export var recovery_quants: int = 8
@export var cooldown_beats: int = 4

## Damage
@export var base_damage: float = 20.0
@export var is_unblockable: bool = false
@export var is_undodgeable: bool = false
@export var can_be_parried: bool = true

## Targeting
@export var target_type: AbilityTypes.TargetType = AbilityTypes.TargetType.SINGLE_ENEMY
@export var attack_range: float = 3.0
@export var attack_radius: float = 2.0  ## For area attacks

## Movement
@export var movement_type: MovementType = MovementType.NONE
@export var movement_distance: float = 0.0
@export var movement_speed: float = 10.0

## Hazards
@export var creates_hazard: bool = false
@export var hazard_scene: PackedScene
@export var hazard_duration: float = 5.0

## Animation/VFX
@export var animation_name: String = ""
@export var telegraph_vfx: PackedScene
@export var attack_vfx: PackedScene
@export var impact_vfx: PackedScene

## Audio
@export var telegraph_sound: AudioStream
@export var attack_sound: AudioStream
@export var impact_sound: AudioStream

## Beat sync
@export var must_start_on_beat: bool = true
@export var timing_bonus_multiplier: float = 1.5  ## Extra damage for on-beat hits


enum MovementType {
	NONE,
	CHARGE,
	LEAP,
	TELEPORT,
	RETREAT,
}


func get_total_quants() -> int:
	return telegraph_quants + startup_quants + active_quants + recovery_quants


func get_attack_start_quant() -> int:
	return telegraph_quants + startup_quants


func get_recovery_start_quant() -> int:
	return telegraph_quants + startup_quants + active_quants
