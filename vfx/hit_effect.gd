## HitEffect - Visual effect for combat hits
class_name HitEffect
extends Node3D


## Configuration
@export var particles: GPUParticles3D
@export var flash_mesh: MeshInstance3D
@export var flash_duration: float = 0.1
@export var lifetime: float = 1.0

## Colors by timing rating
@export var perfect_color: Color = Color(1.0, 0.8, 0.0)    ## Gold
@export var great_color: Color = Color(0.0, 1.0, 0.5)      ## Green
@export var good_color: Color = Color(0.5, 0.5, 1.0)       ## Blue
@export var normal_color: Color = Color(1.0, 1.0, 1.0)     ## White
@export var critical_color: Color = Color(1.0, 0.0, 0.0)   ## Red

var _flash_tween: Tween = null


func _ready() -> void:
	# Auto-destroy after lifetime
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

	if flash_mesh:
		flash_mesh.visible = false


func play(impact_point: Vector3, direction: Vector3 = Vector3.UP, rating: CombatTypes.TimingRating = CombatTypes.TimingRating.GOOD, is_critical: bool = false) -> void:
	global_position = impact_point

	# Orient towards hit direction
	if direction.length_squared() > 0.01:
		look_at(impact_point + direction)

	# Get color based on rating
	var color := _get_color_for_rating(rating, is_critical)

	# Play particles
	if particles:
		_setup_particles(color)
		particles.emitting = true

	# Flash mesh
	if flash_mesh:
		_play_flash(color)


func _get_color_for_rating(rating: CombatTypes.TimingRating, is_critical: bool) -> Color:
	if is_critical:
		return critical_color

	match rating:
		CombatTypes.TimingRating.PERFECT:
			return perfect_color
		CombatTypes.TimingRating.GREAT:
			return great_color
		CombatTypes.TimingRating.GOOD:
			return good_color
		_:
			return normal_color


func _setup_particles(color: Color) -> void:
	if not particles.process_material:
		return

	var mat := particles.process_material as ParticleProcessMaterial
	if mat:
		mat.color = color


func _play_flash(color: Color) -> void:
	flash_mesh.visible = true

	# Get or create material
	var mat: StandardMaterial3D
	if flash_mesh.material_override:
		mat = flash_mesh.material_override as StandardMaterial3D
	else:
		mat = StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.emission_enabled = true
		flash_mesh.material_override = mat

	mat.albedo_color = color
	mat.emission = color
	mat.emission_energy_multiplier = 3.0

	# Animate flash
	if _flash_tween and _flash_tween.is_valid():
		_flash_tween.kill()

	_flash_tween = create_tween()
	_flash_tween.set_ease(Tween.EASE_OUT)
	_flash_tween.set_trans(Tween.TRANS_EXPO)

	# Scale up and fade
	flash_mesh.scale = Vector3.ONE * 0.5
	_flash_tween.tween_property(flash_mesh, "scale", Vector3.ONE * 1.5, flash_duration)
	_flash_tween.parallel().tween_property(mat, "albedo_color:a", 0.0, flash_duration)
	_flash_tween.tween_callback(func(): flash_mesh.visible = false)


## Factory method for spawning hit effects
static func spawn(parent: Node, scene: PackedScene, impact_point: Vector3, direction: Vector3 = Vector3.UP, rating: CombatTypes.TimingRating = CombatTypes.TimingRating.GOOD, is_critical: bool = false) -> HitEffect:
	var instance := scene.instantiate() as HitEffect
	if instance:
		parent.add_child(instance)
		instance.play(impact_point, direction, rating, is_critical)
	return instance
