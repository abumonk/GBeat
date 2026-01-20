## BeatReactiveProp - Generic prop that reacts to beats
class_name BeatReactiveProp
extends Node3D


signal reacted_to_beat(quant_type: Quant.Type)


enum ReactionType {
	SCALE_PULSE,    # Grow and shrink
	ROTATION,       # Spin on beat
	COLOR_FLASH,    # Material color change
	EMISSION,       # Glow brighter
	TRANSLATION,    # Move up/down
	SPAWN_PARTICLE, # Emit particles
}


@export var react_to_quant: Quant.Type = Quant.Type.KICK
@export var reaction_type: ReactionType = ReactionType.SCALE_PULSE
@export var intensity: float = 1.0
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Reaction settings
@export_group("Scale Pulse")
@export var pulse_scale: float = 1.2
@export var pulse_duration: float = 0.15

@export_group("Rotation")
@export var rotation_amount: float = 90.0
@export var rotation_axis: Vector3 = Vector3.UP
@export var rotation_duration: float = 0.2

@export_group("Color Flash")
@export var flash_color: Color = Color.WHITE
@export var flash_duration: float = 0.1

@export_group("Emission")
@export var emission_boost: float = 2.0
@export var emission_duration: float = 0.15

@export_group("Translation")
@export var translation_offset: Vector3 = Vector3(0, 0.5, 0)
@export var translation_duration: float = 0.2

@export_group("Particles")
@export var particle_system: GPUParticles3D
@export var particle_burst_amount: int = 10

## Internal
var _tick_handle: int = -1
var _mesh: MeshInstance3D
var _original_scale: Vector3
var _original_position: Vector3
var _original_rotation: Vector3
var _original_material: Material
var _reaction_tween: Tween


func _ready() -> void:
	_original_scale = scale
	_original_position = position
	_original_rotation = rotation

	# Find mesh child
	for child in get_children():
		if child is MeshInstance3D:
			_mesh = child
			if _mesh.get_surface_override_material(0):
				_original_material = _mesh.get_surface_override_material(0).duplicate()
			elif _mesh.mesh and _mesh.mesh.surface_get_material(0):
				_original_material = _mesh.mesh.surface_get_material(0).duplicate()
			break

	# Subscribe to sequencer
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _on_tick(event: SequencerEvent) -> void:
	if event.quant.type == react_to_quant:
		_react(event.quant.value * intensity)


func _react(reaction_intensity: float) -> void:
	if _reaction_tween:
		_reaction_tween.kill()

	match reaction_type:
		ReactionType.SCALE_PULSE:
			_do_scale_pulse(reaction_intensity)
		ReactionType.ROTATION:
			_do_rotation(reaction_intensity)
		ReactionType.COLOR_FLASH:
			_do_color_flash(reaction_intensity)
		ReactionType.EMISSION:
			_do_emission(reaction_intensity)
		ReactionType.TRANSLATION:
			_do_translation(reaction_intensity)
		ReactionType.SPAWN_PARTICLE:
			_do_spawn_particle(reaction_intensity)

	reacted_to_beat.emit(react_to_quant)


func _do_scale_pulse(intensity_mult: float) -> void:
	var target_scale := _original_scale * (1.0 + (pulse_scale - 1.0) * intensity_mult)

	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_ELASTIC)
	_reaction_tween.set_ease(Tween.EASE_OUT)

	_reaction_tween.tween_property(self, "scale", target_scale, pulse_duration * 0.3)
	_reaction_tween.tween_property(self, "scale", _original_scale, pulse_duration * 0.7)


func _do_rotation(intensity_mult: float) -> void:
	var rotation_rad := deg_to_rad(rotation_amount * intensity_mult)
	var target_rotation := _original_rotation + rotation_axis.normalized() * rotation_rad

	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_BACK)
	_reaction_tween.set_ease(Tween.EASE_OUT)

	_reaction_tween.tween_property(self, "rotation", target_rotation, rotation_duration)

	# Update original for continuous rotation
	_original_rotation = target_rotation


func _do_color_flash(intensity_mult: float) -> void:
	if not _mesh:
		return

	var mat := _get_or_create_material()
	if mat is StandardMaterial3D:
		var original_color: Color = mat.albedo_color
		var target_color := original_color.lerp(flash_color, intensity_mult)

		_reaction_tween = create_tween()
		_reaction_tween.tween_property(mat, "albedo_color", target_color, flash_duration * 0.2)
		_reaction_tween.tween_property(mat, "albedo_color", original_color, flash_duration * 0.8)


func _do_emission(intensity_mult: float) -> void:
	if not _mesh:
		return

	var mat := _get_or_create_material()
	if mat is StandardMaterial3D:
		mat.emission_enabled = true
		var original_energy: float = mat.emission_energy_multiplier
		var target_energy := original_energy + emission_boost * intensity_mult

		_reaction_tween = create_tween()
		_reaction_tween.tween_property(mat, "emission_energy_multiplier", target_energy, emission_duration * 0.2)
		_reaction_tween.tween_property(mat, "emission_energy_multiplier", original_energy, emission_duration * 0.8)


func _do_translation(intensity_mult: float) -> void:
	var target_pos := _original_position + translation_offset * intensity_mult

	_reaction_tween = create_tween()
	_reaction_tween.set_trans(Tween.TRANS_SINE)
	_reaction_tween.set_ease(Tween.EASE_OUT)

	_reaction_tween.tween_property(self, "position", target_pos, translation_duration * 0.3)
	_reaction_tween.tween_property(self, "position", _original_position, translation_duration * 0.7)


func _do_spawn_particle(intensity_mult: float) -> void:
	if particle_system:
		particle_system.amount = int(particle_burst_amount * intensity_mult)
		particle_system.restart()
		particle_system.emitting = true


func _get_or_create_material() -> Material:
	if _mesh.get_surface_override_material(0):
		return _mesh.get_surface_override_material(0)

	# Create a new material from the mesh
	var mat := StandardMaterial3D.new()
	if _original_material and _original_material is StandardMaterial3D:
		mat.albedo_color = _original_material.albedo_color
		mat.metallic = _original_material.metallic
		mat.roughness = _original_material.roughness

	_mesh.set_surface_override_material(0, mat)
	return mat


## Public API

func set_reaction_type(type: ReactionType) -> void:
	reaction_type = type


func set_quant_type(quant: Quant.Type) -> void:
	react_to_quant = quant


func set_intensity(new_intensity: float) -> void:
	intensity = new_intensity


func trigger_reaction(custom_intensity: float = -1.0) -> void:
	var use_intensity := custom_intensity if custom_intensity >= 0 else intensity
	_react(use_intensity)


func reset_to_original() -> void:
	if _reaction_tween:
		_reaction_tween.kill()

	scale = _original_scale
	position = _original_position
	rotation = _original_rotation
