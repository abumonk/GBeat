# BeatBeat Architecture

## Overview

BeatBeat uses a **subscription-based event system** where a central Sequencer emits beat events, and various game systems subscribe to receive callbacks at specific beat boundaries.

## Core Design Patterns

### 1. Subscription/Observer Pattern

The central pattern: systems register callbacks filtered by:
- **Deck**: Which playback source (Menu or Game deck)
- **Quant Type**: What kind of event (Kick, Snare, Animation, etc.)
- **Required Layers**: Optional additional filter requirements

```
┌─────────────┐     emits events      ┌─────────────────────┐
│  Sequencer  │ ───────────────────── │ SubscriptionStore   │
│  (Decks)    │                       │                     │
└─────────────┘                       │  filters & routes   │
                                      │  to subscribers     │
                                      └──────────┬──────────┘
                                                 │
                    ┌────────────────────────────┼────────────────────────────┐
                    │                            │                            │
                    ▼                            ▼                            ▼
            ┌───────────────┐          ┌───────────────┐          ┌───────────────┐
            │   Movement    │          │    Combat     │          │      VFX      │
            │  (subscribes  │          │  (subscribes  │          │  (subscribes  │
            │  to speed)    │          │  to animation)│          │  to kick/snr) │
            └───────────────┘          └───────────────┘          └───────────────┘
```

### 2. State Machine Pattern

Several systems use explicit state machines:

**Deck States:**
```
Idle ──SetNextPattern()──▶ Ready ──Start()──▶ Playing
  ▲                                              │
  │                                              │
  └──────────────────Stop()─────────────────────┘
                         │
                         ▼
                  QueuedTransition (pattern changing at bar boundary)
```

**Enemy Combat States:**
```
Idle ──detect target──▶ Telegraphing ──timer──▶ Attacking ──complete──▶ Idle
  ▲                                                                       │
  │                           ┌───────────────────────────────────────────┘
  │                           │
  └───recover──▶ Stunned ◀────┴── TakeDamage (if threshold exceeded)
```

### 3. Component Composition

Characters are built from composable components:

```
Character
├── MovementComponent        # Quantized velocity application
├── MovementAnimComponent    # Animation step selection
├── CombatAnimComponent      # Combat action management
├── MeleeHitboxComponent     # Hit detection
└── ScreenEffectsComponent   # Visual feedback
```

### 4. Data-Driven Design

Game content defined in data assets:
- **Patterns**: JSON/Resource files defining beat events
- **Movement Steps**: Animation database with movement deltas
- **Combat Steps**: Attack definitions with damage, hitboxes, timing
- **Boss Phases**: Phase progression with health thresholds

## System Relationships

### High-Level Data Flow

```
┌──────────────────────────────────────────────────────────────────────────────┐
│                              SEQUENCER LAYER                                  │
│  ┌──────────┐    ┌──────────┐    ┌───────────────────┐    ┌───────────────┐ │
│  │ Pattern  │───▶│   Deck   │───▶│ SubscriptionStore │───▶│   Callbacks   │ │
│  │ (JSON)   │    │ (Clock)  │    │                   │    │               │ │
│  └──────────┘    └──────────┘    └───────────────────┘    └───────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
                                          │
        ┌─────────────────────────────────┼─────────────────────────────────┐
        │                                 │                                 │
        ▼                                 ▼                                 ▼
┌───────────────┐                ┌───────────────┐                ┌───────────────┐
│   MOVEMENT    │                │    COMBAT     │                │     AUDIO     │
│               │                │               │                │               │
│ Input Buffer  │                │ Action Window │                │ Beat Detect   │
│      ▼        │                │      ▼        │                │      ▼        │
│ Latch @ Quant │                │ Timing Grade  │                │ Quartz Bridge │
│      ▼        │                │      ▼        │                │      ▼        │
│ Step Select   │                │ Step Select   │                │ Music Layers  │
│      ▼        │                │      ▼        │                │               │
│ Root Motion   │                │ Hitbox Active │                │               │
└───────────────┘                └───────────────┘                └───────────────┘
```

### Module Dependencies

```
                    ┌─────────────┐
                    │  Sequencer  │ ◀── Core singleton, no dependencies
                    └──────┬──────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
        ▼                  ▼                  ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│   Character   │  │     Audio     │  │  Environment  │
│   Movement    │  │               │  │               │
└───────┬───────┘  └───────────────┘  └───────────────┘
        │
        ▼
┌───────────────┐
│    Combat     │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│ Enemy / Boss  │
└───────────────┘
```

## Key Data Structures

