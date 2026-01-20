## MovementStepDefinition - Defines a single animation-driven movement step
class_name MovementStepDefinition
extends Resource


## Foot contact states for step continuity
enum FootContact { NONE = 0, LEFT = 1, RIGHT = 2, BOTH = 3 }


## Identification
@export var package: String = ""          ## Animation set grouping (e.g., "walk", "run")
@export var step_name: String = ""        ## Debug identifier
@export var link: String = ""             ## Chaining tag for continuity

## Animation reference
@export var animation: Animation
@export var animation_name: String = ""   ## Name for AnimationPlayer lookup
@export var step_start_frame: int = 0
@export var step_end_frame: int = 0
@export var step_process_times: Array[float] = []  ## Key moments (seconds)

## Foot contact for continuity
@export var step_start_foot_contact: FootContact = FootContact.NONE
@export var step_end_foot_contact: FootContact = FootContact.NONE

## Root motion
@export var movement_delta: Vector3 = Vector3.ZERO      ## Root motion translation
@export var rotation_delta: Vector3 = Vector3.ZERO      ## Root motion rotation (euler degrees)

## Velocity at boundaries
@export var step_start_velocity: Vector2 = Vector2.ZERO  ## 2D velocity at start
@export var step_end_velocity: Vector2 = Vector2.ZERO    ## 2D velocity at end

## Constraints
@export var max_facing_delta_degrees: float = 45.0       ## Max turn per step
@export var min_desired_speed: float = 0.0               ## Min input speed
@export var max_desired_speed: float = 600.0             ## Max input speed

## Timing
@export var base_duration_seconds: float = 0.5
@export var base_duration_frames: int = 30


## Get normalized movement direction
func get_movement_direction() -> Vector3:
	if movement_delta.length_squared() < 0.001:
		return Vector3.FORWARD
	return movement_delta.normalized()


## Get movement speed in units per second
func get_movement_speed() -> float:
	if base_duration_seconds <= 0:
		return 0.0
	return movement_delta.length() / base_duration_seconds


## Check if this step matches a speed range
func matches_speed(speed: float) -> bool:
	return speed >= min_desired_speed and speed <= max_desired_speed


## Create a basic forward walk step
static func create_walk_forward_left() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "walk"
	step.step_name = "walk_forward_left"
	step.link = "walk_forward"
	step.step_start_foot_contact = FootContact.RIGHT
	step.step_end_foot_contact = FootContact.LEFT
	step.movement_delta = Vector3(0, 0, -1.5)  # Forward
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 3.0
	step.base_duration_seconds = 0.5
	return step


static func create_walk_forward_right() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "walk"
	step.step_name = "walk_forward_right"
	step.link = "walk_forward"
	step.step_start_foot_contact = FootContact.LEFT
	step.step_end_foot_contact = FootContact.RIGHT
	step.movement_delta = Vector3(0, 0, -1.5)  # Forward
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 3.0
	step.base_duration_seconds = 0.5
	return step


static func create_run_forward_left() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "run"
	step.step_name = "run_forward_left"
	step.link = "run_forward"
	step.step_start_foot_contact = FootContact.RIGHT
	step.step_end_foot_contact = FootContact.LEFT
	step.movement_delta = Vector3(0, 0, -3.0)  # Forward faster
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 3.0
	step.max_desired_speed = 10.0
	step.base_duration_seconds = 0.35
	return step


static func create_run_forward_right() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "run"
	step.step_name = "run_forward_right"
	step.link = "run_forward"
	step.step_start_foot_contact = FootContact.LEFT
	step.step_end_foot_contact = FootContact.RIGHT
	step.movement_delta = Vector3(0, 0, -3.0)  # Forward faster
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 3.0
	step.max_desired_speed = 10.0
	step.base_duration_seconds = 0.35
	return step


static func create_strafe_left() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "strafe"
	step.step_name = "strafe_left"
	step.link = "strafe"
	step.step_start_foot_contact = FootContact.RIGHT
	step.step_end_foot_contact = FootContact.LEFT
	step.movement_delta = Vector3(-1.5, 0, 0)  # Left
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 5.0
	step.base_duration_seconds = 0.4
	return step


static func create_strafe_right() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "strafe"
	step.step_name = "strafe_right"
	step.link = "strafe"
	step.step_start_foot_contact = FootContact.LEFT
	step.step_end_foot_contact = FootContact.RIGHT
	step.movement_delta = Vector3(1.5, 0, 0)  # Right
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 5.0
	step.base_duration_seconds = 0.4
	return step


static func create_turn_left() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "turn"
	step.step_name = "turn_left"
	step.link = "turn"
	step.step_start_foot_contact = FootContact.BOTH
	step.step_end_foot_contact = FootContact.BOTH
	step.movement_delta = Vector3.ZERO
	step.rotation_delta = Vector3(0, 45, 0)  # Turn left 45 degrees
	step.max_facing_delta_degrees = 90.0
	step.min_desired_speed = 0.0
	step.max_desired_speed = 2.0
	step.base_duration_seconds = 0.3
	return step


static func create_turn_right() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "turn"
	step.step_name = "turn_right"
	step.link = "turn"
	step.step_start_foot_contact = FootContact.BOTH
	step.step_end_foot_contact = FootContact.BOTH
	step.movement_delta = Vector3.ZERO
	step.rotation_delta = Vector3(0, -45, 0)  # Turn right 45 degrees
	step.max_facing_delta_degrees = 90.0
	step.min_desired_speed = 0.0
	step.max_desired_speed = 2.0
	step.base_duration_seconds = 0.3
	return step


static func create_walk_backward_left() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "walk"
	step.step_name = "walk_backward_left"
	step.link = "walk_backward"
	step.step_start_foot_contact = FootContact.RIGHT
	step.step_end_foot_contact = FootContact.LEFT
	step.movement_delta = Vector3(0, 0, 1.0)  # Backward
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 2.5
	step.base_duration_seconds = 0.55
	return step


static func create_walk_backward_right() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "walk"
	step.step_name = "walk_backward_right"
	step.link = "walk_backward"
	step.step_start_foot_contact = FootContact.LEFT
	step.step_end_foot_contact = FootContact.RIGHT
	step.movement_delta = Vector3(0, 0, 1.0)  # Backward
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.1
	step.max_desired_speed = 2.5
	step.base_duration_seconds = 0.55
	return step


static func create_idle() -> MovementStepDefinition:
	var step := MovementStepDefinition.new()
	step.package = "idle"
	step.step_name = "idle"
	step.link = "idle"
	step.step_start_foot_contact = FootContact.BOTH
	step.step_end_foot_contact = FootContact.BOTH
	step.movement_delta = Vector3.ZERO
	step.rotation_delta = Vector3.ZERO
	step.min_desired_speed = 0.0
	step.max_desired_speed = 0.1
	step.base_duration_seconds = 0.5
	return step
