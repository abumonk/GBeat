# Sequencer System

The Sequencer is the heart of BeatBeat, managing beat timing and distributing events to all game systems.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         SEQUENCER                               │
│  (Global Singleton / AutoLoad)                                  │
│                                                                 │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────────┐ │
│  │  MenuDeck   │  │  GameDeck   │  │  SubscriptionStore      │ │
│  │             │  │             │  │                         │ │
│  │  Pattern    │  │  Pattern    │  │  deck → type → callback │ │
│  │  Clock      │  │  Clock      │  │                         │ │
│  │  Cursor     │  │  Cursor     │  │                         │ │
│  └─────────────┘  └─────────────┘  └─────────────────────────┘ │
│                                                                 │
│  ┌─────────────────────┐  ┌─────────────────────┐              │
│  │  PatternCollection  │  │    WaveCollection   │              │
│  │  (Pattern registry) │  │  (Sound registry)   │              │
│  └─────────────────────┘  └─────────────────────┘              │
└─────────────────────────────────────────────────────────────────┘
```

## Sequencer (Singleton)

### Purpose
- Manages two independent playback decks (Menu and Game)
- Provides subscription API for beat events
- Holds pattern and sound registries

### Implementation

```gdscript
# autoload/sequencer.gd
extends Node

signal calibration_completed(delay_seconds: float)

enum DeckType { MENU, GAME }

var decks: Dictionary = {}  # DeckType -> Deck
var subscription_store: SubscriptionStore
var pattern_collection: PatternCollection
var wave_collection: WaveCollection
var movement_database: Array[MovementStepDefinition] = []

var audio_delay_seconds: float = 0.0

func _ready():
    subscription_store = SubscriptionStore.new()
    pattern_collection = PatternCollection.new()
    wave_collection = WaveCollection.new()

    # Create both decks
    decks[DeckType.MENU] = _create_deck("MenuDeck")
    decks[DeckType.GAME] = _create_deck("GameDeck")

func _create_deck(deck_name: String) -> Deck:
    var deck = Deck.new()
    deck.name = deck_name
    deck.quant_event.connect(_on_deck_quant_event.bind(deck))
    add_child(deck)
    return deck

func _on_deck_quant_event(event: SequencerEvent, deck: Deck):
    subscription_store.dispatch(event)

# === Subscription API ===

func subscribe(
    deck_type: DeckType,
    quant_type: Quant.Type,
    callback: Callable,
    required_layers: Array[Quant.Type] = []
) -> int:
    var deck = decks[deck_type]
    return subscription_store.add_subscription(deck, quant_type, callback, required_layers)

func unsubscribe(handle: int):
    subscription_store.remove_subscription(handle)

# === Deck Control API ===

func set_next_pattern(deck_type: DeckType, pattern: Pattern):
    decks[deck_type].set_next_pattern(pattern)

func start(deck_type: DeckType):
    decks[deck_type].start()

func stop(deck_type: DeckType):
    decks[deck_type].stop()

func pause(deck_type: DeckType):
    decks[deck_type].pause()

func resume(deck_type: DeckType):
    decks[deck_type].resume()

# === Pattern API ===

func play_pattern_by_name(deck_type: DeckType, pattern_name: String):
    var pattern = pattern_collection.get_pattern(pattern_name)
    if pattern:
        set_next_pattern(deck_type, pattern)
        start(deck_type)

func play_pattern_asset(deck_type: DeckType, pattern: Pattern):
    set_next_pattern(deck_type, pattern)
    start(deck_type)

# === Query API ===

func get_next_quant_of_type(deck_type: DeckType, quant_type: Quant.Type) -> Quant:
    var deck = decks[deck_type]
    if deck.current_pattern:
        return deck.current_pattern.get_next_quant(quant_type, deck.cursor.position)
    return null

func get_beats_to_quant(deck_type: DeckType, quant_type: Quant.Type) -> float:
    var deck = decks[deck_type]
    if deck.current_pattern:
        return deck.current_pattern.get_beats_to_quant(quant_type, deck.cursor.position)
    return -1.0

func get_deck(deck_type: DeckType) -> Deck:
    return decks[deck_type]

# === Audio Calibration ===

func calibrate_audio_delay(iterations: int = 5, tone_seconds: float = 0.1, silence_seconds: float = 0.5):
    # Implementation would play tones and measure round-trip latency
    # Simplified: just set a default value
    audio_delay_seconds = 0.02  # 20ms default
    calibration_completed.emit(audio_delay_seconds)
