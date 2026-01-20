## AbilityBar - Row of ability slots showing cooldowns and availability
class_name AbilityBar
extends HBoxContainer


signal ability_activated(index: int)


## Configuration
@export var slot_count: int = 4
@export var slot_size: Vector2 = Vector2(64, 64)
@export var slot_spacing: float = 10.0

## State
var _slots: Array[AbilitySlot] = []
var _ability_manager: Node


func _ready() -> void:
	add_theme_constant_override("separation", int(slot_spacing))
	_create_slots()


func _create_slots() -> void:
	for i in range(slot_count):
		var slot := AbilitySlot.new()
		slot.custom_minimum_size = slot_size
		slot.slot_index = i
		slot.input_key = "ability_%d" % (i + 1)
		slot.activated.connect(_on_slot_activated.bind(i))
		add_child(slot)
		_slots.append(slot)


func _on_slot_activated(index: int) -> void:
	ability_activated.emit(index)


func bind_ability_manager(manager: Node) -> void:
	_ability_manager = manager

	if manager.has_signal("ability_used"):
		manager.ability_used.connect(_on_ability_used)
	if manager.has_signal("cooldown_updated"):
		manager.cooldown_updated.connect(_on_cooldown_updated)

	# Initialize slots with current abilities
	if manager.has_method("get_abilities"):
		var abilities: Array = manager.get_abilities()
		for i in range(mini(abilities.size(), _slots.size())):
			_slots[i].set_ability(abilities[i])


func _on_ability_used(index: int) -> void:
	if index >= 0 and index < _slots.size():
		_slots[index].trigger_used()


func _on_cooldown_updated(index: int, remaining: float, total: float) -> void:
	if index >= 0 and index < _slots.size():
		_slots[index].set_cooldown(remaining, total)


func set_ability(index: int, ability_data: Resource) -> void:
	if index >= 0 and index < _slots.size():
		_slots[index].set_ability(ability_data)


func get_slot(index: int) -> AbilitySlot:
	if index >= 0 and index < _slots.size():
		return _slots[index]
	return null
