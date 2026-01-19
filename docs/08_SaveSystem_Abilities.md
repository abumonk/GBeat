# Save System & Abilities

## Save System Overview

The save system provides:
- Multiple save slots
- Auto-save functionality
- Async save/load operations
- Play time tracking

## Save Data Structures

### Player Profile

```gdscript
# save/save_types.gd
class_name BeatSaveTypes

class PlayerProfile:
    var player_name: String = ""
    var play_time: float = 0.0  # seconds
    var score: int = 0
    var level: int = 1
    var timestamp: int = 0  # Unix timestamp

    func to_dict() -> Dictionary:
        return {
            "player_name": player_name,
            "play_time": play_time,
            "score": score,
            "level": level,
            "timestamp": timestamp
        }

    static func from_dict(data: Dictionary) -> PlayerProfile:
        var profile = PlayerProfile.new()
        profile.player_name = data.get("player_name", "")
        profile.play_time = data.get("play_time", 0.0)
        profile.score = data.get("score", 0)
        profile.level = data.get("level", 1)
        profile.timestamp = data.get("timestamp", 0)
        return profile
```

### Save Game Resource

```gdscript
# save/save_game.gd
class_name BeatSaveGame
extends Resource

@export var profile: Dictionary = {}  # PlayerProfile as dict
@export var unlocked_abilities: Array[String] = []
@export var equipped_abilities: Array[String] = []  # Size 4 for slots
@export var settings: Dictionary = {}
@export var statistics: Dictionary = {}
@export var achievements: Array[String] = []

# Current game state
@export var current_checkpoint: String = ""
@export var current_health: float = 100.0
@export var current_combo_record: int = 0

func get_profile() -> BeatSaveTypes.PlayerProfile:
    return BeatSaveTypes.PlayerProfile.from_dict(profile)

func set_profile(p: BeatSaveTypes.PlayerProfile):
    profile = p.to_dict()
```

## Save Manager

### Implementation