```

## Deck (Playback Manager)

### Purpose
- Wraps a precise clock
- Manages pattern state machine
- Emits events at quant boundaries
- Handles audio playback

### State Machine

```
┌───────┐                    ┌───────┐                    ┌─────────┐
│ IDLE  │──SetNextPattern()─▶│ READY │──────Start()──────▶│ PLAYING │
└───────┘                    └───────┘                    └────┬────┘
    ▲                                                          │
    │                                                          │
    └──────────────────────Stop()──────────────────────────────┘
                                │
                   ┌────────────┴───────────┐
                   ▼                        ▼
          ┌───────────────┐        ┌───────────────┐
          │    PAUSED     │        │   QUEUED_     │
          │               │        │  TRANSITION   │
          └───────────────┘        └───────────────┘
```

### Implementation

```gdscript
# core/deck.gd
class_name Deck
extends Node

signal quant_event(event: SequencerEvent)
signal pattern_changed(old_pattern: Pattern, new_pattern: Pattern)
signal state_changed(old_state: State, new_state: State)

enum State { IDLE, READY, PLAYING, PAUSED, QUEUED_TRANSITION }

var state: State = State.IDLE
var current_pattern: Pattern = null
var next_pattern: Pattern = null
var cursor: QuantCursor = QuantCursor.new()

var _clock_accumulator: float = 0.0
var _quant_duration: float = 0.0  # Seconds per quant

var audio_player: AudioStreamPlayer

func _ready():
    audio_player = AudioStreamPlayer.new()
    add_child(audio_player)

func _process(delta: float):
    if state != State.PLAYING:
        return

    _clock_accumulator += delta

    while _clock_accumulator >= _quant_duration:
        _clock_accumulator -= _quant_duration
        _process_quant_tick()

func _process_quant_tick():
    _emit_quant_events()
    _advance_cursor()

func _emit_quant_events():
    if not current_pattern:
        return

    # Find all quants at current position
    var quants_at_position = current_pattern.get_quants_at_position(cursor.position)

    for quant in quants_at_position:
        var event = SequencerEvent.new()
        event.deck = self
        event.pattern = current_pattern
        event.quant = quant
        event.event_time_seconds = Time.get_ticks_msec() / 1000.0
        event.quant_index = cursor.position
        event.bar_index = cursor.bar_index
        event.pattern_loop_index = cursor.loop_count
        event.absolute_quant_index = cursor.step_count

        quant_event.emit(event)

func _advance_cursor():
    cursor.position += 1
    cursor.step_count += 1

    if cursor.position >= 32:
        cursor.position = 0
        cursor.bar_index += 1

        # Check for pattern transition at bar boundary
        if state == State.QUEUED_TRANSITION and next_pattern:
            _transition_to_next_pattern()

        if cursor.bar_index >= current_pattern.get_bar_count():
            cursor.bar_index = 0
            cursor.loop_count += 1

func _transition_to_next_pattern():
    var old = current_pattern
    current_pattern = next_pattern
    next_pattern = null
    cursor.reset()
    _update_quant_duration()
    state = State.PLAYING
    pattern_changed.emit(old, current_pattern)

func _update_quant_duration():
    if current_pattern:
        # 32 quants per bar, at given BPM
        # beats_per_second = BPM / 60
        # bars_per_second = beats_per_second / 4 (assuming 4/4)
        # quants_per_second = bars_per_second * 32
        var beats_per_second = current_pattern.bpm / 60.0
        var quants_per_second = beats_per_second * 8  # 8 quants per beat (32nd notes)
        _quant_duration = 1.0 / quants_per_second

# === Public API ===

func set_next_pattern(pattern: Pattern):
    pattern.initialize()

    if state == State.IDLE:
        current_pattern = pattern
        _update_quant_duration()
        _change_state(State.READY)
    elif state == State.PLAYING:
        next_pattern = pattern
        _change_state(State.QUEUED_TRANSITION)
    else:
        next_pattern = pattern

func start():
    if state == State.IDLE:
        push_error("Cannot start deck without pattern")
        return

    cursor.reset()
    _clock_accumulator = 0.0

    if current_pattern.sound:
        audio_player.stream = current_pattern.sound
        audio_player.play()

    _change_state(State.PLAYING)

