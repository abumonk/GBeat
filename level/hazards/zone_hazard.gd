## ZoneHazard - Area damage over time hazard
class_name ZoneHazard
extends HazardBase


@export_group("Zone Settings")
@export var damage_per_second: float = 5.0
@export var damage_interval: float = 0.5
@export var zone_radius: float = 3.0
@export var zone_height: float = 2.0
@export var slow_effect: float = 0.5  # Movement speed multiplier while in zone
@export var apply_slow: bool = true

## Visual
@export_group("Visuals")
@export var zone_mesh: MeshInstance3D
@export var zone_particles: GPUParticles3D
@export var pulse_on_damage: bool = true
@export var warning_opacity: float = 0.3
@export var active_opacity: float = 0.6

## Internal
var _damage_timer: float = 0.0
var _entities_in_zone: Array[Node3D] = []
var _zone_material: StandardMaterial3D


func _ready() -> void:
	super._ready()
	hazard_type = HazardType.ZONE

	# Setup zone shape
	_setup_zone_collision()
	_setup_zone_visual()

	# Connect signals
	body_entered.connect(_on_zone_entered)
	body_exited.connect(_on_zone_exited)


func _setup_zone_collision() -> void:
	var collision := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = zone_radius
	shape.height = zone_height
	collision.shape = shape
	add_child(collision)


func _setup_zone_visual() -> void:
	if zone_mesh:
		zone_mesh.scale = Vector3(zone_radius * 2, zone_height, zone_radius * 2)

	# Create material for visual
	_zone_material = StandardMaterial3D.new()
	_zone_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_zone_material.albedo_color = Color(1.0, 0.0, 0.0, 0.0)
	_zone_material.emission_enabled = true
	_zone_material.emission = Color.RED
	_zone_material.emission_energy_multiplier = 0.5

	if zone_mesh:
		zone_mesh.material_override = _zone_material


func _process(delta: float) -> void:
	super._process(delta)

	if current_state == HazardState.ACTIVE:
		_damage_timer += delta
		if _damage_timer >= damage_interval:
			_damage_timer = 0.0
			_apply_zone_damage()


func _on_warning_start() -> void:
	_set_zone_opacity(warning_opacity)

	if zone_particles:
		zone_particles.amount_ratio = 0.3
		zone_particles.emitting = true


func _on_activate() -> void:
	_set_zone_opacity(active_opacity)
	_damage_timer = 0.0

	if zone_particles:
		zone_particles.amount_ratio = 1.0


func _on_deactivate() -> void:
	_set_zone_opacity(0.0)
	_remove_slow_from_all()

	if zone_particles:
		zone_particles.emitting = false


func _set_zone_opacity(opacity: float) -> void:
	if _zone_material:
		var color := _zone_material.albedo_color
		color.a = opacity
		_zone_material.albedo_color = color


func _on_zone_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_entities_in_zone.append(body)
		if current_state == HazardState.ACTIVE and apply_slow:
			_apply_slow(body)


func _on_zone_exited(body: Node3D) -> void:
	var idx := _entities_in_zone.find(body)
	if idx >= 0:
		_entities_in_zone.remove_at(idx)
		_remove_slow(body)


func _apply_zone_damage() -> void:
	var damage_amount := damage_per_second * damage_interval

	for entity in _entities_in_zone:
		if is_instance_valid(entity) and entity.is_in_group("player"):
			_deal_damage_amount(entity, damage_amount)

	if pulse_on_damage and not _entities_in_zone.is_empty():
		_pulse_visual()


func _deal_damage_amount(target: Node3D, amount: float) -> void:
	player_hit.emit(amount)

	if target.has_method("take_damage"):
		target.take_damage(amount)
	elif target.has_node("HealthComponent"):
		var health = target.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(amount)


func _apply_slow(entity: Node3D) -> void:
	if entity.has_method("apply_speed_modifier"):
		entity.apply_speed_modifier("zone_hazard", slow_effect)


func _remove_slow(entity: Node3D) -> void:
	if is_instance_valid(entity) and entity.has_method("remove_speed_modifier"):
		entity.remove_speed_modifier("zone_hazard")


func _remove_slow_from_all() -> void:
	for entity in _entities_in_zone:
		_remove_slow(entity)


func _pulse_visual() -> void:
	if not _zone_material:
		return

	var tween := create_tween()
	var current_opacity := _zone_material.albedo_color.a
	tween.tween_method(_set_zone_opacity, current_opacity, mini(current_opacity + 0.2, 0.8), 0.05)
	tween.tween_method(_set_zone_opacity, mini(current_opacity + 0.2, 0.8), current_opacity, 0.15)


func get_entities_in_zone() -> Array[Node3D]:
	return _entities_in_zone


func is_entity_in_zone(entity: Node3D) -> bool:
	return entity in _entities_in_zone