```gdscript
# save/save_manager.gd
class_name BeatSaveManagerComponent
extends Node

signal save_completed(slot: int, success: bool)
signal load_completed(slot: int, success: bool)
signal save_created(slot: int)
signal save_deleted(slot: int)
signal auto_save_triggered()

const SAVE_DIR = "user://saves/"
const SAVE_FILE_PREFIX = "save_slot_"
const SAVE_FILE_EXT = ".tres"

@export var auto_save_enabled: bool = true
@export var auto_save_interval: float = 300.0  # 5 minutes
@export var max_save_slots: int = 3

var current_save: BeatSaveGame = null
var current_slot: int = -1
var _auto_save_timer: float = 0.0
var _play_time_accumulator: float = 0.0
var _session_start_time: float = 0.0

func _ready():
    _ensure_save_dir()
    _session_start_time = Time.get_ticks_msec() / 1000.0

func _process(delta: float):
    _play_time_accumulator += delta

    if auto_save_enabled and current_save:
        _auto_save_timer += delta
        if _auto_save_timer >= auto_save_interval:
            _auto_save_timer = 0.0
            auto_save()

func _ensure_save_dir():
    var dir = DirAccess.open("user://")
    if not dir.dir_exists("saves"):
        dir.make_dir("saves")

func _get_save_path(slot: int) -> String:
    return SAVE_DIR + SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXT

# === Save Operations ===

func save_game(slot: int) -> bool:
    if not current_save:
        current_save = BeatSaveGame.new()

    # Update play time
    update_play_time()

    # Update timestamp
    var profile = current_save.get_profile()
    profile.timestamp = int(Time.get_unix_time_from_system())
    current_save.set_profile(profile)

    var path = _get_save_path(slot)
    var error = ResourceSaver.save(current_save, path)

    var success = error == OK
    current_slot = slot if success else current_slot

    save_completed.emit(slot, success)
    return success

func save_game_async(slot: int):
    # In Godot, ResourceSaver is already fast enough for most saves
    # For truly async, you'd use threads
    var thread = Thread.new()
    thread.start(_save_thread.bind(slot))

func _save_thread(slot: int):
    var success = save_game(slot)
    call_deferred("_on_save_thread_complete", slot, success)

func _on_save_thread_complete(slot: int, success: bool):
    save_completed.emit(slot, success)

func auto_save():
    if current_slot >= 0:
        save_game(current_slot)
        auto_save_triggered.emit()

func load_game(slot: int) -> bool:
    var path = _get_save_path(slot)

    if not FileAccess.file_exists(path):
        load_completed.emit(slot, false)
        return false

    var loaded = ResourceLoader.load(path) as BeatSaveGame
    if not loaded:
        load_completed.emit(slot, false)
        return false

    current_save = loaded
    current_slot = slot
    _play_time_accumulator = 0.0

    load_completed.emit(slot, true)
    return true

func create_new_save(player_name: String, slot: int) -> bool:
    current_save = BeatSaveGame.new()

    var profile = BeatSaveTypes.PlayerProfile.new()
    profile.player_name = player_name
    profile.timestamp = int(Time.get_unix_time_from_system())
    current_save.set_profile(profile)

    current_save.equipped_abilities.resize(4)

    var success = save_game(slot)
    if success:
        save_created.emit(slot)

    return success

func delete_save(slot: int) -> bool:
    var path = _get_save_path(slot)

    if not FileAccess.file_exists(path):
        return false

    var dir = DirAccess.open(SAVE_DIR)
    var error = dir.remove(SAVE_FILE_PREFIX + str(slot) + SAVE_FILE_EXT)

    if error == OK:
        if current_slot == slot:
            current_save = null
            current_slot = -1
        save_deleted.emit(slot)
        return true

    return false

func does_save_exist(slot: int) -> bool:
    return FileAccess.file_exists(_get_save_path(slot))

func get_all_save_profiles() -> Array[BeatSaveTypes.PlayerProfile]:
    var profiles: Array[BeatSaveTypes.PlayerProfile] = []

    for slot in range(max_save_slots):
        if does_save_exist(slot):
            var save = ResourceLoader.load(_get_save_path(slot)) as BeatSaveGame
            if save:
                profiles.append(save.get_profile())
            else:
                profiles.append(null)
        else:
            profiles.append(null)

    return profiles

func update_play_time():
    if current_save:
        var profile = current_save.get_profile()
        profile.play_time += _play_time_accumulator
        current_save.set_profile(profile)
        _play_time_accumulator = 0.0

# === Game State Updates ===

func update_score(score: int):
    if current_save:
        var profile = current_save.get_profile()
        profile.score = score
        current_save.set_profile(profile)

func update_level(level: int):
    if current_save:
        var profile = current_save.get_profile()
        profile.level = level
        current_save.set_profile(profile)

func set_checkpoint(checkpoint_id: String):
    if current_save:
        current_save.current_checkpoint = checkpoint_id

func update_health(health: float):
    if current_save:
        current_save.current_health = health

func record_combo(combo: int):
    if current_save:
        current_save.current_combo_record = max(current_save.current_combo_record, combo)

# === Statistics ===

func increment_stat(stat_name: String, amount: int = 1):
    if current_save:
        var current = current_save.statistics.get(stat_name, 0)
        current_save.statistics[stat_name] = current + amount

func get_stat(stat_name: String) -> int:
    if current_save:
        return current_save.statistics.get(stat_name, 0)
    return 0

# === Achievements ===

func unlock_achievement(achievement_id: String):
    if current_save and not achievement_id in current_save.achievements:
        current_save.achievements.append(achievement_id)

func has_achievement(achievement_id: String) -> bool:
    if current_save:
        return achievement_id in current_save.achievements
    return false
```

## Abilities System

### Purpose
- Character special moves/abilities
- Unlock system with conditions
- Cooldown management
- Resource (stamina/mana) tracking

### Ability Definition

```gdscript
# abilities/ability_types.gd
class_name BeatAbilityTypes

enum UnlockCondition {
    NONE,           # Always unlocked
    SCORE,          # Reach score threshold
    COMBO,          # Achieve combo count
    LEVEL,          # Reach level
    ACHIEVEMENT,    # Unlock achievement
    PURCHASE        # Buy with currency
}

class AbilityDefinition:
    var ability_id: String = ""
    var ability_name: String = ""
    var description: String = ""
    var icon: Texture2D

    var cost: float = 0.0  # Resource cost
    var cooldown_beats: int = 4  # Cooldown in quants
    var duration_beats: int = 0  # 0 = instant

    var unlock_condition: UnlockCondition = UnlockCondition.NONE
    var unlock_value: int = 0  # Threshold for condition

    func to_dict() -> Dictionary:
        return {
            "ability_id": ability_id,
            "ability_name": ability_name,
            "description": description,
            "cost": cost,
            "cooldown_beats": cooldown_beats,
            "duration_beats": duration_beats,
            "unlock_condition": unlock_condition,
            "unlock_value": unlock_value
        }

class AbilityState:
    var definition: AbilityDefinition
    var is_unlocked: bool = false
    var cooldown_remaining: int = 0  # In beats
    var is_active: bool = false
    var active_time_remaining: int = 0
```

