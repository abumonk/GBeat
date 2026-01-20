## ComboChainManager - Tracks inputs and detects combo chains
class_name ComboChainManager
extends Node


signal chain_started(chain: ComboChain)
signal chain_completed(chain: ComboChain)
signal chain_failed()
signal input_registered(input: String)


## Configuration
@export var available_chains: Array[ComboChain] = []
@export var input_timeout: float = 0.5
@export var max_history: int = 10

## State
var input_history: Array[String] = []
var current_chain: ComboChain = null
var _input_timer: float = 0.0


func _ready() -> void:
	_load_default_chains()


func _process(delta: float) -> void:
	if _input_timer > 0:
		_input_timer -= delta
		if _input_timer <= 0:
			_clear_history()


func _load_default_chains() -> void:
	available_chains.append(ComboChain.create_basic_combo())
	available_chains.append(ComboChain.create_launcher_combo())
	available_chains.append(ComboChain.create_perfect_finisher())
	available_chains.append(ComboChain.create_style_burst())


## Register an input
func register_input(input_type: String, combo: int = 0, style_rank: String = "D") -> Dictionary:
	input_history.append(input_type)
	if input_history.size() > max_history:
		input_history.pop_front()

	_input_timer = input_timeout
	input_registered.emit(input_type)

	# Check for matching chains
	var result := _check_chains(combo, style_rank)

	return result


## Check if any chains match
func _check_chains(combo: int, style_rank: String) -> Dictionary:
	var result := {
		"chain_matched": false,
		"chain": null,
		"damage_bonus": 1.0,
		"style_bonus": 0.0,
		"unlocks_finisher": false,
		"finisher_type": "",
	}

	for chain in available_chains:
		if chain.matches_sequence(input_history):
			if chain.can_execute(combo, style_rank):
				result.chain_matched = true
				result.chain = chain
				result.damage_bonus = chain.damage_bonus
				result.style_bonus = chain.style_bonus
				result.unlocks_finisher = chain.unlocks_finisher
				result.finisher_type = chain.finisher_type

				chain_completed.emit(chain)
				_clear_history()
				break

	return result


## Clear input history
func _clear_history() -> void:
	input_history.clear()
	if current_chain:
		chain_failed.emit()
		current_chain = null


## Get current input sequence as string
func get_sequence_string() -> String:
	return " → ".join(input_history)


## Reset state
func reset() -> void:
	input_history.clear()
	current_chain = null
	_input_timer = 0.0


## Add a custom chain
func add_chain(chain: ComboChain) -> void:
	available_chains.append(chain)


## Remove a chain
func remove_chain(chain_name: String) -> void:
	for i in range(available_chains.size() - 1, -1, -1):
		if available_chains[i].chain_name == chain_name:
			available_chains.remove_at(i)
