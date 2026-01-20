## ProjectileHazard - Moving hazard that travels in a direction
class_name ProjectileHazard
extends HazardBase


@export_group("Projectile Settings")
@export var speed: float = 10.0
@export var direction: Vector3 = Vector3.FORWARD
@export var lifetime: float = 5.0
@export var destroy_on_hit: bool = true
@export var bounce: bool = false
@export var max_bounces: int = 3

## Homing
@export_group("Homing")
@export var homing: bool = false
@export var homing_strength: float = 2.0
@export var homing_range: float = 10.0

## Visual
@export var projectile_mesh: MeshInstance3D
@export var trail_particles: GPUParticles3D

## Internal
var _velocity: Vector3
var _lifetime_timer: float = 0.0
var _bounce_count: int = 0
var _homing_target: Node3D = null


func _ready() -> void:
	super._ready()
	hazard_type = HazardType.PROJECTILE

	_velocity = direction.normalized() * speed
	_lifetime_timer = lifetime

	# Start active immediately for projectiles
	current_state = HazardState.ACTIVE

	if trail_particles:
		trail_particles.emitting = true


func _physics_process(delta: float) -> void:
	if current_state != HazardState.ACTIVE:
		return

	# Lifetime
	_lifetime_timer -= delta
	if _lifetime_timer <= 0:
		_destroy()
		return

	# Homing behavior
	if homing and _homing_target:
		var to_target := _homing_target.global_position - global_position
		if to_target.length() < homing_range:
			var desired_direction := to_target.normalized()
			_velocity = _velocity.lerp(desired_direction * speed, homing_strength * delta)

	# Move
	var motion := _velocity * delta
	global_position += motion

	# Face direction of travel
	if _velocity.length() > 0.1:
		look_at(global_position + _velocity, Vector3.UP)


func _on_body_entered(body: Node3D) -> void:
	if current_state != HazardState.ACTIVE:
		return

	if body.is_in_group("player"):
		_deal_damage(body)
		if destroy_on_hit:
			_destroy()
	elif bounce and body.is_in_group("wall"):
		_bounce_off(body)


func _bounce_off(wall: Node3D) -> void:
	_bounce_count += 1
	if _bounce_count >= max_bounces:
		_destroy()
		return

	# Reflect velocity (simplified - assumes axis-aligned walls)
	# In a real implementation, use the collision normal
	_velocity = -_velocity


func _destroy() -> void:
	if trail_particles:
		trail_particles.emitting = false

	# Spawn hit effect
	_spawn_hit_effect()

	queue_free()


func _spawn_hit_effect() -> void:
	# Override in subclasses for custom effects
	pass


func set_target(target: Node3D) -> void:
	_homing_target = target


func set_direction(dir: Vector3) -> void:
	direction = dir.normalized()
	_velocity = direction * speed


func set_speed(new_speed: float) -> void:
	speed = new_speed
	_velocity = _velocity.normalized() * speed


## Factory method for spawning projectiles
static func spawn(parent: Node, position: Vector3, direction: Vector3, damage: float = 10.0) -> ProjectileHazard:
	var projectile := ProjectileHazard.new()
	projectile.position = position
	projectile.direction = direction
	projectile.damage = damage

	# Create simple mesh
	var mesh := MeshInstance3D.new()
	mesh.mesh = SphereMesh.new()
	mesh.mesh.radius = 0.2
	mesh.mesh.height = 0.4
	projectile.add_child(mesh)
	projectile.projectile_mesh = mesh

	# Create collision
	var collision := CollisionShape3D.new()
	collision.shape = SphereShape3D.new()
	collision.shape.radius = 0.2
	projectile.add_child(collision)

	parent.add_child(projectile)
	return projectile