func stop():
    audio_player.stop()
    cursor.reset()
    _clock_accumulator = 0.0
    current_pattern = null
    next_pattern = null
    _change_state(State.IDLE)

func pause():
    if state == State.PLAYING:
        audio_player.stream_paused = true
        _change_state(State.PAUSED)

func resume():
    if state == State.PAUSED:
        audio_player.stream_paused = false
        _change_state(State.PLAYING)

func _change_state(new_state: State):
    var old_state = state
    state = new_state
    state_changed.emit(old_state, new_state)
```

## QuantCursor

### Purpose
Tracks current playback position within pattern

### Implementation

```gdscript
# core/quant_cursor.gd
class_name QuantCursor
extends RefCounted

var position: int = 0      # 0-31 within bar
var bar_index: int = 0     # Current bar
var loop_count: int = 0    # Pattern loop count
var step_count: int = 0    # Absolute step count

func reset():
    position = 0
    bar_index = 0
    loop_count = 0
    step_count = 0

func get_absolute_position() -> int:
    return bar_index * 32 + position
```

## Pattern

### Purpose
- Defines beat events for a musical phrase
- Caches bar and layer structures for efficient queries
- Supports JSON serialization

### Data Format

```json
{
  "name": "BasicBeat",
  "sound": "res://audio/basic_beat.ogg",
  "bpm": 120,
  "quants": [
    { "type": "Kick", "position": 0, "value": 1.0 },
    { "type": "Kick", "position": 16, "value": 1.0 },
    { "type": "Snare", "position": 8, "value": 1.0 },
    { "type": "Snare", "position": 24, "value": 1.0 },
    { "type": "Hat", "position": 0, "value": 0.8 },
    { "type": "Hat", "position": 4, "value": 0.5 },
    { "type": "Hat", "position": 8, "value": 0.8 },
    { "type": "Hat", "position": 12, "value": 0.5 },
    { "type": "Animation", "position": 0, "value": 1.0 },
    { "type": "Animation", "position": 8, "value": 1.0 },
    { "type": "Animation", "position": 16, "value": 1.0 },
    { "type": "Animation", "position": 24, "value": 1.0 },
    { "type": "MoveForwardSpeed", "position": 0, "value": 1.0 },
    { "type": "MoveRightSpeed", "position": 0, "value": 1.0 },
    { "type": "RotationSpeed", "position": 0, "value": 1.0 }
  ]
}
```

### Implementation

```gdscript
# core/pattern.gd
class_name Pattern
extends Resource

@export var pattern_name: String = ""
@export var sound: AudioStream
@export var bpm: float = 120.0
@export var quants: Array[Quant] = []

# Cached structures (built on initialize)
var _bars: Array[Bar] = []
var _layers: Dictionary = {}  # Quant.Type -> Array[Quant]
var _position_map: Dictionary = {}  # position -> Array[Quant]
var _initialized: bool = false

func initialize():
    if _initialized:
        return

    _build_bars()
    _build_layers()
    _build_position_map()
    _initialized = true

func _build_bars():
    _bars.clear()

    # Find max position to determine bar count
    var max_position = 0
    for quant in quants:
        max_position = max(max_position, quant.position)

    var bar_count = (max_position / 32) + 1

    for i in range(bar_count):
        _bars.append(Bar.new())

    for i in range(quants.size()):
        var quant = quants[i]
        var bar_idx = quant.position / 32
        if bar_idx < _bars.size():
            _bars[bar_idx].quant_indices.append(i)
            _bars[bar_idx].quants.append(quant)

func _build_layers():
    _layers.clear()

    for quant in quants:
        if not _layers.has(quant.type):
            _layers[quant.type] = []
        _layers[quant.type].append(quant)

func _build_position_map():
    _position_map.clear()

    for quant in quants:
        var pos = quant.position % 32  # Normalize to single bar
        if not _position_map.has(pos):
            _position_map[pos] = []
        _position_map[pos].append(quant)

func get_bar_count() -> int:
    return max(_bars.size(), 1)

func get_quants_at_position(position: int) -> Array[Quant]:
    if _position_map.has(position):
        return _position_map[position]
    return []

func get_next_quant(quant_type: Quant.Type, from_position: int) -> Quant:
    if not _layers.has(quant_type):
        return null

    var layer_quants = _layers[quant_type]

    # Find first quant after from_position
    for quant in layer_quants:
        if quant.position > from_position:
            return quant

    # Wrap around to beginning
    if layer_quants.size() > 0:
        return layer_quants[0]

    return null

