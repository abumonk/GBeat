## Player - Main player character class
class_name Player
extends CharacterBody3D

signal health_changed(current: float, maximum: float)
signal player_died()
signal attack_performed(timing_rating: CombatTypes.TimingRating)
signal combo_changed(combo_count: int, multiplier: float)

## Health
@export var max_health: float = 100.0
var current_health: float

## Components
@onready var controller: PlayerController = $PlayerController
@onready var movement: BeatMovementComponent = $BeatMovementComponent
@onready var combat: BeatCombatComponent = $BeatCombatComponent
@onready var hitbox: BeatMeleeHitboxComponent = $BeatMeleeHitboxComponent
@onready var mesh: MeshInstance3D = $Mesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer

## Visual feedback
var _base_color: Color = Color(0.2, 0.6, 0.9)
var _damage_flash_time: float = 0.0
var _attack_flash_time: float = 0.0


func _ready() -> void:
	current_health = max_health

	# Setup material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _base_color
	mesh.set_surface_override_material(0, mat)

	# Setup combat connections
	if combat:
		combat.character = self
		combat.hitbox_component = hitbox
		combat.timing_rated.connect(_on_timing_rated)
		combat.combo_changed.connect(_on_combo_changed)

	if hitbox:
		hitbox.combat_component = combat


func _process(delta: float) -> void:
	_handle_combat_input()
	_update_visuals(delta)


func _handle_combat_input() -> void:
	if not controller or not combat:
		return

	if controller.is_light_attack_pressed():
		combat.try_action(CombatTypes.ActionType.LIGHT_ATTACK)
	elif controller.is_heavy_attack_pressed():
		combat.try_action(CombatTypes.ActionType.HEAVY_ATTACK)


func _update_visuals(delta: float) -> void:
	# Damage flash decay
	if _damage_flash_time > 0:
		_damage_flash_time -= delta * 5.0
		_damage_flash_time = max(0, _damage_flash_time)

	# Attack flash decay
	if _attack_flash_time > 0:
		_attack_flash_time -= delta * 8.0
		_attack_flash_time = max(0, _attack_flash_time)

	var mat := mesh.get_surface_override_material(0) as StandardMaterial3D
	if mat:
		if _damage_flash_time > 0:
			mat.albedo_color = _base_color.lerp(Color.RED, _damage_flash_time)
		elif _attack_flash_time > 0:
			mat.albedo_color = _base_color.lerp(Color.WHITE, _attack_flash_time)
		else:
			mat.albedo_color = _base_color


## === Health System ===

func take_damage(amount: float, _source: Node = null) -> void:
	if current_health <= 0:
		return

	current_health = max(0, current_health - amount)
	_damage_flash_time = 1.0

	health_changed.emit(current_health, max_health)

	if current_health <= 0:
		_die()


func heal(amount: float) -> void:
	current_health = min(max_health, current_health + amount)
	health_changed.emit(current_health, max_health)


func _die() -> void:
	player_died.emit()
	# Could trigger death animation, game over, etc.


func get_health_percent() -> float:
	return current_health / max_health


func is_alive() -> bool:
	return current_health > 0


## === Combat Callbacks ===

func _on_timing_rated(rating: CombatTypes.TimingRating) -> void:
	_attack_flash_time = 0.5
	attack_performed.emit(rating)


func _on_combo_changed(count: int, multiplier: float) -> void:
	combo_changed.emit(count, multiplier)


## === Getters for Components ===

func get_controller() -> PlayerController:
	return controller


func get_movement() -> BeatMovementComponent:
	return movement


func get_combat() -> BeatCombatComponent:
	return combat
