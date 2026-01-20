## ArenaDecorator - Spawns and manages decorative elements in arena
class_name ArenaDecorator
extends Node3D


## Configuration
@export var theme: ArenaTheme
@export var arena_bounds: Vector2 = Vector2(20, 20)
@export var auto_decorate: bool = true

## Decoration density
@export_range(0.0, 1.0) var prop_density: float = 0.5
@export var edge_decoration_spacing: float = 4.0

## Beat reactivity
@export var beat_reactive: bool = true

## References
var _environment: WorldEnvironment
var _decorations: Array[Node3D] = []
var _lights: Array[Light3D] = []
var _tick_handle: int = -1


func _ready() -> void:
	if auto_decorate and theme:
		decorate()

	if beat_reactive:
		_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _on_beat(event: SequencerEvent) -> void:
	if event.quant.type == Quant.Type.KICK:
		_pulse_lights(event.quant.value)


func _pulse_lights(intensity: float) -> void:
	for light in _lights:
		if is_instance_valid(light):
			var original_energy: float = light.get_meta("original_energy", light.light_energy)
			var tween := create_tween()
			light.light_energy = original_energy * (1.0 + intensity * 0.5)
			tween.tween_property(light, "light_energy", original_energy, 0.15)


## Apply theme and create decorations
func decorate() -> void:
	_clear_decorations()

	if not theme:
		return

	_setup_environment()
	_create_edge_lights()
	_create_corner_props()
	_spawn_theme_decorations()


func _clear_decorations() -> void:
	for deco in _decorations:
		if is_instance_valid(deco):
			deco.queue_free()
	_decorations.clear()
	_lights.clear()


func _setup_environment() -> void:
	_environment = WorldEnvironment.new()
	var env := Environment.new()
	theme.apply_to_environment(env)
	_environment.environment = env
	add_child(_environment)
	_decorations.append(_environment)


func _create_edge_lights() -> void:
	var half_x := arena_bounds.x / 2
	var half_z := arena_bounds.y / 2
	var height := 3.0

	# Create lights along edges
	var positions := [
		Vector3(-half_x, height, -half_z),
		Vector3(half_x, height, -half_z),
		Vector3(-half_x, height, half_z),
		Vector3(half_x, height, half_z),
	]

	for pos in positions:
		var light := _create_spot_light(pos, theme.accent_light_color)
		light.set_meta("original_energy", light.light_energy)
		_lights.append(light)


func _create_spot_light(pos: Vector3, color: Color) -> SpotLight3D:
	var light := SpotLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = 2.0
	light.spot_range = 15.0
	light.spot_angle = 45.0

	# Point toward center
	light.look_at(Vector3.ZERO)

	add_child(light)
	_decorations.append(light)
	return light


func _create_corner_props() -> void:
	var half_x := arena_bounds.x / 2
	var half_z := arena_bounds.y / 2

	var corners := [
		Vector3(-half_x, 0, -half_z),
		Vector3(half_x, 0, -half_z),
		Vector3(-half_x, 0, half_z),
		Vector3(half_x, 0, half_z),
	]

	for corner in corners:
		var pillar := _create_pillar(corner)
		_decorations.append(pillar)


func _create_pillar(pos: Vector3) -> MeshInstance3D:
	var pillar := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.3
	mesh.bottom_radius = 0.4
	mesh.height = 4.0
	pillar.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = theme.floor_base_color.lightened(0.2)
	mat.emission_enabled = true
	mat.emission = theme.floor_pulse_color.darkened(0.5)
	mat.emission_energy_multiplier = 0.5
	pillar.material_override = mat

	pillar.position = pos + Vector3(0, 2, 0)
	add_child(pillar)
	return pillar


func _spawn_theme_decorations() -> void:
	if theme.decoration_scenes.is_empty():
		return

	var count := int(prop_density * 10)

	for i in range(count):
		var scene: PackedScene = theme.decoration_scenes[randi() % theme.decoration_scenes.size()]
		var instance := scene.instantiate()

		# Random position near edges
		var pos := _get_edge_position()
		instance.position = pos

		add_child(instance)
		_decorations.append(instance)


func _get_edge_position() -> Vector3:
	var half_x := arena_bounds.x / 2
	var half_z := arena_bounds.y / 2
	var margin := 2.0

	# Choose random edge
	var edge := randi() % 4
	var pos: Vector3

	match edge:
		0:  # North
			pos = Vector3(randf_range(-half_x + margin, half_x - margin), 0, -half_z + margin)
		1:  # South
			pos = Vector3(randf_range(-half_x + margin, half_x - margin), 0, half_z - margin)
		2:  # East
			pos = Vector3(half_x - margin, 0, randf_range(-half_z + margin, half_z - margin))
		3:  # West
			pos = Vector3(-half_x + margin, 0, randf_range(-half_z + margin, half_z - margin))

	return pos


## Set theme and redecorate
func set_theme(new_theme: ArenaTheme) -> void:
	theme = new_theme
	decorate()


## Get all decoration nodes
func get_decorations() -> Array[Node3D]:
	return _decorations
