## DanceFloor - Scene with lighting floor and dancing humanoids
extends Node3D


signal beat_pulse()
signal bar_changed(bar_number: int)


## Configuration
@export_range(10, 30) var dancer_count: int = 15
@export var floor_size: Vector2i = Vector2i(16, 16)
@export var tile_size: float = 2.0
@export var patterns_folder: String = "res://beats/patterns/"
@export var audio_folder: String = "res://beats/wav/"

## References
var lighting_floor: LightingFloor
var dancers: Array[DancingHumanoid] = []
var audio_player: AudioStreamPlayer
var pattern_loader: PatternLoader

## State
var _current_pattern: Pattern
var _patterns: Array[Pattern] = []
var _current_bar: int = 0
var _tick_handle: int = -1


func _ready() -> void:
	_setup_environment()
	_create_lighting_floor()
	_load_patterns()
	_create_audio_player()
	_spawn_dancers()
	_subscribe_to_sequencer()
	_start_music()


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _setup_environment() -> void:
	# Create dark environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.02, 0.05)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.1, 0.1, 0.15)
	env.ambient_light_energy = 0.3

	# Glow for neon effect
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.3

	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Main light
	var light := DirectionalLight3D.new()
	light.light_color = Color(0.8, 0.8, 1.0)
	light.light_energy = 0.5
	light.rotation_degrees = Vector3(-45, -30, 0)
	add_child(light)


func _create_lighting_floor() -> void:
	lighting_floor = LightingFloor.new()
	lighting_floor.grid_size = floor_size
	lighting_floor.tile_size = tile_size
	lighting_floor.base_color = Color(0.05, 0.05, 0.1)
	lighting_floor.pulse_color = Color(1.0, 0.2, 0.6)
	lighting_floor.emission_energy = 3.0
	lighting_floor.pattern_mode = LightingFloor.PatternMode.RADIAL
	add_child(lighting_floor)


func _load_patterns() -> void:
	pattern_loader = PatternLoader.new()
	_patterns = pattern_loader.load_patterns_from_folder(patterns_folder)

	if _patterns.is_empty():
		push_warning("DanceFloor: No patterns found in %s" % patterns_folder)
		# Create a default pattern
		_current_pattern = _create_default_pattern()
		_patterns.append(_current_pattern)
	else:
		_current_pattern = _patterns[randi() % _patterns.size()]


func _create_default_pattern() -> Pattern:
	var pattern := Pattern.new()
	pattern.pattern_name = "default"
	pattern.bpm = 120.0

	# Add basic beat pattern
	for i in range(32):
		var tick := Quant.new()
		tick.type = Quant.Type.TICK
		tick.position = i
		tick.value = 1.0
		pattern.quants.append(tick)

		# Kick on 0, 8, 16, 24
		if i % 8 == 0:
			var kick := Quant.new()
			kick.type = Quant.Type.KICK
			kick.position = i
			kick.value = 1.0
			pattern.quants.append(kick)

		# Animation quants on every other position
		if i % 2 == 0:
			var anim := Quant.new()
			anim.type = Quant.Type.ANIMATION
			anim.position = i
			anim.value = 1.0
			pattern.quants.append(anim)

	return pattern


func _create_audio_player() -> void:
	audio_player = AudioStreamPlayer.new()
	audio_player.bus = "Master"
	add_child(audio_player)

	# Try to load audio for current pattern
	if _current_pattern and _current_pattern.audio_file:
		var audio_path := audio_folder + _current_pattern.audio_file.get_file()
		if ResourceLoader.exists(audio_path):
			audio_player.stream = load(audio_path)


func _spawn_dancers() -> void:
	var floor_extent := Vector2(floor_size) * tile_size * 0.5
	var min_distance := 1.5  # Minimum distance between dancers

	for i in range(dancer_count):
		var dancer := DancingHumanoid.new()
		dancer.auto_change_style = true
		dancer.style_change_bars = randi_range(2, 8)

		# Random position on floor with spacing
		var pos := _find_valid_position(floor_extent, min_distance)
		dancer.position = Vector3(pos.x, 0, pos.y)

		# Random facing
		dancer.rotation.y = randf() * TAU

		add_child(dancer)
		dancers.append(dancer)

		# Vary dance intensity
		dancer.set_intensity(randf_range(0.6, 1.2))


func _find_valid_position(extent: Vector2, min_dist: float) -> Vector2:
	var max_attempts := 50

	for attempt in range(max_attempts):
		var pos := Vector2(
			randf_range(-extent.x * 0.8, extent.x * 0.8),
			randf_range(-extent.y * 0.8, extent.y * 0.8)
		)

		var valid := true
		for dancer in dancers:
			var dancer_pos := Vector2(dancer.position.x, dancer.position.z)
			if pos.distance_to(dancer_pos) < min_dist:
				valid = false
				break

		if valid:
			return pos

	# Fallback: return random position anyway
	return Vector2(
		randf_range(-extent.x * 0.8, extent.x * 0.8),
		randf_range(-extent.y * 0.8, extent.y * 0.8)
	)


