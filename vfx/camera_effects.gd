## CameraEffects - Screen shake, FOV changes, and camera reactions
class_name CameraEffects
extends Node


signal shake_started()
signal shake_ended()


## References
@export var camera: Camera3D

## Shake settings
@export var shake_decay: float = 8.0
@export var max_shake_offset: Vector3 = Vector3(0.5, 0.5, 0.2)
@export var max_shake_rotation: Vector3 = Vector3(2.0, 2.0, 1.0)

## FOV settings
@export var base_fov: float = 70.0
@export var hit_fov_punch: float = 5.0
@export var combo_fov_increase: float = 0.5

## Beat pulse
@export var beat_fov_pulse: float = 2.0
@export var beat_pulse_enabled: bool = true

## Sequencer
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

## State
var _shake_intensity: float = 0.0
var _shake_offset: Vector3 = Vector3.ZERO
var _shake_rotation: Vector3 = Vector3.ZERO
var _original_position: Vector3 = Vector3.ZERO
var _original_rotation: Vector3 = Vector3.ZERO

var _fov_offset: float = 0.0
var _combo_fov: float = 0.0

var _tick_handle: int = -1
var _fov_tween: Tween = null


func _ready() -> void:
	if not camera:
		push_warning("CameraEffects: No camera assigned")
		return

	_original_position = camera.position
	_original_rotation = camera.rotation
	base_fov = camera.fov

	if beat_pulse_enabled:
		_tick_handle = Sequencer.subscribe_to_tick(sequencer_deck, _on_tick)


func _exit_tree() -> void:
	if _tick_handle >= 0:
		Sequencer.unsubscribe(_tick_handle)


func _process(delta: float) -> void:
	if not camera:
		return

	_update_shake(delta)
	_update_fov()


func _update_shake(delta: float) -> void:
	if _shake_intensity <= 0.001:
		_shake_offset = Vector3.ZERO
		_shake_rotation = Vector3.ZERO
		camera.position = _original_position
		camera.rotation = _original_rotation
		return

	# Decay shake
	_shake_intensity = move_toward(_shake_intensity, 0.0, shake_decay * delta)

	# Generate random offset
	_shake_offset = Vector3(
		randf_range(-1, 1) * max_shake_offset.x,
		randf_range(-1, 1) * max_shake_offset.y,
		randf_range(-1, 1) * max_shake_offset.z
	) * _shake_intensity

	_shake_rotation = Vector3(
		randf_range(-1, 1) * deg_to_rad(max_shake_rotation.x),
		randf_range(-1, 1) * deg_to_rad(max_shake_rotation.y),
		randf_range(-1, 1) * deg_to_rad(max_shake_rotation.z)
	) * _shake_intensity

	# Apply
	camera.position = _original_position + _shake_offset
	camera.rotation = _original_rotation + _shake_rotation


func _update_fov() -> void:
	camera.fov = base_fov + _fov_offset + _combo_fov


func _on_tick(_event: SequencerEvent) -> void:
	if beat_pulse_enabled:
		fov_pulse(beat_fov_pulse, 0.1)


## === Shake API ===

func shake(intensity: float = 1.0) -> void:
	_shake_intensity = max(_shake_intensity, intensity)
	if _shake_intensity > 0.1:
		shake_started.emit()


func shake_hit(intensity: float = 0.3) -> void:
	shake(intensity)


func shake_heavy_hit(intensity: float = 0.6) -> void:
	shake(intensity)


func shake_damage(intensity: float = 0.5) -> void:
	shake(intensity)


func shake_explosion(intensity: float = 1.0) -> void:
	shake(intensity)


func stop_shake() -> void:
	_shake_intensity = 0.0
	shake_ended.emit()


## === FOV API ===

func fov_pulse(amount: float = 2.0, duration: float = 0.1) -> void:
	if _fov_tween and _fov_tween.is_valid():
		_fov_tween.kill()

	_fov_offset = amount

	_fov_tween = create_tween()
	_fov_tween.set_ease(Tween.EASE_OUT)
	_fov_tween.set_trans(Tween.TRANS_EXPO)
	_fov_tween.tween_property(self, "_fov_offset", 0.0, duration)


func fov_punch(amount: float = 5.0) -> void:
	fov_pulse(amount, 0.15)


func set_combo_fov(combo_count: int) -> void:
	_combo_fov = min(combo_count * combo_fov_increase, 10.0)


func reset_combo_fov() -> void:
	_combo_fov = 0.0


func set_base_fov(fov: float) -> void:
	base_fov = fov


## === Utility ===

func update_original_transform() -> void:
	if camera:
		_original_position = camera.position
		_original_rotation = camera.rotation
