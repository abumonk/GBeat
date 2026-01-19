## WaveCollection - Runtime storage for audio streams (sounds/music)
class_name WaveCollection
extends Resource

@export var waves: Dictionary = {}  ## name -> AudioStream


func add_wave(wave_name: String, stream: AudioStream) -> void:
	waves[wave_name] = stream


func get_wave(wave_name: String) -> AudioStream:
	return waves.get(wave_name)


func has_wave(wave_name: String) -> bool:
	return waves.has(wave_name)


func remove_wave(wave_name: String) -> void:
	waves.erase(wave_name)


func get_or_load_wave(wave_name: String, path: String) -> AudioStream:
	if waves.has(wave_name):
		return waves[wave_name]

	if ResourceLoader.exists(path):
		var stream := load(path) as AudioStream
		if stream:
			waves[wave_name] = stream
			return stream

	return null


func populate_from_directory(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if not dir:
		push_error("Failed to open directory: %s" % dir_path)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if _is_audio_file(file_name):
			var wave_name := file_name.get_basename()
			var full_path := dir_path.path_join(file_name)
			if ResourceLoader.exists(full_path):
				var stream := load(full_path) as AudioStream
				if stream:
					waves[wave_name] = stream
		file_name = dir.get_next()


func _is_audio_file(file_name: String) -> bool:
	var ext := file_name.get_extension().to_lower()
	return ext in ["ogg", "wav", "mp3"]


func get_wave_names() -> Array[String]:
	var names: Array[String] = []
	for key in waves.keys():
		names.append(key)
	return names


func get_wave_count() -> int:
	return waves.size()


func clear() -> void:
	waves.clear()
