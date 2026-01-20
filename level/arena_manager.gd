## ArenaManager - Manages arena layout, spawning, waves, and hazards
class_name ArenaManager
extends Node3D


signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)
signal all_waves_completed()
signal enemy_spawned(enemy: Node3D)
signal enemy_defeated(enemy: Node3D)
signal hazard_triggered(hazard: Node3D)


## Configuration
@export var arena_size: Vector2 = Vector2(20, 20)
@export var spawn_points: Array[SpawnPoint] = []
@export var hazards: Array[Hazard] = []
@export var wave_definitions: Array[WaveDefinition] = []
@export var enemy_scenes: Dictionary = {}  # enemy_type -> PackedScene

## Timing
@export var wave_delay: float = 3.0
@export var spawn_interval: float = 0.5
@export var beat_sync_spawns: bool = true

## State
var _current_wave: int = 0
var _enemies_alive: Array[Node3D] = []
var _is_wave_active: bool = false
var _spawn_queue: Array[Dictionary] = []
var _tick_handle: int = -1


func _ready() -> void:
	if beat_sync_spawns:
		_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)

	_setup_hazards()


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_hazards() -> void:
	for hazard in hazards:
		if hazard:
			hazard.triggered.connect(_on_hazard_triggered.bind(hazard))


func _on_beat(event: SequencerEvent) -> void:
	# Spawn enemies on beat if queue has items
	if not _spawn_queue.is_empty() and event.quant.type == Quant.Type.KICK:
		_process_spawn_queue()


func _on_hazard_triggered(hazard: Hazard) -> void:
	hazard_triggered.emit(hazard)


## Start the arena encounter
func start_encounter() -> void:
	_current_wave = 0
	_start_wave()


## Start a specific wave
func _start_wave() -> void:
	if _current_wave >= wave_definitions.size():
		all_waves_completed.emit()
		return

	_is_wave_active = true
	var wave_def := wave_definitions[_current_wave]
	wave_started.emit(_current_wave + 1)

	# Queue all spawns for this wave
	for spawn_data in wave_def.spawns:
		_spawn_queue.append(spawn_data)

	# If not beat-synced, use timer
	if not beat_sync_spawns:
		_start_spawn_timer()


func _start_spawn_timer() -> void:
	while not _spawn_queue.is_empty():
		_process_spawn_queue()
		await get_tree().create_timer(spawn_interval).timeout


func _process_spawn_queue() -> void:
	if _spawn_queue.is_empty():
		return

	var spawn_data: Dictionary = _spawn_queue.pop_front()
	_spawn_enemy(spawn_data)


func _spawn_enemy(spawn_data: Dictionary) -> void:
	var enemy_type: String = spawn_data.get("type", "grunt")
	var spawn_index: int = spawn_data.get("spawn_point", -1)

	if not enemy_scenes.has(enemy_type):
		push_warning("ArenaManager: Unknown enemy type '%s'" % enemy_type)
		return

	var enemy_scene: PackedScene = enemy_scenes[enemy_type]
	var enemy: Node3D = enemy_scene.instantiate()

	# Position at spawn point or random
	var spawn_pos: Vector3
	if spawn_index >= 0 and spawn_index < spawn_points.size():
		spawn_pos = spawn_points[spawn_index].global_position
	else:
		spawn_pos = _get_random_spawn_position()

	enemy.global_position = spawn_pos

	# Connect defeat signal
	if enemy.has_signal("defeated"):
		enemy.defeated.connect(_on_enemy_defeated.bind(enemy))

	add_child(enemy)
	_enemies_alive.append(enemy)
	enemy_spawned.emit(enemy)


func _get_random_spawn_position() -> Vector3:
	if spawn_points.is_empty():
		# Random position within arena
		return Vector3(
			randf_range(-arena_size.x / 2, arena_size.x / 2),
			0,
			randf_range(-arena_size.y / 2, arena_size.y / 2)
		)
	else:
		var spawn_point := spawn_points[randi() % spawn_points.size()]
		return spawn_point.global_position


func _on_enemy_defeated(enemy: Node3D) -> void:
	_enemies_alive.erase(enemy)
	enemy_defeated.emit(enemy)

	# Check wave completion
	if _is_wave_active and _enemies_alive.is_empty() and _spawn_queue.is_empty():
		_complete_wave()


func _complete_wave() -> void:
	_is_wave_active = false
	wave_completed.emit(_current_wave + 1)
	_current_wave += 1

	# Start next wave after delay
	if _current_wave < wave_definitions.size():
		await get_tree().create_timer(wave_delay).timeout
		_start_wave()
	else:
		all_waves_completed.emit()


## Activate all hazards of a type
func activate_hazards(hazard_type: String = "") -> void:
	for hazard in hazards:
		if hazard and (hazard_type.is_empty() or hazard.hazard_type == hazard_type):
			hazard.activate()


## Deactivate all hazards
func deactivate_hazards() -> void:
	for hazard in hazards:
		if hazard:
			hazard.deactivate()


## Get current wave number (1-indexed)
func get_current_wave() -> int:
	return _current_wave + 1


## Get total wave count
func get_total_waves() -> int:
	return wave_definitions.size()


## Get alive enemy count
func get_enemy_count() -> int:
	return _enemies_alive.size()


## Check if encounter is complete
func is_complete() -> bool:
	return _current_wave >= wave_definitions.size() and _enemies_alive.is_empty()


## Get arena bounds
func get_bounds() -> Rect2:
	return Rect2(-arena_size / 2, arena_size)


## Check if position is within arena
func is_in_bounds(pos: Vector3) -> bool:
	return abs(pos.x) <= arena_size.x / 2 and abs(pos.z) <= arena_size.y / 2
