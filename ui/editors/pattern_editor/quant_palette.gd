## QuantPalette - Palette of quant types for selection
class_name QuantPalette
extends HBoxContainer


signal type_selected(type: Quant.Type)


## Configuration
var type_colors: Dictionary = {
	Quant.Type.TICK: Color(0.5, 0.5, 0.5),
	Quant.Type.KICK: Color(1.0, 0.3, 0.3),
	Quant.Type.SNARE: Color(0.3, 1.0, 0.3),
	Quant.Type.HAT: Color(0.3, 0.3, 1.0),
	Quant.Type.OPEN_HAT: Color(0.3, 0.5, 1.0),
	Quant.Type.CRASH: Color(1.0, 0.8, 0.0),
	Quant.Type.RIDE: Color(0.8, 0.8, 0.3),
	Quant.Type.TOM: Color(0.8, 0.4, 0.2),
	Quant.Type.ANIMATION: Color(1.0, 1.0, 0.3),
	Quant.Type.HIT: Color(1.0, 0.5, 0.0),
}

## State
var _buttons: Dictionary = {}
var _selected_type: Quant.Type = Quant.Type.KICK


func _ready() -> void:
	_create_buttons()


func _create_buttons() -> void:
	var label := Label.new()
	label.text = "Quant Type:"
	add_child(label)

	for type in type_colors:
		var button := Button.new()
		button.text = Quant.Type.keys()[type]
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(60, 30)

		# Style with color
		var style := StyleBoxFlat.new()
		style.bg_color = type_colors[type].darkened(0.5)
		style.border_color = type_colors[type]
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		button.add_theme_stylebox_override("normal", style)

		var pressed_style := style.duplicate()
		pressed_style.bg_color = type_colors[type]
		button.add_theme_stylebox_override("pressed", pressed_style)

		button.button_pressed = (type == _selected_type)
		button.toggled.connect(_on_button_toggled.bind(type))

		add_child(button)
		_buttons[type] = button


func _on_button_toggled(pressed: bool, type: Quant.Type) -> void:
	if pressed:
		_selected_type = type
		type_selected.emit(type)

		# Deselect other buttons
		for other_type in _buttons:
			if other_type != type:
				_buttons[other_type].button_pressed = false


func select_type(type: Quant.Type) -> void:
	if _buttons.has(type):
		_buttons[type].button_pressed = true
		_selected_type = type


func get_selected_type() -> Quant.Type:
	return _selected_type
