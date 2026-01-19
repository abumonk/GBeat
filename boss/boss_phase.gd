## BossPhase - Resource defining a boss phase
@tool
class_name BossPhase
extends Resource


@export var phase_name: String = ""
@export var phase_number: int = 1

## Activation
@export_range(0.0, 1.0) var health_threshold: float = 1.0  ## Phase activates below this health %
@export var transition_type: BossTypes.PhaseTransitionType = BossTypes.PhaseTransitionType.HEALTH_GATE

## Combat
@export var attack_pattern: BossTypes.AttackPattern = BossTypes.AttackPattern.SEQUENCE
@export var available_attacks: Array[BossAttack] = []
@export var attack_sequence: Array[String] = []  ## For SEQUENCE pattern

## Modifiers
@export var speed_multiplier: float = 1.0
@export var damage_multiplier: float = 1.0
@export var defense_bonus: float = 0.0

## Timing (in beats)
@export var min_attack_interval: int = 4
@export var max_attack_interval: int = 8

## Visuals/Audio
@export var intro_animation: String = ""
@export var loop_animation: String = "idle"
@export var music_layer: AudioTypes.LayerType = AudioTypes.LayerType.COMBAT
@export var transition_vfx: PackedScene

## Dialogue/Events
@export var intro_dialogue: String = ""
@export var taunt_lines: Array[String] = []


func get_attack(attack_name: String) -> BossAttack:
	for attack in available_attacks:
		if attack.attack_name == attack_name:
			return attack
	return null


func get_random_attack() -> BossAttack:
	if available_attacks.is_empty():
		return null
	return available_attacks[randi() % available_attacks.size()]


func get_next_sequence_attack(current_index: int) -> BossAttack:
	if attack_sequence.is_empty():
		return get_random_attack()

	var next_index := (current_index + 1) % attack_sequence.size()
	return get_attack(attack_sequence[next_index])
