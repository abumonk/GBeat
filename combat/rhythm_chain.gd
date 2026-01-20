## RhythmChain - Tracks consecutive on-beat actions
class_name RhythmChain
extends Node


signal chain_started()
signal chain_extended(length: int)
signal chain_broken()
signal chain_milestone(milestone: int)
signal chain_bonus_applied(bonus: float)


## Configuration
@export var chain_milestones: Array[int] = [4, 8, 16, 32, 64]
@export var base_bonus: float = 0.1  # Per chain hit
@export var milestone_bonus: float = 0.5
@export var perfect_only: bool = false  # Only perfect timing counts

## State
var chain_length: int = 0
var total_bonus: float = 0.0
var _is_active: bool = false
var _tick_handle: int = -1
var _expected_beat: bool = false


func _ready() -> void:
	_tick_handle = Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _on_beat(event: SequencerEvent) -> void:
	# Mark that a beat occurred - player should act on this beat
	if event.quant.type == Quant.Type.KICK:
		_expected_beat = true

		# If active chain but no action on previous beat, break chain
		# (This gets reset when register_action is called)
		if _is_active:
			# Give a small grace period by checking next frame
			await get_tree().process_frame
			await get_tree().process_frame
			if _expected_beat:
				# No action was registered
				break_chain()


## Register an action on beat
func register_action(is_on_beat: bool, is_perfect: bool = false) -> float:
	_expected_beat = false

	if perfect_only and not is_perfect:
		is_on_beat = false

	if is_on_beat:
		if not _is_active:
			_start_chain()

		chain_length += 1
		chain_extended.emit(chain_length)

		# Calculate bonus
		var bonus := base_bonus * chain_length
		_check_milestones()
		bonus += total_bonus

		chain_bonus_applied.emit(bonus)
		return bonus
	else:
		break_chain()
		return 0.0


func _start_chain() -> void:
	_is_active = true
	chain_length = 0
	total_bonus = 0.0
	chain_started.emit()


func break_chain() -> void:
	if _is_active:
		chain_broken.emit()

	_is_active = false
	chain_length = 0
	total_bonus = 0.0


func _check_milestones() -> void:
	for milestone in chain_milestones:
		if chain_length == milestone:
			total_bonus += milestone_bonus
			chain_milestone.emit(milestone)
			break


## Get current chain info
func get_chain_info() -> Dictionary:
	return {
		"is_active": _is_active,
		"length": chain_length,
		"bonus": total_bonus + (base_bonus * chain_length),
	}


## Reset
func reset() -> void:
	_is_active = false
	chain_length = 0
	total_bonus = 0.0
