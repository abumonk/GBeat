# Level Design

This document describes the level design system for BeatBeat, including environment themes, hazards, and level structure.

## Environment Themes

### Theme System

Each theme defines a complete visual and audio identity:

```gdscript
class_name EnvironmentTheme
extends Resource

@export var theme_id: String
@export var display_name: String

## Visual settings
@export_group("Visuals")
@export var skybox: Sky
@export var ambient_light_color: Color
@export var ambient_light_energy: float
@export var fog_enabled: bool
@export var fog_color: Color
@export var fog_density: float

## Floor settings
@export_group("Floor")
@export var floor_material: Material
@export var floor_tile_size: Vector2
@export var floor_beat_color: Color
@export var floor_idle_color: Color

## Music settings
@export_group("Audio")
@export var default_pattern: Pattern
@export var combat_pattern: Pattern
@export var boss_pattern: Pattern
@export var ambient_sounds: Array[AudioStream]

## Color palette
@export_group("Colors")
@export var palette: ColorPaletteDefinition
```

### Built-in Themes

| Theme | Description | Visual Style |
|-------|-------------|--------------|
| **Neon City** | Cyberpunk urban | Dark blues, neon pinks/cyans |
| **Digital Void** | Abstract cyberspace | Grid lines, data streams |
| **Club Floor** | Dance club | Disco lights, reflective surfaces |
| **Arcade** | Retro gaming | Pixel art elements, CRT effects |
| **Nature Beat** | Organic rhythm | Bioluminescent, flowing lines |
| **Industrial** | Factory/machine | Metal, gears, steam |
| **Celestial** | Space/cosmic | Stars, nebulae, ethereal |
| **Glitch** | Corrupted reality | Visual artifacts, distortion |

### Theme Components

Each theme includes:

```
theme/
├── skybox/          # HDR environment
├── floor/           # Tile materials and meshes
├── props/           # Decorative objects
├── particles/       # Theme-specific VFX
├── audio/           # Music and ambience
├── shaders/         # Custom visual effects
└── palette.tres     # Color definitions
```

---

## Beat-Reactive Elements

### Floor System

The beat-reactive floor is central to visual feedback:

```gdscript
class_name BeatFloorTile
extends Node3D

@export var idle_material: Material
@export var active_material: Material
@export var transition_time: float = 0.1

## Grid position
var grid_position: Vector2i
var is_active: bool = false

## Pattern for this tile
var activation_pattern: Array[int] = []  # Beat positions to activate

func _on_tick(event: SequencerEvent) -> void:
    if event.quant.position in activation_pattern:
        activate()

func activate() -> void:
    is_active = true
    _transition_to_material(active_material)

    var tween := create_tween()
    tween.tween_callback(_deactivate).set_delay(transition_time)

func _deactivate() -> void:
    is_active = false
    _transition_to_material(idle_material)
```

### Floor Patterns

Different reactive patterns for variety:

| Pattern | Description |
|---------|-------------|
| **Radial** | Expands from center on beat |
| **Wave** | Horizontal/vertical sweep |
| **Checkerboard** | Alternating tiles |
| **Spiral** | Rotating activation |
| **Random** | Randomized tiles per beat |
| **Chase** | Follows player movement |
| **Zone** | Highlights combat areas |

### Reactive Props

Environmental objects that respond to beats:

```gdscript
class_name BeatReactiveProp
extends Node3D

@export var react_to_quant: Quant.Type = Quant.Type.KICK
@export var reaction_type: ReactionType
@export var intensity: float = 1.0

enum ReactionType {
    SCALE_PULSE,    # Grow and shrink
    ROTATION,       # Spin on beat
    COLOR_FLASH,    # Material color change
    EMISSION,       # Glow brighter
    TRANSLATION,    # Move up/down
    SPAWN_PARTICLE, # Emit particles
}

func _on_tick(event: SequencerEvent) -> void:
    if event.quant.type == react_to_quant:
        _react(event.quant.value * intensity)
```

---

## Level Structure

### Arena Layout

Levels are built as modular arenas:

