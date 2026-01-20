## ItemDefinition - Resource defining a wearable item
class_name ItemDefinition
extends Resource


@export var name: String = ""
@export var slot: HumanoidTypes.ClothingSlot = HumanoidTypes.ClothingSlot.HEAD
@export var color_category: HumanoidTypes.ColorCategory = HumanoidTypes.ColorCategory.HAT
@export var parts: Array[ItemPartData] = []

@export_group("Attachment")
@export var attachment_bone: String = "Head"
@export var offset: Vector3 = Vector3.ZERO
@export var rotation_offset: Vector3 = Vector3.ZERO
@export var scale_factor: Vector3 = Vector3.ONE


## Create mesh for entire item
func create_mesh() -> Node3D:
	var root := Node3D.new()

	for part in parts:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = ItemMeshGenerator.create_shape_mesh(part)

		var mat := StandardMaterial3D.new()
		mat.albedo_color = part.color_override
		mesh_instance.material_override = mat

		mesh_instance.position = part.position
		mesh_instance.rotation = part.rotation

		root.add_child(mesh_instance)

	root.position = offset
	root.rotation = rotation_offset
	root.scale = scale_factor

	return root


## Duplicate item
func duplicate_item() -> ItemDefinition:
	var dupe := ItemDefinition.new()
	dupe.name = name + "_copy"
	dupe.slot = slot
	dupe.color_category = color_category
	dupe.attachment_bone = attachment_bone
	dupe.offset = offset
	dupe.rotation_offset = rotation_offset
	dupe.scale_factor = scale_factor

	for part in parts:
		dupe.parts.append(part.duplicate())

	return dupe
