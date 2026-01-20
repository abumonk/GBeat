## ComboChain - Defines a specific chain of attacks with bonuses
class_name ComboChain
extends Resource


## Chain definition
@export var chain_name: String = ""
@export var description: String = ""
@export var inputs: Array[String] = []  # e.g., ["light", "light", "heavy"]
@export var timing_strict: bool = false  # Must be on beat

## Rewards
@export var damage_bonus: float = 1.5
@export var style_bonus: float = 500.0
@export var unlocks_finisher: bool = false
@export var finisher_type: String = ""

## Requirements
@export var min_combo: int = 0
@export var required_style_rank: String = ""


## Check if input sequence matches this chain
func matches_sequence(input_history: Array[String]) -> bool:
	if input_history.size() < inputs.size():
		return false

	var start := input_history.size() - inputs.size()
	for i in range(inputs.size()):
		if input_history[start + i] != inputs[i]:
			return false

	return true


## Check if requirements are met
func can_execute(combo: int, style_rank: String) -> bool:
	if combo < min_combo:
		return false

	if not required_style_rank.is_empty():
		var ranks := ["D", "C", "B", "A", "S", "SS", "SSS"]
		var required_idx := ranks.find(required_style_rank)
		var current_idx := ranks.find(style_rank)
		if current_idx < required_idx:
			return false

	return true


## Create preset chains
static func create_basic_combo() -> ComboChain:
	var chain := ComboChain.new()
	chain.chain_name = "Basic Combo"
	chain.description = "Light, Light, Heavy"
	chain.inputs = ["light", "light", "heavy"]
	chain.damage_bonus = 1.3
	chain.style_bonus = 200.0
	return chain


static func create_launcher_combo() -> ComboChain:
	var chain := ComboChain.new()
	chain.chain_name = "Launcher"
	chain.description = "Heavy, Light, Light, Heavy"
	chain.inputs = ["heavy", "light", "light", "heavy"]
	chain.damage_bonus = 1.5
	chain.style_bonus = 400.0
	chain.min_combo = 5
	return chain


static func create_perfect_finisher() -> ComboChain:
	var chain := ComboChain.new()
	chain.chain_name = "Perfect Finisher"
	chain.description = "Light, Light, Dodge, Heavy"
	chain.inputs = ["light", "light", "dodge", "heavy"]
	chain.damage_bonus = 2.0
	chain.style_bonus = 800.0
	chain.unlocks_finisher = true
	chain.finisher_type = "perfect"
	chain.required_style_rank = "A"
	return chain


static func create_style_burst() -> ComboChain:
	var chain := ComboChain.new()
	chain.chain_name = "Style Burst"
	chain.description = "Dodge, Light, Heavy, Light, Heavy"
	chain.inputs = ["dodge", "light", "heavy", "light", "heavy"]
	chain.damage_bonus = 1.8
	chain.style_bonus = 1000.0
	chain.unlocks_finisher = true
	chain.finisher_type = "style"
	chain.required_style_rank = "S"
	return chain
