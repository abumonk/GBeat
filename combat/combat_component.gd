## BeatCombatComponent - Manages combat actions with beat-synchronized timing
class_name BeatCombatComponent
extends Node

signal attack_started(step: CombatStepDefinition)
signal attack_ended(step: CombatStepDefinition)
signal timing_rated(rating: CombatTypes.TimingRating)
signal combo_changed(combo_count: int, multiplier: float)
signal hit_landed(result: CombatTypes.BeatHitResult)
signal window_opened(window_type: CombatTypes.WindowType)
signal window_closed(window_type: CombatTypes.WindowType)

## Configuration
@export var combat_steps: Array[CombatStepDefinition] = []
@export var timing_config: Resource  ## TimingConfig
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Combo settings
@export var combo_timeout_beats: int = 8
@export var combo_increment: float = 0.1  ## Multiplier increment per hit

## References
@export var character: CharacterBody3D
@export var hitbox_component: Node  ## BeatMeleeHitboxComponent

## State
var current_step: CombatStepDefinition = null
var step_progress: int = 0  ## Current quant in step
var current_window: CombatTypes.WindowType = CombatTypes.WindowType.NONE
var window_timer: float = 0.0

## Combo state
var combo_count: int = 0
var combo_multiplier: float = 1.0
var _combo_timeout_counter: int = 0
var _last_action_type: CombatTypes.ActionType = CombatTypes.ActionType.NONE

## Timing
var _tick_handle: int = -1
var _last_timing_quality: float = 0.0
var _attack_queued: CombatTypes.ActionType = CombatTypes.ActionType.NONE


func _ready() -> void:
	_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _on_tick(_event: SequencerEvent) -> void:
	_update_step_progress()
	_update_combo_timeout()
	_check_queued_attack()


func _update_step_progress() -> void:
	if not current_step:
		return

	step_progress += 1

	# Check if step completed
	if step_progress >= current_step.get_total_quants():
		_end_current_step()


func _update_combo_timeout() -> void:
	if combo_count > 0:
		_combo_timeout_counter += 1
		if _combo_timeout_counter >= combo_timeout_beats:
			_reset_combo()


func _check_queued_attack() -> void:
	if _attack_queued != CombatTypes.ActionType.NONE:
		_try_execute_action(_attack_queued)
		_attack_queued = CombatTypes.ActionType.NONE


func _end_current_step() -> void:
	if current_step:
		attack_ended.emit(current_step)
		current_step = null
		step_progress = 0
		close_window()


func _reset_combo() -> void:
	if combo_count > 0:
		combo_count = 0
		combo_multiplier = 1.0
		_combo_timeout_counter = 0
		combo_changed.emit(combo_count, combo_multiplier)


## === Public API ===

func try_action(action_type: CombatTypes.ActionType) -> bool:
	# Calculate timing quality
	var timing := _calculate_timing_quality()
	_last_timing_quality = timing.quality

	# If already in an attack, queue for combo
	if current_step:
		if _can_cancel_into(action_type):
			_attack_queued = action_type
			return true
		return false

	return _try_execute_action(action_type)


func _try_execute_action(action_type: CombatTypes.ActionType) -> bool:
	var step := _find_step_for_action(action_type)
	if not step:
		return false

	_start_step(step)
	return true


func _start_step(step: CombatStepDefinition) -> void:
	current_step = step
	step_progress = 0
	_last_action_type = step.action_type

	# Open attack window
	open_window(CombatTypes.WindowType.ATTACK, step.get_total_quants())

	# Reset combo timeout
	_combo_timeout_counter = 0

	# Emit timing rating
	var rating := _get_timing_rating(_last_timing_quality)
	timing_rated.emit(rating)

	attack_started.emit(step)


func _find_step_for_action(action_type: CombatTypes.ActionType) -> CombatStepDefinition:
	# Find step matching action type and valid combo link
	for step in combat_steps:
		if step.action_type != action_type:
			continue

		# Check combo link
		if _last_action_type == CombatTypes.ActionType.NONE:
			return step  # First attack, any step is valid

		match step.combo_link_type:
			CombatTypes.ComboLinkType.ANY:
				return step
			CombatTypes.ComboLinkType.LIGHT_ONLY:
				if _last_action_type == CombatTypes.ActionType.LIGHT_ATTACK:
					return step
			CombatTypes.ComboLinkType.HEAVY_ONLY:
				if _last_action_type == CombatTypes.ActionType.HEAVY_ATTACK:
					return step
			CombatTypes.ComboLinkType.LIGHT_CHAIN:
				if _last_action_type == CombatTypes.ActionType.LIGHT_ATTACK:
					return step
			CombatTypes.ComboLinkType.HEAVY_CHAIN:
				if _last_action_type == CombatTypes.ActionType.HEAVY_ATTACK:
					return step

	# Fallback: return first matching action type
	for step in combat_steps:
		if step.action_type == action_type:
			return step

	return null


