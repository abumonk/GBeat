## MainMenu - Main menu screen with navigation
class_name MainMenu
extends Control


signal play_pressed()
signal editors_pressed()
signal settings_pressed()
signal quit_pressed()


## UI References
var title_label: Label
var button_container: VBoxContainer
var version_label: Label


func _ready() -> void:
	_create_ui()
	_animate_entrance()


func _create_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.05)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Main container
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.text = "GBEAT"
	title_label.add_theme_font_size_override("font_size", 72)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.6))
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title_label)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Rhythm-Driven Action"
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 50
	vbox.add_child(spacer)

	# Button container
	button_container = VBoxContainer.new()
	button_container.add_theme_constant_override("separation", 15)
	vbox.add_child(button_container)

	# Buttons
	_create_menu_button("Play", _on_play_pressed)
	_create_menu_button("Dance Floor", _on_dance_floor_pressed)
	_create_menu_button("Editors", _on_editors_pressed)
	_create_menu_button("Settings", _on_settings_pressed)
	_create_menu_button("Quit", _on_quit_pressed)

	# Version
	version_label = Label.new()
	version_label.text = "v0.1.0 - Early Development"
	version_label.add_theme_font_size_override("font_size", 12)
	version_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.45))
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	version_label.position = Vector2(-150, -30)
	add_child(version_label)


func _create_menu_button(text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(250, 50)
	button.pressed.connect(callback)

	# Style
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15)
	style.border_color = Color(1.0, 0.2, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.15, 0.1, 0.2)
	hover_style.border_color = Color(1.0, 0.4, 0.7)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = Color(0.2, 0.1, 0.25)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_font_size_override("font_size", 20)

	button_container.add_child(button)
	return button


func _animate_entrance() -> void:
	# Fade in
	modulate.a = 0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.5)

	# Title pulse
	_start_title_pulse()


func _start_title_pulse() -> void:
	var tween := create_tween()
	tween.set_loops()

	var original_color := Color(1.0, 0.2, 0.6)
	var pulse_color := Color(1.0, 0.4, 0.8)

	tween.tween_property(title_label, "modulate", pulse_color, 0.5)
	tween.tween_property(title_label, "modulate", original_color, 0.5)


func _on_play_pressed() -> void:
	play_pressed.emit()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_dance_floor_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dance_floor.tscn")


func _on_editors_pressed() -> void:
	editors_pressed.emit()
	# Show editor selection
	_show_editor_menu()


func _on_settings_pressed() -> void:
	settings_pressed.emit()


func _on_quit_pressed() -> void:
	quit_pressed.emit()
	get_tree().quit()


func _show_editor_menu() -> void:
	var popup := PopupMenu.new()
	popup.add_item("Pattern Editor", 0)
	popup.add_item("Item Editor", 1)
	popup.add_item("Animation Editor", 2)
	popup.add_item("Palette Editor", 3)
	popup.id_pressed.connect(_on_editor_selected)
	popup.position = get_viewport().get_mouse_position()
	add_child(popup)
	popup.popup()


func _on_editor_selected(id: int) -> void:
	match id:
		0:
			_open_pattern_editor()
		1:
			_open_item_editor()
		2:
			_open_animation_editor()
		3:
			_open_palette_editor()


func _open_pattern_editor() -> void:
	var editor := PatternEditor.new()
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(editor)
	hide()


func _open_item_editor() -> void:
	var editor := ItemEditor.new()
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(editor)
	hide()


func _open_animation_editor() -> void:
	var editor := AnimationEditor.new()
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(editor)
	hide()


func _open_palette_editor() -> void:
	var editor := PaletteEditor.new()
	editor.set_anchors_preset(Control.PRESET_FULL_RECT)
	get_tree().root.add_child(editor)
	hide()
