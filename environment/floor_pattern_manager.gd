## FloorPatternManager - Manages beat-reactive floor patterns
class_name FloorPatternManager
extends Node


signal pattern_changed(pattern_type: PatternType)
signal pattern_triggered()


enum PatternType {
	RADIAL,       # Expands from center on beat
	WAVE,         # Horizontal/vertical sweep
	CHECKERBOARD, # Alternating tiles
	SPIRAL,       # Rotating activation
	RANDOM,       # Randomized tiles per beat
	CHASE,        # Follows player movement
	ZONE,         # Highlights specific areas
}


@export var lighting_floor: Node3D  # BeatLightingFloor reference
@export var current_pattern: PatternType = PatternType.RADIAL
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Pattern settings
@export_group("Pattern Settings")
@export var pattern_speed: float = 1.0
@export var wave_direction: Vector2 = Vector2(1, 0)
@export var spiral_clockwise: bool = true
@export var random_density: float = 0.3
@export var chase_radius: float = 3.0

## Colors
@export_group("Colors")
@export var active_color: Color = Color(0.8, 0.2, 1.0)
@export var inactive_color: Color = Color(0.1, 0.1, 0.2)
@export var highlight_color: Color = Color(1.0, 1.0, 1.0)

## Internal state
var _tick_handle: int = -1
var _grid_size: Vector2i = Vector2i(16, 16)
var _center: Vector2 = Vector2(8, 8)
var _current_radius: float = 0.0
var _wave_position: float = 0.0
var _spiral_angle: float = 0.0
var _player_position: Vector2 = Vector2.ZERO
var _zone_positions: Array[Vector2i] = []
var _tile_states: Array[Array] = []


func _ready() -> void:
	# Get grid size from lighting floor
	if lighting_floor and lighting_floor.has_method("get_grid_size"):
		_grid_size = lighting_floor.get_grid_size()
	elif lighting_floor and "grid_size" in lighting_floor:
		_grid_size = lighting_floor.grid_size

	_center = Vector2(_grid_size.x / 2.0, _grid_size.y / 2.0)

	# Initialize tile states
	_init_tile_states()

	# Subscribe to sequencer
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _init_tile_states() -> void:
	_tile_states.clear()
	for x in range(_grid_size.x):
		var row: Array = []
		for y in range(_grid_size.y):
			row.append(false)
		_tile_states.append(row)


func _on_tick(event: SequencerEvent) -> void:
	if event.quant.type == Quant.Type.KICK:
		_trigger_pattern()


func _trigger_pattern() -> void:
	match current_pattern:
		PatternType.RADIAL:
			_trigger_radial()
		PatternType.WAVE:
			_trigger_wave()
		PatternType.CHECKERBOARD:
			_trigger_checkerboard()
		PatternType.SPIRAL:
			_trigger_spiral()
		PatternType.RANDOM:
			_trigger_random()
		PatternType.CHASE:
			_trigger_chase()
		PatternType.ZONE:
			_trigger_zone()

	pattern_triggered.emit()


func _trigger_radial() -> void:
	_current_radius = 0.0
	_animate_radial()


func _animate_radial() -> void:
	var max_radius := _center.length() * 1.5
	var tween := create_tween()

	tween.tween_method(_update_radial, 0.0, max_radius, 0.5 / pattern_speed)


func _update_radial(radius: float) -> void:
	_current_radius = radius

	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(_center)
			var in_ring := abs(dist - radius) < 1.5
			_set_tile(x, y, in_ring)


func _trigger_wave() -> void:
	_wave_position = 0.0
	_animate_wave()


func _animate_wave() -> void:
	var max_pos := maxf(_grid_size.x, _grid_size.y) * 1.5
	var tween := create_tween()

	tween.tween_method(_update_wave, -2.0, max_pos, 0.5 / pattern_speed)


