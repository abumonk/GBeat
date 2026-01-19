## BossBase - Base class for boss enemies
class_name BossBase
extends CharacterBody3D


signal state_changed(old_state: BossTypes.BossState, new_state: BossTypes.BossState)
signal phase_changed(phase_number: int)
signal health_changed(current: float, max: float)
signal stagger_started()
signal stagger_ended()
signal attack_started(attack: BossAttack)
signal attack_ended(attack: BossAttack)
signal defeated()


## Configuration
@export var boss_name: String = "Boss"
@export var phases: Array[BossPhase] = []
@export var stats: Resource  ## BossStatsResource
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## References
@export var animation_player: AnimationPlayer
@export var telegraph_point: Node3D  ## Where to show attack telegraphs
@export var target: Node3D  ## Player reference

## Stats
var _stats: BossTypes.BossStats = BossTypes.BossStats.new()

## State
var _current_state: BossTypes.BossState = BossTypes.BossState.INACTIVE
var _current_phase: BossPhase = null
var _phase_index: int = 0

## Attack state
var _current_attack: BossAttack = null
var _attack_progress: int = 0
var _attack_cooldowns: Dictionary = {}  ## attack_name -> beats remaining
var _sequence_index: int = 0
var _beats_until_attack: int = 4

## Sequencer
var _tick_handle: int = -1
var _stagger_timer: float = 0.0


func _ready() -> void:
	_initialize_stats()
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)

	# Start in first phase
	if phases.size() > 0:
		_set_phase(0)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _initialize_stats() -> void:
	# Would load from resource in real implementation
	_stats.max_health = 1000.0
	_stats.current_health = _stats.max_health


func _physics_process(delta: float) -> void:
	match _current_state:
		BossTypes.BossState.STAGGERED:
			_stagger_timer -= delta
			if _stagger_timer <= 0:
				_end_stagger()
		BossTypes.BossState.FIGHTING:
			_update_facing()


func _on_tick(_event: SequencerEvent) -> void:
	if _current_state != BossTypes.BossState.FIGHTING:
		return

	_update_cooldowns()
	_update_attack_progress()

	if not _current_attack:
		_beats_until_attack -= 1
		if _beats_until_attack <= 0:
			_start_next_attack()


func _update_cooldowns() -> void:
	for attack_name in _attack_cooldowns.keys():
		_attack_cooldowns[attack_name] = max(0, _attack_cooldowns[attack_name] - 1)


func _update_attack_progress() -> void:
	if not _current_attack:
		return

	_attack_progress += 1

	# Check attack phases
	var telegraph_end := _current_attack.telegraph_quants
	var startup_end := telegraph_end + _current_attack.startup_quants
	var active_end := startup_end + _current_attack.active_quants
	var total := _current_attack.get_total_quants()

	if _attack_progress == telegraph_end:
		_on_telegraph_end()
	elif _attack_progress == startup_end:
		_on_attack_active()
	elif _attack_progress == active_end:
		_on_attack_recovery()
	elif _attack_progress >= total:
		_end_attack()


func _update_facing() -> void:
	if not target:
		return

	var to_target := (target.global_position - global_position).normalized()
	to_target.y = 0

	if to_target.length_squared() > 0.01:
		var target_rotation := atan2(to_target.x, to_target.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, 0.1)


## === State Management ===

func _set_state(new_state: BossTypes.BossState) -> void:
	if new_state == _current_state:
		return

	var old_state := _current_state
	_current_state = new_state
	state_changed.emit(old_state, new_state)


func _set_phase(phase_idx: int) -> void:
	if phase_idx < 0 or phase_idx >= phases.size():
		return

	_phase_index = phase_idx
	_current_phase = phases[phase_idx]
	_sequence_index = 0

	# Play transition
	if animation_player and _current_phase.intro_animation:
		animation_player.play(_current_phase.intro_animation)

	phase_changed.emit(phase_idx + 1)


func _check_phase_transition() -> void:
	if not _current_phase:
		return

	var health_percent := _stats.get_health_percent()

	# Check if we should transition to next phase
	for i in range(_phase_index + 1, phases.size()):
		var phase := phases[i]
		if health_percent <= phase.health_threshold:
			_begin_phase_transition(i)
			break


func _begin_phase_transition(new_phase_idx: int) -> void:
	_set_state(BossTypes.BossState.PHASE_TRANSITION)

	# Cancel current attack
	if _current_attack:
		_end_attack()

	# Transition animation
	_set_phase(new_phase_idx)

	# Return to fighting after transition
	await get_tree().create_timer(1.0).timeout
	_set_state(BossTypes.BossState.FIGHTING)


## === Attack System ===

func _start_next_attack() -> void:
	if not _current_phase:
		return

	var attack := _select_attack()
	if not attack:
		_beats_until_attack = 2
		return

	_start_attack(attack)


