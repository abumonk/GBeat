# Godot Implementation Guide

This guide provides specific guidance for implementing BeatBeat in Godot Engine 4.x.

## Project Setup

### Recommended Project Settings

```ini
# project.godot

[application]
config/name="BeatBeat"
config/features=PackedStringArray("4.2", "Forward Plus")
run/main_scene="res://scenes/main_menu.tscn"

[autoload]
Sequencer="*res://autoload/sequencer.gd"
GameManager="*res://autoload/game_manager.gd"
AudioManager="*res://autoload/audio_manager.gd"
SaveManager="*res://autoload/save_manager.gd"

[display]
window/size/viewport_width=1920
window/size/viewport_height=1080
window/vsync/vsync_mode=1

[input]
move_left={...}
move_right={...}
move_up={...}
move_down={...}
light_attack={...}
heavy_attack={...}
block={...}
dodge={...}
ability_1={...}
ability_2={...}
ability_3={...}
ability_4={...}

[physics]
common/physics_ticks_per_second=120

[rendering]
renderer/rendering_method="forward_plus"
anti_aliasing/quality/msaa_3d=2
```

### Folder Structure

```
res://
├── autoload/
│   ├── sequencer.gd
│   ├── game_manager.gd
│   ├── audio_manager.gd
│   └── save_manager.gd
├── core/
│   ├── pattern.gd
│   ├── deck.gd
│   ├── quant.gd
│   ├── quant_cursor.gd
│   ├── subscription_store.gd
│   ├── pattern_collection.gd
│   └── wave_collection.gd
├── character/
│   ├── player.gd
│   ├── player.tscn
│   ├── player_controller.gd
│   └── movement/
│       ├── beat_movement.gd
│       ├── movement_anim.gd
│       └── movement_types.gd
├── combat/
│   ├── combat_component.gd
│   ├── combat_types.gd
│   ├── hitbox.gd
│   └── melee_weapon_data.gd
├── enemy/
│   ├── beat_enemy.gd
│   ├── beat_enemy.tscn
│   ├── enemy_combat.gd
│   └── enemy_ai.gd
├── boss/
│   ├── beat_boss.gd
│   ├── beat_boss.tscn
│   └── boss_types.gd
├── audio/
│   ├── beat_detection.gd
│   ├── quartz_bridge.gd
│   ├── music_layer.gd
│   ├── reactive_audio.gd
│   └── audio_types.gd
├── environment/
│   ├── lighting_floor.gd
│   ├── lighting_floor.tscn
│   ├── floor_tile.gd
│   ├── color_palette.gd
│   └── floor_reaction_script.gd
├── vfx/
│   ├── screen_effects.gd
│   ├── camera_effects.gd
│   └── pulse_visualizer.gd
├── level/
│   ├── arena_manager.gd
│   ├── spawn_point.gd
│   └── hazard.gd
├── save/
│   ├── save_manager.gd
│   ├── save_game.gd
│   └── save_types.gd
├── abilities/
│   ├── ability_component.gd
│   ├── ability_types.gd
│   └── ability_data.gd
├── ui/
│   ├── hud.tscn
│   ├── timing_feedback.gd
│   ├── combo_counter.gd
│   ├── ability_slot.gd
│   └── resource_bar.gd
├── resources/
│   ├── patterns/
│   │   └── *.tres (Pattern resources)
│   ├── movement_steps/
│   │   └── *.tres (MovementStepDefinition resources)
│   ├── combat_steps/
│   │   └── *.tres (CombatStepDefinition resources)
│   ├── abilities/
│   │   └── *.tres (BeatAbilityData resources)
│   └── color_palettes/
│       └── *.tres (ColorPalette resources)
├── scenes/
│   ├── main_menu.tscn
│   ├── game.tscn
│   └── arenas/
│       └── *.tscn
├── audio/
│   ├── music/
│   │   └── *.ogg
│   └── sfx/
│       └── *.wav
├── shaders/
│   ├── vignette.gdshader
│   ├── chromatic_aberration.gdshader
│   └── tile_emissive.gdshader
└── animations/
    └── *.tres (Animation resources)
```

## UE5 to Godot Mapping

### Type Mappings

