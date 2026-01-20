## Pattern - Defines a repeating musical phrase with beat events
class_name Pattern
extends Resource

@export var pattern_name: String = ""
@export var sound: AudioStream
@export var bpm: float = 120.0
@export var quants: Array[Quant] = []

## Cached structures (built on initialize)
var _bars: Array[Bar] = []
var _layers: Dictionary = {}  ## Quant.Type -> Array[Quant]
var _position_map: Dictionary = {}  ## position -> Array[Quant]
var _initialized: bool = false


func initialize() -> void:
	if _initialized:
		return

	_build_bars()
	_build_layers()
	_build_position_map()
	_initialized = true


func _build_bars() -> void:
	_bars.clear()

	if quants.is_empty():
		_bars.append(Bar.new())
		return

	# Find max position to determine bar count
	var max_position := 0
	for quant in quants:
		max_position = max(max_position, quant.position)

	var bar_count := (max_position / 32) + 1

	for i in range(bar_count):
		_bars.append(Bar.new())

	for i in range(quants.size()):
		var quant := quants[i]
		var bar_idx := quant.position / 32
		if bar_idx < _bars.size():
			_bars[bar_idx].add_quant(i, quant)


func _build_layers() -> void:
	_layers.clear()

	for quant in quants:
		if not _layers.has(quant.type):
			_layers[quant.type] = []
		_layers[quant.type].append(quant)


func _build_position_map() -> void:
	_position_map.clear()

	for quant in quants:
		var pos := quant.position % 32  # Normalize to single bar
		if not _position_map.has(pos):
			_position_map[pos] = []
		_position_map[pos].append(quant)


func get_bar_count() -> int:
	if not _initialized:
		initialize()
	return max(_bars.size(), 1)


func get_quants_at_position(position: int) -> Array[Quant]:
	if not _initialized:
		initialize()

	var result: Array[Quant] = []
	if _position_map.has(position):
		for q in _position_map[position]:
			result.append(q)
	return result


func get_next_quant(quant_type: Quant.Type, from_position: int) -> Quant:
	if not _initialized:
		initialize()

	if not _layers.has(quant_type):
		return null

	var layer_quants: Array = _layers[quant_type]

	# Find first quant after from_position
	for quant in layer_quants:
		if quant.position > from_position:
			return quant

	# Wrap around to beginning
	if layer_quants.size() > 0:
		return layer_quants[0]

	return null


func get_beats_to_quant(quant_type: Quant.Type, from_position: int) -> float:
	var next_quant := get_next_quant(quant_type, from_position)
	if not next_quant:
		return -1.0

	var distance := next_quant.position - from_position
	if distance <= 0:
		distance += 32  # Wrapped

	# Convert positions to beats (8 positions per beat)
	return distance / 8.0


func try_get_quant_value(quant_type: Quant.Type, position: int) -> float:
	var quants_at_pos := get_quants_at_position(position)
	for quant in quants_at_pos:
		if quant.type == quant_type:
			return quant.value
	return 0.0


func set_quant_value(quant_type: Quant.Type, position: int, value: float) -> void:
	# Find existing quant
	for quant in quants:
		if quant.type == quant_type and quant.position == position:
			quant.value = value
			return

	# Create new quant
	var new_quant := Quant.new()
	new_quant.type = quant_type
	new_quant.position = position
	new_quant.value = value
	quants.append(new_quant)

	# Rebuild caches
	_initialized = false
	initialize()


func has_layer(quant_type: Quant.Type) -> bool:
	if not _initialized:
		initialize()
	return _layers.has(quant_type)


## Get quants filtered by type
func get_quants_by_type(quant_type: Quant.Type) -> Array:
	if not _initialized:
		initialize()

	if _layers.has(quant_type):
		return _layers[quant_type]
	return []


## Timing calculations
func get_beat_duration() -> float:
	return 60.0 / bpm


func get_bar_duration() -> float:
	return get_beat_duration() * 4.0


func get_quant_duration() -> float:
	return get_beat_duration() / 8.0


## Serialize to JSON string
func to_json() -> String:
	var data := {
		"name": pattern_name,
		"sound": sound.resource_path if sound else "",
		"bpm": bpm,
		"quants": []
	}

	for quant in quants:
		data.quants.append({
			"type": Quant.type_to_string(quant.type),
			"position": quant.position,
			"value": quant.value
		})

	return JSON.stringify(data, "  ")


## JSON Serialization

func save_to_json(path: String) -> void:
	var data := {
		"name": pattern_name,
		"sound": sound.resource_path if sound else "",
		"bpm": bpm,
		"quants": []
	}

	for quant in quants:
		data.quants.append({
			"type": Quant.type_to_string(quant.type),
			"position": quant.position,
			"value": quant.value
		})

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data, "  "))


static func load_from_json(path: String) -> Pattern:
	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		return null

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	if error != OK:
		push_error("Failed to parse pattern JSON: %s" % json.get_error_message())
		return null

	var data: Dictionary = json.data
	var pattern := Pattern.new()
	pattern.pattern_name = data.get("name", "")
	pattern.bpm = data.get("bpm", 120.0)

	var sound_path: String = data.get("sound", "")
	if sound_path and ResourceLoader.exists(sound_path):
		pattern.sound = load(sound_path)

	for quant_data in data.get("quants", []):
		var quant := Quant.new()
		quant.type = Quant.string_to_type(quant_data.get("type", "TICK"))
		quant.position = quant_data.get("position", 0)
		quant.value = quant_data.get("value", 1.0)
		pattern.quants.append(quant)

	pattern.initialize()
	return pattern


## Create a basic pattern programmatically

static func create_basic_4_4(p_bpm: float = 120.0) -> Pattern:
	var pattern := Pattern.new()
	pattern.pattern_name = "Basic4_4"
	pattern.bpm = p_bpm

	# Kick on 1 and 3 (positions 0 and 16)
	pattern.quants.append(Quant.new(Quant.Type.KICK, 0, 1.0))
	pattern.quants.append(Quant.new(Quant.Type.KICK, 16, 1.0))

	# Snare on 2 and 4 (positions 8 and 24)
	pattern.quants.append(Quant.new(Quant.Type.SNARE, 8, 1.0))
	pattern.quants.append(Quant.new(Quant.Type.SNARE, 24, 1.0))

	# Hi-hat on every 8th note
	for i in range(0, 32, 4):
		pattern.quants.append(Quant.new(Quant.Type.HAT, i, 0.7 if i % 8 == 0 else 0.4))

	# Animation triggers on each beat
	for i in range(0, 32, 8):
		pattern.quants.append(Quant.new(Quant.Type.ANIMATION, i, 1.0))

	# Movement speed quants
	pattern.quants.append(Quant.new(Quant.Type.MOVE_FORWARD_SPEED, 0, 1.0))
	pattern.quants.append(Quant.new(Quant.Type.MOVE_RIGHT_SPEED, 0, 1.0))
	pattern.quants.append(Quant.new(Quant.Type.ROTATION_SPEED, 0, 1.0))

	pattern.initialize()
	return pattern
