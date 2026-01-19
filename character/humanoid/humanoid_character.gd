## HumanoidCharacter - Complete procedural humanoid character
class_name HumanoidCharacter
extends Node3D


signal appearance_changed()


## Configuration
@export var auto_generate: bool = true
@export var randomize_on_ready: bool = false

## Proportions
@export var body_type: BodyType = BodyType.DEFAULT

## Equipped items
@export var hat_style: int = -1  ## -1 = none
@export var glasses: bool = false
@export var backpack: bool = false
@export var weapon_type: HumanoidWeapon.WeaponType = HumanoidWeapon.WeaponType.NONE
@export var shield: bool = false

enum BodyType {
	DEFAULT,
	STOCKY,
	SLIM,
	CHIBI,
}

## Runtime
var skeleton: HumanoidSkeleton
var palette: HumanoidTypes.ColorPalette
var _body_meshes: Array[MeshInstance3D] = []
var _clothing_items: Array[Node3D] = []
var _weapon_item: Node3D = null
var _shield_item: Node3D = null


func _ready() -> void:
	palette = HumanoidTypes.ColorPalette.new()

	if randomize_on_ready:
		randomize_appearance()

	if auto_generate:
		generate()


func generate() -> void:
	_clear_existing()
	_create_skeleton()
	_create_body()
	_create_clothing()
	_create_weapons()
	appearance_changed.emit()


func _clear_existing() -> void:
	# Clear body meshes
	for mesh in _body_meshes:
		if is_instance_valid(mesh):
			mesh.queue_free()
	_body_meshes.clear()

	# Clear clothing
	for item in _clothing_items:
		if is_instance_valid(item):
			item.queue_free()
	_clothing_items.clear()

	# Clear weapons
	if _weapon_item and is_instance_valid(_weapon_item):
		_weapon_item.queue_free()
		_weapon_item = null
	if _shield_item and is_instance_valid(_shield_item):
		_shield_item.queue_free()
		_shield_item = null

	# Clear skeleton
	if skeleton and is_instance_valid(skeleton):
		skeleton.queue_free()
		skeleton = null


func _create_skeleton() -> void:
	skeleton = HumanoidSkeleton.new()

	match body_type:
		BodyType.DEFAULT:
			skeleton.proportions = HumanoidTypes.BodyProportions.default()
		BodyType.STOCKY:
			skeleton.proportions = HumanoidTypes.BodyProportions.stocky()
		BodyType.SLIM:
			skeleton.proportions = HumanoidTypes.BodyProportions.slim()
		BodyType.CHIBI:
			skeleton.proportions = HumanoidTypes.BodyProportions.chibi()

	add_child(skeleton)
	skeleton.build_skeleton()


func _create_body() -> void:
	_body_meshes = HumanoidMeshGenerator.generate_body_meshes(skeleton, palette)


func _create_clothing() -> void:
	if hat_style >= 0:
		var hat := HumanoidClothing.create_hat(hat_style, skeleton,
			palette.get_color(HumanoidTypes.ColorCategory.HAT))
		if hat:
			_clothing_items.append(hat)

	if glasses:
		var specs := HumanoidClothing.create_glasses(0, skeleton,
			palette.get_color(HumanoidTypes.ColorCategory.ACCESSORY))
		if specs:
			_clothing_items.append(specs)

	if backpack:
		var pack := HumanoidClothing.create_backpack(0, skeleton,
			palette.get_color(HumanoidTypes.ColorCategory.ACCESSORY))
		if pack:
			_clothing_items.append(pack)


func _create_weapons() -> void:
	if weapon_type != HumanoidWeapon.WeaponType.NONE:
		_weapon_item = HumanoidWeapon.create_weapon(
			weapon_type,
			skeleton,
			palette.get_color(HumanoidTypes.ColorCategory.WEAPON_PRIMARY),
			palette.get_color(HumanoidTypes.ColorCategory.WEAPON_SECONDARY),
			true
		)

	if shield:
		_shield_item = HumanoidWeapon.create_weapon(
			HumanoidWeapon.WeaponType.SHIELD,
			skeleton,
			palette.get_color(HumanoidTypes.ColorCategory.WEAPON_PRIMARY),
			palette.get_color(HumanoidTypes.ColorCategory.WEAPON_SECONDARY),
			false
		)


## === Appearance API ===

func randomize_appearance() -> void:
	palette.randomize()

	body_type = randi() % BodyType.size() as BodyType
	hat_style = randi() % 5 - 1  ## -1 to 3
	glasses = randf() > 0.7
	backpack = randf() > 0.8
	weapon_type = randi() % HumanoidWeapon.WeaponType.size() as HumanoidWeapon.WeaponType
	shield = randf() > 0.85 and weapon_type != HumanoidWeapon.WeaponType.RIFLE


func set_color(category: HumanoidTypes.ColorCategory, color: Color) -> void:
	palette.set_color(category, color)


func set_body_type(type: BodyType) -> void:
	body_type = type


func set_hat(style: int) -> void:
	hat_style = style


func set_weapon(type: HumanoidWeapon.WeaponType) -> void:
	weapon_type = type


func set_glasses_enabled(enabled: bool) -> void:
	glasses = enabled


func set_backpack_enabled(enabled: bool) -> void:
	backpack = enabled


func set_shield_enabled(enabled: bool) -> void:
	shield = enabled


## === Skeleton Access ===

func get_skeleton() -> HumanoidSkeleton:
	return skeleton


func get_bone_transform(part: HumanoidTypes.BodyPart) -> Transform3D:
	if not skeleton:
		return Transform3D.IDENTITY

	var bone_idx := skeleton.get_bone_index(part)
	if bone_idx >= 0:
		return skeleton.get_bone_global_pose(bone_idx)

	return Transform3D.IDENTITY


func get_proportions() -> HumanoidTypes.BodyProportions:
	if skeleton:
		return skeleton.proportions
	return HumanoidTypes.BodyProportions.default()
