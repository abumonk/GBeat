## CharacterAppearance - Complete character customization save data
@tool
class_name CharacterAppearance
extends Resource


signal appearance_changed()


@export var preset_name: String = "Custom"

## Body customization
@export var body: BodyCustomization

## Clothing by slot
@export var clothing: Dictionary = {}  # ClothingSlot -> ClothingItem path

## Materials by zone ID
@export var materials: Dictionary = {}  # zone_id: String -> CustomMaterial

## Accessories
@export var accessories: Array[String] = []  # Accessory resource paths

## Colors (quick access)
@export_group("Colors")
@export var primary_color: Color = Color.WHITE
@export var secondary_color: Color = Color.GRAY
@export var accent_color: Color = Color.CYAN


## Clothing slots enum
enum ClothingSlot {
	HEAD,
	FACE,
	UPPER_BODY,
	LOWER_BODY,
	HANDS,
	FEET,
	BACK,
	FULL_BODY,
}


func _init() -> void:
	if not body:
		body = BodyCustomization.new()


func set_clothing(slot: ClothingSlot, item_path: String) -> void:
	clothing[slot] = item_path
	appearance_changed.emit()


func get_clothing(slot: ClothingSlot) -> String:
	return clothing.get(slot, "")


func clear_clothing(slot: ClothingSlot) -> void:
	clothing.erase(slot)
	appearance_changed.emit()


func set_material(zone_id: String, material: CustomMaterial) -> void:
	materials[zone_id] = material
	appearance_changed.emit()


func get_material(zone_id: String) -> CustomMaterial:
	return materials.get(zone_id)


func add_accessory(accessory_path: String) -> void:
	if accessory_path not in accessories:
		accessories.append(accessory_path)
		appearance_changed.emit()


func remove_accessory(accessory_path: String) -> void:
	var idx := accessories.find(accessory_path)
	if idx >= 0:
		accessories.remove_at(idx)
		appearance_changed.emit()


func has_accessory(accessory_path: String) -> bool:
	return accessory_path in accessories


func copy_from(other: CharacterAppearance) -> void:
	preset_name = other.preset_name

	if other.body:
		if not body:
			body = BodyCustomization.new()
		body.copy_from(other.body)

	clothing = other.clothing.duplicate()

	materials.clear()
	for zone_id in other.materials.keys():
		var mat := CustomMaterial.new()
		mat.copy_from(other.materials[zone_id])
		materials[zone_id] = mat

	accessories = other.accessories.duplicate()
	primary_color = other.primary_color
	secondary_color = other.secondary_color
	accent_color = other.accent_color


func reset_to_default() -> void:
	preset_name = "Default"

	if body:
		body.reset_to_default()
	else:
		body = BodyCustomization.new()

	clothing.clear()
	materials.clear()
	accessories.clear()
	primary_color = Color.WHITE
	secondary_color = Color.GRAY
	accent_color = Color.CYAN

	appearance_changed.emit()


func serialize() -> Dictionary:
	var clothing_data := {}
	for slot in clothing.keys():
		clothing_data[str(slot)] = clothing[slot]

	var materials_data := {}
	for zone_id in materials.keys():
		var mat: CustomMaterial = materials[zone_id]
		materials_data[zone_id] = mat.serialize() if mat else {}

	return {
		"preset_name": preset_name,
		"body": body.serialize() if body else {},
		"clothing": clothing_data,
		"materials": materials_data,
		"accessories": accessories,
		"primary_color": primary_color.to_html(),
		"secondary_color": secondary_color.to_html(),
		"accent_color": accent_color.to_html(),
	}


static func deserialize(data: Dictionary) -> CharacterAppearance:
	var appearance := CharacterAppearance.new()

	appearance.preset_name = data.get("preset_name", "Custom")

	var body_data: Dictionary = data.get("body", {})
	if not body_data.is_empty():
		appearance.body = BodyCustomization.deserialize(body_data)
	else:
		appearance.body = BodyCustomization.new()

	var clothing_data: Dictionary = data.get("clothing", {})
	for slot_str in clothing_data.keys():
		var slot := int(slot_str)
		appearance.clothing[slot] = clothing_data[slot_str]

	var materials_data: Dictionary = data.get("materials", {})
	for zone_id in materials_data.keys():
		appearance.materials[zone_id] = CustomMaterial.deserialize(materials_data[zone_id])

	appearance.accessories = []
	var acc_data: Array = data.get("accessories", [])
	for acc in acc_data:
		appearance.accessories.append(acc)

	appearance.primary_color = Color.html(data.get("primary_color", "#ffffff"))
	appearance.secondary_color = Color.html(data.get("secondary_color", "#808080"))
	appearance.accent_color = Color.html(data.get("accent_color", "#00ffff"))

	return appearance


## Preset factory methods
static func create_default() -> CharacterAppearance:
	var appearance := CharacterAppearance.new()
	appearance.preset_name = "Default"
	appearance.body = BodyCustomization.create_default()
	appearance.primary_color = Color.WHITE
	appearance.secondary_color = Color.GRAY
	appearance.accent_color = Color.CYAN
	return appearance


static func create_neon_runner() -> CharacterAppearance:
	var appearance := CharacterAppearance.new()
	appearance.preset_name = "Neon Runner"
	appearance.body = BodyCustomization.create_athletic()
	appearance.primary_color = Color(0.1, 0.1, 0.15)
	appearance.secondary_color = Color.MAGENTA
	appearance.accent_color = Color.CYAN
	return appearance


static func create_street_fighter() -> CharacterAppearance:
	var appearance := CharacterAppearance.new()
	appearance.preset_name = "Street Fighter"
	appearance.body = BodyCustomization.create_heroic()
	appearance.primary_color = Color(0.8, 0.2, 0.2)
	appearance.secondary_color = Color.WHITE
	appearance.accent_color = Color(1.0, 0.8, 0.0)
	return appearance
