## BeatEnemyAI - Simple state-based AI for enemies
class_name BeatEnemyAI
extends Node

enum AIState { IDLE, PURSUE, ATTACK, RETREAT, PATROL }

@export var enemy: BeatEnemy
@export var pursue_range: float = 8.0
@export var attack_range: float = 2.0
@export var retreat_health_threshold: float = 0.2
@export var move_speed: float = 3.0
@export var retreat_speed: float = 2.0
@export var patrol_speed: float = 1.5

var ai_state: AIState = AIState.IDLE
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0


func _process(delta: float) -> void:
	if not enemy or not enemy.is_alive():
		return

	if enemy.is_stunned:
		return

	_update_ai_state()
	_execute_ai_state(delta)


func _update_ai_state() -> void:
	# Check for retreat
	if enemy.get_health_percent() <= retreat_health_threshold:
		ai_state = AIState.RETREAT
		return

	# Check for target
	if not enemy.target:
		ai_state = AIState.PATROL if patrol_points.size() > 0 else AIState.IDLE
		return

	var distance := enemy.global_position.distance_to(enemy.target.global_position)

	if distance <= attack_range:
		ai_state = AIState.ATTACK
	elif distance <= pursue_range:
		ai_state = AIState.PURSUE
	else:
		ai_state = AIState.IDLE


func _execute_ai_state(delta: float) -> void:
	match ai_state:
		AIState.IDLE:
			_do_idle()
		AIState.PURSUE:
			_do_pursue(delta)
		AIState.ATTACK:
			_do_attack()
		AIState.RETREAT:
			_do_retreat(delta)
		AIState.PATROL:
			_do_patrol(delta)


func _do_idle() -> void:
	# Stand still, could add idle animation
	enemy.velocity.x = 0
	enemy.velocity.z = 0


func _do_pursue(delta: float) -> void:
	if not enemy.target:
		return

	var direction := (enemy.target.global_position - enemy.global_position).normalized()
	direction.y = 0

	enemy.velocity.x = direction.x * move_speed
	enemy.velocity.z = direction.z * move_speed

	# Face target
	_face_direction(direction)

	enemy.move_and_slide()


func _do_attack() -> void:
	# Combat component handles actual attack timing
	# Just face target
	if enemy.target:
		var direction := (enemy.target.global_position - enemy.global_position).normalized()
		direction.y = 0
		_face_direction(direction)

	enemy.velocity.x = 0
	enemy.velocity.z = 0


func _do_retreat(delta: float) -> void:
	if not enemy.target:
		return

	var direction := (enemy.global_position - enemy.target.global_position).normalized()
	direction.y = 0

	enemy.velocity.x = direction.x * retreat_speed
	enemy.velocity.z = direction.z * retreat_speed

	enemy.move_and_slide()


func _do_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target_point := patrol_points[current_patrol_index]
	var direction := (target_point - enemy.global_position).normalized()
	direction.y = 0

	enemy.velocity.x = direction.x * patrol_speed
	enemy.velocity.z = direction.z * patrol_speed

	_face_direction(direction)

	enemy.move_and_slide()

	# Check if reached point
	if enemy.global_position.distance_to(target_point) < 0.5:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()


func _face_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.001:
		return

	var target_angle := atan2(direction.x, direction.z)
	enemy.rotation.y = target_angle


## === Public API ===

func set_patrol_points(points: Array[Vector3]) -> void:
	patrol_points = points
	current_patrol_index = 0


func add_patrol_point(point: Vector3) -> void:
	patrol_points.append(point)


func clear_patrol_points() -> void:
	patrol_points.clear()
	current_patrol_index = 0


func get_current_state() -> AIState:
	return ai_state


func force_state(state: AIState) -> void:
	ai_state = state
