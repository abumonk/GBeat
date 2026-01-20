## BeatMovementAnimComponent - Animation-driven step selection for beat-synchronized movement
class_name BeatMovementAnimComponent
extends Node

signal step_selected(plan: MovementStepPlaybackPlan)
signal step_started(step_name: String)
signal step_completed(step_name: String)

## Step database - populated via editor or code
@export var movement_database: Array[MovementStepDefinition] = []

## Scoring weights
@export var movement_direction_weight: float = 0.7
@export var rotation_direction_weight: float = 0.3
@export var target_direction_tolerance_degrees: float = 30.0

## Continuity bonuses
@export var frame_match_bonus: float = 0.1
@export var package_match_bonus: float = 0.05
@export var animation_match_bonus: float = 0.02
@export var link_match_bonus: float = 0.08

## Duration filtering
@export var filter_by_duration: bool = false
@export var max_play_rate_deviation: float = 0.3  # +/- 30%

## Root motion scaling
@export var enable_root_motion_scaling: bool = true

## Continuity tracking
var current_foot_contact: MovementStepDefinition.FootContact = MovementStepDefinition.FootContact.NONE
var last_step_package: String = ""
var last_step_animation: Animation = null
var last_step_end_frame: int = 0
var last_step_link: String = ""

## Current playback state
var _current_plan: MovementStepPlaybackPlan = null
var _step_time_remaining: float = 0.0


func _process(delta: float) -> void:
	if _current_plan and _step_time_remaining > 0:
		_step_time_remaining -= delta
		if _step_time_remaining <= 0:
			_on_step_complete()


## Build a step plan from desired movement inputs
func build_step_plan_from_inputs(
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float
) -> MovementStepPlaybackPlan:

	if movement_database.is_empty():
		return null

	# If no movement desired, return null (idle)
	if desired_movement.length_squared() < 0.001:
		return null

	# Filter candidates
	var candidates := _filter_candidates(desired_movement, desired_facing, current_speed)

	if candidates.is_empty():
		# Fallback: try without foot contact constraint
		candidates = _filter_candidates_relaxed(desired_movement, desired_facing, current_speed)

	if candidates.is_empty():
		return null

	# Score and select best
	var best_step := _select_best_step(candidates, desired_movement, desired_facing)

	if not best_step:
		return null

	# Build playback plan
	var plan := _build_plan(best_step, desired_movement)

	# Update continuity state
	_update_continuity(best_step)

	step_selected.emit(plan)
	return plan


## Build step plan with duration constraint
func build_step_plan_with_duration(
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float,
	target_duration: float
) -> MovementStepPlaybackPlan:

	var plan := build_step_plan_from_inputs(desired_movement, desired_facing, current_speed)

	if plan and filter_by_duration:
		if not plan.adjust_to_duration(target_duration, max_play_rate_deviation):
			# Can't match duration within acceptable play rate, find alternative
			return _find_duration_compatible_step(desired_movement, desired_facing, current_speed, target_duration)

	return plan


## Start executing a movement step
func start_step(plan: MovementStepPlaybackPlan) -> void:
	_current_plan = plan
	_step_time_remaining = plan.quantized_duration_seconds
	step_started.emit(plan.step_name)


## Filter candidates based on movement requirements
func _filter_candidates(
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float
) -> Array[MovementStepDefinition]:

	var candidates: Array[MovementStepDefinition] = []

	for step in movement_database:
		if not _step_matches_requirements(step, desired_movement, desired_facing, current_speed, true):
			continue
		candidates.append(step)

	return candidates


## Filter candidates with relaxed foot contact constraint
func _filter_candidates_relaxed(
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float
) -> Array[MovementStepDefinition]:

	var candidates: Array[MovementStepDefinition] = []

	for step in movement_database:
		if not _step_matches_requirements(step, desired_movement, desired_facing, current_speed, false):
			continue
		candidates.append(step)

	return candidates


## Check if a step matches movement requirements
func _step_matches_requirements(
	step: MovementStepDefinition,
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float,
	check_foot_contact: bool
) -> bool:

	# Direction match (reject opposite directions)
	var step_direction := step.get_movement_direction()
	var desired_dir_normalized := desired_movement.normalized()
	var direction_dot := step_direction.dot(desired_dir_normalized)

	if direction_dot < 0.0:
		return false

	# Speed range check
	if current_speed < step.min_desired_speed or current_speed > step.max_desired_speed:
		return false

	# Facing delta check
	var facing_delta := _calculate_facing_delta(desired_facing, step)
	if facing_delta > step.max_facing_delta_degrees:
		return false

	# Foot contact continuity (optional)
	if check_foot_contact and current_foot_contact != MovementStepDefinition.FootContact.NONE:
		if not _foot_contact_compatible(current_foot_contact, step.step_start_foot_contact):
			return false

	return true


## Select best step from candidates based on scoring
func _select_best_step(
	candidates: Array[MovementStepDefinition],
	desired_movement: Vector3,
	desired_facing: Vector3
) -> MovementStepDefinition:

	var best_step: MovementStepDefinition = null
	var best_score: float = -INF

	for step in candidates:
		var score := _score_step(step, desired_movement, desired_facing)

		if score > best_score:
			best_score = score
			best_step = step

	return best_step


