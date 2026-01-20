## WaveDefinition - Defines a wave of enemies for arena encounters
class_name WaveDefinition
extends Resource


## Wave info
@export var wave_name: String = ""
@export var description: String = ""

## Spawns - Array of dictionaries with: type, spawn_point, delay
@export var spawns: Array[Dictionary] = []

## Timing
@export var min_enemies_for_next: int = 0  # 0 = wait for all dead
@export var time_limit: float = 0.0  # 0 = no limit

## Modifiers
@export var enemy_health_multiplier: float = 1.0
@export var enemy_damage_multiplier: float = 1.0
@export var enemy_speed_multiplier: float = 1.0

## Events
@export var activate_hazards: Array[String] = []
@export var music_intensity: float = 1.0


## Add a spawn to this wave
func add_spawn(enemy_type: String, spawn_point: int = -1, delay: float = 0.0) -> void:
	spawns.append({
		"type": enemy_type,
		"spawn_point": spawn_point,
		"delay": delay
	})


## Create a simple wave with one enemy type
static func create_simple(enemy_type: String, count: int) -> WaveDefinition:
	var wave := WaveDefinition.new()
	for i in range(count):
		wave.add_spawn(enemy_type, -1, i * 0.5)
	return wave


## Create a mixed wave
static func create_mixed(enemy_counts: Dictionary) -> WaveDefinition:
	var wave := WaveDefinition.new()
	var delay := 0.0

	for enemy_type in enemy_counts:
		var count: int = enemy_counts[enemy_type]
		for i in range(count):
			wave.add_spawn(enemy_type, -1, delay)
			delay += 0.3

	return wave


## Get total enemy count in this wave
func get_enemy_count() -> int:
	return spawns.size()


## Get count of specific enemy type
func get_enemy_type_count(enemy_type: String) -> int:
	var count := 0
	for spawn in spawns:
		if spawn.get("type") == enemy_type:
			count += 1
	return count
