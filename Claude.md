# Claude.md - BeatBeat Development Guide

## Project Overview

**BeatBeat** is a rhythm-driven action game being developed in Godot Engine 4.x. The game combines:
- **Quantized Input**: Player actions snapped to beat boundaries
- **Animation-Driven Movement**: Motion matching based on direction and continuity
- **Beat-Synchronized Combat**: All gameplay events sync to the music

## Repository Structure

```
res://
├── autoload/           # Global singletons (Sequencer, GameManager, etc.)
├── core/               # Core systems (Pattern, Deck, Quant, Subscriptions)
├── character/          # Player character and movement systems
├── combat/             # Combat system, hitboxes, weapons
├── enemy/              # Enemy AI and combat
├── boss/               # Boss system with phases
├── audio/              # Beat detection, music layers
├── environment/        # Lighting floor, visual effects
├── vfx/                # Screen effects, camera effects
├── level/              # Arena management, spawning
├── save/               # Save/load system
├── abilities/          # Special abilities system
├── ui/                 # User interface components
├── resources/          # Data files (.tres)
├── scenes/             # Scene files (.tscn)
├── shaders/            # Shader files (.gdshader)
└── docs/               # Documentation
```

## Key Concepts

### Quant (Beat Event)
A single beat event with:
- **Type**: KICK, SNARE, HAT, ANIMATION, MOVE_FORWARD_SPEED, etc.
- **Position**: 0-31 (32nd note subdivisions within a bar)
- **Value**: Intensity 0.0-1.0

### Pattern
Defines a repeating musical phrase containing:
- BPM (tempo)
- Audio stream reference
- Array of Quants

### Deck
Manages playback of a Pattern:
- Wraps a precise clock
- Emits events at quant boundaries
- Handles pattern transitions

### Subscription Model
Systems subscribe to specific quant types:
- Movement subscribes to `MOVE_FORWARD_SPEED`, `MOVE_RIGHT_SPEED`, `ROTATION_SPEED`
- Combat subscribes to `ANIMATION` quants
- VFX subscribes to `KICK`, `SNARE`, etc.

## Development Commands

### Run Project
```bash
# From Godot editor or command line
godot --path . res://scenes/main_menu.tscn
```

### Export Build
```bash
godot --headless --export-release "Windows Desktop" build/GBeat.exe
```

## Coding Conventions

### GDScript Style
- Use `snake_case` for functions and variables
- Use `PascalCase` for class names
- Use `SCREAMING_SNAKE_CASE` for constants
- Prefix private members with underscore `_`

### Signals
```gdscript
signal my_event(param: Type)
```

### Resources
- Store reusable data as `.tres` files in `resources/` folder
- Use `@export` for inspector-editable properties

### Component Pattern
- Attach functionality as child nodes
- Use signals for loose coupling
- Access via `@onready var component = $ComponentName`

## AutoLoad Singletons

| Name | Purpose |
|------|---------|
| `Sequencer` | Beat timing and event distribution |
| `GameManager` | Game state and flow control |
| `AudioManager` | Music layers and reactive audio |
| `SaveManager` | Save/load operations |

## Important Files

| File | Description |
|------|-------------|
| `autoload/sequencer.gd` | Core beat sequencer system |
| `core/pattern.gd` | Pattern resource definition |
| `core/deck.gd` | Pattern playback manager |
| `character/player.gd` | Main player character |
| `combat/combat_component.gd` | Combat windows and timing |
| `enemy/beat_enemy.gd` | Base enemy class |

## Testing

Use GUT (Godot Unit Test) for testing:
```gdscript
extends GutTest

func test_example():
    assert_eq(1 + 1, 2)
```

## Documentation Reference

Detailed documentation is in `/docs`:
- `01_Architecture.md` - System design and data flow
- `02_Sequencer.md` - Beat sequencer implementation
- `03_Character_Movement.md` - Movement and animation
- `04_Combat.md` - Combat system details
- `05_Enemy_Boss.md` - Enemy and boss AI
- `06_Audio.md` - Audio integration
- `07_Environment.md` - Visual effects
- `08_SaveSystem_Abilities.md` - Persistence and abilities
- `09_Godot_Implementation.md` - Godot-specific guidance

## Current Development Phase

See `DEVELOPMENT_PLAN.md` for detailed implementation roadmap.
