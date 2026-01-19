## HumanoidMeshGenerator - Generates simple mesh parts for humanoid skeleton
class_name HumanoidMeshGenerator
extends RefCounted


## Generate all body part meshes attached to skeleton
static func generate_body_meshes(skeleton: HumanoidSkeleton, palette: HumanoidTypes.ColorPalette) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	var props := skeleton.proportions

	# Head
	meshes.append(_create_head(skeleton, props, palette))

	# Torso
	meshes.append(_create_torso(skeleton, props, palette))

	# Arms
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.UPPER_ARM_L,
		props.arm_thickness, props.height * props.arm_length * 0.5, palette, HumanoidTypes.ColorCategory.SHIRT))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.LOWER_ARM_L,
		props.arm_thickness * 0.9, props.height * props.arm_length * 0.4, palette, HumanoidTypes.ColorCategory.SKIN))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.UPPER_ARM_R,
		props.arm_thickness, props.height * props.arm_length * 0.5, palette, HumanoidTypes.ColorCategory.SHIRT))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.LOWER_ARM_R,
		props.arm_thickness * 0.9, props.height * props.arm_length * 0.4, palette, HumanoidTypes.ColorCategory.SKIN))

	# Hands
	meshes.append(_create_hand(skeleton, HumanoidTypes.BodyPart.HAND_L, props, palette))
	meshes.append(_create_hand(skeleton, HumanoidTypes.BodyPart.HAND_R, props, palette))

	# Legs
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.THIGH_L,
		props.leg_thickness, props.height * props.leg_length * 0.5, palette, HumanoidTypes.ColorCategory.PANTS))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.CALF_L,
		props.leg_thickness * 0.85, props.height * props.leg_length * 0.45, palette, HumanoidTypes.ColorCategory.PANTS))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.THIGH_R,
		props.leg_thickness, props.height * props.leg_length * 0.5, palette, HumanoidTypes.ColorCategory.PANTS))
	meshes.append(_create_limb(skeleton, HumanoidTypes.BodyPart.CALF_R,
		props.leg_thickness * 0.85, props.height * props.leg_length * 0.45, palette, HumanoidTypes.ColorCategory.PANTS))

	# Feet
	meshes.append(_create_foot(skeleton, HumanoidTypes.BodyPart.FOOT_L, props, palette))
	meshes.append(_create_foot(skeleton, HumanoidTypes.BodyPart.FOOT_R, props, palette))

	return meshes


static func _create_head(skeleton: HumanoidSkeleton, props: HumanoidTypes.BodyProportions, palette: HumanoidTypes.ColorPalette) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	var head_size := props.height * 0.1 * props.head_scale

	# Main head shape (sphere)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = head_size
	head_mesh.height = head_size * 2.2
	mesh_instance.mesh = head_mesh

	# Material
	mesh_instance.material_override = _create_material(palette.get_color(HumanoidTypes.ColorCategory.SKIN))

	# Attach to skeleton
	var bone_idx := skeleton.get_bone_index(HumanoidTypes.BodyPart.HEAD)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(mesh_instance)
		mesh_instance.position = Vector3(0, head_size, 0)

	return mesh_instance


static func _create_torso(skeleton: HumanoidSkeleton, props: HumanoidTypes.BodyProportions, palette: HumanoidTypes.ColorPalette) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	var torso_height := props.height * props.torso_length
	var torso_width := props.shoulder_width
	var torso_depth := props.body_thickness

	# Box mesh for torso
	var torso_mesh := BoxMesh.new()
	torso_mesh.size = Vector3(torso_width, torso_height, torso_depth)
	mesh_instance.mesh = torso_mesh

	# Material
	mesh_instance.material_override = _create_material(palette.get_color(HumanoidTypes.ColorCategory.SHIRT))

	# Attach to pelvis
	var bone_idx := skeleton.get_bone_index(HumanoidTypes.BodyPart.PELVIS)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(mesh_instance)
		mesh_instance.position = Vector3(0, torso_height * 0.5, 0)

	return mesh_instance


static func _create_limb(skeleton: HumanoidSkeleton, part: HumanoidTypes.BodyPart, radius: float, length: float, palette: HumanoidTypes.ColorPalette, color_cat: HumanoidTypes.ColorCategory) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	var limb_mesh := CapsuleMesh.new()
	limb_mesh.radius = radius
	limb_mesh.height = length
	mesh_instance.mesh = limb_mesh

	mesh_instance.material_override = _create_material(palette.get_color(color_cat))

	var bone_idx := skeleton.get_bone_index(part)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(mesh_instance)
		mesh_instance.position = Vector3(0, -length * 0.5, 0)

	return mesh_instance


static func _create_hand(skeleton: HumanoidSkeleton, part: HumanoidTypes.BodyPart, props: HumanoidTypes.BodyProportions, palette: HumanoidTypes.ColorPalette) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	var hand_size := props.arm_thickness * 1.5

	var hand_mesh := BoxMesh.new()
	hand_mesh.size = Vector3(hand_size, hand_size * 1.2, hand_size * 0.5)
	mesh_instance.mesh = hand_mesh

	mesh_instance.material_override = _create_material(palette.get_color(HumanoidTypes.ColorCategory.SKIN))

	var bone_idx := skeleton.get_bone_index(part)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(mesh_instance)
		mesh_instance.position = Vector3(0, -hand_size * 0.6, 0)

	return mesh_instance


static func _create_foot(skeleton: HumanoidSkeleton, part: HumanoidTypes.BodyPart, props: HumanoidTypes.BodyProportions, palette: HumanoidTypes.ColorPalette) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()

	var foot_length := props.leg_thickness * 2.5
	var foot_width := props.leg_thickness * 1.2
	var foot_height := props.leg_thickness * 0.8

	var foot_mesh := BoxMesh.new()
	foot_mesh.size = Vector3(foot_width, foot_height, foot_length)
	mesh_instance.mesh = foot_mesh

	mesh_instance.material_override = _create_material(palette.get_color(HumanoidTypes.ColorCategory.SHOES))

	var bone_idx := skeleton.get_bone_index(part)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(mesh_instance)
		mesh_instance.position = Vector3(0, -foot_height * 0.5, foot_length * 0.3)

	return mesh_instance


static func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.8
	mat.metallic = 0.0
	return mat
