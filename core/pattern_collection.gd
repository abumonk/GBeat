## PatternCollection - Registry of named patterns
class_name PatternCollection
extends Resource

@export var patterns: Dictionary = {}  ## name -> Pattern
@export var pattern_order: Array[String] = []


func create_pattern(pattern_name: String, sound: AudioStream, bpm: float = 120.0) -> Pattern:
	var pattern := Pattern.new()
	pattern.pattern_name = pattern_name
	pattern.sound = sound
	pattern.bpm = bpm

	patterns[pattern_name] = pattern
	pattern_order.append(pattern_name)

	return pattern


func add_pattern(pattern: Pattern) -> void:
	if pattern.pattern_name.is_empty():
		push_error("Cannot add pattern without name")
		return

	patterns[pattern.pattern_name] = pattern
	if not pattern_order.has(pattern.pattern_name):
		pattern_order.append(pattern.pattern_name)


func get_pattern(pattern_name: String) -> Pattern:
	return patterns.get(pattern_name)


func has_pattern(pattern_name: String) -> bool:
	return patterns.has(pattern_name)


func remove_pattern(pattern_name: String) -> void:
	patterns.erase(pattern_name)
	pattern_order.erase(pattern_name)


func get_pattern_names() -> Array[String]:
	return pattern_order.duplicate()


func get_pattern_count() -> int:
	return patterns.size()


func load_pattern_from_json(pattern_name: String, path: String) -> Pattern:
	var pattern := Pattern.load_from_json(path)
	if pattern:
		pattern.pattern_name = pattern_name
		patterns[pattern_name] = pattern
		if not pattern_order.has(pattern_name):
			pattern_order.append(pattern_name)
	return pattern


func save_pattern_to_json(pattern_name: String, path: String) -> void:
	var pattern := get_pattern(pattern_name)
	if pattern:
		pattern.save_to_json(path)


func load_patterns_from_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.ends_with(".json"):
			var pattern_name := file_name.get_basename()
			load_pattern_from_json(pattern_name, dir_path.path_join(file_name))
		file_name = dir.get_next()


func clear() -> void:
	patterns.clear()
	pattern_order.clear()