func _select_attack() -> BossAttack:
	match _current_phase.attack_pattern:
		BossTypes.AttackPattern.SEQUENCE:
			return _current_phase.get_next_sequence_attack(_sequence_index)
		BossTypes.AttackPattern.RANDOM:
			return _select_random_available_attack()
		BossTypes.AttackPattern.ADAPTIVE:
			return _select_adaptive_attack()
		_:
			return _current_phase.get_random_attack()


func _select_random_available_attack() -> BossAttack:
	var available: Array[BossAttack] = []

	for attack in _current_phase.available_attacks:
		if _attack_cooldowns.get(attack.attack_name, 0) <= 0:
			available.append(attack)

	if available.is_empty():
		return null

	return available[randi() % available.size()]


func _select_adaptive_attack() -> BossAttack:
	# Would analyze player behavior and select counter
	# For now, just random
	return _select_random_available_attack()


func _start_attack(attack: BossAttack) -> void:
	_current_attack = attack
	_attack_progress = 0

	# Start telegraph
	_show_telegraph(attack)

	# Play telegraph animation/sound
	if attack.telegraph_sound:
		# Would play sound
		pass

	attack_started.emit(attack)


func _show_telegraph(attack: BossAttack) -> void:
	if attack.telegraph_vfx and telegraph_point:
		var vfx := attack.telegraph_vfx.instantiate()
		telegraph_point.add_child(vfx)


func _on_telegraph_end() -> void:
	# Telegraph finished, attack is starting
	if animation_player and _current_attack.animation_name:
		animation_player.play(_current_attack.animation_name)


func _on_attack_active() -> void:
	# Attack is now dealing damage
	_execute_attack_damage()


func _execute_attack_damage() -> void:
	if not _current_attack or not target:
		return

	var dist := global_position.distance_to(target.global_position)
	if dist > _current_attack.attack_range:
		return

	# Apply damage
	var damage := _current_attack.base_damage
	if _current_phase:
		damage *= _current_phase.damage_multiplier

	if target.has_method("take_damage"):
		target.take_damage(damage)


func _on_attack_recovery() -> void:
	# Attack active frames ended, in recovery
	pass


func _end_attack() -> void:
	if _current_attack:
		_attack_cooldowns[_current_attack.attack_name] = _current_attack.cooldown_beats
		attack_ended.emit(_current_attack)

		if _current_phase.attack_pattern == BossTypes.AttackPattern.SEQUENCE:
			_sequence_index += 1

	_current_attack = null
	_attack_progress = 0

	# Set time until next attack
	if _current_phase:
		_beats_until_attack = randi_range(
			_current_phase.min_attack_interval,
			_current_phase.max_attack_interval
		)
	else:
		_beats_until_attack = 4


## === Damage and Stagger ===

func take_damage(amount: float, stagger_amount: float = 0.0) -> void:
	if _current_state == BossTypes.BossState.DEFEATED:
		return

	# Apply defense from phase
	var defense := _stats.defense
	if _current_phase:
		defense += _current_phase.defense_bonus

	var actual := max(0, amount - defense)
	_stats.current_health = max(0, _stats.current_health - actual)

	health_changed.emit(_stats.current_health, _stats.max_health)

	# Check stagger
	if stagger_amount > 0 and _stats.add_stagger(stagger_amount):
		_begin_stagger()

	# Check death
	if _stats.current_health <= 0:
		_on_defeated()
		return

	# Check phase transition
	_check_phase_transition()


func _begin_stagger() -> void:
	if _current_state == BossTypes.BossState.STAGGERED:
		return

	_set_state(BossTypes.BossState.STAGGERED)
	_stagger_timer = _stats.stagger_duration

	# Cancel current attack
	if _current_attack:
		_end_attack()

	if animation_player:
		animation_player.play("stagger")

	stagger_started.emit()


func _end_stagger() -> void:
	_set_state(BossTypes.BossState.FIGHTING)
	stagger_ended.emit()


func _on_defeated() -> void:
	_set_state(BossTypes.BossState.DEFEATED)

	if _current_attack:
		_end_attack()

	if animation_player:
		animation_player.play("death")

	defeated.emit()


## === Public API ===

func start_fight() -> void:
	_set_state(BossTypes.BossState.INTRO)

	# Play intro
	if animation_player and phases.size() > 0 and phases[0].intro_animation:
		animation_player.play(phases[0].intro_animation)
		await animation_player.animation_finished

	_set_state(BossTypes.BossState.FIGHTING)


func get_health_percent() -> float:
	return _stats.get_health_percent()


func get_current_phase() -> int:
	return _phase_index + 1


func get_state() -> BossTypes.BossState:
	return _current_state


func is_attackable() -> bool:
	return _current_state == BossTypes.BossState.FIGHTING or _current_state == BossTypes.BossState.STAGGERED


func is_staggered() -> bool:
	return _current_state == BossTypes.BossState.STAGGERED


func set_target(new_target: Node3D) -> void:
	target = new_target
