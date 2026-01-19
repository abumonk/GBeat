## BeatEnemy - Base enemy class with beat-synchronized combat
class_name BeatEnemy
extends CharacterBody3D

signal on_death()
signal on_damaged(damage: float, source: Node3D)
signal on_stunned(duration: float)
signal on_stun_ended()
signal health_changed(current: float, max_health: float)

## Health
@export var max_health: float = 100.0
var current_health: float

## Detection
@export var detection_range: float = 10.0
@export var detection_angle: float = 120.0  ## Degrees
@export var can_detect_behind: bool = false

## Stun
var is_stunned: bool = false
var stun_time_remaining: float = 0.0

## Visual feedback colors
@export var idle_color: Color = Color(0.8, 0.3, 0.3)
@export var telegraph_color: Color = Color.YELLOW
@export var attack_color: Color = Color.RED
@export var stunned_color: Color = Color.BLUE

## Components
@onready var combat_component: BeatEnemyCombatComponent = $BeatEnemyCombatComponent
@onready var mesh: MeshInstance3D = $Mesh

## Current target
var target: Node3D = null
var _material: StandardMaterial3D


func _ready() -> void:
	current_health = max_health

	_setup_material()

	if combat_component:
		combat_component.state_changed.connect(_on_combat_state_changed)


func _setup_material() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = idle_color
	if mesh:
		mesh.set_surface_override_material(0, _material)


func _process(delta: float) -> void:
	if is_stunned:
		stun_time_remaining -= delta
		if stun_time_remaining <= 0:
			_end_stun()

	_update_visuals()


## === Health System ===

func get_health_percent() -> float:
	return current_health / max_health


func is_alive() -> bool:
	return current_health > 0


func take_damage(amount: float, source: Node3D = null) -> void:
	if not is_alive():
		return

	current_health = max(0, current_health - amount)
	health_changed.emit(current_health, max_health)
	on_damaged.emit(amount, source)

	if current_health <= 0:
		_die()


func take_beat_damage(hit_result: CombatTypes.BeatHitResult) -> void:
	take_damage(hit_result.final_damage, hit_result.hit_actor)

	# Stun on critical hit
	if hit_result.is_critical:
		stun(0.5)


func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func _die() -> void:
	if combat_component:
		combat_component.set_state(BeatEnemyCombatComponent.State.DEAD)
	on_death.emit()
	queue_free()


## === Stun System ===

func stun(duration: float) -> void:
	if is_stunned:
		stun_time_remaining = max(stun_time_remaining, duration)
		return

	is_stunned = true
	stun_time_remaining = duration
	if combat_component:
		combat_component.set_state(BeatEnemyCombatComponent.State.STUNNED)
	on_stunned.emit(duration)


func _end_stun() -> void:
	is_stunned = false
	stun_time_remaining = 0.0
	if combat_component:
		combat_component.set_state(BeatEnemyCombatComponent.State.IDLE)
	on_stun_ended.emit()


func get_stun_time_remaining() -> float:
	return stun_time_remaining


## === Target Detection ===

func find_target(potential_targets: Array[Node3D]) -> Node3D:
	var best_target: Node3D = null
	var best_distance: float = INF

	for potential in potential_targets:
		if can_detect_actor(potential):
			var dist := global_position.distance_to(potential.global_position)
			if dist < best_distance:
				best_distance = dist
				best_target = potential

	target = best_target
	return target


func can_detect_actor(actor: Node3D) -> bool:
	if not actor:
		return false

	var to_actor := actor.global_position - global_position
	var distance := to_actor.length()

	# Range check
	if distance > detection_range:
		return false

	# Angle check
	var forward := -global_transform.basis.z
	var dot := forward.dot(to_actor.normalized())
	var angle := rad_to_deg(acos(clamp(dot, -1.0, 1.0)))

	if angle > detection_angle / 2.0 and not can_detect_behind:
		return false

	return true


## === Visual Feedback ===

func _update_visuals() -> void:
	if not _material or not combat_component:
		return

	var target_color: Color

	match combat_component.current_state:
		BeatEnemyCombatComponent.State.IDLE:
			target_color = idle_color
		BeatEnemyCombatComponent.State.TELEGRAPHING:
			target_color = telegraph_color
		BeatEnemyCombatComponent.State.ATTACKING:
			target_color = attack_color
		BeatEnemyCombatComponent.State.STUNNED:
			target_color = stunned_color
		BeatEnemyCombatComponent.State.DEAD:
			target_color = Color.BLACK
		_:
			target_color = idle_color

	_material.albedo_color = target_color


func _on_combat_state_changed(_old_state: BeatEnemyCombatComponent.State, _new_state: BeatEnemyCombatComponent.State) -> void:
	_update_visuals()


## === Setters ===

func set_target(new_target: Node3D) -> void:
	target = new_target


func clear_target() -> void:
	target = null