### FQuant (Beat Event)
```gdscript
class_name Quant
extends Resource

enum Type {
    TICK,           # Basic timing pulse
    HIT,            # Generic hit marker
    KICK,           # Kick drum
    SNARE,          # Snare drum
    HAT,            # Hi-hat
    OPEN_HAT,       # Open hi-hat
    CRASH,          # Crash cymbal
    RIDE,           # Ride cymbal
    TOM,            # Tom drum
    ANIMATION,      # Trigger animation step
    TIME_SCALE,     # Adjust time
    MOVE_FORWARD_SPEED,  # Forward velocity
    MOVE_RIGHT_SPEED,    # Lateral velocity
    ROTATION_SPEED       # Rotation rate
}

@export var type: Type
@export var position: int  # 0-31 (32nd notes in bar)
@export var value: float   # 0.0-1.0 intensity
```

### FSequencerEvent (Emitted Event)
```gdscript
class_name SequencerEvent
extends RefCounted

var deck: Deck
var pattern: Pattern
var quant: Quant
var event_time_seconds: float
var quant_index: int
var bar_index: int
var pattern_loop_index: int
var absolute_quant_index: int
```

### FBar (Bar Cache)
```gdscript
class_name Bar
extends RefCounted

var quant_indices: Array[int]  # Indices into pattern's quants array
var quants: Array[Quant]       # Quants in this bar
```

## Timing Model

### Beat Grid
- 32 positions per bar (32nd note resolution)
- Position 0 = downbeat
- Position 8 = beat 2
- Position 16 = beat 3 (snare typically)
- Position 24 = beat 4

### Quant Cursor
Tracks current playback position:
```gdscript
class_name QuantCursor
extends RefCounted

var position: int = 0      # 0-31 within bar
var bar_index: int = 0     # Which bar
var loop_count: int = 0    # Pattern loops
var step_count: int = 0    # Absolute steps

func advance():
    position += 1
    step_count += 1
    if position >= 32:
        position = 0
        bar_index += 1
        if bar_index >= pattern.bar_count:
            bar_index = 0
            loop_count += 1
```

### Clock Precision
The original uses Quartz (audio-thread timing). In Godot:
- Use `AudioServer.get_time_since_last_mix()` for audio-accurate timing
- Or `Time.get_ticks_usec()` for microsecond precision
- Maintain drift compensation for long sessions

## Input Flow

```
Raw Input (analog stick) ──▶ Input Buffer
                                  │
                           [wait for quant]
                                  │
                                  ▼
                           Latch Input ──▶ Quantized Direction/Magnitude
                                  │
                                  ▼
                           Step Selection ──▶ Best matching animation
                                  │
                                  ▼
                           Playback Plan ──▶ Adjusted root motion
                                  │
                                  ▼
                           Character Movement ──▶ World position update
```

## Animation Step Selection Algorithm

The movement system selects animations based on:

1. **Direction Match**: Dot product between desired and animation direction
2. **Speed Range**: Animation supports requested speed
3. **Facing Delta**: Rotation stays within tolerance
4. **Foot Contact**: Maintains foot continuity (left/right)
5. **Package Match**: Same animation set for visual consistency
6. **Frame Match**: End frame matches next step's start frame

Scoring formula:
```
score = direction_dot * direction_weight
      + rotation_score * (1 - direction_weight)
      + frame_match_bonus
      + same_package_bonus
      + same_animation_bonus
      + link_match_bonus
```

## Combat Timing System

### Action Windows
Combat actions are valid only during specific windows:
- Window opens at quant boundary
- Player has N beats to input action
- Timing grade based on proximity to beat

### Timing Grades
```
| Grade   | Normalized Range |
|---------|------------------|
| Perfect | >= 0.95          |
| Great   | >= 0.85          |
| Good    | >= 0.65          |
| Early   | < 0.65 (early)   |
| Late    | < 0.65 (late)    |
| Miss    | Outside window   |
```

### Combo System
- Successful hits increment combo counter
- Combo multiplier increases damage
- Missing window or taking damage drops combo
- Timeout drops combo after N seconds

## Memory Management

### Object Lifecycle
- **Patterns**: Loaded on demand, cached in PatternCollection
- **Waves**: Loaded async, cached in WaveCollection
- **Steps**: Loaded at startup into MovementDatabase
- **Subscriptions**: Manual unsubscribe or weak references

### Godot Considerations
- Use `Resource` for data (auto memory management)
- Use `RefCounted` for runtime objects
- Use signals instead of storing callback references
- Leverage `preload()` for critical resources

## Threading Model

Original UE5 uses:
- Game thread for logic
- Audio thread for Quartz timing
- Async tasks for loading

Godot approach:
- Main thread for all game logic
- Use `AudioServer` callbacks for timing
- Use `ResourceLoader.load_threaded_*` for async loading