### Ability Data Resource

```gdscript
# abilities/ability_data.gd
class_name BeatAbilityData
extends Resource

@export var ability_id: String = ""
@export var ability_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var cost: float = 0.0
@export var cooldown_beats: int = 4
@export var duration_beats: int = 0

@export var unlock_condition: BeatAbilityTypes.UnlockCondition = BeatAbilityTypes.UnlockCondition.NONE
@export var unlock_value: int = 0

# Visual/Audio
@export var activation_vfx: PackedScene
@export var activation_sound: AudioStream

func to_definition() -> BeatAbilityTypes.AbilityDefinition:
    var def = BeatAbilityTypes.AbilityDefinition.new()
    def.ability_id = ability_id
    def.ability_name = ability_name
    def.description = description
    def.icon = icon
    def.cost = cost
    def.cooldown_beats = cooldown_beats
    def.duration_beats = duration_beats
    def.unlock_condition = unlock_condition
    def.unlock_value = unlock_value
    return def
```

### Ability Component

```gdscript
# abilities/ability_component.gd
class_name BeatAbilityComponent
extends Node

signal ability_activated(ability_id: String)
signal ability_deactivated(ability_id: String)
signal ability_unlocked(ability_id: String)
signal ability_cooldown_complete(ability_id: String)
signal resource_changed(current: float, maximum: float)

@export var default_abilities: Array[BeatAbilityData] = []
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

# Resource
@export var max_resource: float = 100.0
@export var resource_regen_rate: float = 5.0  # Per second
var current_resource: float

# Timing
@export var beat_timing_tolerance: float = 0.2  # 0-1, how close to beat for bonus

# State
var _abilities: Dictionary = {}  # ability_id -> AbilityState
var _equipped_slots: Array[String] = ["", "", "", ""]  # 4 slots
var _subscription_handle: int = -1

func _ready():
    current_resource = max_resource

    # Register default abilities
    for ability_data in default_abilities:
        register_ability(ability_data.to_definition())

    # Subscribe to beats for cooldown tracking
    _subscription_handle = Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.TICK,
        _on_tick
    )

func _exit_tree():
    if _subscription_handle >= 0:
        Sequencer.unsubscribe(_subscription_handle)

func _process(delta: float):
    # Regenerate resource
    if current_resource < max_resource:
        current_resource = min(max_resource, current_resource + resource_regen_rate * delta)
        resource_changed.emit(current_resource, max_resource)

func _on_tick(event: SequencerEvent):
    # Update cooldowns
    for ability_id in _abilities.keys():
        var state = _abilities[ability_id] as BeatAbilityTypes.AbilityState

        if state.cooldown_remaining > 0:
            state.cooldown_remaining -= 1
            if state.cooldown_remaining <= 0:
                ability_cooldown_complete.emit(ability_id)

        if state.is_active and state.active_time_remaining > 0:
            state.active_time_remaining -= 1
            if state.active_time_remaining <= 0:
                _deactivate_ability(ability_id)

# === Registration ===

func register_ability(definition: BeatAbilityTypes.AbilityDefinition):
    var state = BeatAbilityTypes.AbilityState.new()
    state.definition = definition
    state.is_unlocked = definition.unlock_condition == BeatAbilityTypes.UnlockCondition.NONE

    _abilities[definition.ability_id] = state

func get_ability_by_id(ability_id: String) -> BeatAbilityTypes.AbilityState:
    return _abilities.get(ability_id)

func get_all_abilities() -> Array[BeatAbilityTypes.AbilityState]:
    var result: Array[BeatAbilityTypes.AbilityState] = []
    for state in _abilities.values():
        result.append(state)
    return result

# === Activation ===

func try_activate_ability(ability_id: String) -> bool:
    if not can_activate_ability(ability_id):
        return false

    var state = _abilities[ability_id] as BeatAbilityTypes.AbilityState
    var def = state.definition

    # Consume resource
    current_resource -= def.cost
    resource_changed.emit(current_resource, max_resource)

    # Start cooldown
    state.cooldown_remaining = def.cooldown_beats

    # Activate (duration or instant)
    if def.duration_beats > 0:
        state.is_active = true
        state.active_time_remaining = def.duration_beats
    else:
        # Instant ability - trigger effect immediately
        pass

    ability_activated.emit(ability_id)
    return true

func can_activate_ability(ability_id: String) -> bool:
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    if not state:
        return false

    if not state.is_unlocked:
        return false

    if state.cooldown_remaining > 0:
        return false

    if state.is_active:
        return false

    if current_resource < state.definition.cost:
        return false

    return true

func _deactivate_ability(ability_id: String):
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    if state:
        state.is_active = false
        state.active_time_remaining = 0
        ability_deactivated.emit(ability_id)

func get_cooldown_remaining(ability_id: String) -> int:
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    if state:
        return state.cooldown_remaining
    return 0

# === Slots ===

func equip_ability_to_slot(ability_id: String, slot: int):
    if slot < 0 or slot >= _equipped_slots.size():
        return

    # Check if ability exists and is unlocked
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    if not state or not state.is_unlocked:
        return

    # Remove from previous slot if equipped
    for i in range(_equipped_slots.size()):
        if _equipped_slots[i] == ability_id:
            _equipped_slots[i] = ""
            break

    _equipped_slots[slot] = ability_id

func activate_slot(slot: int) -> bool:
    if slot < 0 or slot >= _equipped_slots.size():
        return false

    var ability_id = _equipped_slots[slot]
    if ability_id.is_empty():
        return false

    return try_activate_ability(ability_id)

func get_ability_in_slot(slot: int) -> String:
    if slot < 0 or slot >= _equipped_slots.size():
        return ""
    return _equipped_slots[slot]

func get_equipped_abilities() -> Array[String]:
    return _equipped_slots.duplicate()

# === Unlock System ===

func unlock_ability(ability_id: String):
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    if state and not state.is_unlocked:
        state.is_unlocked = true
        ability_unlocked.emit(ability_id)

func is_ability_unlocked(ability_id: String) -> bool:
    var state = _abilities.get(ability_id) as BeatAbilityTypes.AbilityState
    return state and state.is_unlocked

func get_unlocked_abilities() -> Array[String]:
    var result: Array[String] = []
    for ability_id in _abilities.keys():
        var state = _abilities[ability_id] as BeatAbilityTypes.AbilityState
        if state.is_unlocked:
            result.append(ability_id)
    return result

func check_unlock_conditions(score: int, max_combo: int, level: int):
    for ability_id in _abilities.keys():
        var state = _abilities[ability_id] as BeatAbilityTypes.AbilityState
        if state.is_unlocked:
            continue

        var def = state.definition
        var should_unlock = false

        match def.unlock_condition:
            BeatAbilityTypes.UnlockCondition.SCORE:
                should_unlock = score >= def.unlock_value
            BeatAbilityTypes.UnlockCondition.COMBO:
                should_unlock = max_combo >= def.unlock_value
            BeatAbilityTypes.UnlockCondition.LEVEL:
                should_unlock = level >= def.unlock_value

        if should_unlock:
            unlock_ability(ability_id)

# === Resource Management ===

func add_resource(amount: float):
    current_resource = min(max_resource, current_resource + amount)
    resource_changed.emit(current_resource, max_resource)

func consume_resource(amount: float) -> bool:
    if current_resource >= amount:
        current_resource -= amount
        resource_changed.emit(current_resource, max_resource)
        return true
    return false

func get_resource_percent() -> float:
    return current_resource / max_resource

# === Save/Load Integration ===

func save_to_save_game(save: BeatSaveGame):
    save.unlocked_abilities.clear()
    for ability_id in _abilities.keys():
        var state = _abilities[ability_id] as BeatAbilityTypes.AbilityState
        if state.is_unlocked:
            save.unlocked_abilities.append(ability_id)

    save.equipped_abilities = _equipped_slots.duplicate()

func load_from_save_game(save: BeatSaveGame):
    # Restore unlocks
    for ability_id in save.unlocked_abilities:
        if _abilities.has(ability_id):
            _abilities[ability_id].is_unlocked = true

    # Restore equipped
    if save.equipped_abilities.size() == _equipped_slots.size():
        _equipped_slots = save.equipped_abilities.duplicate()
```

