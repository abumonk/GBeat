## HumanoidWeapon - Generates simple weapon meshes for humanoids
class_name HumanoidWeapon
extends RefCounted


enum WeaponType {
	NONE,
	SWORD,
	AXE,
	HAMMER,
	PISTOL,
	RIFLE,
	STAFF,
	DAGGER,
	SHIELD,
}


## Create weapon and attach to hand
static func create_weapon(weapon_type: WeaponType, skeleton: HumanoidSkeleton, primary_color: Color, secondary_color: Color, right_hand: bool = true) -> Node3D:
	var weapon: Node3D = null

	match weapon_type:
		WeaponType.SWORD:
			weapon = _create_sword(skeleton, primary_color, secondary_color)
		WeaponType.AXE:
			weapon = _create_axe(skeleton, primary_color, secondary_color)
		WeaponType.HAMMER:
			weapon = _create_hammer(skeleton, primary_color, secondary_color)
		WeaponType.PISTOL:
			weapon = _create_pistol(skeleton, primary_color, secondary_color)
		WeaponType.RIFLE:
			weapon = _create_rifle(skeleton, primary_color, secondary_color)
		WeaponType.STAFF:
			weapon = _create_staff(skeleton, primary_color, secondary_color)
		WeaponType.DAGGER:
			weapon = _create_dagger(skeleton, primary_color, secondary_color)
		WeaponType.SHIELD:
			weapon = _create_shield(skeleton, primary_color, secondary_color)
		_:
			return null

	if weapon:
		var hand_part := HumanoidTypes.BodyPart.HAND_R if right_hand else HumanoidTypes.BodyPart.HAND_L
		_attach_to_hand(weapon, skeleton, hand_part)

	return weapon


static func _create_sword(skeleton: HumanoidSkeleton, blade_color: Color, handle_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Sword"

	var scale := skeleton.proportions.height / 1.8

	# Blade
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.05 * scale, 0.8 * scale, 0.01 * scale)
	blade.mesh = blade_mesh
	blade.position = Vector3(0, 0.45 * scale, 0)
	blade.material_override = _create_material(blade_color)
	root.add_child(blade)

	# Handle
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.015 * scale
	handle_mesh.bottom_radius = 0.015 * scale
	handle_mesh.height = 0.15 * scale
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0, 0)
	handle.material_override = _create_material(handle_color)
	root.add_child(handle)

	# Guard
	var guard := MeshInstance3D.new()
	var guard_mesh := BoxMesh.new()
	guard_mesh.size = Vector3(0.12 * scale, 0.02 * scale, 0.03 * scale)
	guard.mesh = guard_mesh
	guard.position = Vector3(0, 0.08 * scale, 0)
	guard.material_override = _create_material(blade_color)
	root.add_child(guard)

	return root


static func _create_axe(skeleton: HumanoidSkeleton, head_color: Color, handle_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Axe"

	var scale := skeleton.proportions.height / 1.8

	# Handle
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.02 * scale
	handle_mesh.bottom_radius = 0.025 * scale
	handle_mesh.height = 0.7 * scale
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.3 * scale, 0)
	handle.material_override = _create_material(handle_color)
	root.add_child(handle)

	# Axe head
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.15 * scale, 0.2 * scale, 0.04 * scale)
	head.mesh = head_mesh
	head.position = Vector3(0.08 * scale, 0.6 * scale, 0)
	head.material_override = _create_material(head_color)
	root.add_child(head)

	return root


static func _create_hammer(skeleton: HumanoidSkeleton, head_color: Color, handle_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Hammer"

	var scale := skeleton.proportions.height / 1.8

	# Handle
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.02 * scale
	handle_mesh.bottom_radius = 0.025 * scale
	handle_mesh.height = 0.6 * scale
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0.25 * scale, 0)
	handle.material_override = _create_material(handle_color)
	root.add_child(handle)

	# Hammer head
	var head := MeshInstance3D.new()
	var head_mesh := BoxMesh.new()
	head_mesh.size = Vector3(0.2 * scale, 0.15 * scale, 0.1 * scale)
	head.mesh = head_mesh
	head.position = Vector3(0, 0.55 * scale, 0)
	head.material_override = _create_material(head_color)
	root.add_child(head)

	return root


static func _create_pistol(skeleton: HumanoidSkeleton, body_color: Color, grip_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Pistol"

	var scale := skeleton.proportions.height / 1.8

	# Barrel
	var barrel := MeshInstance3D.new()
	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = Vector3(0.03 * scale, 0.03 * scale, 0.15 * scale)
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(0, 0.02 * scale, 0.08 * scale)
	barrel.material_override = _create_material(body_color)
	root.add_child(barrel)

	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.025 * scale, 0.06 * scale, 0.1 * scale)
	body.mesh = body_mesh
	body.position = Vector3(0, 0, 0)
	body.material_override = _create_material(body_color)
	root.add_child(body)

	# Grip
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.025 * scale, 0.08 * scale, 0.03 * scale)
	grip.mesh = grip_mesh
	grip.position = Vector3(0, -0.05 * scale, -0.02 * scale)
	grip.rotation.x = deg_to_rad(-15)
	grip.material_override = _create_material(grip_color)
	root.add_child(grip)

	return root


