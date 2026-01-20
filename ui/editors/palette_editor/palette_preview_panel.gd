## PalettePreviewPanel - Preview palette on character/scene
class_name PalettePreviewPanel
extends Control


enum PreviewMode {
	CHARACTER,
	SCENE,
	PATTERN,
	ALL,
}


var _palette: GamePalette
var _preview_mode: PreviewMode = PreviewMode.ALL
var _preview_viewport: SubViewportContainer


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var label := Label.new()
	label.text = "Preview"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	# Mode selector
	var mode_hbox := HBoxContainer.new()

	var mode_option := OptionButton.new()
	mode_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_option.add_item("Character")
	mode_option.add_item("Scene")
	mode_option.add_item("Pattern")
	mode_option.add_item("All")
	mode_option.select(3)
	mode_option.item_selected.connect(_on_mode_selected)
	mode_hbox.add_child(mode_option)

	vbox.add_child(mode_hbox)

	# Preview area
	var preview_panel := Panel.new()
	preview_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(preview_panel)

	# Draw preview
	_preview_viewport = SubViewportContainer.new()
	_preview_viewport.set_anchors_preset(Control.PRESET_FULL_RECT)
	_preview_viewport.stretch = true
	preview_panel.add_child(_preview_viewport)

	var viewport := SubViewport.new()
	viewport.size = Vector2i(250, 300)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_preview_viewport.add_child(viewport)

	_setup_preview_scene(viewport)


func _setup_preview_scene(viewport: SubViewport) -> void:
	# Environment
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.1, 0.1, 0.15)
	env.environment = environment
	viewport.add_child(env)

	# Camera
	var camera := Camera3D.new()
	camera.position = Vector3(0, 1, 3)
	camera.look_at(Vector3(0, 0.5, 0))
	viewport.add_child(camera)

	# Light
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -45, 0)
	viewport.add_child(light)

	# Simple character preview
	var character := _create_simple_character()
	character.name = "PreviewCharacter"
	viewport.add_child(character)

	# Floor
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "PreviewFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(4, 4)
	floor_mesh.mesh = plane

	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.2, 0.2, 0.25)
	floor_mesh.material_override = floor_mat
	viewport.add_child(floor_mesh)


func _create_simple_character() -> Node3D:
	var root := Node3D.new()

	# Body
	var body := MeshInstance3D.new()
	body.name = "Body"
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.6, 0.2)
	body.mesh = box
	body.position = Vector3(0, 0.8, 0)
	root.add_child(body)

	# Head
	var head := MeshInstance3D.new()
	head.name = "Head"
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	head.mesh = sphere
	head.position = Vector3(0, 1.25, 0)
	root.add_child(head)

	# Legs
	for i in [-1, 1]:
		var leg := MeshInstance3D.new()
		leg.name = "Leg" + ("L" if i < 0 else "R")
		var leg_box := BoxMesh.new()
		leg_box.size = Vector3(0.12, 0.5, 0.12)
		leg.mesh = leg_box
		leg.position = Vector3(i * 0.12, 0.25, 0)
		root.add_child(leg)

	return root


func set_palette(palette: GamePalette) -> void:
	_palette = palette
	_update_preview()


func _on_mode_selected(index: int) -> void:
	_preview_mode = index as PreviewMode
	_update_preview()


func _update_preview() -> void:
	if not _palette:
		return

	var viewport := _preview_viewport.get_child(0) as SubViewport
	if not viewport:
		return

	# Update character colors
	var character := viewport.get_node_or_null("PreviewCharacter")
	if character:
		var body := character.get_node_or_null("Body") as MeshInstance3D
		if body:
			var mat := body.material_override as StandardMaterial3D
			if not mat:
				mat = StandardMaterial3D.new()
				body.material_override = mat
			mat.albedo_color = _palette.shirt

		var head := character.get_node_or_null("Head") as MeshInstance3D
		if head:
			var mat := head.material_override as StandardMaterial3D
			if not mat:
				mat = StandardMaterial3D.new()
				head.material_override = mat
			mat.albedo_color = _palette.skin

		for leg_name in ["LegL", "LegR"]:
			var leg := character.get_node_or_null(leg_name) as MeshInstance3D
			if leg:
				var mat := leg.material_override as StandardMaterial3D
				if not mat:
					mat = StandardMaterial3D.new()
					leg.material_override = mat
				mat.albedo_color = _palette.pants

	# Update floor
	var floor_node := viewport.get_node_or_null("PreviewFloor") as MeshInstance3D
	if floor_node:
		var mat := floor_node.material_override as StandardMaterial3D
		if mat:
			mat.albedo_color = _palette.floor_base

	# Update environment
	var env := viewport.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if env and env.environment:
		env.environment.background_color = _palette.background
