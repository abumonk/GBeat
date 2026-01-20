## HazardBase - Base class for all beat-synchronized hazards
class_name HazardBase
extends Area3D


signal hazard_activated()
signal hazard_deactivated()
signal player_hit(damage: float)


enum HazardType {
	SPIKE,
	LASER,
	PROJECTILE,
	ZONE,
	PLATFORM,
	CRUSHER,
}


enum HazardState {
	INACTIVE,
	WARNING,
	ACTIVE,
	COOLDOWN,
}


@export var hazard_type: HazardType = HazardType.SPIKE
@export var damage: float = 10.0
@export var warning_beats: float = 1.0
@export var active_duration: float = 0.5
@export var cooldown_duration: float = 0.5

## Beat sync settings
@export_group("Beat Sync")
@export var sync_to_beat: bool = true
@export var active_on_quant: Quant.Type = Quant.Type.KICK
@export var activation_pattern: Array[int] = []  # Beat positions (0-31)
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## Visual feedback
@export_group("Visuals")
@export var warning_material: Material
@export var active_material: Material
@export var inactive_material: Material

## Current state
var current_state: HazardState = HazardState.INACTIVE
var _tick_handle: int = -1
var _state_timer: float = 0.0
var _mesh: MeshInstance3D


func _ready() -> void:
	# Find mesh child
	for child in get_children():
		if child is MeshInstance3D:
			_mesh = child
			break

	# Set initial material
	_apply_material(inactive_material)

	# Connect collision
	body_entered.connect(_on_body_entered)

	# Subscribe to sequencer
	if sync_to_beat:
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	if current_state == HazardState.WARNING or current_state == HazardState.ACTIVE or current_state == HazardState.COOLDOWN:
		_state_timer -= delta
		if _state_timer <= 0:
			_advance_state()


func _on_tick(event: SequencerEvent) -> void:
	if not sync_to_beat:
		return

	# Check if this beat should activate the hazard
	var should_activate := false

	if activation_pattern.is_empty():
		# No pattern - activate on matching quant type
		should_activate = event.quant.type == active_on_quant
	else:
		# Pattern-based activation
		should_activate = event.quant.position in activation_pattern

	if should_activate and current_state == HazardState.INACTIVE:
		start_warning()


func start_warning() -> void:
	if current_state != HazardState.INACTIVE:
		return

	current_state = HazardState.WARNING
	_state_timer = _get_warning_time()
	_apply_material(warning_material)
	_on_warning_start()


func activate() -> void:
	current_state = HazardState.ACTIVE
	_state_timer = active_duration
	_apply_material(active_material)
	hazard_activated.emit()
	_on_activate()


func deactivate() -> void:
	current_state = HazardState.COOLDOWN
	_state_timer = cooldown_duration
	_apply_material(inactive_material)
	hazard_deactivated.emit()
	_on_deactivate()


func _advance_state() -> void:
	match current_state:
		HazardState.WARNING:
			activate()
		HazardState.ACTIVE:
			deactivate()
		HazardState.COOLDOWN:
			current_state = HazardState.INACTIVE
			_on_cooldown_complete()


func _get_warning_time() -> float:
	if sync_to_beat:
		var deck := Sequencer.get_deck(sequencer_deck)
		if deck and deck.current_pattern:
			var beat_duration := 60.0 / deck.current_pattern.bpm
			return warning_beats * beat_duration
	return warning_beats * 0.5  # Default 120 BPM


func _on_body_entered(body: Node3D) -> void:
	if current_state != HazardState.ACTIVE:
		return

	if body.is_in_group("player"):
		_deal_damage(body)


func _deal_damage(target: Node3D) -> void:
	player_hit.emit(damage)

	# Try to apply damage via health component
	if target.has_method("take_damage"):
		target.take_damage(damage)
	elif target.has_node("HealthComponent"):
		var health = target.get_node("HealthComponent")
		if health.has_method("take_damage"):
			health.take_damage(damage)


func _apply_material(mat: Material) -> void:
	if _mesh and mat:
		_mesh.material_override = mat


## Override in subclasses
func _on_warning_start() -> void:
	pass


func _on_activate() -> void:
	pass


func _on_deactivate() -> void:
	pass


func _on_cooldown_complete() -> void:
	pass


## Force activation (bypass beat sync)
func force_activate() -> void:
	if current_state == HazardState.INACTIVE:
		start_warning()
	elif current_state == HazardState.WARNING:
		activate()


## Immediate activation (no warning)
func instant_activate() -> void:
	current_state = HazardState.INACTIVE
	activate()


func is_active() -> bool:
	return current_state == HazardState.ACTIVE


func is_warning() -> bool:
	return current_state == HazardState.WARNING


func get_state() -> HazardState:
	return current_state
