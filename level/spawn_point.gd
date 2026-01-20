## SpawnPoint - Designated enemy spawn location
class_name SpawnPoint
extends Marker3D


signal spawn_triggered()


## Configuration
@export var spawn_type: SpawnType = SpawnType.GROUND
@export var spawn_radius: float = 1.0
@export var spawn_effect: PackedScene
@export var spawn_delay: float = 0.0
@export var enabled: bool = true

enum SpawnType {
	GROUND,     # Enemies appear on ground
	AIR,        # Flying enemies
	PORTAL,     # With portal effect
	EDGE,       # Arena edge spawns
}

## Visualization
@export var debug_color: Color = Color(1.0, 0.5, 0.0, 0.5)
@export var show_in_game: bool = false


func _ready() -> void:
	if not Engine.is_editor_hint() and not show_in_game:
		visible = false


func _draw() -> void:
	if Engine.is_editor_hint() or show_in_game:
		# Draw spawn area indicator
		pass  # 3D drawing handled differently


## Get a random position within spawn radius
func get_spawn_position() -> Vector3:
	if spawn_radius <= 0:
		return global_position

	var angle := randf() * TAU
	var dist := randf() * spawn_radius
	var offset := Vector3(cos(angle) * dist, 0, sin(angle) * dist)

	return global_position + offset


## Trigger spawn effect
func trigger_spawn_effect() -> void:
	spawn_triggered.emit()

	if spawn_effect:
		var effect := spawn_effect.instantiate()
		effect.global_position = global_position
		get_tree().current_scene.add_child(effect)

	# Visual feedback
	_play_spawn_animation()


func _play_spawn_animation() -> void:
	# Simple scale animation
	var tween := create_tween()
	var original_scale := scale
	scale = Vector3.ZERO
	tween.tween_property(self, "scale", original_scale * 1.5, 0.1)
	tween.tween_property(self, "scale", original_scale, 0.1)


## Check if spawn point is available
func is_available() -> bool:
	return enabled


## Temporarily disable spawn point
func disable_for(duration: float) -> void:
	enabled = false
	await get_tree().create_timer(duration).timeout
	enabled = true
