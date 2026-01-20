## FloorReactionScript - Defines how floor reacts to beat events
class_name FloorReactionScript
extends Resource


## Script name for identification
@export var script_name: String = "Default Reaction"

## Reaction events - what happens on each quant type
@export var reaction_events: Array[ReactionEvent] = []


## Individual reaction event definition
class ReactionEvent:
	## Which quant type triggers this reaction
	var quant_type: Quant.Type = Quant.Type.TICK

	## Pattern mode for this reaction
	var pattern_mode: LightingFloor.PatternMode = LightingFloor.PatternMode.RADIAL

	## Intensity multiplier (0.0 - 1.0)
	var intensity: float = 1.0

	## Color override (null = use palette)
	var color_override: Color = Color.WHITE
	var use_color_override: bool = false

	## Delay before reaction starts
	var delay: float = 0.0


## Get reaction for a specific quant type
func get_reaction(quant_type: Quant.Type) -> ReactionEvent:
	for event in reaction_events:
		if event.quant_type == quant_type:
			return event
	return null


## Check if this script reacts to a quant type
func reacts_to(quant_type: Quant.Type) -> bool:
	return get_reaction(quant_type) != null


## Create default beat reaction script
static func create_default() -> FloorReactionScript:
	var script := FloorReactionScript.new()
	script.script_name = "Default Beat Reaction"

	# Kick - strong radial pulse
	var kick_reaction := ReactionEvent.new()
	kick_reaction.quant_type = Quant.Type.KICK
	kick_reaction.pattern_mode = LightingFloor.PatternMode.RADIAL
	kick_reaction.intensity = 1.0
	script.reaction_events.append(kick_reaction)

	# Snare - checkerboard
	var snare_reaction := ReactionEvent.new()
	snare_reaction.quant_type = Quant.Type.SNARE
	snare_reaction.pattern_mode = LightingFloor.PatternMode.CHECKERBOARD
	snare_reaction.intensity = 0.8
	script.reaction_events.append(snare_reaction)

	# Hat - random subtle
	var hat_reaction := ReactionEvent.new()
	hat_reaction.quant_type = Quant.Type.HAT
	hat_reaction.pattern_mode = LightingFloor.PatternMode.RANDOM
	hat_reaction.intensity = 0.4
	script.reaction_events.append(hat_reaction)

	return script


## Create wave reaction script
static func create_wave() -> FloorReactionScript:
	var script := FloorReactionScript.new()
	script.script_name = "Wave Reaction"

	# All beats use row pattern
	var kick_reaction := ReactionEvent.new()
	kick_reaction.quant_type = Quant.Type.KICK
	kick_reaction.pattern_mode = LightingFloor.PatternMode.ROWS
	kick_reaction.intensity = 1.0
	script.reaction_events.append(kick_reaction)

	var snare_reaction := ReactionEvent.new()
	snare_reaction.quant_type = Quant.Type.SNARE
	snare_reaction.pattern_mode = LightingFloor.PatternMode.ROWS
	snare_reaction.intensity = 0.7
	snare_reaction.delay = 0.05
	script.reaction_events.append(snare_reaction)

	return script


## Create intense reaction script
static func create_intense() -> FloorReactionScript:
	var script := FloorReactionScript.new()
	script.script_name = "Intense Reaction"

	# Everything pulses all
	var kick_reaction := ReactionEvent.new()
	kick_reaction.quant_type = Quant.Type.KICK
	kick_reaction.pattern_mode = LightingFloor.PatternMode.ALL
	kick_reaction.intensity = 1.0
	script.reaction_events.append(kick_reaction)

	var snare_reaction := ReactionEvent.new()
	snare_reaction.quant_type = Quant.Type.SNARE
	snare_reaction.pattern_mode = LightingFloor.PatternMode.ALL
	snare_reaction.intensity = 0.9
	script.reaction_events.append(snare_reaction)

	var hat_reaction := ReactionEvent.new()
	hat_reaction.quant_type = Quant.Type.HAT
	hat_reaction.pattern_mode = LightingFloor.PatternMode.ALL
	hat_reaction.intensity = 0.5
	script.reaction_events.append(hat_reaction)

	var tick_reaction := ReactionEvent.new()
	tick_reaction.quant_type = Quant.Type.TICK
	tick_reaction.pattern_mode = LightingFloor.PatternMode.ALL
	tick_reaction.intensity = 0.3
	script.reaction_events.append(tick_reaction)

	return script