```gdscript
class_name ArenaDefinition
extends Resource

@export var arena_id: String
@export var display_name: String
@export var theme: EnvironmentTheme

## Geometry
@export_group("Geometry")
@export var floor_size: Vector2i = Vector2i(20, 20)
@export var boundary_type: BoundaryType
@export var spawn_points: Array[Vector3]
@export var hazard_placements: Array[HazardPlacement]
@export var prop_placements: Array[PropPlacement]

## Gameplay
@export_group("Gameplay")
@export var enemy_spawn_zones: Array[SpawnZone]
@export var power_up_spawns: Array[Vector3]
@export var objective_markers: Array[ObjectiveMarker]

enum BoundaryType {
    WALLS,      # Solid walls
    VOID,       # Fall off edges
    WRAP,       # Wrap around (pac-man style)
    HAZARD,     # Damaging boundary
}
```

### Level Layers

```
Level Composition:
├── Background Layer
│   └── Skybox, distant props, parallax
├── Floor Layer
│   └── Beat-reactive tiles, floor props
├── Gameplay Layer
│   └── Player, enemies, hazards, items
├── Props Layer
│   └── Decorative elements, barriers
├── Effects Layer
│   └── Particles, screen effects
└── UI Layer
    └── Health, combo, timing feedback
```

### Wave System

Levels use wave-based enemy spawning:

```gdscript
class_name WaveDefinition
extends Resource

@export var wave_number: int
@export var enemies: Array[EnemySpawn]
@export var spawn_delay: float = 0.5
@export var clear_condition: ClearCondition

## Modifiers
@export var time_limit: float = 0.0  # 0 = no limit
@export var special_rules: Array[WaveModifier]

enum ClearCondition {
    ALL_ENEMIES,    # Kill all enemies
    SURVIVE_TIME,   # Survive for duration
    REACH_SCORE,    # Hit score threshold
    BOSS_DEFEAT,    # Defeat boss enemy
}
```

---

## Hazard Design

### Hazard Types

```gdscript
enum HazardType {
    SPIKE,          # Periodic damage zones
    LASER,          # Line damage, rotating
    PROJECTILE,     # Moving hazards
    ZONE,           # Area damage over time
    PLATFORM,       # Moving/disappearing floor
    CRUSHER,        # Timed crushing hazard
}
```

### Hazard Definition

```gdscript
class_name HazardDefinition
extends Resource

@export var hazard_type: HazardType
@export var damage: float = 10.0
@export var beat_pattern: Array[int]  # Activation beats
@export var warning_beats: float = 1.0
@export var active_duration: float = 0.5

## Visual
@export_group("Visuals")
@export var mesh: Mesh
@export var warning_material: Material
@export var active_material: Material
@export var warning_particles: PackedScene
@export var hit_particles: PackedScene
```

### Hazard Examples

| Hazard | Pattern | Warning |
|--------|---------|---------|
| **Beat Spikes** | KICK quants | Floor glow before activation |
| **Laser Grid** | Rotates on SNARE | Red line preview |
| **Pulse Wave** | Expands on BAR | Expanding ring preview |
| **Drop Platforms** | Random beats | Platform flickers |
| **Energy Walls** | Alternating beats | Wall color shift |

### Hazard Choreography

Hazards sync to music patterns:

```gdscript
class_name HazardChoreographer
extends Node

@export var hazards: Array[BeatHazard]
@export var pattern: Pattern

func _ready() -> void:
    # Subscribe each hazard to its specific quants
    for hazard in hazards:
        Sequencer.subscribe_to_type(
            hazard.active_on_quant,
            hazard._on_beat
        )

func choreograph_sequence(sequence: Array[ChoreographyStep]) -> void:
    for step in sequence:
        _schedule_hazard(step.hazard, step.start_beat, step.pattern)
```

---

## Level Editor

### Editor Features

The in-game level editor allows creation of custom arenas:

```
┌─────────────────────────────────────────────────────────────┐
│ LEVEL EDITOR                              [Save] [Test]     │
├───────────────┬─────────────────────────────────────────────┤
│ TOOLS         │                                             │
│ ┌───────────┐ │            TOP-DOWN VIEW                    │
│ │ [Select]  │ │  ┌─────────────────────────────────────┐   │
│ │ [Paint]   │ │  │ · · · · · · · · · · · · · · · · · · │   │
│ │ [Erase]   │ │  │ · · · · · · · · · · · · · · · · · · │   │
│ │ [Props]   │ │  │ · · · ▲ · · · · · · · ▲ · · · · · · │   │
│ │ [Hazards] │ │  │ · · · · · · ■ · · · · · · · · · · · │   │
│ │ [Spawns]  │ │  │ · · · · · · · · · · · · · · · · · · │   │
│ ├───────────┤ │  │ · · · · · · · · ★ · · · · · · · · · │   │
│ │ PALETTE   │ │  │ · · · · · · · · · · · · · · · · · · │   │
│ │ [Tile A]  │ │  │ · · ▲ · · · · · · · · · · ▲ · · · · │   │
│ │ [Tile B]  │ │  │ · · · · · · · · · · · · · · · · · · │   │
│ │ [Spike]   │ │  └─────────────────────────────────────┘   │
│ │ [Laser]   │ │                                             │
│ │ [Spawn]   │ │  LEGEND: ★ Player  ▲ Enemy  ■ Hazard        │
│ └───────────┘ │                                             │
├───────────────┴─────────────────────────────────────────────┤
│ Grid: 1x1  │  Theme: Neon City  │  Waves: 5                 │
└─────────────────────────────────────────────────────────────┘
```

