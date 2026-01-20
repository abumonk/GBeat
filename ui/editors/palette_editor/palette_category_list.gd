## PaletteCategoryList - List of color categories with swatches
class_name PaletteCategoryList
extends Control


signal category_selected(category: String)
signal color_changed(category: String, color: Color)


## Category groups
var category_groups: Dictionary = {
	"Character": ["skin", "hair", "eye", "shirt", "pants", "shoes", "hat", "accessory", "weapon_primary", "weapon_secondary"],
	"Scene": ["background", "floor_base", "floor_accent", "light_main", "light_accent", "fog"],
	"UI": ["ui_primary", "ui_secondary", "ui_accent", "ui_background"],
	"Pattern": ["beat_kick", "beat_snare", "beat_hat", "beat_accent"],
}

## State
var _palette: GamePalette
var _swatches: Dictionary = {}
var _selected: String = ""


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.name = "CategoryVBox"
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)


func set_palette(palette: GamePalette) -> void:
	_palette = palette
	_rebuild_list()


func _rebuild_list() -> void:
	var vbox := get_node("ScrollContainer/CategoryVBox")
	if not vbox:
		return

	# Clear
	for child in vbox.get_children():
		child.queue_free()
	_swatches.clear()

	if not _palette:
		return

	# Create groups
	for group_name in category_groups:
		var group := _create_group(group_name, category_groups[group_name])
		vbox.add_child(group)


func _create_group(group_name: String, categories: Array) -> Control:
	var group := VBoxContainer.new()

	# Header
	var header := Label.new()
	header.text = group_name
	header.add_theme_font_size_override("font_size", 14)
	group.add_child(header)

	# Categories
	for category in categories:
		var row := _create_category_row(category)
		group.add_child(row)

	return group


func _create_category_row(category: String) -> Control:
	var row := HBoxContainer.new()

	# Color swatch button
	var swatch := ColorPickerButton.new()
	swatch.custom_minimum_size = Vector2(40, 25)
	swatch.color = _palette.get_color(category)
	swatch.color_changed.connect(_on_swatch_changed.bind(category))
	swatch.pressed.connect(_on_swatch_pressed.bind(category))
	row.add_child(swatch)
	_swatches[category] = swatch

	# Label
	var label := Label.new()
	label.text = category.capitalize().replace("_", " ")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)

	return row


func _on_swatch_pressed(category: String) -> void:
	_selected = category
	category_selected.emit(category)


func _on_swatch_changed(color: Color, category: String) -> void:
	color_changed.emit(category, color)


func update_color(category: String, color: Color) -> void:
	if _swatches.has(category):
		_swatches[category].color = color


func get_selected() -> String:
	return _selected
