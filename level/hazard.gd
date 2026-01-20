## Hazard - Beat-synchronized environmental hazard
class_name Hazard
extends Node3D


signal triggered()
signal damage_dealt(target: Node3D, amount: float)


## Configuration
@export var hazard_type: String = "floor_shock"
@export var damage: float = 10.0
@export var knockback_force: float = 5.0
@export var activation_duration: float = 0.5
@export var cooldown: float = 2.0

## Beat Sync
@export var beat_sync: bool = true
@export var trigger_on_beat: int = 0  # 0 = every beat, 4 = every 4th, etc.
@export var trigger_quant_type: Quant.Type = Quant.Type.KICK

## Visual
@export var warning_duration: float = 0.5
@export var warning_color: Color = Color(1.0, 1.0, 0.0, 0.5)
@export var active_color: Color = Color(1.0, 0.0, 0.0, 0.8)
@export var idle_color: Color = Color(0.2, 0.2, 0.2, 0.3)

## State
var _is_active: bool = false
var _is_warning: bool = false
var _on_cooldown: bool = false
var _tick_handle: int = -1
var _beat_counter: int = 0
var _hit_targets: Array[Node3D] = []

## Components
var _collision_area: Area3D
var _visual_mesh: MeshInstance3D
var _material: StandardMaterial3D


func _ready() -> void:
	_setup_collision()
	_setup_visual()

	if beat_sync:
		_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_collision() -> void:
	_collision_area = Area3D.new()
	_collision_area.collision_layer = 0
	_collision_area.collision_mask = 3  # Player and enemies
	_collision_area.monitoring = false

	var collision_shape := CollisionShape3D.new()
	collision_shape.shape = BoxShape3D.new()
	_collision_area.add_child(collision_shape)

	_collision_area.body_entered.connect(_on_body_entered)
	add_child(_collision_area)


func _setup_visual() -> void:
	_visual_mesh = MeshInstance3D.new()
	_visual_mesh.mesh = BoxMesh.new()

	_material = StandardMaterial3D.new()
	_material.albedo_color = idle_color
	_material.emission_enabled = true
	_material.emission = idle_color
	_material.emission_energy_multiplier = 0.0
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_visual_mesh.material_override = _material

	add_child(_visual_mesh)


func _on_beat(event: SequencerEvent) -> void:
	if event.quant.type != trigger_quant_type:
		return

	_beat_counter += 1

	if trigger_on_beat > 0 and _beat_counter % trigger_on_beat != 0:
		return

	if not _on_cooldown:
		activate()


func _on_body_entered(body: Node3D) -> void:
	if _is_active and body not in _hit_targets:
		_hit_targets.append(body)
		_deal_damage(body)


func _deal_damage(target: Node3D) -> void:
	if target.has_method("take_damage"):
		target.take_damage(damage, self)
		damage_dealt.emit(target, damage)

	# Apply knockback
	if knockback_force > 0 and target.has_method("apply_knockback"):
		var direction := (target.global_position - global_position).normalized()
		direction.y = 0.3  # Slight upward
		target.apply_knockback(direction * knockback_force)


## Activate the hazard
func activate() -> void:
	if _is_active or _on_cooldown:
		return

	# Warning phase
	_start_warning()

	await get_tree().create_timer(warning_duration).timeout

	# Active phase
	_become_active()

	await get_tree().create_timer(activation_duration).timeout

	# Deactivate
	_become_inactive()

	# Cooldown
	_on_cooldown = true
	await get_tree().create_timer(cooldown).timeout
	_on_cooldown = false


func _start_warning() -> void:
	_is_warning = true
	triggered.emit()

	# Warning visual
	var tween := create_tween()
	tween.set_loops(int(warning_duration / 0.1))
	tween.tween_property(_material, "emission", warning_color, 0.05)
	tween.tween_property(_material, "emission", idle_color, 0.05)


func _become_active() -> void:
	_is_warning = false
	_is_active = true
	_hit_targets.clear()
	_collision_area.monitoring = true

	# Active visual
	_material.emission = active_color
	_material.emission_energy_multiplier = 3.0


func _become_inactive() -> void:
	_is_active = false
	_collision_area.monitoring = false

	# Return to idle
	var tween := create_tween()
	tween.tween_property(_material, "emission", idle_color, 0.2)
	tween.tween_property(_material, "emission_energy_multiplier", 0.0, 0.2)


## Force deactivate
func deactivate() -> void:
	_is_active = false
	_is_warning = false
	_collision_area.monitoring = false
	_material.emission = idle_color
	_material.emission_energy_multiplier = 0.0


## Set hazard size
func set_size(new_size: Vector3) -> void:
	if _visual_mesh and _visual_mesh.mesh is BoxMesh:
		(_visual_mesh.mesh as BoxMesh).size = new_size

	if _collision_area:
		var shape := _collision_area.get_child(0) as CollisionShape3D
		if shape and shape.shape is BoxShape3D:
			(shape.shape as BoxShape3D).size = new_size


## Check if hazard is currently dangerous
func is_dangerous() -> bool:
	return _is_active