func _can_cancel_into(action_type: CombatTypes.ActionType) -> bool:
	if not current_step:
		return true

	# Check if in recovery phase (can cancel)
	var recovery_start := current_step.startup_quants + current_step.active_quants
	if step_progress >= recovery_start:
		return true

	# Check explicit cancel list
	var step := _find_step_for_action(action_type)
	if step and current_step.can_cancel_into.has(step.step_name):
		return true

	return false


## === Timing ===

class TimingResult:
	var quality: float = 0.0
	var is_early: bool = false
	var is_late: bool = false


func _calculate_timing_quality() -> TimingResult:
	var result := TimingResult.new()

	var deck := Sequencer.get_deck(sequencer_deck)
	if not deck or not deck.is_playing():
		result.quality = 0.5  # Default to half if no sequencer
		return result

	var time_to_beat := deck.get_time_to_next_beat()
	var beat_duration := deck.get_beat_duration()
	var time_since_beat := beat_duration - time_to_beat

	# Quality is based on distance from nearest beat edge
	var distance: float = min(time_since_beat, time_to_beat)
	result.quality = 1.0 - (distance / (beat_duration / 2.0))
	result.quality = clamp(result.quality, 0.0, 1.0)

	result.is_early = time_to_beat < time_since_beat
	result.is_late = time_since_beat < time_to_beat

	return result


func _get_timing_rating(quality: float) -> CombatTypes.TimingRating:
	if quality >= 0.95:
		return CombatTypes.TimingRating.PERFECT
	elif quality >= 0.85:
		return CombatTypes.TimingRating.GREAT
	elif quality >= 0.65:
		return CombatTypes.TimingRating.GOOD
	elif quality < 0.5:
		return CombatTypes.TimingRating.MISS
	else:
		# Determine early vs late
		var timing := _calculate_timing_quality()
		if timing.is_early:
			return CombatTypes.TimingRating.EARLY
		else:
			return CombatTypes.TimingRating.LATE


## === Combat Windows ===

func open_window(window_type: CombatTypes.WindowType, duration_quants: int) -> void:
	current_window = window_type
	window_timer = duration_quants * Sequencer.get_deck(sequencer_deck).get_quant_duration()
	window_opened.emit(window_type)


func close_window() -> void:
	if current_window != CombatTypes.WindowType.NONE:
		window_closed.emit(current_window)
		current_window = CombatTypes.WindowType.NONE
		window_timer = 0.0


func is_window_open(window_type: CombatTypes.WindowType) -> bool:
	return current_window == window_type


## === Combo ===

func increment_combo() -> void:
	combo_count += 1
	combo_multiplier = 1.0 + (combo_count * combo_increment)
	_combo_timeout_counter = 0
	combo_changed.emit(combo_count, combo_multiplier)


func get_combo_count() -> int:
	return combo_count


func get_combo_multiplier() -> float:
	return combo_multiplier


## === Hit Registration ===

func register_hit(target: Node3D, impact_point: Vector3) -> CombatTypes.BeatHitResult:
	if not current_step:
		return null

	var result := CombatTypes.BeatHitResult.new()
	result.hit_actor = character
	result.target = target
	result.impact_point = impact_point
	result.base_damage = current_step.base_damage

	# Calculate timing multiplier
	var rating := _get_timing_rating(_last_timing_quality)
	result.timing_rating = rating
	result.timing_quality = _last_timing_quality
	result.timing_multiplier = CombatTypes.get_timing_multiplier(rating)

	# Apply combo
	result.combo_multiplier = combo_multiplier
	result.is_critical = rating == CombatTypes.TimingRating.PERFECT

	result.calculate_final_damage()

	# Increment combo on hit
	increment_combo()

	hit_landed.emit(result)
	return result


## === Queries ===

func is_attacking() -> bool:
	return current_step != null


func get_current_step() -> CombatStepDefinition:
	return current_step


func is_in_startup() -> bool:
	if not current_step:
		return false
	return step_progress < current_step.startup_quants


func is_in_active_frames() -> bool:
	if not current_step:
		return false
	var active_start := current_step.startup_quants
	var active_end := active_start + current_step.active_quants
	return step_progress >= active_start and step_progress < active_end


func is_in_recovery() -> bool:
	if not current_step:
		return false
	return step_progress >= current_step.startup_quants + current_step.active_quants
