## MovementStepPlaybackPlan - Result of step selection with adjusted parameters
class_name MovementStepPlaybackPlan
extends RefCounted


## Source step info
var step_name: String = ""
var step_definition: MovementStepDefinition = null

## Animation playback
var animation: Animation = null
var animation_name: String = ""
var play_rate: float = 1.0

## Timing
var quantized_duration_seconds: float = 0.5
var quant_count: int = 1

## Adjusted motion (scaled by input)
var adjusted_movement_delta: Vector3 = Vector3.ZERO
var adjusted_rotation_delta: Vector3 = Vector3.ZERO

## Input magnitude that was used
var input_magnitude: float = 1.0


## Get movement velocity for this step
func get_velocity() -> Vector3:
	if quantized_duration_seconds <= 0:
		return Vector3.ZERO
	return adjusted_movement_delta / quantized_duration_seconds


## Get rotation rate in degrees per second
func get_rotation_rate() -> Vector3:
	if quantized_duration_seconds <= 0:
		return Vector3.ZERO
	return adjusted_rotation_delta / quantized_duration_seconds


## Create a plan from a step definition
static func from_step(step: MovementStepDefinition, input_mag: float = 1.0, scale_motion: bool = true) -> MovementStepPlaybackPlan:
	var plan := MovementStepPlaybackPlan.new()
	plan.step_name = step.step_name
	plan.step_definition = step
	plan.animation = step.animation
	plan.animation_name = step.animation_name
	plan.play_rate = 1.0
	plan.quantized_duration_seconds = step.base_duration_seconds
	plan.quant_count = 1
	plan.input_magnitude = input_mag

	if scale_motion:
		plan.adjusted_movement_delta = step.movement_delta * input_mag
	else:
		plan.adjusted_movement_delta = step.movement_delta

	plan.adjusted_rotation_delta = step.rotation_delta

	return plan


## Adjust duration to match a target (changes play rate)
func adjust_to_duration(target_duration: float, max_rate_deviation: float = 0.3) -> bool:
	if quantized_duration_seconds <= 0 or target_duration <= 0:
		return false

	var required_rate := quantized_duration_seconds / target_duration

	# Check if within acceptable range
	if required_rate < (1.0 - max_rate_deviation) or required_rate > (1.0 + max_rate_deviation):
		return false

	play_rate = required_rate
	quantized_duration_seconds = target_duration
	return true