| UE5 Type | Godot Type | Notes |
|----------|------------|-------|
| `UObject` | `RefCounted` or `Resource` | Use `Resource` for saveable data |
| `AActor` | `Node3D` | Base for all 3D objects |
| `ACharacter` | `CharacterBody3D` | Built-in movement support |
| `UActorComponent` | `Node` | Attach as child |
| `UGameInstanceSubsystem` | AutoLoad singleton | Add to project settings |
| `FStruct` | `class` or `Dictionary` | Inner classes or dicts |
| `TArray<T>` | `Array[T]` | Typed arrays in GDScript |
| `TMap<K,V>` | `Dictionary` | No typed dictionaries |
| `FMulticastDelegate` | `signal` | Godot signals |
| `USoundWave` | `AudioStream` | OGG, WAV, MP3 |
| `UAnimSequence` | `Animation` | AnimationPlayer animations |
| `UDataAsset` | `Resource` | Custom resource classes |
| `UDataTable` | `Array[Resource]` | Array of typed resources |
| `FTimerHandle` | `Timer` node or `await` | Timer patterns differ |
| `UMaterialInstanceDynamic` | `ShaderMaterial` | Dynamic materials |

### Blueprint to GDScript

| Blueprint Concept | GDScript Equivalent |
|-------------------|---------------------|
| Event Graph | `func _ready()`, `func _process()` |
| Functions | `func my_function():` |
| Variables | `var my_var` / `@export var` |
| Event Dispatchers | `signal my_signal()` |
| Interfaces | Duck typing or `class_name` |
| Cast To | `as Type` or `is Type` check |
| Get All Actors of Class | `get_tree().get_nodes_in_group()` |
| Spawn Actor | `instantiate()` + `add_child()` |
| Destroy Actor | `queue_free()` |

### Common Patterns

#### Singleton Access (UE5 Subsystem → Godot AutoLoad)

```cpp
// UE5
USequencer* Seq = GetGameInstance()->GetSubsystem<USequencer>();
```

```gdscript
# Godot - AutoLoad is globally accessible by name
Sequencer.subscribe(...)
```

#### Component Access

```cpp
// UE5
UBeatMovementComponent* Movement = Character->FindComponentByClass<UBeatMovementComponent>();
```

```gdscript
# Godot - Get child node by type or name
var movement = $BeatMovementComponent
# or
var movement = get_node("BeatMovementComponent")
# or find by type
for child in get_children():
    if child is BeatMovementComponent:
        movement = child
```

#### Event Binding (UE5 Delegates → Godot Signals)

```cpp
// UE5
Sequencer->OnQuantEvent.AddDynamic(this, &AMyActor::HandleQuant);
```

```gdscript
# Godot
Sequencer.quant_event.connect(_on_quant_event)
```

#### Timer Usage

```cpp
// UE5
GetWorldTimerManager().SetTimer(TimerHandle, this, &AMyActor::OnTimer, 1.0f, false);
```

```gdscript
# Godot - Multiple approaches

# 1. Timer node
var timer = Timer.new()
timer.wait_time = 1.0
timer.one_shot = true
timer.timeout.connect(_on_timer)
add_child(timer)
timer.start()

# 2. Await pattern (simpler for one-offs)
await get_tree().create_timer(1.0).timeout
_on_timer()

# 3. Tween for animations
var tween = create_tween()
tween.tween_callback(_on_timer).set_delay(1.0)
```

## Critical Implementation Details

### 1. Precise Timing

The Sequencer needs precise timing for beat synchronization:

```gdscript
# Option A: Process-based (simple, slightly less accurate)
func _process(delta: float):
    _accumulator += delta
    while _accumulator >= _quant_duration:
        _accumulator -= _quant_duration
        _emit_quant()

# Option B: Audio-based (more accurate)
func _get_audio_time() -> float:
    return AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()

# Option C: Physics process (fixed timestep)
func _physics_process(delta: float):
    # More consistent timing
    _process_beat_logic()
```

### 2. Animation Integration

For animation-driven movement:

```gdscript
# Root motion extraction
func _get_root_motion_from_animation(anim: Animation) -> Vector3:
    var root_track = anim.find_track(".:position", Animation.TYPE_POSITION_3D)
    if root_track < 0:
        return Vector3.ZERO

    var start_pos = anim.position_track_interpolate(root_track, 0.0)
    var end_pos = anim.position_track_interpolate(root_track, anim.length)
    return end_pos - start_pos

# Apply root motion in character
func _apply_root_motion(plan: MovementStepPlaybackPlan):
    var delta_per_frame = plan.adjusted_movement_delta / (plan.quantized_duration_seconds * 60.0)
    velocity = delta_per_frame * 60.0  # Convert to velocity
```

