## SpeakerProp - Decorative speaker that reacts to beats
class_name SpeakerProp
extends Node3D


## Configuration
@export var base_color: Color = Color(0.1, 0.1, 0.1)
@export var cone_color: Color = Color(0.2, 0.2, 0.25)
@export var glow_color: Color = Color(0.0, 0.8, 1.0)
@export var pulse_scale: float = 0.1
@export var speaker_size: Vector3 = Vector3(1.0, 1.5, 0.5)

## Components
var _body_mesh: MeshInstance3D
var _cone_mesh: MeshInstance3D
var _glow_mesh: MeshInstance3D
var _cone_material: StandardMaterial3D
var _tick_handle: int = -1


func _ready() -> void:
	_create_meshes()
	_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _create_meshes() -> void:
	# Speaker body (cabinet)
	_body_mesh = MeshInstance3D.new()
	var body := BoxMesh.new()
	body.size = speaker_size
	_body_mesh.mesh = body

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = base_color
	_body_mesh.material_override = body_mat
	add_child(_body_mesh)

	# Speaker cone
	_cone_mesh = MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = speaker_size.x * 0.35
	cone.bottom_radius = speaker_size.x * 0.4
	cone.height = 0.1
	_cone_mesh.mesh = cone
	_cone_mesh.rotation.x = PI / 2
	_cone_mesh.position.z = speaker_size.z / 2 + 0.05

	_cone_material = StandardMaterial3D.new()
	_cone_material.albedo_color = cone_color
	_cone_mesh.material_override = _cone_material
	add_child(_cone_mesh)

	# Glow ring
	_glow_mesh = MeshInstance3D.new()
	var glow := TorusMesh.new()
	glow.inner_radius = speaker_size.x * 0.32
	glow.outer_radius = speaker_size.x * 0.38
	_glow_mesh.mesh = glow
	_glow_mesh.rotation.x = PI / 2
	_glow_mesh.position.z = speaker_size.z / 2 + 0.06

	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = glow_color
	glow_mat.emission_enabled = true
	glow_mat.emission = glow_color
	glow_mat.emission_energy_multiplier = 0.0
	_glow_mesh.material_override = glow_mat
	add_child(_glow_mesh)


func _on_beat(event: SequencerEvent) -> void:
	var intensity := event.quant.value

	# Pulse cone outward
	var tween := create_tween()
	_cone_mesh.position.z = speaker_size.z / 2 + 0.05 + pulse_scale * intensity
	tween.tween_property(_cone_mesh, "position:z", speaker_size.z / 2 + 0.05, 0.1)

	# Pulse glow
	var glow_mat := _glow_mesh.material_override as StandardMaterial3D
	glow_mat.emission_energy_multiplier = 3.0 * intensity
	tween.parallel().tween_property(glow_mat, "emission_energy_multiplier", 0.0, 0.15)


func set_glow_color(color: Color) -> void:
	glow_color = color
	if _glow_mesh:
		var mat := _glow_mesh.material_override as StandardMaterial3D
		mat.emission = color
