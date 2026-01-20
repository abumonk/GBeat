## LaserLight - Animated laser beam that sweeps and reacts to beats
class_name LaserLight
extends Node3D


## Configuration
@export var laser_color: Color = Color(1.0, 0.0, 0.5)
@export var beam_length: float = 20.0
@export var beam_width: float = 0.05
@export var sweep_speed: float = 1.0
@export var sweep_angle: float = 45.0  # Degrees
@export var beat_flash: bool = true

## Animation
@export var auto_sweep: bool = true
@export var sweep_pattern: SweepPattern = SweepPattern.SINE

enum SweepPattern {
	SINE,       # Smooth back and forth
	LINEAR,     # Linear sweep
	RANDOM,     # Random positions
	STEP,       # Step on beat
}

## Components
var _beam_mesh: MeshInstance3D
var _beam_material: StandardMaterial3D
var _light: SpotLight3D
var _tick_handle: int = -1
var _sweep_time: float = 0.0
var _target_angle: float = 0.0


func _ready() -> void:
	_create_beam()
	_create_light()
	_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	if auto_sweep:
		_update_sweep(delta)


func _create_beam() -> void:
	_beam_mesh = MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = beam_width
	mesh.bottom_radius = beam_width * 1.5
	mesh.height = beam_length
	_beam_mesh.mesh = mesh

	_beam_material = StandardMaterial3D.new()
	_beam_material.albedo_color = laser_color
	_beam_material.emission_enabled = true
	_beam_material.emission = laser_color
	_beam_material.emission_energy_multiplier = 2.0
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_material.albedo_color.a = 0.5
	_beam_mesh.material_override = _beam_material

	# Rotate so beam points forward
	_beam_mesh.rotation.x = PI / 2
	_beam_mesh.position.z = beam_length / 2

	add_child(_beam_mesh)


func _create_light() -> void:
	_light = SpotLight3D.new()
	_light.light_color = laser_color
	_light.light_energy = 1.0
	_light.spot_range = beam_length
	_light.spot_angle = 5.0
	add_child(_light)


func _update_sweep(delta: float) -> void:
	_sweep_time += delta * sweep_speed

	var angle: float
	match sweep_pattern:
		SweepPattern.SINE:
			angle = sin(_sweep_time) * deg_to_rad(sweep_angle)
		SweepPattern.LINEAR:
			var t := fmod(_sweep_time, 2.0)
			if t > 1.0:
				t = 2.0 - t
			angle = lerp(-deg_to_rad(sweep_angle), deg_to_rad(sweep_angle), t)
		SweepPattern.RANDOM:
			angle = _target_angle
		SweepPattern.STEP:
			angle = _target_angle

	rotation.y = angle


func _on_beat(event: SequencerEvent) -> void:
	if beat_flash:
		_flash(event.quant.value)

	# Update target for step/random patterns
	if sweep_pattern == SweepPattern.RANDOM:
		_target_angle = randf_range(-deg_to_rad(sweep_angle), deg_to_rad(sweep_angle))
	elif sweep_pattern == SweepPattern.STEP:
		_target_angle += deg_to_rad(sweep_angle / 2)
		if abs(_target_angle) > deg_to_rad(sweep_angle):
			_target_angle = -_target_angle


func _flash(intensity: float) -> void:
	var tween := create_tween()
	_beam_material.emission_energy_multiplier = 5.0 * intensity
	_light.light_energy = 3.0 * intensity
	tween.tween_property(_beam_material, "emission_energy_multiplier", 2.0, 0.1)
	tween.parallel().tween_property(_light, "light_energy", 1.0, 0.1)


func set_color(color: Color) -> void:
	laser_color = color
	if _beam_material:
		_beam_material.albedo_color = color
		_beam_material.albedo_color.a = 0.5
		_beam_material.emission = color
	if _light:
		_light.light_color = color