### 3. Input Quantization

```gdscript
func _quantize_input(raw: Vector2, dead_zone: float, magnitude_step: float) -> Vector2:
    if raw.length() < dead_zone:
        return Vector2.ZERO

    # Quantize magnitude
    var mag = raw.length()
    mag = ceil(mag / magnitude_step) * magnitude_step
    mag = clamp(mag, 0.0, 1.0)

    # Quantize to 8 directions
    var angle = raw.angle()
    var quantized_angle = round(angle / (PI / 4)) * (PI / 4)

    return Vector2.from_angle(quantized_angle) * mag
```

### 4. Hitbox Detection

```gdscript
# Use Area3D for efficient overlap detection
func _setup_hitbox():
    hitbox_area = Area3D.new()
    var shape = CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    hitbox_area.add_child(shape)
    hitbox_area.monitoring = false  # Enable only during active frames

func _activate_hitbox(plan: CombatStepPlaybackPlan):
    var box = hitbox_area.get_child(0).shape as BoxShape3D
    box.size = plan.hitbox_half_extent * 2
    hitbox_area.position = plan.hitbox_offset
    hitbox_area.monitoring = true

    # Check overlaps
    for body in hitbox_area.get_overlapping_bodies():
        if body != owner and body is BeatEnemy:
            _on_hit(body)
```

### 5. Resource Loading

```gdscript
# Preload for critical resources
const PATTERN_COMBAT = preload("res://resources/patterns/combat.tres")

# Load dynamically for optional content
func _load_pattern_async(path: String):
    ResourceLoader.load_threaded_request(path)

    while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
        await get_tree().process_frame

    return ResourceLoader.load_threaded_get(path)
```

## Performance Considerations

### 1. Object Pooling

For frequently spawned objects (enemies, effects):

```gdscript
class_name ObjectPool
extends Node

var _pool: Array[Node] = []
var _scene: PackedScene

func _init(scene: PackedScene, initial_size: int = 10):
    _scene = scene
    for i in range(initial_size):
        var obj = _scene.instantiate()
        obj.set_process(false)
        _pool.append(obj)

func get_object() -> Node:
    for obj in _pool:
        if not obj.is_inside_tree():
            return obj

    # Pool exhausted, create new
    var obj = _scene.instantiate()
    _pool.append(obj)
    return obj

func return_object(obj: Node):
    obj.get_parent().remove_child(obj)
    obj.set_process(false)
```

### 2. Signal Optimization

```gdscript
# Prefer direct method calls for high-frequency events
# Instead of:
signal high_freq_event
# Use:
var _listeners: Array[Callable] = []

func add_listener(callback: Callable):
    _listeners.append(callback)

func _emit_high_freq():
    for listener in _listeners:
        listener.call()
```

### 3. Subscription Filtering

Pre-filter subscriptions to avoid unnecessary checks:

```gdscript
# Store subscriptions indexed by quant type
var _by_type: Dictionary = {}  # Quant.Type -> Array[Subscription]

func dispatch(event: SequencerEvent):
    var subs = _by_type.get(event.quant.type, [])
    for sub in subs:
        if sub.deck == event.deck:
            sub.callback.call(event)
```

## Testing Strategy

### Unit Tests

```gdscript
# test/test_pattern.gd
extends GutTest

func test_pattern_initialization():
    var pattern = Pattern.new()
    pattern.bpm = 120.0

    var quant = Quant.new()
    quant.type = Quant.Type.KICK
    quant.position = 0
    quant.value = 1.0
    pattern.quants.append(quant)

    pattern.initialize()

    assert_eq(pattern.get_bar_count(), 1)
    assert_eq(pattern.get_quants_at_position(0).size(), 1)

func test_deck_state_machine():
    var deck = Deck.new()
    add_child(deck)

    assert_eq(deck.state, Deck.State.IDLE)

    var pattern = Pattern.new()
    pattern.bpm = 120.0
    deck.set_next_pattern(pattern)

    assert_eq(deck.state, Deck.State.READY)

    deck.start()
    assert_eq(deck.state, Deck.State.PLAYING)

    deck.stop()
    assert_eq(deck.state, Deck.State.IDLE)
```

