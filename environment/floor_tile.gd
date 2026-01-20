## FloorTile - Individual floor tile with beat reactions
class_name FloorTile
extends Node3D


signal tile_activated(tile: FloorTile)
signal tile_pulsed(intensity: float)


## Configuration
@export var base_color: Color = Color(0.1, 0.1, 0.15)
@export var active_color: Color = Color(1.0, 0.2, 0.4)
@export var emission_energy: float = 2.0
@export var pulse_duration: float = 0.2

## Grid position
var grid_position: Vector2i = Vector2i.ZERO

## Components
var mesh_instance: MeshInstance3D
var material: StandardMaterial3D

## State
var _is_active: bool = false
var _current_pulse: float = 0.0


func _ready() -> void:
	_setup_visuals()


func _setup_visuals() -> void:
	# Create mesh if not already present
	if not mesh_instance:
		mesh_instance = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(1.9, 0.05, 1.9)
		mesh_instance.mesh = box
		add_child(mesh_instance)

	# Create material
	material = StandardMaterial3D.new()
	material.albedo_color = base_color
	material.emission_enabled = true
	material.emission = base_color
	material.emission_energy_multiplier = 0.0
	mesh_instance.material_override = material


## Pulse the tile with given intensity
func pulse(intensity: float = 1.0, delay: float = 0.0) -> void:
	_current_pulse = intensity
	tile_pulsed.emit(intensity)

	var pulse_col := base_color.lerp(active_color, intensity)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	if delay > 0:
		tween.tween_interval(delay)

	# Pulse up
	tween.tween_property(material, "emission", pulse_col, 0.02)
	tween.parallel().tween_property(material, "emission_energy_multiplier", emission_energy * intensity, 0.02)

	# Pulse down
	tween.tween_property(material, "emission", base_color, pulse_duration)
	tween.parallel().tween_property(material, "emission_energy_multiplier", 0.0, pulse_duration)
	tween.tween_callback(func(): _current_pulse = 0.0)


## Set tile to active state (sustained glow)
func set_active(active: bool) -> void:
	if active == _is_active:
		return

	_is_active = active

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)

	if active:
		tile_activated.emit(self)
		tween.tween_property(material, "emission", active_color, 0.1)
		tween.parallel().tween_property(material, "emission_energy_multiplier", emission_energy * 0.5, 0.1)
	else:
		tween.tween_property(material, "emission", base_color, 0.2)
		tween.parallel().tween_property(material, "emission_energy_multiplier", 0.0, 0.2)


## Set colors
func set_colors(base: Color, active: Color) -> void:
	base_color = base
	active_color = active
	material.albedo_color = base


## Check if tile is currently pulsing
func is_pulsing() -> bool:
	return _current_pulse > 0.0


## Check if tile is active
func is_active() -> bool:
	return _is_active


## Get current pulse intensity
func get_pulse_intensity() -> float:
	return _current_pulse
