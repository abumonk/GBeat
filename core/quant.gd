## Quant - A single beat event with type, position, and value
## Position is 0-31 representing 32nd note subdivisions within a bar
class_name Quant
extends Resource

enum Type {
	TICK,           ## Basic timing pulse
	HIT,            ## Generic hit marker
	KICK,           ## Kick drum
	SNARE,          ## Snare drum
	HAT,            ## Hi-hat
	OPEN_HAT,       ## Open hi-hat
	CRASH,          ## Crash cymbal
	RIDE,           ## Ride cymbal
	TOM,            ## Tom drum
	ANIMATION,      ## Trigger animation step
	TIME_SCALE,     ## Adjust time
	MOVE_FORWARD_SPEED,  ## Forward velocity
	MOVE_RIGHT_SPEED,    ## Lateral velocity
	ROTATION_SPEED       ## Rotation rate
}

@export var type: Type = Type.TICK
@export_range(0, 31) var position: int = 0  ## 0-31 (32nd notes in bar)
@export_range(0.0, 1.0) var value: float = 1.0  ## Intensity


func _init(p_type: Type = Type.TICK, p_position: int = 0, p_value: float = 1.0) -> void:
	type = p_type
	position = p_position
	value = p_value


func duplicate_quant() -> Quant:
	var q := Quant.new()
	q.type = type
	q.position = position
	q.value = value
	return q


static func type_to_string(t: Type) -> String:
	return Type.keys()[t]


static func string_to_type(s: String) -> Type:
	var idx := Type.keys().find(s.to_upper())
	if idx >= 0:
		return idx as Type
	return Type.TICK