## Ability UI

### Ability Slot Display

```gdscript
# ui/ability_slot.gd
class_name AbilitySlotUI
extends Control

signal slot_pressed(slot_index: int)

@export var slot_index: int = 0
@export var ability_component: BeatAbilityComponent

@onready var icon: TextureRect = $Icon
@onready var cooldown_overlay: ColorRect = $CooldownOverlay
@onready var cooldown_label: Label = $CooldownLabel
@onready var hotkey_label: Label = $HotkeyLabel

var _ability_id: String = ""

func _ready():
    hotkey_label.text = str(slot_index + 1)
    _update_display()

    if ability_component:
        ability_component.ability_activated.connect(_on_ability_activated)
        ability_component.ability_cooldown_complete.connect(_on_cooldown_complete)

func _process(_delta: float):
    _update_cooldown_display()

func _update_display():
    _ability_id = ability_component.get_ability_in_slot(slot_index) if ability_component else ""

    if _ability_id.is_empty():
        icon.texture = null
        cooldown_overlay.visible = false
        return

    var state = ability_component.get_ability_by_id(_ability_id)
    if state:
        icon.texture = state.definition.icon
        cooldown_overlay.visible = state.cooldown_remaining > 0

func _update_cooldown_display():
    if _ability_id.is_empty() or not ability_component:
        return

    var remaining = ability_component.get_cooldown_remaining(_ability_id)
    cooldown_overlay.visible = remaining > 0
    cooldown_label.text = str(remaining) if remaining > 0 else ""

func _on_ability_activated(ability_id: String):
    if ability_id == _ability_id:
        _update_display()

func _on_cooldown_complete(ability_id: String):
    if ability_id == _ability_id:
        cooldown_overlay.visible = false

func _gui_input(event: InputEvent):
    if event is InputEventMouseButton and event.pressed:
        slot_pressed.emit(slot_index)
```

