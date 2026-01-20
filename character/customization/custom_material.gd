## CustomMaterial - Customizable material for character clothing and items
@tool
class_name CustomMaterial
extends Resource


signal material_changed()


## Base appearance
@export var base_color: Color = Color.WHITE:
	set(value):
		base_color = value
		_update_material()

@export var pattern: Texture2D:
	set(value):
		pattern = value
		_update_material()

@export var pattern_scale: float = 1.0:
	set(value):
		pattern_scale = value
		_update_material()

@export var pattern_color: Color = Color.BLACK:
	set(value):
		pattern_color = value
		_update_material()

## Surface properties
@export_group("Surface")
@export_range(0.0, 1.0) var metallic: float = 0.0:
	set(value):
		metallic = value
		_update_material()

@export_range(0.0, 1.0) var roughness: float = 0.5:
	set(value):
		roughness = value
		_update_material()

@export_range(0.0, 1.0) var specular: float = 0.5:
	set(value):
		specular = value
		_update_material()

## Emission
@export_group("Emission")
@export var emission_enabled: bool = false:
	set(value):
		emission_enabled = value
		_update_material()

@export var emission_color: Color = Color.WHITE:
	set(value):
		emission_color = value
		_update_material()

@export_range(0.0, 16.0) var emission_strength: float = 1.0:
	set(value):
		emission_strength = value
		_update_material()

## Cached material
var _cached_material: StandardMaterial3D = null


func _update_material() -> void:
	if _cached_material:
		_apply_to_material(_cached_material)
	material_changed.emit()


func get_material() -> StandardMaterial3D:
	if not _cached_material:
		_cached_material = StandardMaterial3D.new()
		_apply_to_material(_cached_material)
	return _cached_material


func _apply_to_material(mat: StandardMaterial3D) -> void:
	mat.albedo_color = base_color

	if pattern:
		mat.albedo_texture = pattern
		mat.uv1_scale = Vector3(pattern_scale, pattern_scale, 1.0)
	else:
		mat.albedo_texture = null

	mat.metallic = metallic
	mat.roughness = roughness
	mat.metallic_specular = specular

	mat.emission_enabled = emission_enabled
	if emission_enabled:
		mat.emission = emission_color
		mat.emission_energy_multiplier = emission_strength


func apply_to_mesh(mesh_instance: MeshInstance3D, surface_index: int = 0) -> void:
	var mat := get_material()
	mesh_instance.set_surface_override_material(surface_index, mat)


func copy_from(other: CustomMaterial) -> void:
	base_color = other.base_color
	pattern = other.pattern
	pattern_scale = other.pattern_scale
	pattern_color = other.pattern_color
	metallic = other.metallic
	roughness = other.roughness
	specular = other.specular
	emission_enabled = other.emission_enabled
	emission_color = other.emission_color
	emission_strength = other.emission_strength


func serialize() -> Dictionary:
	return {
		"base_color": base_color.to_html(),
		"pattern_path": pattern.resource_path if pattern else "",
		"pattern_scale": pattern_scale,
		"pattern_color": pattern_color.to_html(),
		"metallic": metallic,
		"roughness": roughness,
		"specular": specular,
		"emission_enabled": emission_enabled,
		"emission_color": emission_color.to_html(),
		"emission_strength": emission_strength,
	}


static func deserialize(data: Dictionary) -> CustomMaterial:
	var mat := CustomMaterial.new()
	mat.base_color = Color.html(data.get("base_color", "#ffffff"))
	var pattern_path: String = data.get("pattern_path", "")
	if pattern_path and ResourceLoader.exists(pattern_path):
		mat.pattern = load(pattern_path)
	mat.pattern_scale = data.get("pattern_scale", 1.0)
	mat.pattern_color = Color.html(data.get("pattern_color", "#000000"))
	mat.metallic = data.get("metallic", 0.0)
	mat.roughness = data.get("roughness", 0.5)
	mat.specular = data.get("specular", 0.5)
	mat.emission_enabled = data.get("emission_enabled", false)
	mat.emission_color = Color.html(data.get("emission_color", "#ffffff"))
	mat.emission_strength = data.get("emission_strength", 1.0)
	return mat


## Factory methods for common material types
static func create_matte(color: Color) -> CustomMaterial:
	var mat := CustomMaterial.new()
	mat.base_color = color
	mat.metallic = 0.0
	mat.roughness = 0.9
	return mat


static func create_metallic(color: Color) -> CustomMaterial:
	var mat := CustomMaterial.new()
	mat.base_color = color
	mat.metallic = 0.9
	mat.roughness = 0.2
	return mat


static func create_glossy(color: Color) -> CustomMaterial:
	var mat := CustomMaterial.new()
	mat.base_color = color
	mat.metallic = 0.0
	mat.roughness = 0.1
	mat.specular = 0.8
	return mat


static func create_emissive(color: Color, strength: float = 2.0) -> CustomMaterial:
	var mat := CustomMaterial.new()
	mat.base_color = color
	mat.emission_enabled = true
	mat.emission_color = color
	mat.emission_strength = strength
	return mat
