## BossTelegraph - Visual telegraph for boss attacks
class_name BossTelegraph
extends Node3D


signal telegraph_started()
signal telegraph_warning()  ## Final warning before attack
signal telegraph_ended()


## Configuration
@export var telegraph_duration: float = 1.0
@export var warning_time: float = 0.25  ## Time before attack for final warning
@export var pulse_on_beat: bool = true

## Visual elements
@export var indicator_mesh: MeshInstance3D
@export var area_indicator: MeshInstance3D
@export var target_marker: Node3D

## Colors
@export var start_color: Color = Color(1.0, 0.8, 0.0, 0.3)  ## Yellow
@export var warning_color: Color = Color(1.0, 0.2, 0.0, 0.6)  ## Red
@export var pulse_color: Color = Color(1.0, 1.0, 1.0, 0.8)

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## State
var _elapsed: float = 0.0
var _is_active: bool = false
var _material: StandardMaterial3D = null
var _tick_handle: int = -1


func _ready() -> void:
	visible = false
	_setup_material()

	if pulse_on_beat:
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_material() -> void:
	if indicator_mesh:
		_material = StandardMaterial3D.new()
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_material.albedo_color = start_color
		indicator_mesh.material_override = _material


func _process(delta: float) -> void:
	if not _is_active:
		return

	_elapsed += delta

	# Update color based on progress
	var progress := _elapsed / telegraph_duration
	var in_warning := _elapsed >= telegraph_duration - warning_time

	if _material:
		if in_warning:
			_material.albedo_color = warning_color
		else:
			_material.albedo_color = start_color.lerp(warning_color, progress)

	# Scale up as attack approaches
	if indicator_mesh:
		var scale_val := 1.0 + progress * 0.2
		indicator_mesh.scale = Vector3.ONE * scale_val

	# Check for warning
	if in_warning and _elapsed - delta < telegraph_duration - warning_time:
		telegraph_warning.emit()

	# Check for end
	if _elapsed >= telegraph_duration:
		stop()


func _on_tick(_event: SequencerEvent) -> void:
	if not _is_active:
		return

	# Pulse effect
	if _material:
		var current_color := _material.albedo_color
		_material.albedo_color = pulse_color

		var tween := create_tween()
		tween.tween_property(_material, "albedo_color", current_color, 0.1)


## === Public API ===

func start(duration: float = -1.0, target_position: Vector3 = Vector3.ZERO) -> void:
	if duration > 0:
		telegraph_duration = duration

	_elapsed = 0.0
	_is_active = true
	visible = true

	if target_position != Vector3.ZERO:
		global_position = target_position

	if _material:
		_material.albedo_color = start_color

	telegraph_started.emit()


func stop() -> void:
	_is_active = false
	visible = false
	telegraph_ended.emit()


func set_radius(radius: float) -> void:
	if area_indicator:
		area_indicator.scale = Vector3(radius, 1.0, radius)


func set_target_position(pos: Vector3) -> void:
	if target_marker:
		target_marker.global_position = pos


func is_active() -> bool:
	return _is_active


func get_progress() -> float:
	return _elapsed / telegraph_duration if telegraph_duration > 0 else 0.0
