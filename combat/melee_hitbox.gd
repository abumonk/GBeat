## BeatMeleeHitboxComponent - Manages melee attack hitbox detection
class_name BeatMeleeHitboxComponent
extends Node3D

signal hit_detected(target: Node3D, result: CombatTypes.BeatHitResult)

## Configuration
@export var combat_component: BeatCombatComponent
@export var collision_mask: int = 2  ## Layer for enemies

## Hit tracking
var _hit_targets: Array[Node3D] = []
var _hitbox_active: bool = false

## Shape cast for hit detection
var _shape_cast: ShapeCast3D


func _ready() -> void:
	_setup_shape_cast()

	if combat_component:
		combat_component.attack_started.connect(_on_attack_started)
		combat_component.attack_ended.connect(_on_attack_ended)


func _setup_shape_cast() -> void:
	_shape_cast = ShapeCast3D.new()
	_shape_cast.enabled = false
	_shape_cast.collision_mask = collision_mask
	_shape_cast.max_results = 8

	var box := BoxShape3D.new()
	box.size = Vector3(1, 1, 1)  ## Default size, updated per attack
	_shape_cast.shape = box

	add_child(_shape_cast)


func _physics_process(_delta: float) -> void:
	if not _hitbox_active or not combat_component:
		return

	if not combat_component.is_in_active_frames():
		return

	_check_hits()


func _check_hits() -> void:
	_shape_cast.force_shapecast_update()

	if not _shape_cast.is_colliding():
		return

	for i in range(_shape_cast.get_collision_count()):
		var collider := _shape_cast.get_collider(i)

		if not collider is Node3D:
			continue

		if collider in _hit_targets:
			continue  ## Already hit this target

		# Register hit
		_hit_targets.append(collider)

		var impact_point := _shape_cast.get_collision_point(i)
		var result := combat_component.register_hit(collider, impact_point)

		if result:
			hit_detected.emit(collider, result)
			_apply_hit_to_target(collider, result)


func _apply_hit_to_target(target: Node3D, result: CombatTypes.BeatHitResult) -> void:
	# Apply damage if target has take_damage method
	if target.has_method("take_damage"):
		target.take_damage(result.final_damage, result.hit_actor)
	elif target.has_method("take_beat_damage"):
		target.take_beat_damage(result)

	# Apply knockback if target is CharacterBody3D
	if target is CharacterBody3D:
		var step := combat_component.get_current_step()
		if step:
			var knockback_dir := (target.global_position - global_position).normalized()
			knockback_dir.y = 0.2  ## Slight upward
			target.velocity += knockback_dir * step.knockback_force


func _on_attack_started(step: CombatStepDefinition) -> void:
	_activate_hitbox(step)


func _on_attack_ended(_step: CombatStepDefinition) -> void:
	_deactivate_hitbox()


func _activate_hitbox(step: CombatStepDefinition) -> void:
	_hit_targets.clear()
	_hitbox_active = true

	# Update shape size
	var box := _shape_cast.shape as BoxShape3D
	if box:
		box.size = step.hitbox_half_extent * 2.0

	# Update position
	_shape_cast.position = step.hitbox_offset
	_shape_cast.target_position = Vector3(0, 0, step.hitbox_half_extent.z)
	_shape_cast.enabled = true


func _deactivate_hitbox() -> void:
	_hitbox_active = false
	_shape_cast.enabled = false
	_hit_targets.clear()


## === Public API ===

func is_active() -> bool:
	return _hitbox_active


func get_hit_count() -> int:
	return _hit_targets.size()


func clear_hit_targets() -> void:
	_hit_targets.clear()