### Resource Bar

```gdscript
# ui/resource_bar.gd
class_name ResourceBarUI
extends Control

@export var ability_component: BeatAbilityComponent

@onready var fill_bar: ProgressBar = $FillBar
@onready var value_label: Label = $ValueLabel

func _ready():
    if ability_component:
        ability_component.resource_changed.connect(_on_resource_changed)
        _update_display(ability_component.current_resource, ability_component.max_resource)

func _on_resource_changed(current: float, maximum: float):
    _update_display(current, maximum)

func _update_display(current: float, maximum: float):
    fill_bar.max_value = maximum
    fill_bar.value = current
    value_label.text = "%d / %d" % [int(current), int(maximum)]
```

## Scene Structure

### Save Manager Scene
```
SaveManager (Node)
└── BeatSaveManagerComponent
```

### Abilities Scene
```
AbilitiesManager (Node)
├── BeatAbilityComponent
└── AbilityUI (Control)
    ├── AbilitySlot0
    ├── AbilitySlot1
    ├── AbilitySlot2
    ├── AbilitySlot3
    └── ResourceBar
```

## Integration Example

```gdscript
# game_manager.gd
extends Node

@onready var save_manager: BeatSaveManagerComponent = $SaveManager
@onready var ability_component: BeatAbilityComponent = $Player/AbilityComponent

func _ready():
    # Load save on start
    if save_manager.does_save_exist(0):
        save_manager.load_game(0)
        ability_component.load_from_save_game(save_manager.current_save)

func _unhandled_input(event: InputEvent):
    # Ability slots (1-4 keys)
    if event.is_action_pressed("ability_1"):
        ability_component.activate_slot(0)
    elif event.is_action_pressed("ability_2"):
        ability_component.activate_slot(1)
    elif event.is_action_pressed("ability_3"):
        ability_component.activate_slot(2)
    elif event.is_action_pressed("ability_4"):
        ability_component.activate_slot(3)

func on_level_complete(score: int, combo: int, level: int):
    # Check for ability unlocks
    ability_component.check_unlock_conditions(score, combo, level)

    # Save progress
    save_manager.update_score(score)
    save_manager.update_level(level)
    ability_component.save_to_save_game(save_manager.current_save)
    save_manager.save_game(save_manager.current_slot)
```
