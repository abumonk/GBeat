## ItemPartData - Single component of an item
class_name ItemPartData
extends Resource


enum ShapeType {
	BOX,
	SPHERE,
	CYLINDER,
	CAPSULE,
	CONE,
	PRISM,
	TORUS,
}


@export var shape: ShapeType = ShapeType.BOX
@export var size: Vector3 = Vector3.ONE
@export var position: Vector3 = Vector3.ZERO
@export var rotation: Vector3 = Vector3.ZERO
@export var color_override: Color = Color.WHITE
@export var use_category_color: bool = true


## Mesh generator helper
class ItemMeshGenerator:
	static func create_shape_mesh(part: ItemPartData) -> Mesh:
		var mesh: Mesh

		match part.shape:
			ItemPartData.ShapeType.BOX:
				var box := BoxMesh.new()
				box.size = part.size
				mesh = box

			ItemPartData.ShapeType.SPHERE:
				var sphere := SphereMesh.new()
				sphere.radius = part.size.x / 2.0
				sphere.height = part.size.y
				mesh = sphere

			ItemPartData.ShapeType.CYLINDER:
				var cylinder := CylinderMesh.new()
				cylinder.top_radius = part.size.x / 2.0
				cylinder.bottom_radius = part.size.z / 2.0
				cylinder.height = part.size.y
				mesh = cylinder

			ItemPartData.ShapeType.CAPSULE:
				var capsule := CapsuleMesh.new()
				capsule.radius = part.size.x / 2.0
				capsule.height = part.size.y
				mesh = capsule

			ItemPartData.ShapeType.CONE:
				var cone := CylinderMesh.new()
				cone.top_radius = 0.0
				cone.bottom_radius = part.size.x / 2.0
				cone.height = part.size.y
				mesh = cone

			ItemPartData.ShapeType.PRISM:
				var prism := PrismMesh.new()
				prism.size = part.size
				mesh = prism

			ItemPartData.ShapeType.TORUS:
				var torus := TorusMesh.new()
				torus.inner_radius = part.size.x / 4.0
				torus.outer_radius = part.size.x / 2.0
				mesh = torus

		return mesh
