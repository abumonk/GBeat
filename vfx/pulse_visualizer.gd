## PulseVisualizer - Visualizes beat pulses in 3D space
class_name PulseVisualizer
extends Node3D


signal pulse_started()
signal pulse_completed()


## Configuration
@export var pulse_mesh: Mesh
@export var pulse_material: ShaderMaterial
@export var base_scale: float = 1.0
@export var pulse_scale: float = 3.0
@export var pulse_duration: float = 0.3
@export var fade_with_scale: bool = true

## Colors
@export var pulse_color: Color = Color(1.0, 0.2, 0.6)
@export var emission_energy: float = 3.0

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
@export var trigger_quant_type: Quant.Type = Quant.Type.KICK

## Components
var _mesh_instance: MeshInstance3D
var _material: StandardMaterial3D
var _tick_handle: int = -1

## State
var _is_pulsing: bool = false


func _ready() -> void:
	_create_visualizer()
	_tick_handle = Sequencer.subscribe(sequencer_deck, trigger_quant_type, _on_trigger_quant)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _create_visualizer() -> void:
	_mesh_instance = MeshInstance3D.new()

	# Use provided mesh or create default ring
	if pulse_mesh:
		_mesh_instance.mesh = pulse_mesh
	else:
		var torus := TorusMesh.new()
		torus.inner_radius = 0.8
		torus.outer_radius = 1.0
		torus.rings = 32
		torus.ring_segments = 16
		_mesh_instance.mesh = torus

	# Use provided material or create default
	if pulse_material:
		_mesh_instance.material_override = pulse_material
	else:
		_material = StandardMaterial3D.new()
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.albedo_color = Color(pulse_color.r, pulse_color.g, pulse_color.b, 0.0)
		_material.emission_enabled = true
		_material.emission = pulse_color
		_material.emission_energy_multiplier = 0.0
		_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_mesh_instance.material_override = _material

	_mesh_instance.scale = Vector3.ONE * base_scale
	add_child(_mesh_instance)


func _on_trigger_quant(event: SequencerEvent) -> void:
	trigger_pulse(event.quant.value)


## Trigger a pulse effect
func trigger_pulse(intensity: float = 1.0) -> void:
	if _is_pulsing:
		return

	_is_pulsing = true
	pulse_started.emit()

	var target_scale := base_scale + (pulse_scale - base_scale) * intensity

	# Reset
	_mesh_instance.scale = Vector3.ONE * base_scale
	if _material:
		_material.albedo_color.a = 1.0
		_material.emission_energy_multiplier = emission_energy * intensity

	# Animate
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	# Scale up
	tween.tween_property(_mesh_instance, "scale", Vector3.ONE * target_scale, pulse_duration)

	# Fade out
	if _material and fade_with_scale:
		tween.parallel().tween_property(_material, "albedo_color:a", 0.0, pulse_duration)
		tween.parallel().tween_property(_material, "emission_energy_multiplier", 0.0, pulse_duration)

	tween.tween_callback(_on_pulse_complete)


func _on_pulse_complete() -> void:
	_is_pulsing = false
	_mesh_instance.scale = Vector3.ONE * base_scale
	pulse_completed.emit()


## Set pulse color
func set_pulse_color(color: Color) -> void:
	pulse_color = color
	if _material:
		_material.emission = color


## Check if currently pulsing
func is_pulsing() -> bool:
	return _is_pulsing


## Manually trigger pulse at a position
func pulse_at(world_position: Vector3, intensity: float = 1.0) -> void:
	global_position = world_position
	trigger_pulse(intensity)