## Score a step based on how well it matches desired movement
func _score_step(
	step: MovementStepDefinition,
	desired_movement: Vector3,
	desired_facing: Vector3
) -> float:

	var score: float = 0.0

	# Direction score (0 to movement_direction_weight)
	var step_direction := step.get_movement_direction()
	var desired_dir_normalized := desired_movement.normalized()
	var direction_dot := step_direction.dot(desired_dir_normalized)
	score += direction_dot * movement_direction_weight

	# Rotation score (0 to rotation_direction_weight)
	var rotation_score := 1.0 - (_calculate_facing_delta(desired_facing, step) / 180.0)
	score += rotation_score * rotation_direction_weight

	# Frame match bonus - animation continuity
	if step.step_start_frame == last_step_end_frame and last_step_animation != null:
		score += frame_match_bonus

	# Same package bonus - style consistency
	if step.package == last_step_package and not step.package.is_empty():
		score += package_match_bonus

	# Same animation bonus - smooth loops
	if step.animation == last_step_animation and step.animation != null:
		score += animation_match_bonus

	# Link match bonus - designed transitions
	if step.link == last_step_link and not step.link.is_empty():
		score += link_match_bonus

	return score


## Build playback plan from selected step
func _build_plan(step: MovementStepDefinition, desired_movement: Vector3) -> MovementStepPlaybackPlan:
	var input_magnitude := desired_movement.length()
	var plan := MovementStepPlaybackPlan.from_step(step, input_magnitude, enable_root_motion_scaling)
	return plan


## Update continuity state after executing a step
func _update_continuity(step: MovementStepDefinition) -> void:
	current_foot_contact = step.step_end_foot_contact
	last_step_package = step.package
	last_step_animation = step.animation
	last_step_end_frame = step.step_end_frame
	last_step_link = step.link


## Calculate facing delta between desired facing and step rotation
func _calculate_facing_delta(desired_facing: Vector3, step: MovementStepDefinition) -> float:
	if desired_facing.length_squared() < 0.01:
		return 0.0

	# How much this step rotates vs how much we want to rotate
	var step_rotation := abs(step.rotation_delta.y)
	return step_rotation


## Check if foot contact transition is natural
func _foot_contact_compatible(current: MovementStepDefinition.FootContact, next_start: MovementStepDefinition.FootContact) -> bool:
	# Natural walking: alternate feet
	match current:
		MovementStepDefinition.FootContact.LEFT:
			return next_start == MovementStepDefinition.FootContact.RIGHT or next_start == MovementStepDefinition.FootContact.NONE
		MovementStepDefinition.FootContact.RIGHT:
			return next_start == MovementStepDefinition.FootContact.LEFT or next_start == MovementStepDefinition.FootContact.NONE
		MovementStepDefinition.FootContact.BOTH:
			return true
		_:
			return true


## Find a step that can match the target duration
func _find_duration_compatible_step(
	desired_movement: Vector3,
	desired_facing: Vector3,
	current_speed: float,
	target_duration: float
) -> MovementStepPlaybackPlan:

	var best_plan: MovementStepPlaybackPlan = null
	var best_score: float = -INF

	for step in movement_database:
		if not _step_matches_requirements(step, desired_movement, desired_facing, current_speed, false):
			continue

		var test_plan := MovementStepPlaybackPlan.from_step(step, desired_movement.length(), enable_root_motion_scaling)

		if test_plan.adjust_to_duration(target_duration, max_play_rate_deviation):
			var score := _score_step(step, desired_movement, desired_facing)
			if score > best_score:
				best_score = score
				best_plan = test_plan
				_update_continuity(step)

	if best_plan:
		step_selected.emit(best_plan)

	return best_plan


## Handle step completion
func _on_step_complete() -> void:
	if _current_plan:
		step_completed.emit(_current_plan.step_name)
	_current_plan = null


## Reset continuity state (e.g., after landing, taking damage, etc.)
func reset_step_context() -> void:
	current_foot_contact = MovementStepDefinition.FootContact.NONE
	last_step_package = ""
	last_step_animation = null
	last_step_end_frame = 0
	last_step_link = ""
	_current_plan = null
	_step_time_remaining = 0.0


## Get current step being executed
func get_current_plan() -> MovementStepPlaybackPlan:
	return _current_plan


## Check if currently executing a step
func is_stepping() -> bool:
	return _current_plan != null and _step_time_remaining > 0


## Add a step definition to the database
func add_step(step: MovementStepDefinition) -> void:
	movement_database.append(step)


## Remove a step definition from the database
func remove_step(step: MovementStepDefinition) -> void:
	movement_database.erase(step)


## Load step database from resource array
func load_database(steps: Array[MovementStepDefinition]) -> void:
	movement_database = steps


## Create default movement database with basic steps
func create_default_database() -> void:
	movement_database.clear()

	# Forward walk steps (alternating feet)
	movement_database.append(MovementStepDefinition.create_walk_forward_left())
	movement_database.append(MovementStepDefinition.create_walk_forward_right())

	# Backward walk steps
	movement_database.append(MovementStepDefinition.create_walk_backward_left())
	movement_database.append(MovementStepDefinition.create_walk_backward_right())

	# Strafe steps
	movement_database.append(MovementStepDefinition.create_strafe_left())
	movement_database.append(MovementStepDefinition.create_strafe_right())

	# Idle step
	movement_database.append(MovementStepDefinition.create_idle())