### Editor Workflow

1. **Select Theme**: Choose visual style
2. **Define Boundaries**: Set arena size and edges
3. **Paint Floor**: Create beat-reactive patterns
4. **Place Props**: Add visual elements
5. **Add Hazards**: Position and configure
6. **Set Spawns**: Player and enemy locations
7. **Configure Waves**: Enemy composition
8. **Test Play**: Immediate playtest
9. **Save/Share**: Export level file

### Level Validation

Editor validates levels before saving:

```gdscript
func validate_level(level: ArenaDefinition) -> ValidationResult:
    var result := ValidationResult.new()

    # Required checks
    if not level.spawn_points or level.spawn_points.is_empty():
        result.add_error("No player spawn point")

    if level.enemy_spawn_zones.is_empty():
        result.add_error("No enemy spawn zones")

    # Balance checks
    var hazard_density := _calculate_hazard_density(level)
    if hazard_density > MAX_HAZARD_DENSITY:
        result.add_warning("High hazard density may be frustrating")

    return result
```

---

## Dynamic Level Elements

### Moving Platforms

```gdscript
class_name MovingPlatform
extends AnimatableBody3D

@export var path: Path3D
@export var speed: float = 2.0
@export var sync_to_beat: bool = true
@export var move_on_quant: Quant.Type = Quant.Type.KICK

var _path_follow: PathFollow3D
var _target_progress: float = 0.0

func _on_tick(event: SequencerEvent) -> void:
    if sync_to_beat and event.quant.type == move_on_quant:
        _advance_to_next_point()

func _advance_to_next_point() -> void:
    _target_progress += 0.25  # Move 25% along path
    if _target_progress > 1.0:
        _target_progress = 0.0
```

### Destructible Elements

```gdscript
class_name DestructibleProp
extends Node3D

@export var health: float = 100.0
@export var destroyed_scene: PackedScene
@export var drop_items: Array[PackedScene]
@export var score_value: int = 50

signal destroyed()

func take_damage(amount: float) -> void:
    health -= amount
    if health <= 0:
        _on_destroyed()

func _on_destroyed() -> void:
    destroyed.emit()
    _spawn_drops()
    _play_destruction_effect()
    queue_free()
```

---

## Level Progression

### World Structure

```
World 1: Neon City
├── Level 1-1: Tutorial
├── Level 1-2: Basic Combat
├── Level 1-3: Hazard Introduction
├── Level 1-4: Wave Challenge
├── Level 1-5: Mini-boss
└── Level 1-B: Boss - DJ Destructor

World 2: Digital Void
├── Level 2-1: New Mechanics
...
```

### Difficulty Scaling

```gdscript
class_name DifficultyScaler
extends Node

func scale_level(level: ArenaDefinition, difficulty: float) -> void:
    # Scale enemy stats
    for wave in level.waves:
        for spawn in wave.enemies:
            spawn.health_multiplier = 1.0 + (difficulty * 0.5)
            spawn.damage_multiplier = 1.0 + (difficulty * 0.3)
            spawn.speed_multiplier = 1.0 + (difficulty * 0.2)

    # Scale hazards
    for hazard in level.hazards:
        hazard.warning_beats *= (1.0 - difficulty * 0.3)  # Less warning time
        hazard.damage *= (1.0 + difficulty * 0.5)
```

---

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Theme System | Partial | Basic themes exist |
| Beat Floor | Implemented | LightingFloor working |
| Hazard System | Partial | Basic hazards done |
| Level Editor | Planned | Complex feature |
| Wave System | Implemented | Basic functionality |
| Moving Platforms | Planned | Path system needed |
| Destructibles | Planned | Health system ready |

See `docs/plans/04_LEVEL_DESIGN.md` for detailed implementation roadmap.