static func _create_rifle(skeleton: HumanoidSkeleton, body_color: Color, stock_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Rifle"

	var scale := skeleton.proportions.height / 1.8

	# Barrel
	var barrel := MeshInstance3D.new()
	var barrel_mesh := CylinderMesh.new()
	barrel_mesh.top_radius = 0.015 * scale
	barrel_mesh.bottom_radius = 0.015 * scale
	barrel_mesh.height = 0.5 * scale
	barrel.mesh = barrel_mesh
	barrel.rotation.x = deg_to_rad(90)
	barrel.position = Vector3(0, 0.03 * scale, 0.35 * scale)
	barrel.material_override = _create_material(body_color)
	root.add_child(barrel)

	# Body
	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.04 * scale, 0.08 * scale, 0.25 * scale)
	body.mesh = body_mesh
	body.position = Vector3(0, 0, 0)
	body.material_override = _create_material(body_color)
	root.add_child(body)

	# Stock
	var stock := MeshInstance3D.new()
	var stock_mesh := BoxMesh.new()
	stock_mesh.size = Vector3(0.03 * scale, 0.1 * scale, 0.2 * scale)
	stock.mesh = stock_mesh
	stock.position = Vector3(0, -0.02 * scale, -0.2 * scale)
	stock.rotation.x = deg_to_rad(-10)
	stock.material_override = _create_material(stock_color)
	root.add_child(stock)

	return root


static func _create_staff(skeleton: HumanoidSkeleton, shaft_color: Color, orb_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Staff"

	var scale := skeleton.proportions.height / 1.8

	# Shaft
	var shaft := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.02 * scale
	shaft_mesh.bottom_radius = 0.025 * scale
	shaft_mesh.height = 1.4 * scale
	shaft.mesh = shaft_mesh
	shaft.position = Vector3(0, 0.6 * scale, 0)
	shaft.material_override = _create_material(shaft_color)
	root.add_child(shaft)

	# Orb on top
	var orb := MeshInstance3D.new()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.06 * scale
	orb.mesh = orb_mesh
	orb.position = Vector3(0, 1.35 * scale, 0)

	var orb_mat := StandardMaterial3D.new()
	orb_mat.albedo_color = orb_color
	orb_mat.emission_enabled = true
	orb_mat.emission = orb_color
	orb_mat.emission_energy_multiplier = 2.0
	orb.material_override = orb_mat
	root.add_child(orb)

	return root


static func _create_dagger(skeleton: HumanoidSkeleton, blade_color: Color, handle_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Dagger"

	var scale := skeleton.proportions.height / 1.8

	# Blade
	var blade := MeshInstance3D.new()
	var blade_mesh := BoxMesh.new()
	blade_mesh.size = Vector3(0.025 * scale, 0.2 * scale, 0.005 * scale)
	blade.mesh = blade_mesh
	blade.position = Vector3(0, 0.15 * scale, 0)
	blade.material_override = _create_material(blade_color)
	root.add_child(blade)

	# Handle
	var handle := MeshInstance3D.new()
	var handle_mesh := CylinderMesh.new()
	handle_mesh.top_radius = 0.012 * scale
	handle_mesh.bottom_radius = 0.015 * scale
	handle_mesh.height = 0.1 * scale
	handle.mesh = handle_mesh
	handle.position = Vector3(0, 0, 0)
	handle.material_override = _create_material(handle_color)
	root.add_child(handle)

	return root


static func _create_shield(skeleton: HumanoidSkeleton, face_color: Color, rim_color: Color) -> Node3D:
	var root := Node3D.new()
	root.name = "Shield"

	var scale := skeleton.proportions.height / 1.8

	# Shield face
	var face := MeshInstance3D.new()
	var face_mesh := CylinderMesh.new()
	face_mesh.top_radius = 0.25 * scale
	face_mesh.bottom_radius = 0.25 * scale
	face_mesh.height = 0.03 * scale
	face.mesh = face_mesh
	face.rotation.x = deg_to_rad(90)
	face.position = Vector3(0, 0, 0.02 * scale)
	face.material_override = _create_material(face_color)
	root.add_child(face)

	# Rim
	var rim := MeshInstance3D.new()
	var rim_mesh := TorusMesh.new()
	rim_mesh.inner_radius = 0.22 * scale
	rim_mesh.outer_radius = 0.26 * scale
	rim.mesh = rim_mesh
	rim.rotation.x = deg_to_rad(90)
	rim.position = Vector3(0, 0, 0.02 * scale)
	rim.material_override = _create_material(rim_color)
	root.add_child(rim)

	return root


static func _attach_to_hand(weapon: Node3D, skeleton: HumanoidSkeleton, hand_part: HumanoidTypes.BodyPart) -> void:
	var bone_idx := skeleton.get_bone_index(hand_part)
	if bone_idx >= 0:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = skeleton.get_bone_name(bone_idx)
		skeleton.add_child(attachment)
		attachment.add_child(weapon)


static func _create_material(color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.5
	mat.metallic = 0.3
	return mat
