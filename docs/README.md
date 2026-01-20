# BeatBeat - Godot Port Documentation

This documentation describes the BeatBeat rhythm-action game, originally built in Unreal Engine 5.7, for the purpose of recreating it in Godot Engine.

## Game Overview

**BeatBeat** is a rhythm-driven action game that combines:
- **Quantized Input**: Player actions are snapped to beat boundaries
- **Motion Matching**: Animation selection based on movement direction and continuity
- **Beat-Synchronized Actions**: All gameplay events (movement, combat, effects) sync to the beat

The core loop: Players input directions/actions which are latched at beat boundaries, triggering animation-driven movement and combat that feels locked to the music.

## Documentation Index

### Core Systems (Implemented)

| Document | Description |
|----------|-------------|
| [01_Architecture.md](01_Architecture.md) | Core architecture, design patterns, and data flow |
| [02_Sequencer.md](02_Sequencer.md) | Beat sequencer system (clock, decks, patterns, subscriptions) |
| [03_Character_Movement.md](03_Character_Movement.md) | Character controller and animation-driven movement |
| [04_Combat.md](04_Combat.md) | Combat system, action windows, hitboxes, timing feedback |
| [05_Enemy_Boss.md](05_Enemy_Boss.md) | Enemy AI, boss phases, arena management |
| [06_Audio.md](06_Audio.md) | Audio systems, beat detection, music layers |
| [07_Environment.md](07_Environment.md) | Beat-reactive environment (lighting floor, VFX) |
| [08_SaveSystem_Abilities.md](08_SaveSystem_Abilities.md) | Save/load system and ability management |
| [09_Godot_Implementation.md](09_Godot_Implementation.md) | Godot-specific implementation guide and mapping |

### Feature Designs (Planned/Partial)

| Document | Description |
|----------|-------------|
| [10_Editors.md](10_Editors.md) | In-game editors (Pattern, Item, Animation, Color Palette) |
| [11_Gameplay_Expansion.md](11_Gameplay_Expansion.md) | Combo system, style meter, game modes, accessibility |
| [12_Customization.md](12_Customization.md) | Character customization (body, clothing, materials) |
| [13_Level_Design.md](13_Level_Design.md) | Level design, themes, hazards, level editor |
| [14_Technical_Roadmap.md](14_Technical_Roadmap.md) | Platform support, networking, CI/CD, localization |

### Additional Resources

| Document | Description |
|----------|-------------|
| [TESTING.md](TESTING.md) | Testing framework and conventions |
| [plans/](plans/) | Detailed implementation roadmaps and timelines |

## Key Concepts

### Quant (Quantization Unit)
A **Quant** is a single beat event with:
- **Type**: What kind of event (Kick, Snare, Hat, Animation, MoveForwardSpeed, etc.)
- **Position**: Where in the bar (0-31, representing 32nd note subdivisions)
- **Value**: Intensity/magnitude (0.0-1.0)

### Pattern
A **Pattern** defines a repeating musical phrase:
- BPM (tempo)
- Sound reference (audio file)
- Array of Quants defining when events occur

### Deck
A **Deck** manages playback of a Pattern:
- Wraps a precise clock (Quartz in UE5)
- Emits events at each quant boundary
- Handles pattern transitions

### Subscription Model
Systems subscribe to specific quant types on specific decks:
- Movement subscribes to `MoveForwardSpeed`, `MoveRightSpeed`, `RotationSpeed`
- Combat subscribes to `Animation` quants
- VFX subscribes to `Kick`, `Snare`, etc.

## Technology Mapping (UE5 → Godot)

| UE5 Concept | Godot Equivalent |
|-------------|------------------|
| GameInstanceSubsystem | AutoLoad singleton |
| ActorComponent | Node (attached to parent) |
| UObject | Resource or RefCounted |
| Blueprint | GDScript or C# |
| Quartz Clock | AudioServer + Timer |
| Enhanced Input | Input singleton + InputMap |
| CharacterMovementComponent | CharacterBody3D |
| AnimSequence | Animation in AnimationPlayer |
| DataAsset | Resource file (.tres) |
| DataTable | Dictionary or Resource array |
| Multicast Delegate | Signal |
| TMap | Dictionary |
| TArray | Array |

## Project Structure Recommendation

```
res://
├── autoload/
│   └── sequencer.gd          # Global beat sequencer
├── core/
│   ├── pattern.gd            # Pattern resource
│   ├── deck.gd               # Deck playback manager
│   ├── quant.gd              # Quant data structure
│   └── subscription_store.gd # Event routing
├── character/
│   ├── player.gd             # Player character
│   ├── player_controller.gd  # Input handling
│   └── movement/
│       ├── beat_movement.gd  # Quantized movement
│       └── movement_anim.gd  # Animation step selection
├── combat/
│   ├── combat_component.gd   # Action windows & combos
│   ├── hitbox.gd             # Hit detection
│   └── combat_types.gd       # Combat data structures
├── enemy/
│   ├── beat_enemy.gd         # Base enemy
│   ├── beat_boss.gd          # Boss with phases
│   └── enemy_combat.gd       # Enemy attack patterns
├── audio/
│   ├── beat_detection.gd     # Real-time beat detection
│   └── music_layer.gd        # Dynamic music mixing
├── environment/
│   ├── lighting_floor.gd     # Beat-reactive floor
│   └── floor_tile.gd         # Individual tile
├── vfx/
│   ├── screen_effects.gd     # Post-process effects
│   └── pulse_visualizer.gd   # Beat visualization
├── save/
│   └── save_manager.gd       # Save/load system
├── abilities/
│   └── ability_component.gd  # Special moves
└── resources/
    ├── patterns/             # Pattern .tres files
    ├── movement_steps/       # Movement animation data
    └── combat_steps/         # Combat animation data
```

## Implementation Priority

1. **Sequencer System** - Foundation for everything
2. **Pattern & Deck** - Beat playback
3. **Character & Movement** - Player control
4. **Combat System** - Action gameplay
5. **Enemy System** - Opposition
6. **Audio Integration** - Music sync
7. **Environment** - Visual feedback
8. **Save System** - Persistence
9. **Boss System** - Advanced enemies
10. **Abilities** - Extended gameplay

## Quick Start

1. Start with [01_Architecture.md](01_Architecture.md) to understand the overall design
2. Implement the Sequencer following [02_Sequencer.md](02_Sequencer.md)
3. Build character systems from [03_Character_Movement.md](03_Character_Movement.md)
4. Add combat per [04_Combat.md](04_Combat.md)
5. Reference [09_Godot_Implementation.md](09_Godot_Implementation.md) for Godot-specific patterns