func get_beats_to_quant(quant_type: Quant.Type, from_position: int) -> float:
    var next_quant = get_next_quant(quant_type, from_position)
    if not next_quant:
        return -1.0

    var distance = next_quant.position - from_position
    if distance <= 0:
        distance += 32  # Wrapped

    # Convert positions to beats (8 positions per beat)
    return distance / 8.0

func try_get_quant_value(quant_type: Quant.Type, position: int) -> float:
    var quants_at_pos = get_quants_at_position(position)
    for quant in quants_at_pos:
        if quant.type == quant_type:
            return quant.value
    return 0.0

func set_quant_value(quant_type: Quant.Type, position: int, value: float):
    # Find existing quant
    for quant in quants:
        if quant.type == quant_type and quant.position == position:
            quant.value = value
            return

    # Create new quant
    var new_quant = Quant.new()
    new_quant.type = quant_type
    new_quant.position = position
    new_quant.value = value
    quants.append(new_quant)

    # Rebuild caches
    _initialized = false
    initialize()

# === JSON Serialization ===

func save_to_json(path: String):
    var data = {
        "name": pattern_name,
        "sound": sound.resource_path if sound else "",
        "bpm": bpm,
        "quants": []
    }

    for quant in quants:
        data.quants.append({
            "type": Quant.Type.keys()[quant.type],
            "position": quant.position,
            "value": quant.value
        })

    var file = FileAccess.open(path, FileAccess.WRITE)
    file.store_string(JSON.stringify(data, "  "))

static func load_from_json(path: String) -> Pattern:
    var file = FileAccess.open(path, FileAccess.READ)
    if not file:
        return null

    var json = JSON.new()
    var error = json.parse(file.get_as_text())
    if error != OK:
        return null

    var data = json.data
    var pattern = Pattern.new()
    pattern.pattern_name = data.get("name", "")
    pattern.bpm = data.get("bpm", 120.0)

    var sound_path = data.get("sound", "")
    if sound_path:
        pattern.sound = load(sound_path)

    for quant_data in data.get("quants", []):
        var quant = Quant.new()
        quant.type = Quant.Type.get(quant_data.type, Quant.Type.TICK)
        quant.position = quant_data.position
        quant.value = quant_data.value
        pattern.quants.append(quant)

    pattern.initialize()
    return pattern
```

## SubscriptionStore

### Purpose
- Stores callbacks organized by deck and quant type
- Efficiently dispatches events to matching subscribers
- Handles subscription lifecycle

### Implementation

```gdscript
# core/subscription_store.gd
class_name SubscriptionStore
extends RefCounted

class Subscription:
    var handle: int
    var deck: Deck
    var quant_type: Quant.Type
    var required_layers: Array[Quant.Type]
    var callback: Callable

var _subscriptions: Dictionary = {}  # handle -> Subscription
var _by_deck_and_type: Dictionary = {}  # deck -> quant_type -> Array[Subscription]
var _next_handle: int = 1

func add_subscription(
    deck: Deck,
    quant_type: Quant.Type,
    callback: Callable,
    required_layers: Array[Quant.Type] = []
) -> int:
    var sub = Subscription.new()
    sub.handle = _next_handle
    sub.deck = deck
    sub.quant_type = quant_type
    sub.required_layers = required_layers
    sub.callback = callback

    _subscriptions[sub.handle] = sub

    # Index by deck and type
    if not _by_deck_and_type.has(deck):
        _by_deck_and_type[deck] = {}
    if not _by_deck_and_type[deck].has(quant_type):
        _by_deck_and_type[deck][quant_type] = []
    _by_deck_and_type[deck][quant_type].append(sub)

    _next_handle += 1
    return sub.handle

func remove_subscription(handle: int):
    if not _subscriptions.has(handle):
        return

    var sub = _subscriptions[handle]
    _subscriptions.erase(handle)

    # Remove from index
    if _by_deck_and_type.has(sub.deck):
        if _by_deck_and_type[sub.deck].has(sub.quant_type):
            _by_deck_and_type[sub.deck][sub.quant_type].erase(sub)

func dispatch(event: SequencerEvent):
    var deck = event.deck
    var quant_type = event.quant.type

    if not _by_deck_and_type.has(deck):
        return
    if not _by_deck_and_type[deck].has(quant_type):
        return

    for sub in _by_deck_and_type[deck][quant_type]:
        # Check required layers
        if _check_required_layers(event, sub.required_layers):
            sub.callback.call(event)