func _update_wave(pos: float) -> void:
	_wave_position = pos

	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var tile_pos := Vector2(x, y)
			var wave_dist := tile_pos.dot(wave_direction.normalized())
			var in_wave := abs(wave_dist - pos) < 2.0
			_set_tile(x, y, in_wave)


func _trigger_checkerboard() -> void:
	# Toggle checkerboard pattern
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var is_even := (x + y) % 2 == 0
			_set_tile(x, y, is_even)

	# Fade out after delay
	var tween := create_tween()
	tween.tween_interval(0.2)
	tween.tween_callback(_clear_all_tiles)


func _trigger_spiral() -> void:
	_spiral_angle = 0.0
	_animate_spiral()


func _animate_spiral() -> void:
	var total_rotation := TAU * 2  # Two full rotations
	var direction := 1.0 if spiral_clockwise else -1.0
	var tween := create_tween()

	tween.tween_method(_update_spiral.bind(direction), 0.0, total_rotation, 1.0 / pattern_speed)


func _update_spiral(angle: float, direction: float) -> void:
	_spiral_angle = angle * direction

	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var pos := Vector2(x, y) - _center
			var tile_angle := pos.angle()
			var tile_dist := pos.length()

			# Spiral formula: angle increases with distance
			var spiral_phase := fmod(tile_angle - _spiral_angle + tile_dist * 0.5, TAU)
			var in_spiral := spiral_phase > 0 and spiral_phase < 0.5
			_set_tile(x, y, in_spiral)


func _trigger_random() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var active := randf() < random_density
			_set_tile(x, y, active)

	# Fade out
	var tween := create_tween()
	tween.tween_interval(0.15)
	tween.tween_callback(_clear_all_tiles)


func _trigger_chase() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			var pos := Vector2(x, y)
			var dist := pos.distance_to(_player_position)
			var in_range := dist < chase_radius
			_set_tile(x, y, in_range)


func _trigger_zone() -> void:
	_clear_all_tiles()

	for zone_pos in _zone_positions:
		if zone_pos.x >= 0 and zone_pos.x < _grid_size.x and \
		   zone_pos.y >= 0 and zone_pos.y < _grid_size.y:
			_set_tile(zone_pos.x, zone_pos.y, true)


func _set_tile(x: int, y: int, active: bool) -> void:
	if x < 0 or x >= _grid_size.x or y < 0 or y >= _grid_size.y:
		return

	_tile_states[x][y] = active

	# Update actual floor tile
	if lighting_floor:
		if lighting_floor.has_method("set_tile_active"):
			lighting_floor.set_tile_active(x, y, active)
		elif lighting_floor.has_method("set_tile_color"):
			var color := active_color if active else inactive_color
			lighting_floor.set_tile_color(x, y, color)


func _clear_all_tiles() -> void:
	for x in range(_grid_size.x):
		for y in range(_grid_size.y):
			_set_tile(x, y, false)


## Public API

func set_pattern(pattern: PatternType) -> void:
	current_pattern = pattern
	pattern_changed.emit(pattern)


func set_player_position(world_pos: Vector3) -> void:
	# Convert world position to grid coordinates
	if lighting_floor and lighting_floor.has_method("world_to_grid"):
		var grid_pos: Vector2i = lighting_floor.world_to_grid(world_pos)
		_player_position = Vector2(grid_pos.x, grid_pos.y)
	else:
		# Assume 1 unit per tile
		_player_position = Vector2(world_pos.x + _center.x, world_pos.z + _center.y)


func set_zone_positions(positions: Array[Vector2i]) -> void:
	_zone_positions = positions


func add_zone_position(pos: Vector2i) -> void:
	if pos not in _zone_positions:
		_zone_positions.append(pos)


func clear_zone_positions() -> void:
	_zone_positions.clear()


func trigger_now() -> void:
	_trigger_pattern()


func get_tile_state(x: int, y: int) -> bool:
	if x >= 0 and x < _grid_size.x and y >= 0 and y < _grid_size.y:
		return _tile_states[x][y]
	return false