func _subscribe_to_sequencer() -> void:
	_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_tick)


func _start_music() -> void:
	# Set pattern in sequencer
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)
	if deck and _current_pattern:
		deck.set_pattern(_current_pattern)
		deck.play()

	# Start audio
	if audio_player.stream:
		audio_player.play()


func _on_tick(event: SequencerEvent) -> void:
	# Check for bar change (every 32 quants)
	var new_bar := event.quant_index / 32
	if new_bar != _current_bar:
		_current_bar = new_bar
		bar_changed.emit(_current_bar)

		# Randomly change floor pattern
		if randf() > 0.7:
			lighting_floor.pattern_mode = randi() % LightingFloor.PatternMode.size() as LightingFloor.PatternMode

		# Randomly change floor colors
		if randf() > 0.85:
			_randomize_floor_colors()

	# Pulse floor on kicks
	if event.quant.type == Quant.Type.KICK:
		beat_pulse.emit()


func _randomize_floor_colors() -> void:
	var palettes := [
		[Color(1.0, 0.2, 0.6), Color(0.05, 0.02, 0.08)],  # Pink
		[Color(0.2, 0.8, 1.0), Color(0.02, 0.05, 0.08)],  # Cyan
		[Color(1.0, 0.5, 0.0), Color(0.08, 0.03, 0.0)],   # Orange
		[Color(0.5, 1.0, 0.3), Color(0.02, 0.08, 0.02)],  # Green
		[Color(0.8, 0.2, 1.0), Color(0.05, 0.02, 0.08)],  # Purple
		[Color(1.0, 1.0, 0.2), Color(0.08, 0.08, 0.02)],  # Yellow
	]

	var palette: Array = palettes[randi() % palettes.size()]
	lighting_floor.set_pulse_color(palette[0])
	lighting_floor.set_base_color(palette[1])


## === Public API ===

func change_pattern() -> void:
	if _patterns.size() > 1:
		var new_pattern := _patterns[randi() % _patterns.size()]
		while new_pattern == _current_pattern and _patterns.size() > 1:
			new_pattern = _patterns[randi() % _patterns.size()]
		_current_pattern = new_pattern

		var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)
		if deck:
			deck.set_pattern(_current_pattern)


func set_dancer_count(count: int) -> void:
	# Remove excess dancers
	while dancers.size() > count:
		var dancer := dancers.pop_back()
		dancer.queue_free()

	# Add new dancers
	var floor_extent := Vector2(floor_size) * tile_size * 0.5
	while dancers.size() < count:
		var dancer := DancingHumanoid.new()
		var pos := _find_valid_position(floor_extent, 1.5)
		dancer.position = Vector3(pos.x, 0, pos.y)
		dancer.rotation.y = randf() * TAU
		add_child(dancer)
		dancers.append(dancer)


func get_dancers() -> Array[DancingHumanoid]:
	return dancers


## Pattern loader helper class
class PatternLoader:
	func load_patterns_from_folder(folder_path: String) -> Array[Pattern]:
		var patterns: Array[Pattern] = []
		var dir := DirAccess.open(folder_path)

		if not dir:
			return patterns

		dir.list_dir_begin()
		var file_name := dir.get_next()

		while file_name != "":
			if file_name.ends_with(".json"):
				var pattern := _load_pattern_json(folder_path + file_name)
				if pattern:
					patterns.append(pattern)
			file_name = dir.get_next()

		dir.list_dir_end()
		return patterns

	func _load_pattern_json(path: String) -> Pattern:
		var file := FileAccess.open(path, FileAccess.READ)
		if not file:
			return null

		var json := JSON.new()
		var error := json.parse(file.get_as_text())
		file.close()

		if error != OK:
			push_error("Failed to parse pattern: %s" % path)
			return null

		var data: Dictionary = json.data
		var pattern := Pattern.new()
		pattern.pattern_name = data.get("name", "")
		pattern.bpm = data.get("bpm", 120.0)
		pattern.audio_file = data.get("sound", "")

		var quants_data: Array = data.get("quants", [])
		for q_data in quants_data:
			var quant := Quant.new()
			quant.type = _string_to_quant_type(q_data.get("type", "Tick"))
			quant.position = q_data.get("position", 0)
			quant.value = q_data.get("value", 1.0)
			pattern.quants.append(quant)

		pattern.rebuild_cache()
		return pattern

	func _string_to_quant_type(type_str: String) -> Quant.Type:
		match type_str:
			"Tick":
				return Quant.Type.TICK
			"Hit":
				return Quant.Type.HIT
			"Kick":
				return Quant.Type.KICK
			"Snare":
				return Quant.Type.SNARE
			"Hat":
				return Quant.Type.HAT
			"OpenHat":
				return Quant.Type.OPEN_HAT
			"Crash":
				return Quant.Type.CRASH
			"Ride":
				return Quant.Type.RIDE
			"Tom":
				return Quant.Type.TOM
			"Animation":
				return Quant.Type.ANIMATION
			_:
				return Quant.Type.TICK
