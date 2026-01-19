## HumanoidClothing - Generates simple clothing meshes for humanoids
class_name HumanoidClothing
extends RefCounted


## Generate clothing item based on slot
static func create_clothing(slot: HumanoidTypes.ClothingSlot, style: int, skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	match slot:
		HumanoidTypes.ClothingSlot.HEAD:
			return create_hat(style, skeleton, color)
		HumanoidTypes.ClothingSlot.FACE:
			return create_glasses(style, skeleton, color)
		HumanoidTypes.ClothingSlot.BACK:
			return create_backpack(style, skeleton, color)
		_:
			return null


## === Hats ===

static func create_hat(style: int, skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	match style:
		0:
			return _create_cap(skeleton, color)
		1:
			return _create_tophat(skeleton, color)
		2:
			return _create_beanie(skeleton, color)
		3:
			return _create_cowboy_hat(skeleton, color)
		_:
			return _create_cap(skeleton, color)


static func _create_cap(skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Cap"

	var head_size := skeleton.proportions.height * 0.1 * skeleton.proportions.head_scale

	# Cap dome
	var dome := MeshInstance3D.new()
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = head_size * 1.05
	dome_mesh.height = head_size * 0.8
	dome_mesh.is_hemisphere = true
	dome.mesh = dome_mesh
	dome.position = Vector3(0, head_size * 1.1, 0)
	dome.material_override = _create_material(color)
	root.add_child(dome)

	# Brim
	var brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = head_size * 1.3
	brim_mesh.bottom_radius = head_size * 1.1
	brim_mesh.height = 0.02
	brim.mesh = brim_mesh
	brim.position = Vector3(0, head_size * 1.1, head_size * 0.3)
	brim.rotation.x = deg_to_rad(-10)
	brim.material_override = _create_material(color)
	root.add_child(brim)

	_attach_to_head(root, skeleton)
	return root


static func _create_tophat(skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "TopHat"

	var head_size := skeleton.proportions.height * 0.1 * skeleton.proportions.head_scale

	# Hat cylinder
	var cylinder := MeshInstance3D.new()
	var cyl_mesh := CylinderMesh.new()
	cyl_mesh.top_radius = head_size * 0.8
	cyl_mesh.bottom_radius = head_size * 0.85
	cyl_mesh.height = head_size * 1.2
	cylinder.mesh = cyl_mesh
	cylinder.position = Vector3(0, head_size * 1.5, 0)
	cylinder.material_override = _create_material(color)
	root.add_child(cylinder)

	# Brim
	var brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = head_size * 1.3
	brim_mesh.bottom_radius = head_size * 1.3
	brim_mesh.height = 0.03
	brim.mesh = brim_mesh
	brim.position = Vector3(0, head_size * 0.95, 0)
	brim.material_override = _create_material(color)
	root.add_child(brim)

	_attach_to_head(root, skeleton)
	return root


static func _create_beanie(skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Beanie"

	var head_size := skeleton.proportions.height * 0.1 * skeleton.proportions.head_scale

	var beanie := MeshInstance3D.new()
	var beanie_mesh := SphereMesh.new()
	beanie_mesh.radius = head_size * 1.1
	beanie_mesh.height = head_size * 1.4
	beanie_mesh.is_hemisphere = true
	beanie.mesh = beanie_mesh
	beanie.position = Vector3(0, head_size * 0.9, 0)
	beanie.material_override = _create_material(color)
	root.add_child(beanie)

	_attach_to_head(root, skeleton)
	return root


static func _create_cowboy_hat(skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "CowboyHat"

	var head_size := skeleton.proportions.height * 0.1 * skeleton.proportions.head_scale

	# Crown
	var crown := MeshInstance3D.new()
	var crown_mesh := CylinderMesh.new()
	crown_mesh.top_radius = head_size * 0.7
	crown_mesh.bottom_radius = head_size * 0.9
	crown_mesh.height = head_size * 0.7
	crown.mesh = crown_mesh
	crown.position = Vector3(0, head_size * 1.3, 0)
	crown.material_override = _create_material(color)
	root.add_child(crown)

	# Wide brim
	var brim := MeshInstance3D.new()
	var brim_mesh := CylinderMesh.new()
	brim_mesh.top_radius = head_size * 1.8
	brim_mesh.bottom_radius = head_size * 1.8
	brim_mesh.height = 0.03
	brim.mesh = brim_mesh
	brim.position = Vector3(0, head_size * 0.95, 0)
	brim.material_override = _create_material(color)
	root.add_child(brim)

	_attach_to_head(root, skeleton)
	return root


## === Accessories ===

static func create_glasses(style: int, skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Glasses"

	var head_size := skeleton.proportions.height * 0.1 * skeleton.proportions.head_scale
	var lens_size := head_size * 0.3
	var frame_color := color

	# Left lens frame
	var left_frame := MeshInstance3D.new()
	var frame_mesh := TorusMesh.new()
	frame_mesh.inner_radius = lens_size * 0.8
	frame_mesh.outer_radius = lens_size
	left_frame.mesh = frame_mesh
	left_frame.position = Vector3(-lens_size, head_size * 0.1, head_size * 0.85)
	left_frame.rotation.x = deg_to_rad(90)
	left_frame.material_override = _create_material(frame_color)
	root.add_child(left_frame)

	# Right lens frame
	var right_frame := MeshInstance3D.new()
	right_frame.mesh = frame_mesh
	right_frame.position = Vector3(lens_size, head_size * 0.1, head_size * 0.85)
	right_frame.rotation.x = deg_to_rad(90)
	right_frame.material_override = _create_material(frame_color)
	root.add_child(right_frame)

	# Bridge
	var bridge := MeshInstance3D.new()
	var bridge_mesh := CylinderMesh.new()
	bridge_mesh.top_radius = 0.01
	bridge_mesh.bottom_radius = 0.01
	bridge_mesh.height = lens_size
	bridge.mesh = bridge_mesh
	bridge.position = Vector3(0, head_size * 0.1, head_size * 0.9)
	bridge.rotation.z = deg_to_rad(90)
	bridge.material_override = _create_material(frame_color)
	root.add_child(bridge)

	_attach_to_head(root, skeleton)
	return root


static func create_backpack(style: int, skeleton: HumanoidSkeleton, color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Backpack"

	var props := skeleton.proportions
	var pack_width := props.shoulder_width * 0.7
	var pack_height := props.height * props.torso_length * 0.6
	var pack_depth := props.body_thickness * 1.5

	var pack := MeshInstance3D.new()
	var pack_mesh := BoxMesh.new()
	pack_mesh.size = Vector3(pack_width, pack_height, pack_depth)
	pack.mesh = pack_mesh
	pack.position = Vector3(0, pack_height * 0.3, -pack_depth * 0.5 - props.body_thickness * 0.5)
	pack.material_override = _create_material(color)
	root.add_child(pack)

	# Attach to chest
	var bone_idx := skeleton.get_bone_index(HumanoidTypes.BodyPart.CHEST)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(root)

	return root


## === Utility ===

static func _attach_to_head(node: Node3D, skeleton: HumanoidSkeleton) -> void:
	var bone_idx := skeleton.get_bone_index(HumanoidTypes.BodyPart.HEAD)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(node)


static func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.7
	return mat
