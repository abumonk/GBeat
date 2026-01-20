## CrusherHazard - Timed crushing hazard that smashes down
class_name CrusherHazard
extends HazardBase


@export_group("Crusher Settings")
@export var crush_height: float = 3.0
@export var retracted_height: float = 0.3
@export var crush_speed: float = 20.0
@export var retract_speed: float = 3.0
@export var hold_time_up: float = 1.0
@export var hold_time_down: float = 0.2
@export var instant_kill: bool = false

## Visual
@export var crusher_mesh: MeshInstance3D
@export var impact_particles: GPUParticles3D
@export var warning_light: OmniLight3D

## Internal
var _start_position: Vector3
var _crush_position: Vector3
var _is_crushing: bool = false
var _hold_timer: float = 0.0
var _movement_tween: Tween


func _ready() -> void:
	super._ready()
	hazard_type = HazardType.CRUSHER

	if crusher_mesh:
		_start_position = crusher_mesh.position
		_crush_position = Vector3(_start_position.x, retracted_height, _start_position.z)
		crusher_mesh.position.y = crush_height

	if warning_light:
		warning_light.light_energy = 0.0


func _process(delta: float) -> void:
	super._process(delta)

	if _hold_timer > 0:
		_hold_timer -= delta
		if _hold_timer <= 0:
			if _is_crushing:
				_retract()
			else:
				_crush()


func _on_warning_start() -> void:
	# Flash warning light
	if warning_light:
		var tween := create_tween()
		tween.set_loops(int(warning_beats * 2))
		tween.tween_property(warning_light, "light_energy", 2.0, 0.1)
		tween.tween_property(warning_light, "light_energy", 0.0, 0.1)

	# Shake slightly
	if crusher_mesh:
		var tween := create_tween()
		tween.set_loops(int(warning_beats * 4))
		tween.tween_property(crusher_mesh, "position:x", _start_position.x + 0.05, 0.05)
		tween.tween_property(crusher_mesh, "position:x", _start_position.x - 0.05, 0.05)


func _on_activate() -> void:
	_crush()


func _on_deactivate() -> void:
	_hold_timer = 0
	_retract()


func _crush() -> void:
	_is_crushing = true

	if _movement_tween:
		_movement_tween.kill()

	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_QUAD)
	_movement_tween.set_ease(Tween.EASE_IN)

	var crush_time := (crush_height - retracted_height) / crush_speed
	_movement_tween.tween_property(crusher_mesh, "position:y", retracted_height, crush_time)
	_movement_tween.tween_callback(_on_crush_impact)


func _on_crush_impact() -> void:
	# Spawn impact effect
	if impact_particles:
		impact_particles.global_position = crusher_mesh.global_position
		impact_particles.global_position.y = retracted_height
		impact_particles.restart()

	# Screen shake (if available)
	_trigger_screen_shake()

	# Hold at bottom
	_hold_timer = hold_time_down


func _retract() -> void:
	_is_crushing = false

	if _movement_tween:
		_movement_tween.kill()

	_movement_tween = create_tween()
	_movement_tween.set_trans(Tween.TRANS_SINE)
	_movement_tween.set_ease(Tween.EASE_OUT)

	var retract_time := (crush_height - retracted_height) / retract_speed
	_movement_tween.tween_property(crusher_mesh, "position:y", crush_height, retract_time)
	_movement_tween.tween_callback(_on_retract_complete)


func _on_retract_complete() -> void:
	if current_state == HazardState.ACTIVE:
		_hold_timer = hold_time_up


func _on_body_entered(body: Node3D) -> void:
	if not _is_crushing:
		return

	if body.is_in_group("player"):
		if instant_kill:
			_instant_kill(body)
		else:
			_deal_damage(body)


func _instant_kill(target: Node3D) -> void:
	player_hit.emit(9999.0)

	if target.has_method("die"):
		target.die()
	elif target.has_node("HealthComponent"):
		var health = target.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(9999.0)


func _trigger_screen_shake() -> void:
	# Try to find camera effects component
	var cameras := get_tree().get_nodes_in_group("camera")
	for camera in cameras:
		if camera.has_method("shake"):
			camera.shake(0.3, 10.0)
			return

		for child in camera.get_children():
			if child.has_method("shake"):
				child.shake(0.3, 10.0)
				return


func get_crusher_position() -> float:
	if crusher_mesh:
		return crusher_mesh.position.y
	return crush_height


func is_at_bottom() -> bool:
	return crusher_mesh and crusher_mesh.position.y <= retracted_height + 0.1


func is_crushing() -> bool:
	return _is_crushing
