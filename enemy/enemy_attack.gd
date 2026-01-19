## BeatEnemyAttack - Defines an enemy attack pattern
class_name BeatEnemyAttack
extends Resource

@export var attack_name: String = ""
@export var animation_name: String = ""

## Timing (in beats)
@export var telegraph_duration: float = 1.0  ## Warning time in seconds
@export var attack_duration: float = 0.5     ## Active attack window

## Damage
@export var damage: float = 20.0
@export var knockback_force: float = 5.0

## Range
@export var attack_range: float = 2.0
@export var attack_radius: float = 0.0  ## AoE radius (0 = single target)

## Targeting
@export var requires_target: bool = true
@export var tracks_target_during_telegraph: bool = true

## Visual
@export var telegraph_color: Color = Color.YELLOW
@export var attack_color: Color = Color.RED
