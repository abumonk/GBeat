## AbilityDefinition - Resource defining an ability
@tool
class_name AbilityDefinition
extends Resource


@export var ability_id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

## Category and behavior
@export var category: AbilityTypes.AbilityCategory = AbilityTypes.AbilityCategory.ACTIVE
@export var trigger_condition: AbilityTypes.TriggerCondition = AbilityTypes.TriggerCondition.NONE
@export var trigger_value: float = 0.0  ## e.g., combo threshold, health percentage

## Targeting
@export var target_type: AbilityTypes.TargetType = AbilityTypes.TargetType.SELF
@export var range: float = 5.0
@export var area_radius: float = 3.0

## Cost and cooldown
@export var cooldown: float = 5.0
@export var max_charges: int = 1
@export var charge_time: float = 0.0  ## Time to gain a charge

## Beat sync
@export var sync_to_beat: bool = true
@export var beat_multiplier: float = 1.0  ## Effect multiplier on beat

## Effects
@export var effects: Array[Resource] = []  ## Array of AbilityEffect resources

## Visual/Audio
@export var activation_animation: String = ""
@export var activation_sound: AudioStream
@export var vfx_scene: PackedScene

## Unlock requirements
@export var unlock_cost: int = 100
@export var required_level: int = 1
@export var prerequisite_ability: String = ""


func get_effect_description() -> String:
	var desc := ""
	for effect_res in effects:
		var effect := effect_res as AbilityEffectResource
		if effect:
			desc += effect.get_description() + "\n"
	return desc.strip_edges()
