## BodyCustomization - Resource defining character body proportions
@tool
class_name BodyCustomization
extends Resource


## Overall proportions
@export_range(0.8, 1.2) var height: float = 1.0
@export_range(0.8, 1.2) var body_width: float = 1.0
@export_range(0.8, 1.2) var body_depth: float = 1.0

## Head
@export_group("Head")
@export_range(0.8, 1.2) var head_size: float = 1.0
@export_range(0.9, 1.1) var head_width: float = 1.0

## Torso
@export_group("Torso")
@export_range(0.8, 1.2) var shoulder_width: float = 1.0
@export_range(0.8, 1.2) var chest_size: float = 1.0
@export_range(0.8, 1.2) var waist_size: float = 1.0
@export_range(0.8, 1.2) var hip_width: float = 1.0

## Arms
@export_group("Arms")
@export_range(0.8, 1.2) var arm_length: float = 1.0
@export_range(0.8, 1.2) var arm_thickness: float = 1.0
@export_range(0.8, 1.2) var hand_size: float = 1.0

## Legs
@export_group("Legs")
@export_range(0.8, 1.2) var leg_length: float = 1.0
@export_range(0.8, 1.2) var leg_thickness: float = 1.0
@export_range(0.8, 1.2) var foot_size: float = 1.0


## Blend shape name mappings
const BLEND_SHAPE_NAMES := {
	"height": "Height",
	"body_width": "BodyWidth",
	"body_depth": "BodyDepth",
	"head_size": "HeadSize",
	"head_width": "HeadWidth",
	"shoulder_width": "ShoulderWidth",
	"chest_size": "ChestSize",
	"waist_size": "WaistSize",
	"hip_width": "HipWidth",
	"arm_length": "ArmLength",
	"arm_thickness": "ArmThickness",
	"hand_size": "HandSize",
	"leg_length": "LegLength",
	"leg_thickness": "LegThickness",
	"foot_size": "FootSize",
}


func get_blend_value(property: String) -> float:
	var value: float = get(property)
	# Convert from 0.8-1.2 range to -1.0 to 1.0 for blend shapes
	return (value - 1.0) * 5.0


func get_all_blend_values() -> Dictionary:
	var values := {}
	for property in BLEND_SHAPE_NAMES.keys():
		values[BLEND_SHAPE_NAMES[property]] = get_blend_value(property)
	return values


func copy_from(other: BodyCustomization) -> void:
	height = other.height
	body_width = other.body_width
	body_depth = other.body_depth
	head_size = other.head_size
	head_width = other.head_width
	shoulder_width = other.shoulder_width
	chest_size = other.chest_size
	waist_size = other.waist_size
	hip_width = other.hip_width
	arm_length = other.arm_length
	arm_thickness = other.arm_thickness
	hand_size = other.hand_size
	leg_length = other.leg_length
	leg_thickness = other.leg_thickness
	foot_size = other.foot_size


func reset_to_default() -> void:
	height = 1.0
	body_width = 1.0
	body_depth = 1.0
	head_size = 1.0
	head_width = 1.0
	shoulder_width = 1.0
	chest_size = 1.0
	waist_size = 1.0
	hip_width = 1.0
	arm_length = 1.0
	arm_thickness = 1.0
	hand_size = 1.0
	leg_length = 1.0
	leg_thickness = 1.0
	foot_size = 1.0


func lerp_to(target: BodyCustomization, weight: float) -> void:
	height = lerpf(height, target.height, weight)
	body_width = lerpf(body_width, target.body_width, weight)
	body_depth = lerpf(body_depth, target.body_depth, weight)
	head_size = lerpf(head_size, target.head_size, weight)
	head_width = lerpf(head_width, target.head_width, weight)
	shoulder_width = lerpf(shoulder_width, target.shoulder_width, weight)
	chest_size = lerpf(chest_size, target.chest_size, weight)
	waist_size = lerpf(waist_size, target.waist_size, weight)
	hip_width = lerpf(hip_width, target.hip_width, weight)
	arm_length = lerpf(arm_length, target.arm_length, weight)
	arm_thickness = lerpf(arm_thickness, target.arm_thickness, weight)
	hand_size = lerpf(hand_size, target.hand_size, weight)
	leg_length = lerpf(leg_length, target.leg_length, weight)
	leg_thickness = lerpf(leg_thickness, target.leg_thickness, weight)
	foot_size = lerpf(foot_size, target.foot_size, weight)


func serialize() -> Dictionary:
	return {
		"height": height,
		"body_width": body_width,
		"body_depth": body_depth,
		"head_size": head_size,
		"head_width": head_width,
		"shoulder_width": shoulder_width,
		"chest_size": chest_size,
		"waist_size": waist_size,
		"hip_width": hip_width,
		"arm_length": arm_length,
		"arm_thickness": arm_thickness,
		"hand_size": hand_size,
		"leg_length": leg_length,
		"leg_thickness": leg_thickness,
		"foot_size": foot_size,
	}


static func deserialize(data: Dictionary) -> BodyCustomization:
	var custom := BodyCustomization.new()
	custom.height = data.get("height", 1.0)
	custom.body_width = data.get("body_width", 1.0)
	custom.body_depth = data.get("body_depth", 1.0)
	custom.head_size = data.get("head_size", 1.0)
	custom.head_width = data.get("head_width", 1.0)
	custom.shoulder_width = data.get("shoulder_width", 1.0)
	custom.chest_size = data.get("chest_size", 1.0)
	custom.waist_size = data.get("waist_size", 1.0)
	custom.hip_width = data.get("hip_width", 1.0)
	custom.arm_length = data.get("arm_length", 1.0)
	custom.arm_thickness = data.get("arm_thickness", 1.0)
	custom.hand_size = data.get("hand_size", 1.0)
	custom.leg_length = data.get("leg_length", 1.0)
	custom.leg_thickness = data.get("leg_thickness", 1.0)
	custom.foot_size = data.get("foot_size", 1.0)
	return custom


## Preset factory methods
static func create_default() -> BodyCustomization:
	return BodyCustomization.new()


static func create_athletic() -> BodyCustomization:
	var custom := BodyCustomization.new()
	custom.height = 1.1
	custom.shoulder_width = 1.15
	custom.chest_size = 1.1
	custom.waist_size = 0.9
	custom.arm_thickness = 1.1
	custom.leg_length = 1.05
	custom.leg_thickness = 1.1
	return custom


static func create_compact() -> BodyCustomization:
	var custom := BodyCustomization.new()
	custom.height = 0.9
	custom.body_width = 1.1
	custom.shoulder_width = 1.1
	custom.chest_size = 1.1
	custom.waist_size = 1.05
	custom.hip_width = 1.1
	custom.leg_length = 0.9
	return custom


static func create_slender() -> BodyCustomization:
	var custom := BodyCustomization.new()
	custom.height = 1.15
	custom.body_width = 0.9
	custom.shoulder_width = 0.95
	custom.chest_size = 0.9
	custom.waist_size = 0.85
	custom.hip_width = 0.9
	custom.arm_thickness = 0.9
	custom.leg_thickness = 0.9
	return custom


static func create_heroic() -> BodyCustomization:
	var custom := BodyCustomization.new()
	custom.height = 1.15
	custom.shoulder_width = 1.2
	custom.chest_size = 1.15
	custom.waist_size = 0.95
	custom.hip_width = 1.0
	custom.arm_length = 1.05
	custom.arm_thickness = 1.15
	custom.leg_length = 1.1
	custom.leg_thickness = 1.1
	custom.hand_size = 1.1
	return custom