func _check_required_layers(event: SequencerEvent, required: Array[Quant.Type]) -> bool:
    if required.is_empty():
        return true

    # Check if pattern has quants of all required types at this position
    var pattern = event.pattern
    var position = event.quant_index

    for req_type in required:
        var found = false
        for quant in pattern.get_quants_at_position(position):
            if quant.type == req_type:
                found = true
                break
        if not found:
            return false

    return true
```

## PatternCollection

### Purpose
- Registry of named patterns
- Supports loading from JSON files
- Manages playback order

### Implementation

```gdscript
# core/pattern_collection.gd
class_name PatternCollection
extends Resource

@export var patterns: Dictionary = {}  # name -> Pattern
@export var pattern_order: Array[String] = []

func create_pattern(pattern_name: String, sound: AudioStream, bpm: float = 120.0) -> Pattern:
    var pattern = Pattern.new()
    pattern.pattern_name = pattern_name
    pattern.sound = sound
    pattern.bpm = bpm

    patterns[pattern_name] = pattern
    pattern_order.append(pattern_name)

    return pattern

func get_pattern(pattern_name: String) -> Pattern:
    return patterns.get(pattern_name)

func remove_pattern(pattern_name: String):
    patterns.erase(pattern_name)
    pattern_order.erase(pattern_name)

func load_pattern_from_json(pattern_name: String, path: String) -> Pattern:
    var pattern = Pattern.load_from_json(path)
    if pattern:
        pattern.pattern_name = pattern_name
        patterns[pattern_name] = pattern
        if not pattern_order.has(pattern_name):
            pattern_order.append(pattern_name)
    return pattern

func save_pattern_to_json(pattern_name: String, path: String):
    var pattern = get_pattern(pattern_name)
    if pattern:
        pattern.save_to_json(path)

func load_patterns_from_directory(dir_path: String):
    var dir = DirAccess.open(dir_path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.ends_with(".json"):
            var pattern_name = file_name.get_basename()
            load_pattern_from_json(pattern_name, dir_path.path_join(file_name))
        file_name = dir.get_next()
```

## WaveCollection

### Purpose
- Runtime storage for sound waves
- Supports lazy loading and caching

### Implementation

```gdscript
# core/wave_collection.gd
class_name WaveCollection
extends Resource

@export var waves: Dictionary = {}  # name -> AudioStream

func add_wave(wave_name: String, stream: AudioStream):
    waves[wave_name] = stream

func get_wave(wave_name: String) -> AudioStream:
    return waves.get(wave_name)

func get_or_load_wave(wave_name: String, path: String) -> AudioStream:
    if waves.has(wave_name):
        return waves[wave_name]

    var stream = load(path) as AudioStream
    if stream:
        waves[wave_name] = stream
    return stream

func populate_from_directory(dir_path: String):
    var dir = DirAccess.open(dir_path)
    if not dir:
        return

    dir.list_dir_begin()
    var file_name = dir.get_next()

    while file_name != "":
        if file_name.ends_with(".ogg") or file_name.ends_with(".wav") or file_name.ends_with(".mp3"):
            var wave_name = file_name.get_basename()
            var stream = load(dir_path.path_join(file_name))
            if stream:
                waves[wave_name] = stream
        file_name = dir.get_next()
```

## Usage Example

```gdscript
# In a game manager script
extends Node

func _ready():
    # Load a pattern
    var pattern = Pattern.load_from_json("res://patterns/combat_beat.json")

    # Subscribe to kick drums for VFX
    Sequencer.subscribe(
        Sequencer.DeckType.GAME,
        Quant.Type.KICK,
        _on_kick
    )

    # Subscribe to animation quants for movement
    Sequencer.subscribe(
        Sequencer.DeckType.GAME,
        Quant.Type.ANIMATION,
        _on_animation_quant
    )

    # Start playback
    Sequencer.set_next_pattern(Sequencer.DeckType.GAME, pattern)
    Sequencer.start(Sequencer.DeckType.GAME)

func _on_kick(event: SequencerEvent):
    # Flash screen on kick
    $ScreenEffects.flash(Color.WHITE, 0.1)

func _on_animation_quant(event: SequencerEvent):
    # Trigger movement step
    $Character.trigger_movement_step()
```