### Integration Tests

```gdscript
# test/test_combat_flow.gd
extends GutTest

var player: Player
var enemy: BeatEnemy

func before_each():
    player = preload("res://character/player.tscn").instantiate()
    enemy = preload("res://enemy/beat_enemy.tscn").instantiate()
    add_child(player)
    add_child(enemy)

    enemy.global_position = player.global_position + Vector3(100, 0, 0)

func test_attack_hits_enemy():
    var combat = player.combat_anim_component
    combat.open_window(CombatTypes.WindowType.ATTACK, 1.0)

    var hit_detected = false
    player.melee_hitbox.hit_detected.connect(func(r): hit_detected = true)

    combat.try_action_in_window(CombatTypes.ActionType.LIGHT_ATTACK)

    # Simulate frames
    for i in range(30):
        await get_tree().physics_frame

    assert_true(hit_detected)
```

## Debugging Tools

### Beat Visualizer

```gdscript
# debug/beat_visualizer.gd
extends Control

@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

var _beat_history: Array[float] = []
const HISTORY_SIZE = 32

func _ready():
    Sequencer.subscribe(sequencer_deck, Quant.Type.KICK, _on_kick)

func _on_kick(event: SequencerEvent):
    _beat_history.append(event.quant.value)
    if _beat_history.size() > HISTORY_SIZE:
        _beat_history.pop_front()
    queue_redraw()

func _draw():
    var bar_width = size.x / HISTORY_SIZE
    for i in range(_beat_history.size()):
        var height = _beat_history[i] * size.y
        draw_rect(Rect2(i * bar_width, size.y - height, bar_width - 2, height), Color.GREEN)
```

### State Inspector

```gdscript
# debug/state_inspector.gd
extends Panel

@export var target: Node

func _process(_delta):
    if not target:
        return

    var text = ""
    for prop in target.get_property_list():
        if prop.name.begins_with("_"):
            continue
        text += "%s: %s\n" % [prop.name, str(target.get(prop.name))]

    $Label.text = text
```

## Deployment Checklist

1. **Audio**
   - [ ] All audio files converted to OGG for music, WAV for SFX
   - [ ] Audio bus setup with SpectrumAnalyzer
   - [ ] Latency compensation tested

2. **Input**
   - [ ] All input actions defined in project settings
   - [ ] Controller support tested
   - [ ] Dead zones calibrated

3. **Performance**
   - [ ] Object pools implemented for spawned objects
   - [ ] Profiler checked for frame drops
   - [ ] Memory usage monitored

4. **Save System**
   - [ ] Save/load tested across sessions
   - [ ] Corruption handling implemented
   - [ ] Auto-save working

5. **Visual**
   - [ ] Shaders compiled and tested
   - [ ] Materials properly assigned
   - [ ] Post-processing optimized

6. **Build**
   - [ ] Export templates installed
   - [ ] Export presets configured
   - [ ] Release build tested

## Quick Reference: Common Tasks

### Add New Quant Type

1. Add to `Quant.Type` enum in `core/quant.gd`
2. Add color mapping in `BeatColorPalette.get_color_for_quant_type()`
3. Add subscription in relevant systems

### Add New Enemy Attack

1. Create `BeatEnemyAttack` resource in `resources/enemy_attacks/`
2. Add to enemy's `attacks` array in inspector
3. Configure telegraph duration, damage, range

### Add New Ability

1. Create `BeatAbilityData` resource in `resources/abilities/`
2. Add to `BeatAbilityComponent.default_abilities` or register at runtime
3. Implement effect in `_on_ability_activated()` handler

### Add New Pattern

1. Create JSON file in `resources/patterns/`:
```json
{
  "name": "NewPattern",
  "sound": "res://audio/music/new_pattern.ogg",
  "bpm": 128,
  "quants": [...]
}
```
2. Load via `Pattern.load_from_json()` or convert to `.tres`

### Add Beat Reaction

1. Create `BeatFloorReactionScript` resource
2. Add `ReactionEvent` entries for desired quant types
3. Assign to `BeatLightingFloorActor.reaction_script`
