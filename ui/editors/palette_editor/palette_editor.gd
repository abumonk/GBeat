## PaletteEditor - Visual editor for creating color palettes
class_name PaletteEditor
extends Control


signal palette_saved(palette: GamePalette)
signal palette_loaded(palette: GamePalette)


## UI References
var toolbar: HBoxContainer
var category_list: PaletteCategoryList
var color_picker: ColorPickerPanel
var preview_panel: PalettePreviewPanel
var harmony_panel: HarmonyGeneratorPanel

## State
var current_palette: GamePalette
var selected_category: String = ""

## Editing
var undo_stack: Array[Dictionary] = []
var redo_stack: Array[Dictionary] = []


func _ready() -> void:
	_setup_ui()
	new_palette()


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		_handle_shortcut(event)


func _setup_ui() -> void:
	var main_vbox := VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# Toolbar
	toolbar = _create_toolbar()
	main_vbox.add_child(toolbar)

	# Main content
	var main_split := HSplitContainer.new()
	main_split.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(main_split)

	# Left - Category list
	category_list = PaletteCategoryList.new()
	category_list.custom_minimum_size.x = 250
	category_list.category_selected.connect(_on_category_selected)
	category_list.color_changed.connect(_on_color_changed)
	main_split.add_child(category_list)

	# Center - Color picker and harmony
	var center_panel := VBoxContainer.new()
	center_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	color_picker = ColorPickerPanel.new()
	color_picker.custom_minimum_size.y = 300
	color_picker.color_changed.connect(_on_picker_color_changed)
	center_panel.add_child(color_picker)

	harmony_panel = HarmonyGeneratorPanel.new()
	harmony_panel.harmony_generated.connect(_on_harmony_generated)
	center_panel.add_child(harmony_panel)

	main_split.add_child(center_panel)

	# Right - Preview
	preview_panel = PalettePreviewPanel.new()
	preview_panel.custom_minimum_size.x = 300
	main_split.add_child(preview_panel)


func _create_toolbar() -> HBoxContainer:
	var tb := HBoxContainer.new()
	tb.custom_minimum_size.y = 40

	var new_btn := Button.new()
	new_btn.text = "New"
	new_btn.pressed.connect(new_palette)
	tb.add_child(new_btn)

	var load_btn := Button.new()
	load_btn.text = "Load"
	load_btn.pressed.connect(_on_load_pressed)
	tb.add_child(load_btn)

	var save_btn := Button.new()
	save_btn.text = "Save"
	save_btn.pressed.connect(_on_save_pressed)
	tb.add_child(save_btn)

	tb.add_child(_create_separator())

	# Presets
	var preset_label := Label.new()
	preset_label.text = "Presets:"
	tb.add_child(preset_label)

	var preset_option := OptionButton.new()
	preset_option.add_item("Neon Cyberpunk")
	preset_option.add_item("Sunset Warm")
	preset_option.add_item("Forest Natural")
	preset_option.add_item("Monochrome")
	preset_option.item_selected.connect(_on_preset_selected)
	tb.add_child(preset_option)

	tb.add_child(_create_separator())

	var randomize_btn := Button.new()
	randomize_btn.text = "🎲 Randomize"
	randomize_btn.pressed.connect(randomize_palette)
	tb.add_child(randomize_btn)

	return tb


func _create_separator() -> VSeparator:
	var sep := VSeparator.new()
	sep.custom_minimum_size.x = 20
	return sep


func _handle_shortcut(event: InputEventKey) -> void:
	if event.ctrl_pressed:
		match event.keycode:
			KEY_Z:
				undo()
			KEY_Y:
				redo()
			KEY_S:
				save_palette("")
	else:
		match event.keycode:
			KEY_R:
				randomize_palette()
			KEY_H:
				_generate_harmony()


## Create new palette
func new_palette() -> void:
	current_palette = GamePalette.new()
	current_palette.name = "New Palette"

	selected_category = ""
	_refresh_display()
	undo_stack.clear()
	redo_stack.clear()


## Save palette
func save_palette(path: String) -> void:
	if path.is_empty():
		path = "res://resources/palettes/%s.tres" % current_palette.name.to_snake_case()

	ResourceSaver.save(current_palette, path)
	palette_saved.emit(current_palette)


## Load palette
func load_palette(path: String) -> void:
	if not ResourceLoader.exists(path):
		return

	current_palette = load(path)
	_refresh_display()
	palette_loaded.emit(current_palette)


## Randomize all colors
func randomize_palette() -> void:
	_save_undo_state()

	for category in current_palette.get_all_categories():
		var hue := randf()
		var sat := randf_range(0.5, 1.0)
		var val := randf_range(0.3, 1.0)
		current_palette.set_color(category, Color.from_hsv(hue, sat, val))

	_refresh_display()


## Apply preset
func apply_preset(preset_name: String) -> void:
	_save_undo_state()

	match preset_name:
		"Neon Cyberpunk":
			current_palette = GamePalette.create_neon_cyberpunk()
		"Sunset Warm":
			current_palette = GamePalette.create_sunset_warm()
		"Forest Natural":
			current_palette = GamePalette.create_forest_natural()
		"Monochrome":
			current_palette = GamePalette.create_monochrome()

	_refresh_display()


func _refresh_display() -> void:
	category_list.set_palette(current_palette)
	preview_panel.set_palette(current_palette)

	if not selected_category.is_empty():
		var color := current_palette.get_color(selected_category)
		color_picker.set_color(color)


func _generate_harmony() -> void:
	if selected_category.is_empty():
		return

	var base_color := current_palette.get_color(selected_category)
	harmony_panel.set_base_color(base_color)


## Signal handlers
func _on_category_selected(category: String) -> void:
	selected_category = category
	var color := current_palette.get_color(category)
	color_picker.set_color(color)


func _on_color_changed(category: String, color: Color) -> void:
	_save_undo_state()
	current_palette.set_color(category, color)
	_refresh_display()


func _on_picker_color_changed(color: Color) -> void:
	if selected_category.is_empty():
		return

	_save_undo_state()
	current_palette.set_color(selected_category, color)
	category_list.update_color(selected_category, color)
	preview_panel.set_palette(current_palette)


func _on_harmony_generated(colors: Array[Color]) -> void:
	# Apply generated colors to related categories
	# This is a simplified implementation
	var categories := current_palette.get_all_categories()
	for i in range(mini(colors.size(), categories.size())):
		current_palette.set_color(categories[i], colors[i])

	_refresh_display()


func _on_preset_selected(index: int) -> void:
	var presets := ["Neon Cyberpunk", "Sunset Warm", "Forest Natural", "Monochrome"]
	if index < presets.size():
		apply_preset(presets[index])


func _on_load_pressed() -> void:
	pass


func _on_save_pressed() -> void:
	save_palette("")


## Undo/Redo
func _save_undo_state() -> void:
	undo_stack.append(current_palette.duplicate())
	redo_stack.clear()


func undo() -> void:
	if undo_stack.is_empty():
		return
	redo_stack.append(current_palette.duplicate())
	current_palette = undo_stack.pop_back()
	_refresh_display()


func redo() -> void:
	if redo_stack.is_empty():
		return
	undo_stack.append(current_palette.duplicate())
	current_palette = redo_stack.pop_back()
	_refresh_display()
