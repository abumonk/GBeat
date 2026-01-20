## OutfitManager - Manages saved character outfits
class_name OutfitManager
extends Node


signal outfit_changed(index: int)
signal outfit_saved(index: int)
signal outfit_deleted(index: int)


const MAX_OUTFITS := 10
const OUTFITS_SAVE_PATH := "user://outfits.json"


@export var auto_save: bool = true

## Saved outfits
var saved_outfits: Array[CharacterAppearance] = []
var current_outfit_index: int = 0

## Current working appearance (may not be saved yet)
var current_appearance: CharacterAppearance


func _ready() -> void:
	current_appearance = CharacterAppearance.create_default()
	load_outfits()


func save_outfit(name: String = "", index: int = -1) -> int:
	var outfit := CharacterAppearance.new()
	outfit.copy_from(current_appearance)
	outfit.preset_name = name if name else "Outfit %d" % (saved_outfits.size() + 1)

	if index >= 0 and index < saved_outfits.size():
		# Overwrite existing
		saved_outfits[index] = outfit
	elif saved_outfits.size() < MAX_OUTFITS:
		# Add new
		saved_outfits.append(outfit)
		index = saved_outfits.size() - 1
	else:
		push_warning("OutfitManager: Maximum outfits reached (%d)" % MAX_OUTFITS)
		return -1

	current_outfit_index = index
	outfit_saved.emit(index)

	if auto_save:
		save_outfits_to_file()

	return index


func load_outfit(index: int) -> bool:
	if index < 0 or index >= saved_outfits.size():
		push_warning("OutfitManager: Invalid outfit index %d" % index)
		return false

	current_appearance.copy_from(saved_outfits[index])
	current_outfit_index = index
	outfit_changed.emit(index)
	return true


func delete_outfit(index: int) -> bool:
	if index < 0 or index >= saved_outfits.size():
		return false

	saved_outfits.remove_at(index)

	# Adjust current index if needed
	if current_outfit_index >= saved_outfits.size():
		current_outfit_index = maxi(0, saved_outfits.size() - 1)

	outfit_deleted.emit(index)

	if auto_save:
		save_outfits_to_file()

	return true


func quick_switch() -> void:
	if saved_outfits.is_empty():
		return

	current_outfit_index = (current_outfit_index + 1) % saved_outfits.size()
	load_outfit(current_outfit_index)


func quick_switch_reverse() -> void:
	if saved_outfits.is_empty():
		return

	current_outfit_index = (current_outfit_index - 1 + saved_outfits.size()) % saved_outfits.size()
	load_outfit(current_outfit_index)


func get_outfit(index: int) -> CharacterAppearance:
	if index >= 0 and index < saved_outfits.size():
		return saved_outfits[index]
	return null


func get_outfit_count() -> int:
	return saved_outfits.size()


func get_current_outfit() -> CharacterAppearance:
	return current_appearance


func set_current_appearance(appearance: CharacterAppearance) -> void:
	current_appearance.copy_from(appearance)
	outfit_changed.emit(-1)  # -1 indicates unsaved changes


func rename_outfit(index: int, new_name: String) -> bool:
	if index < 0 or index >= saved_outfits.size():
		return false

	saved_outfits[index].preset_name = new_name

	if auto_save:
		save_outfits_to_file()

	return true


func duplicate_outfit(index: int) -> int:
	if index < 0 or index >= saved_outfits.size():
		return -1

	if saved_outfits.size() >= MAX_OUTFITS:
		push_warning("OutfitManager: Maximum outfits reached")
		return -1

	var original := saved_outfits[index]
	var copy := CharacterAppearance.new()
	copy.copy_from(original)
	copy.preset_name = original.preset_name + " (Copy)"

	saved_outfits.append(copy)
	var new_index := saved_outfits.size() - 1

	outfit_saved.emit(new_index)

	if auto_save:
		save_outfits_to_file()

	return new_index


func save_outfits_to_file() -> bool:
	var data := []
	for outfit in saved_outfits:
		data.append(outfit.serialize())

	var file := FileAccess.open(OUTFITS_SAVE_PATH, FileAccess.WRITE)
	if not file:
		push_error("OutfitManager: Failed to save outfits")
		return false

	var json := JSON.stringify(data, "\t")
	file.store_string(json)
	file.close()
	return true


func load_outfits() -> bool:
	if not FileAccess.file_exists(OUTFITS_SAVE_PATH):
		# Create default outfit
		_create_default_outfits()
		return true

	var file := FileAccess.open(OUTFITS_SAVE_PATH, FileAccess.READ)
	if not file:
		push_error("OutfitManager: Failed to load outfits")
		return false

	var json := JSON.new()
	var error := json.parse(file.get_as_text())
	file.close()

	if error != OK:
		push_error("OutfitManager: Failed to parse outfits: %s" % json.get_error_message())
		return false

	saved_outfits.clear()
	var data: Array = json.data
	for outfit_data in data:
		var outfit := CharacterAppearance.deserialize(outfit_data)
		saved_outfits.append(outfit)

	# Load first outfit if available
	if not saved_outfits.is_empty():
		load_outfit(0)

	return true


func _create_default_outfits() -> void:
	saved_outfits.clear()
	saved_outfits.append(CharacterAppearance.create_default())
	saved_outfits.append(CharacterAppearance.create_neon_runner())
	saved_outfits.append(CharacterAppearance.create_street_fighter())

	if not saved_outfits.is_empty():
		current_appearance.copy_from(saved_outfits[0])
		current_outfit_index = 0

	if auto_save:
		save_outfits_to_file()


func apply_preset(preset_name: String) -> void:
	match preset_name.to_lower():
		"default":
			current_appearance = CharacterAppearance.create_default()
		"neon_runner", "neon runner":
			current_appearance = CharacterAppearance.create_neon_runner()
		"street_fighter", "street fighter":
			current_appearance = CharacterAppearance.create_street_fighter()
		_:
			push_warning("OutfitManager: Unknown preset '%s'" % preset_name)
			return

	outfit_changed.emit(-1)


func randomize_appearance() -> void:
	current_appearance.body.height = randf_range(0.85, 1.15)
	current_appearance.body.shoulder_width = randf_range(0.9, 1.1)
	current_appearance.body.chest_size = randf_range(0.9, 1.1)
	current_appearance.body.waist_size = randf_range(0.9, 1.1)
	current_appearance.body.hip_width = randf_range(0.9, 1.1)

	current_appearance.primary_color = Color(randf(), randf(), randf())
	current_appearance.secondary_color = Color(randf(), randf(), randf())
	current_appearance.accent_color = Color(randf(), randf(), randf())

	outfit_changed.emit(-1)


func has_unsaved_changes() -> bool:
	if current_outfit_index < 0 or current_outfit_index >= saved_outfits.size():
		return true

	# Compare current to saved (simplified check)
	var saved := saved_outfits[current_outfit_index]
	return current_appearance.primary_color != saved.primary_color or \
		   current_appearance.secondary_color != saved.secondary_color or \
		   current_appearance.accent_color != saved.accent_color
