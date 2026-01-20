## PlatformHazard - Moving or disappearing floor platform
class_name PlatformHazard
extends AnimatableBody3D


signal platform_activated()
signal platform_deactivated()
signal player_fell()


enum PlatformMode {
	MOVING,       # Moves along a path
	APPEARING,    # Appears and disappears
	CRUMBLING,    # Falls after stepped on
	BOUNCING,     # Launches player upward
}


@export var mode: PlatformMode = PlatformMode.MOVING
@export var damage_on_fall: float = 20.0

## Beat sync
@export_group("Beat Sync")
@export var sync_to_beat: bool = true
@export var active_on_quant: Quant.Type = Quant.Type.KICK
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Moving platform settings
@export_group("Moving")
@export var move_path: Path3D
@export var move_speed: float = 2.0
@export var move_on_beat: bool = true
@export var path_progress_per_beat: float = 0.25

## Appearing platform settings
@export_group("Appearing")
@export var visible_duration: float = 2.0
@export var hidden_duration: float = 1.0
@export var fade_time: float = 0.2

## Crumbling platform settings
@export_group("Crumbling")
@export var crumble_delay: float = 0.5
@export var respawn_time: float = 3.0
@export var shake_intensity: float = 0.1

## Bouncing platform settings
@export_group("Bouncing")
@export var bounce_force: float = 15.0

## Visual
@export_group("Visual")
@export var platform_mesh: MeshInstance3D
@export var warning_material: Material
@export var safe_material: Material
@export var danger_material: Material

## Internal
var _tick_handle: int = -1
var _path_follow: PathFollow3D
var _target_progress: float = 0.0
var _original_position: Vector3
var _is_solid: bool = true
var _crumble_timer: float = 0.0
var _respawn_timer: float = 0.0
var _player_on_platform: bool = false
var _collision_shape: CollisionShape3D


func _ready() -> void:
	_original_position = global_position

	# Find collision shape
	for child in get_children():
		if child is CollisionShape3D:
			_collision_shape = child
			break

	# Setup based on mode
	match mode:
		PlatformMode.MOVING:
			_setup_moving()
		PlatformMode.APPEARING:
			_setup_appearing()
		PlatformMode.CRUMBLING:
			_setup_crumbling()
		PlatformMode.BOUNCING:
			_setup_bouncing()

	# Subscribe to sequencer
	if sync_to_beat:
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)

	# Apply initial material
	_apply_material(safe_material)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_moving() -> void:
	if move_path:
		_path_follow = PathFollow3D.new()
		_path_follow.loop = true
		move_path.add_child(_path_follow)


func _setup_appearing() -> void:
	pass


func _setup_crumbling() -> void:
	pass


func _setup_bouncing() -> void:
	pass


func _process(delta: float) -> void:
	match mode:
		PlatformMode.MOVING:
			_process_moving(delta)
		PlatformMode.APPEARING:
			_process_appearing(delta)
		PlatformMode.CRUMBLING:
			_process_crumbling(delta)


func _process_moving(delta: float) -> void:
	if not _path_follow or not move_on_beat:
		return

	# Smooth movement to target progress
	_path_follow.progress_ratio = lerp(_path_follow.progress_ratio, _target_progress, delta * 5.0)
	global_position = _path_follow.global_position


func _process_appearing(delta: float) -> void:
	pass  # Handled by beat sync


func _process_crumbling(delta: float) -> void:
	if _crumble_timer > 0:
		_crumble_timer -= delta

		# Shake effect
		if platform_mesh:
			platform_mesh.position = Vector3(
				randf_range(-shake_intensity, shake_intensity),
				0,
				randf_range(-shake_intensity, shake_intensity)
			)

		if _crumble_timer <= 0:
			_do_crumble()

	if _respawn_timer > 0:
		_respawn_timer -= delta
		if _respawn_timer <= 0:
			_respawn()


func _on_tick(event: SequencerEvent) -> void:
	if event.quant.type != active_on_quant:
		return

	match mode:
		PlatformMode.MOVING:
			if move_on_beat:
				_target_progress = fmod(_target_progress + path_progress_per_beat, 1.0)
		PlatformMode.APPEARING:
			_toggle_visibility()


func _toggle_visibility() -> void:
	_is_solid = not _is_solid

	if _is_solid:
		_show_platform()
	else:
		_hide_platform()


func _show_platform() -> void:
	if _collision_shape:
		_collision_shape.disabled = false

	if platform_mesh:
		var tween := create_tween()
		tween.tween_property(platform_mesh, "scale", Vector3.ONE, fade_time)

	_apply_material(safe_material)
	platform_activated.emit()


func _hide_platform() -> void:
	_apply_material(danger_material)

	if platform_mesh:
		var tween := create_tween()
		tween.tween_property(platform_mesh, "scale", Vector3(1, 0.01, 1), fade_time)
		tween.tween_callback(_disable_collision)

	platform_deactivated.emit()


func _disable_collision() -> void:
	if _collision_shape:
		_collision_shape.disabled = true


func on_player_enter() -> void:
	_player_on_platform = true

	match mode:
		PlatformMode.CRUMBLING:
			if _crumble_timer <= 0 and _is_solid:
				_start_crumble()
		PlatformMode.BOUNCING:
			_do_bounce()


func on_player_exit() -> void:
	_player_on_platform = false


func _start_crumble() -> void:
	_crumble_timer = crumble_delay
	_apply_material(warning_material)


func _do_crumble() -> void:
	_is_solid = false

	if _collision_shape:
		_collision_shape.disabled = true

	if platform_mesh:
		var tween := create_tween()
		tween.tween_property(platform_mesh, "position:y", -5.0, 0.5)
		tween.parallel().tween_property(platform_mesh, "modulate:a", 0.0, 0.5)

	_respawn_timer = respawn_time
	platform_deactivated.emit()

	if _player_on_platform:
		player_fell.emit()


func _respawn() -> void:
	_is_solid = true

	if _collision_shape:
		_collision_shape.disabled = false

	if platform_mesh:
		platform_mesh.position = Vector3.ZERO
		platform_mesh.modulate.a = 1.0

	_apply_material(safe_material)
	platform_activated.emit()


func _do_bounce() -> void:
	# Find player and apply bounce
	var bodies := get_tree().get_nodes_in_group("player")
	for body in bodies:
		if body is CharacterBody3D:
			body.velocity.y = bounce_force


func _apply_material(mat: Material) -> void:
	if platform_mesh and mat:
		platform_mesh.material_override = mat


func is_solid() -> bool:
	return _is_solid
