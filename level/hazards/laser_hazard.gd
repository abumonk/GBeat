## LaserHazard - Rotating line damage hazard
class_name LaserHazard
extends HazardBase


@export_group("Laser Settings")
@export var laser_length: float = 10.0
@export var laser_width: float = 0.2
@export var rotation_speed: float = 45.0  # Degrees per second
@export var rotate_on_beat: bool = true
@export var rotation_per_beat: float = 90.0  # Degrees per beat

## Visual
@export var laser_mesh: MeshInstance3D
@export var laser_particles: GPUParticles3D
@export var warning_color: Color = Color(1.0, 0.3, 0.3, 0.5)
@export var active_color: Color = Color(1.0, 0.0, 0.0, 1.0)

## Raycast for hit detection
var _raycast: RayCast3D
var _target_rotation: float = 0.0
var _current_rotation: float = 0.0


func _ready() -> void:
	super._ready()
	hazard_type = HazardType.LASER

	# Create raycast for precise hit detection
	_raycast = RayCast3D.new()
	_raycast.target_position = Vector3(laser_length, 0, 0)
	_raycast.collision_mask = 1  # Player layer
	add_child(_raycast)

	# Setup laser visual
	if laser_mesh:
		laser_mesh.scale.x = laser_length
		laser_mesh.scale.y = laser_width
		laser_mesh.scale.z = laser_width
		_set_laser_color(Color.TRANSPARENT)


func _process(delta: float) -> void:
	super._process(delta)

	# Smooth rotation
	if not rotate_on_beat and current_state == HazardState.ACTIVE:
		_current_rotation += rotation_speed * delta
		rotation_degrees.y = _current_rotation
	elif abs(_current_rotation - _target_rotation) > 0.1:
		_current_rotation = lerp(_current_rotation, _target_rotation, delta * 10.0)
		rotation_degrees.y = _current_rotation

	# Active hit detection
	if current_state == HazardState.ACTIVE:
		_check_laser_hit()


func _on_tick(event: SequencerEvent) -> void:
	super._on_tick(event)

	# Rotate on beat
	if rotate_on_beat and current_state == HazardState.ACTIVE:
		if event.quant.type == Quant.Type.SNARE:
			_target_rotation += rotation_per_beat


func _on_warning_start() -> void:
	_set_laser_color(warning_color)

	if laser_particles:
		laser_particles.emitting = false


func _on_activate() -> void:
	_set_laser_color(active_color)

	if laser_particles:
		laser_particles.emitting = true


func _on_deactivate() -> void:
	_set_laser_color(Color.TRANSPARENT)

	if laser_particles:
		laser_particles.emitting = false


func _set_laser_color(color: Color) -> void:
	if not laser_mesh:
		return

	var mat := laser_mesh.get_surface_override_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		laser_mesh.set_surface_override_material(0, mat)

	if mat is StandardMaterial3D:
		mat.albedo_color = color
		mat.emission = Color(color.r, color.g, color.b)
		mat.emission_energy_multiplier = 2.0 if color.a > 0.5 else 0.5


func _check_laser_hit() -> void:
	_raycast.force_raycast_update()

	if _raycast.is_colliding():
		var collider := _raycast.get_collider()
		if collider and collider.is_in_group("player"):
			_deal_damage(collider)


func set_rotation_angle(degrees: float) -> void:
	_target_rotation = degrees
	_current_rotation = degrees
	rotation_degrees.y = degrees


func get_laser_direction() -> Vector3:
	return -global_transform.basis.z
