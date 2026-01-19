## TrailEffect - Mesh-based trail for weapons and attacks
class_name TrailEffect
extends MeshInstance3D


## Configuration
@export var trail_length: int = 20
@export var trail_width: float = 0.1
@export var fade_out: bool = true
@export var emit_distance: float = 0.05

## Appearance
@export var trail_color: Color = Color(1.0, 0.5, 0.2, 0.8)
@export var tip_color: Color = Color(1.0, 1.0, 1.0, 1.0)

## State
var _points: Array[Vector3] = []
var _is_emitting: bool = false
var _last_position: Vector3 = Vector3.ZERO
var _immediate_mesh: ImmediateMesh = null
var _material: StandardMaterial3D = null


func _ready() -> void:
	_setup_mesh()


func _setup_mesh() -> void:
	_immediate_mesh = ImmediateMesh.new()
	mesh = _immediate_mesh

	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_material.vertex_color_use_as_albedo = true
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _material


func _process(_delta: float) -> void:
	if _is_emitting:
		_update_trail()
	elif _points.size() > 0 and fade_out:
		_fade_trail()

	_render_trail()


func _update_trail() -> void:
	var current_pos := global_position

	# Only add point if moved enough
	if _last_position.distance_to(current_pos) >= emit_distance:
		_points.push_front(current_pos)
		_last_position = current_pos

		# Limit trail length
		while _points.size() > trail_length:
			_points.pop_back()


func _fade_trail() -> void:
	# Remove oldest point each frame
	if _points.size() > 0:
		_points.pop_back()


func _render_trail() -> void:
	_immediate_mesh.clear_surfaces()

	if _points.size() < 2:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	var camera := get_viewport().get_camera_3d()
	if not camera:
		_immediate_mesh.surface_end()
		return

	for i in range(_points.size()):
		var point := _points[i]
		var t := float(i) / float(_points.size() - 1)  ## 0 at tip, 1 at tail

		# Calculate width
		var width := trail_width * (1.0 - t * 0.5)  ## Slightly narrower at tail

		# Calculate perpendicular direction (billboard towards camera)
		var to_camera := (camera.global_position - point).normalized()
		var forward := Vector3.ZERO
		if i < _points.size() - 1:
			forward = (_points[i + 1] - point).normalized()
		elif i > 0:
			forward = (point - _points[i - 1]).normalized()

		var right := forward.cross(to_camera).normalized() * width

		# Color with alpha fade
		var alpha := 1.0 - t if fade_out else 1.0
		var color := tip_color.lerp(trail_color, t)
		color.a *= alpha

		# Add vertices
		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(point + right)
		_immediate_mesh.surface_set_color(color)
		_immediate_mesh.surface_add_vertex(point - right)

	_immediate_mesh.surface_end()


## === API ===

func start_emitting() -> void:
	_is_emitting = true
	_last_position = global_position
	_points.clear()


func stop_emitting() -> void:
	_is_emitting = false


func is_emitting() -> bool:
	return _is_emitting


func set_colors(tip: Color, trail: Color) -> void:
	tip_color = tip
	trail_color = trail


func clear_trail() -> void:
	_points.clear()
