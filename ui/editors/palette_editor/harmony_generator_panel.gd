## HarmonyGeneratorPanel - Generate color harmonies
class_name HarmonyGeneratorPanel
extends Control


signal harmony_generated(colors: Array[Color])


enum HarmonyType {
	COMPLEMENTARY,
	ANALOGOUS,
	TRIADIC,
	SPLIT_COMPLEMENT,
	TETRADIC,
	MONOCHROMATIC,
}


var _base_color: Color = Color.WHITE
var _harmony_type: HarmonyType = HarmonyType.COMPLEMENTARY
var _preview_swatches: Array[ColorRect] = []


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var label := Label.new()
	label.text = "Color Harmony"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	# Harmony type selector
	var type_hbox := HBoxContainer.new()

	var type_label := Label.new()
	type_label.text = "Type:"
	type_hbox.add_child(type_label)

	var type_option := OptionButton.new()
	type_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for t in HarmonyType.keys():
		type_option.add_item(t.capitalize())
	type_option.item_selected.connect(_on_type_selected)
	type_hbox.add_child(type_option)

	vbox.add_child(type_hbox)

	# Preview swatches
	var preview_hbox := HBoxContainer.new()
	preview_hbox.custom_minimum_size.y = 40

	for i in range(5):
		var swatch := ColorRect.new()
		swatch.custom_minimum_size = Vector2(40, 40)
		swatch.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		swatch.color = Color.GRAY
		preview_hbox.add_child(swatch)
		_preview_swatches.append(swatch)

	vbox.add_child(preview_hbox)

	# Generate button
	var gen_btn := Button.new()
	gen_btn.text = "Apply Harmony"
	gen_btn.pressed.connect(_on_generate_pressed)
	vbox.add_child(gen_btn)


func set_base_color(color: Color) -> void:
	_base_color = color
	_update_preview()


func _on_type_selected(index: int) -> void:
	_harmony_type = index as HarmonyType
	_update_preview()


func _update_preview() -> void:
	var colors := _generate_harmony(_base_color, _harmony_type)

	for i in range(_preview_swatches.size()):
		if i < colors.size():
			_preview_swatches[i].color = colors[i]
			_preview_swatches[i].visible = true
		else:
			_preview_swatches[i].visible = false


func _on_generate_pressed() -> void:
	var colors := _generate_harmony(_base_color, _harmony_type)
	harmony_generated.emit(colors)


func _generate_harmony(base: Color, type: HarmonyType) -> Array[Color]:
	var colors: Array[Color] = [base]
	var h := base.h
	var s := base.s
	var v := base.v

	match type:
		HarmonyType.COMPLEMENTARY:
			colors.append(Color.from_hsv(fmod(h + 0.5, 1.0), s, v))

		HarmonyType.ANALOGOUS:
			colors.append(Color.from_hsv(fmod(h + 0.083, 1.0), s, v))
			colors.append(Color.from_hsv(fmod(h - 0.083 + 1.0, 1.0), s, v))

		HarmonyType.TRIADIC:
			colors.append(Color.from_hsv(fmod(h + 0.333, 1.0), s, v))
			colors.append(Color.from_hsv(fmod(h + 0.666, 1.0), s, v))

		HarmonyType.SPLIT_COMPLEMENT:
			colors.append(Color.from_hsv(fmod(h + 0.416, 1.0), s, v))
			colors.append(Color.from_hsv(fmod(h + 0.583, 1.0), s, v))

		HarmonyType.TETRADIC:
			colors.append(Color.from_hsv(fmod(h + 0.25, 1.0), s, v))
			colors.append(Color.from_hsv(fmod(h + 0.5, 1.0), s, v))
			colors.append(Color.from_hsv(fmod(h + 0.75, 1.0), s, v))

		HarmonyType.MONOCHROMATIC:
			colors.append(Color.from_hsv(h, s * 0.5, v))
			colors.append(Color.from_hsv(h, s, v * 0.7))
			colors.append(Color.from_hsv(h, s * 0.7, v * 0.5))

	return colors
