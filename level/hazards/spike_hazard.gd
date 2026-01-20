## SpikeHazard - Periodic damage zones that extend on beat
class_name SpikeHazard
extends HazardBase


@export_group("Spike Settings")
@export var extended_height: float = 1.5
@export var retracted_height: float = 0.1
@export var extension_time: float = 0.1
@export var retraction_time: float = 0.2

## Visual
@export var spike_mesh: MeshInstance3D

## Internal
var _original_position: Vector3
var _extension_tween: Tween


func _ready() -> void:
	super._ready()
	hazard_type = HazardType.SPIKE

	if spike_mesh:
		_original_position = spike_mesh.position
		# Start retracted
		spike_mesh.position.y = _original_position.y - (extended_height - retracted_height)
		spike_mesh.scale.y = retracted_height / extended_height


func _on_warning_start() -> void:
	# Visual pulse to warn player
	if spike_mesh:
		var tween := create_tween()
		tween.set_loops(3)
		tween.tween_property(spike_mesh, "scale:y", retracted_height / extended_height * 1.2, 0.1)
		tween.tween_property(spike_mesh, "scale:y", retracted_height / extended_height, 0.1)


func _on_activate() -> void:
	_extend_spikes()


func _on_deactivate() -> void:
	_retract_spikes()


func _extend_spikes() -> void:
	if not spike_mesh:
		return

	if _extension_tween:
		_extension_tween.kill()

	_extension_tween = create_tween()
	_extension_tween.set_trans(Tween.TRANS_BACK)
	_extension_tween.set_ease(Tween.EASE_OUT)

	_extension_tween.tween_property(spike_mesh, "position:y", _original_position.y, extension_time)
	_extension_tween.parallel().tween_property(spike_mesh, "scale:y", 1.0, extension_time)


func _retract_spikes() -> void:
	if not spike_mesh:
		return

	if _extension_tween:
		_extension_tween.kill()

	_extension_tween = create_tween()
	_extension_tween.set_trans(Tween.TRANS_SINE)
	_extension_tween.set_ease(Tween.EASE_IN)

	var retracted_y := _original_position.y - (extended_height - retracted_height)
	_extension_tween.tween_property(spike_mesh, "position:y", retracted_y, retraction_time)
	_extension_tween.parallel().tween_property(spike_mesh, "scale:y", retracted_height / extended_height, retraction_time)
