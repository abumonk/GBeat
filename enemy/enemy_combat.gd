## BeatEnemyCombatComponent - Manages enemy attacks synchronized to beats
class_name BeatEnemyCombatComponent
extends Node

signal state_changed(old_state: State, new_state: State)
signal attack_started(attack: BeatEnemyAttack)
signal attack_completed(attack: BeatEnemyAttack)
signal telegraph_started(attack: BeatEnemyAttack)

enum State { IDLE, TELEGRAPHING, ATTACKING, STUNNED, DEAD }

@export var attacks: Array[BeatEnemyAttack] = []
@export var attack_cooldown: float = 2.0
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

var current_state: State = State.IDLE
var current_attack: BeatEnemyAttack = null
var state_timer: float = 0.0
var cooldown_timer: float = 0.0

@onready var enemy: BeatEnemy = get_parent()

var _subscription_handle: int = -1


func _ready() -> void:
	# Subscribe to animation quants for attack timing
	_subscription_handle = Sequencer.subscribe(
		sequencer_deck,
		Quant.Type.ANIMATION,
		_on_animation_quant
	)


func _exit_tree() -> void:
	if _subscription_handle >= 0:
		Sequencer.unsubscribe(_subscription_handle)


func _process(delta: float) -> void:
	# Update cooldown
	if cooldown_timer > 0:
		cooldown_timer -= delta

	# Update state timer
	match current_state:
		State.TELEGRAPHING:
			state_timer -= delta
			if state_timer <= 0:
				_start_attack()

		State.ATTACKING:
			state_timer -= delta
			if state_timer <= 0:
				_complete_attack()


func _on_animation_quant(_event: SequencerEvent) -> void:
	# Try to start attack on beat
	if current_state == State.IDLE and cooldown_timer <= 0:
		_try_start_attack()


func _try_start_attack() -> void:
	if not enemy or not enemy.target:
		return

	# Select attack based on context
	var attack := _select_attack()
	if not attack:
		return

	_start_telegraph(attack)


func _select_attack() -> BeatEnemyAttack:
	if attacks.is_empty():
		return null

	if not enemy or not enemy.target:
		return null

	var target_distance := enemy.global_position.distance_to(enemy.target.global_position)

	var valid_attacks: Array[BeatEnemyAttack] = []

	for attack in attacks:
		if target_distance <= attack.attack_range:
			valid_attacks.append(attack)

	if valid_attacks.is_empty():
		return null

	# Random selection (could be weighted)
	return valid_attacks[randi() % valid_attacks.size()]


func _start_telegraph(attack: BeatEnemyAttack) -> void:
	current_attack = attack
	state_timer = attack.telegraph_duration
	set_state(State.TELEGRAPHING)
	telegraph_started.emit(attack)


func _start_attack() -> void:
	if not current_attack:
		return

	state_timer = current_attack.attack_duration
	set_state(State.ATTACKING)
	attack_started.emit(current_attack)

	# Deal damage
	_deal_damage()


func _deal_damage() -> void:
	if not enemy or not enemy.target or not current_attack:
		return

	var target_distance := enemy.global_position.distance_to(enemy.target.global_position)

	if target_distance > current_attack.attack_range:
		return  ## Target out of range

	# Create hit result
	if enemy.target.has_method("take_damage"):
		enemy.target.take_damage(current_attack.damage, enemy)


func _complete_attack() -> void:
	var completed := current_attack
	current_attack = null
	cooldown_timer = attack_cooldown
	set_state(State.IDLE)
	if completed:
		attack_completed.emit(completed)


func set_state(new_state: State) -> void:
	var old_state := current_state
	current_state = new_state
	state_changed.emit(old_state, new_state)


## === External Control ===

func force_attack(attack: BeatEnemyAttack) -> void:
	if current_state != State.IDLE:
		return
	_start_telegraph(attack)


func cancel_attack() -> void:
	current_attack = null
	set_state(State.IDLE)


func is_attacking() -> bool:
	return current_state == State.ATTACKING


func is_telegraphing() -> bool:
	return current_state == State.TELEGRAPHING


func is_busy() -> bool:
	return current_state in [State.TELEGRAPHING, State.ATTACKING, State.STUNNED]
