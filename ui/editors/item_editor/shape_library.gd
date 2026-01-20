## ShapeLibrary - Grid of shape buttons for item creation
class_name ShapeLibrary
extends Control


signal shape_selected(shape: ItemPartData.ShapeType)


## Configuration
var shape_icons: Dictionary = {
	ItemPartData.ShapeType.BOX: "▢",
	ItemPartData.ShapeType.SPHERE: "◯",
	ItemPartData.ShapeType.CYLINDER: "▭",
	ItemPartData.ShapeType.CAPSULE: "⬭",
	ItemPartData.ShapeType.CONE: "△",
	ItemPartData.ShapeType.PRISM: "◇",
	ItemPartData.ShapeType.TORUS: "◎",
}


func _ready() -> void:
	_create_ui()


func _create_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(vbox)

	var label := Label.new()
	label.text = "Shape Library"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(label)

	var grid := GridContainer.new()
	grid.columns = 4
	vbox.add_child(grid)

	for shape in ItemPartData.ShapeType.values():
		var button := Button.new()
		button.text = shape_icons.get(shape, "?") + "\n" + ItemPartData.ShapeType.keys()[shape]
		button.custom_minimum_size = Vector2(50, 50)
		button.pressed.connect(_on_shape_pressed.bind(shape))
		grid.add_child(button)


func _on_shape_pressed(shape: ItemPartData.ShapeType) -> void:
	shape_selected.emit(shape)
