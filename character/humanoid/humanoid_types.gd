## HumanoidTypes - Enums and data for procedural humanoid system
class_name HumanoidTypes
extends RefCounted


## Body part identifiers for the skeleton
enum BodyPart {
	# Core
	PELVIS,
	SPINE_LOWER,
	SPINE_UPPER,
	CHEST,
	NECK,
	HEAD,

	# Left Arm
	SHOULDER_L,
	UPPER_ARM_L,
	LOWER_ARM_L,
	HAND_L,

	# Right Arm
	SHOULDER_R,
	UPPER_ARM_R,
	LOWER_ARM_R,
	HAND_R,

	# Left Leg
	THIGH_L,
	CALF_L,
	FOOT_L,

	# Right Leg
	THIGH_R,
	CALF_R,
	FOOT_R,
}


## Clothing/accessory slots
enum ClothingSlot {
	NONE,
	HEAD,           ## Hats, helmets, hair
	FACE,           ## Glasses, masks
	TORSO_UPPER,    ## Shirts, jackets
	TORSO_LOWER,    ## Belts, waist items
	LEGS,           ## Pants, shorts
	FEET,           ## Shoes, boots
	HAND_L,         ## Gloves, watches
	HAND_R,         ## Gloves, rings
	BACK,           ## Backpacks, capes
	WEAPON_R,       ## Right hand weapon
	WEAPON_L,       ## Left hand weapon
}


## Color categories for the palette system
enum ColorCategory {
	SKIN,
	HAIR,
	EYE,
	SHIRT,
	PANTS,
	SHOES,
	HAT,
	ACCESSORY,
	WEAPON_PRIMARY,
	WEAPON_SECONDARY,
}


## Body proportions for different character types
class BodyProportions:
	var height: float = 1.8               ## Total height in meters
	var head_scale: float = 1.0           ## Head size multiplier
	var torso_length: float = 0.5         ## Torso proportion
	var arm_length: float = 0.4           ## Arm length proportion
	var leg_length: float = 0.5           ## Leg length proportion
	var shoulder_width: float = 0.4       ## Shoulder width
	var hip_width: float = 0.3            ## Hip width
	var arm_thickness: float = 0.06       ## Arm radius
	var leg_thickness: float = 0.08       ## Leg radius
	var body_thickness: float = 0.15      ## Torso depth

	static func default() -> BodyProportions:
		return BodyProportions.new()

	static func stocky() -> BodyProportions:
		var p := BodyProportions.new()
		p.height = 1.6
		p.shoulder_width = 0.5
		p.hip_width = 0.35
		p.arm_thickness = 0.08
		p.leg_thickness = 0.1
		p.body_thickness = 0.2
		return p

	static func slim() -> BodyProportions:
		var p := BodyProportions.new()
		p.height = 1.85
		p.shoulder_width = 0.35
		p.hip_width = 0.25
		p.arm_thickness = 0.04
		p.leg_thickness = 0.06
		p.body_thickness = 0.1
		return p

	static func chibi() -> BodyProportions:
		var p := BodyProportions.new()
		p.height = 1.0
		p.head_scale = 1.5
		p.torso_length = 0.35
		p.arm_length = 0.3
		p.leg_length = 0.35
		p.shoulder_width = 0.3
		p.hip_width = 0.25
		p.arm_thickness = 0.05
		p.leg_thickness = 0.07
		return p


## Character color palette
class ColorPalette:
	var colors: Dictionary = {}  ## ColorCategory -> Color

	func _init() -> void:
		# Set defaults
		colors[ColorCategory.SKIN] = Color(0.87, 0.72, 0.58)
		colors[ColorCategory.HAIR] = Color(0.2, 0.15, 0.1)
		colors[ColorCategory.EYE] = Color(0.3, 0.5, 0.7)
		colors[ColorCategory.SHIRT] = Color(0.2, 0.4, 0.8)
		colors[ColorCategory.PANTS] = Color(0.15, 0.15, 0.2)
		colors[ColorCategory.SHOES] = Color(0.1, 0.1, 0.1)
		colors[ColorCategory.HAT] = Color(0.8, 0.2, 0.2)
		colors[ColorCategory.ACCESSORY] = Color(0.8, 0.7, 0.2)
		colors[ColorCategory.WEAPON_PRIMARY] = Color(0.5, 0.5, 0.5)
		colors[ColorCategory.WEAPON_SECONDARY] = Color(0.3, 0.2, 0.1)

	func get_color(category: ColorCategory) -> Color:
		return colors.get(category, Color.WHITE)

	func set_color(category: ColorCategory, color: Color) -> void:
		colors[category] = color

	func randomize() -> void:
		colors[ColorCategory.SKIN] = _random_skin_color()
		colors[ColorCategory.HAIR] = _random_hair_color()
		colors[ColorCategory.EYE] = Color(randf(), randf(), randf())
		colors[ColorCategory.SHIRT] = Color(randf(), randf(), randf())
		colors[ColorCategory.PANTS] = Color(randf() * 0.5, randf() * 0.5, randf() * 0.5)
		colors[ColorCategory.SHOES] = Color(randf() * 0.3, randf() * 0.3, randf() * 0.3)
		colors[ColorCategory.HAT] = Color(randf(), randf(), randf())

	func _random_skin_color() -> Color:
		var skin_tones := [
			Color(0.95, 0.87, 0.78),  # Light
			Color(0.87, 0.72, 0.58),  # Medium light
			Color(0.76, 0.57, 0.42),  # Medium
			Color(0.55, 0.38, 0.26),  # Medium dark
			Color(0.36, 0.24, 0.15),  # Dark
		]
		return skin_tones[randi() % skin_tones.size()]

	func _random_hair_color() -> Color:
		var hair_colors := [
			Color(0.1, 0.05, 0.0),    # Black
			Color(0.3, 0.2, 0.1),     # Dark brown
			Color(0.5, 0.35, 0.2),    # Brown
			Color(0.7, 0.5, 0.3),     # Light brown
			Color(0.9, 0.8, 0.5),     # Blonde
			Color(0.6, 0.3, 0.1),     # Red/Auburn
			Color(0.5, 0.5, 0.5),     # Gray
			Color(0.9, 0.9, 0.9),     # White
			Color(1.0, 0.2, 0.5),     # Pink (stylized)
			Color(0.2, 0.5, 1.0),     # Blue (stylized)
		]
		return hair_colors[randi() % hair_colors.size()]


## Bone data for skeleton construction
class BoneData:
	var name: String
	var parent: BodyPart
	var local_position: Vector3
	var local_rotation: Vector3
	var length: float
	var mesh_type: MeshType = MeshType.CAPSULE

	enum MeshType {
		NONE,
		CAPSULE,
		BOX,
		SPHERE,
		CYLINDER,
	}
