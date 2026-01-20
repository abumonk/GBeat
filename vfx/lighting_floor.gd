## LightingFloor - Grid of lights that react to beats
class_name LightingFloor
extends Node3D


signal floor_pulsed(pattern: Array)


## Configuration
@export var grid_size: Vector2i = Vector2i(8, 8)
@export var tile_size: float = 2.0
@export var tile_spacing: float = 0.1

## Visuals
@export var tile_mesh: Mesh
@export var base_material: Material
@export var base_color: Color = Color(0.1, 0.1, 0.15)
@export var pulse_color: Color = Color(1.0, 0.2, 0.4)
@export var emission_energy: float = 2.0

## Pulse patterns
@export var pattern_mode: PatternMode = PatternMode.RADIAL
@export var pulse_duration: float = 0.2
@export var wave_speed: float = 10.0

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

enum PatternMode {
	ALL,        ## All tiles at once
	RADIAL,     ## Radial wave from center
	ROWS,       ## Row by row
	RANDOM,     ## Random tiles
	CHECKERBOARD,
}

## State
var _tiles: Array[MeshInstance3D] = []
var _tile_materials: Array[StandardMaterial3D] = []
var _tick_handle: int = -1
var _center: Vector2
var _floor_collision: StaticBody3D


func _ready() -> void:
	_create_floor()
	_create_collision()
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _create_floor() -> void:
	_center = Vector2(grid_size.x - 1, grid_size.y - 1) * 0.5

	var default_mesh := BoxMesh.new()
	default_mesh.size = Vector3(tile_size - tile_spacing, 0.05, tile_size - tile_spacing)

	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var tile := MeshInstance3D.new()
			tile.mesh = tile_mesh if tile_mesh else default_mesh

			# Create unique material for each tile
			var mat := StandardMaterial3D.new()
			mat.albedo_color = base_color
			mat.emission_enabled = true
			mat.emission = base_color
			mat.emission_energy_multiplier = 0.0
			tile.material_override = mat

			# Position
			var pos_x := (x - _center.x) * tile_size
			var pos_z := (y - _center.y) * tile_size
			tile.position = Vector3(pos_x, 0, pos_z)

			add_child(tile)
			_tiles.append(tile)
			_tile_materials.append(mat)


func _create_collision() -> void:
	## Create a single collision plane for the entire floor
	_floor_collision = StaticBody3D.new()
	_floor_collision.collision_layer = 1  # Ground layer
	_floor_collision.collision_mask = 0   # Doesn't need to detect anything

	var collision_shape := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()

	# Size to cover entire floor grid
	var floor_width := grid_size.x * tile_size
	var floor_depth := grid_size.y * tile_size
	box_shape.size = Vector3(floor_width, 0.1, floor_depth)

	collision_shape.shape = box_shape
	# Position collision slightly below tile surfaces
	collision_shape.position = Vector3(0, -0.05, 0)

	_floor_collision.add_child(collision_shape)
	add_child(_floor_collision)


func _on_tick(event: SequencerEvent) -> void:
	pulse_pattern(event.quant.value)


func pulse_pattern(intensity: float = 1.0) -> void:
	match pattern_mode:
		PatternMode.ALL:
			_pulse_all(intensity)
		PatternMode.RADIAL:
			_pulse_radial(intensity)
		PatternMode.ROWS:
			_pulse_rows(intensity)
		PatternMode.RANDOM:
			_pulse_random(intensity)
		PatternMode.CHECKERBOARD:
			_pulse_checkerboard(intensity)


func _pulse_all(intensity: float) -> void:
	for mat in _tile_materials:
		_pulse_tile(mat, intensity, 0.0)


func _pulse_radial(intensity: float) -> void:
	for i in range(_tiles.size()):
		var x := i % grid_size.x
		var y := i / grid_size.x
		var dist := Vector2(x, y).distance_to(_center)
		var delay := dist / wave_speed
		_pulse_tile(_tile_materials[i], intensity, delay)


func _pulse_rows(intensity: float) -> void:
	for i in range(_tiles.size()):
		var y := i / grid_size.x
		var delay := float(y) / wave_speed
		_pulse_tile(_tile_materials[i], intensity, delay)


func _pulse_random(intensity: float) -> void:
	# Pulse random subset of tiles
	var count := int(_tiles.size() * 0.3)
	var indices := range(_tiles.size())
	indices.shuffle()

	for i in range(min(count, indices.size())):
		_pulse_tile(_tile_materials[indices[i]], intensity, randf() * 0.1)


func _pulse_checkerboard(intensity: float) -> void:
	for i in range(_tiles.size()):
		var x := i % grid_size.x
		var y := i / grid_size.x
		if (x + y) % 2 == 0:
			_pulse_tile(_tile_materials[i], intensity, 0.0)


func _pulse_tile(mat: StandardMaterial3D, intensity: float, delay: float) -> void:
	var pulse_col := base_color.lerp(pulse_color, intensity)

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_EXPO)

	if delay > 0:
		tween.tween_interval(delay)

	# Pulse up
	tween.tween_property(mat, "emission", pulse_col, 0.02)
	tween.parallel().tween_property(mat, "emission_energy_multiplier", emission_energy * intensity, 0.02)

	# Pulse down
	tween.tween_property(mat, "emission", base_color, pulse_duration)
	tween.parallel().tween_property(mat, "emission_energy_multiplier", 0.0, pulse_duration)


## Public API

func set_base_color(color: Color) -> void:
	base_color = color
	for mat in _tile_materials:
		mat.albedo_color = color


func set_pulse_color(color: Color) -> void:
	pulse_color = color


func set_pattern_mode(mode: PatternMode) -> void:
	pattern_mode = mode


func trigger_pulse(intensity: float = 1.0) -> void:
	pulse_pattern(intensity)
