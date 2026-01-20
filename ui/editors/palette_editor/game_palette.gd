## GamePalette - Resource storing all game colors
class_name GamePalette
extends Resource


@export var name: String = ""
@export var description: String = ""

## Character colors
@export_group("Character")
@export var skin: Color = Color(0.96, 0.80, 0.69)
@export var hair: Color = Color(0.2, 0.1, 0.05)
@export var eye: Color = Color(0.3, 0.5, 0.8)
@export var shirt: Color = Color(0.2, 0.4, 0.8)
@export var pants: Color = Color(0.15, 0.15, 0.2)
@export var shoes: Color = Color(0.1, 0.1, 0.1)
@export var hat: Color = Color(0.3, 0.2, 0.1)
@export var accessory: Color = Color(1.0, 0.8, 0.0)
@export var weapon_primary: Color = Color(0.7, 0.7, 0.75)
@export var weapon_secondary: Color = Color(0.4, 0.2, 0.1)

## Scene colors
@export_group("Scene")
@export var background: Color = Color(0.05, 0.05, 0.1)
@export var floor_base: Color = Color(0.1, 0.1, 0.15)
@export var floor_accent: Color = Color(1.0, 0.0, 1.0)
@export var light_main: Color = Color(1.0, 1.0, 1.0)
@export var light_accent: Color = Color(1.0, 0.0, 0.5)
@export var fog: Color = Color(0.1, 0.1, 0.2)

## UI colors
@export_group("UI")
@export var ui_primary: Color = Color(0.9, 0.9, 0.95)
@export var ui_secondary: Color = Color(0.0, 0.8, 1.0)
@export var ui_accent: Color = Color(1.0, 0.3, 0.5)
@export var ui_background: Color = Color(0.1, 0.1, 0.15, 0.9)

## Pattern/beat colors
@export_group("Pattern")
@export var beat_kick: Color = Color(1.0, 0.2, 0.2)
@export var beat_snare: Color = Color(0.2, 1.0, 0.2)
@export var beat_hat: Color = Color(0.2, 0.2, 1.0)
@export var beat_accent: Color = Color(1.0, 1.0, 0.2)


## Get color by category name
func get_color(category: String) -> Color:
	var prop_name := category.to_lower()
	if has(prop_name):
		return get(prop_name)
	return Color.WHITE


## Set color by category name
func set_color(category: String, color: Color) -> void:
	var prop_name := category.to_lower()
	if has(prop_name):
		set(prop_name, color)


## Check if property exists
func has(property: String) -> bool:
	for prop in get_property_list():
		if prop.name == property:
			return true
	return false


## Get all category names
func get_all_categories() -> Array[String]:
	return [
		"skin", "hair", "eye", "shirt", "pants", "shoes",
		"hat", "accessory", "weapon_primary", "weapon_secondary",
		"background", "floor_base", "floor_accent",
		"light_main", "light_accent", "fog",
		"ui_primary", "ui_secondary", "ui_accent", "ui_background",
		"beat_kick", "beat_snare", "beat_hat", "beat_accent"
	]


## Preset creators
static func create_neon_cyberpunk() -> GamePalette:
	var p := GamePalette.new()
	p.name = "Neon Cyberpunk"
	p.shirt = Color(0.0, 1.0, 1.0)
	p.hair = Color(0.0, 0.8, 1.0)
	p.floor_accent = Color(1.0, 0.0, 1.0)
	p.light_accent = Color(0.0, 1.0, 0.8)
	p.background = Color(0.02, 0.0, 0.05)
	return p


static func create_sunset_warm() -> GamePalette:
	var p := GamePalette.new()
	p.name = "Sunset Warm"
	p.shirt = Color(1.0, 0.5, 0.2)
	p.floor_accent = Color(1.0, 0.3, 0.1)
	p.light_accent = Color(1.0, 0.8, 0.3)
	p.background = Color(0.1, 0.05, 0.1)
	return p


static func create_forest_natural() -> GamePalette:
	var p := GamePalette.new()
	p.name = "Forest Natural"
	p.shirt = Color(0.2, 0.5, 0.2)
	p.floor_accent = Color(0.4, 0.8, 0.3)
	p.light_accent = Color(0.8, 1.0, 0.6)
	p.background = Color(0.05, 0.1, 0.05)
	return p


static func create_monochrome() -> GamePalette:
	var p := GamePalette.new()
	p.name = "Monochrome"
	p.shirt = Color(0.7, 0.7, 0.7)
	p.floor_accent = Color(1.0, 1.0, 1.0)
	p.light_accent = Color(0.9, 0.9, 0.9)
	p.background = Color(0.1, 0.1, 0.1)
	return p
