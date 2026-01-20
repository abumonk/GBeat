# In-Game Editors

This document describes the design for BeatBeat's in-game creation tools. These editors enable players and designers to create custom content without external tools.

## Overview

BeatBeat includes four integrated editors:
1. **Pattern Editor** - Create beat patterns that drive gameplay
2. **Item Editor** - Design visual items from primitive shapes
3. **Animation Editor** - Build keyframe-based animations
4. **Color Palette Editor** - Define game-wide color schemes

All editors share common UI patterns and integrate with the game's existing systems.

---

## Pattern Editor

The Pattern Editor allows creation and modification of beat patterns that drive the Sequencer system.

### Core Features

#### Waveform Display
- Visual waveform rendering of the audio track
- Zoom controls for detailed editing
- Playhead showing current position
- Beat markers overlaid on waveform

#### Grid System
- Configurable grid divisions (1/4, 1/8, 1/16, 1/32 notes)
- Snap-to-grid for precise placement
- Visual measure/bar markers
- Time signature support (4/4, 3/4, etc.)

#### Quant Placement
- Drag-and-drop quant types onto the timeline
- Multiple lanes for different quant types:
  - **Drum Lane**: KICK, SNARE, HAT
  - **Movement Lane**: MOVE_FORWARD_SPEED, MOVE_RIGHT_SPEED, ROTATION_SPEED
  - **Action Lane**: ANIMATION, custom events
- Value adjustment (0.0-1.0 intensity) via vertical position or slider

#### Audio Integration
- Import audio files (OGG, WAV, MP3)
- BPM detection with manual override
- Loop region selection
- Preview playback with metronome option

### Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [File] [Edit] [View]    Pattern: "Boss Theme"    BPM: 140  │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                    WAVEFORM DISPLAY                      │ │
│ │  ▁▂▃▄▅▆▇█▇▆▅▄▃▂▁▂▃▄▅▆▇█▇▆▅▄▃▂▁▂▃▄▅▆▇█▇▆▅▄▃▂▁          │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ KICK    │ ● │   │ ● │   │ ● │   │ ● │   │ ● │   │ ● │  │ │
│ │ SNARE   │   │   │ ● │   │   │   │ ● │   │   │   │ ● │  │ │
│ │ HAT     │ ● │ ● │ ● │ ● │ ● │ ● │ ● │ ● │ ● │ ● │ ● │  │ │
│ │ MOVE_F  │ ● │   │   │   │ ● │   │   │   │ ● │   │   │  │ │
│ │ ANIM    │   │   │ ● │   │   │   │ ● │   │   │   │ ● │  │ │
│ └─────────────────────────────────────────────────────────┘ │
│ ◄─────────────────────[▶]─────────────────────────────────► │
│                                                             │
│ [Quant Palette]  [Properties]  [Preview]  [Export]          │
└─────────────────────────────────────────────────────────────┘
```

### Data Format

Patterns are saved as Godot Resources (`.tres`):

```gdscript
# Pattern resource structure
class_name Pattern
extends Resource

@export var pattern_name: String
@export var bpm: float = 120.0
@export var time_signature_numerator: int = 4
@export var time_signature_denominator: int = 4
@export var audio_stream: AudioStream
@export var quants: Array[Quant] = []
@export var loop_start_beat: int = 0
@export var loop_end_beat: int = -1  # -1 = end of audio
```

### Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Play/Pause |
| 1-5 | Select quant type |
| Delete | Remove selected quant |
| Ctrl+Z | Undo |
| Ctrl+S | Save pattern |
| +/- | Zoom in/out |
| G | Toggle grid snap |

---

## Item Editor

The Item Editor enables creation of visual items using primitive shapes, inspired by games like Lethal Company.

### Primitive Shapes

#### Basic Primitives
- **Box**: Width, height, depth
- **Sphere**: Radius, segments
- **Cylinder**: Radius, height, segments
- **Cone**: Radius, height, segments
- **Capsule**: Radius, height
- **Torus**: Major radius, minor radius

#### Advanced Primitives
- **Prism**: Triangular base
- **Pyramid**: Square base
- **Wedge**: Sloped block

### Transformation Tools

- **Move**: Translate in X, Y, Z
- **Rotate**: Euler rotation with gizmo
- **Scale**: Uniform and non-uniform scaling
- **Mirror**: Flip across axis
- **Duplicate**: Copy selected primitives

### Material System

Each primitive can have:
- **Color**: Base color from palette
- **Metallic**: 0.0 - 1.0
- **Roughness**: 0.0 - 1.0
- **Emission**: Glow intensity and color

### Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [File] [Edit]          Item: "Cool Sword"                   │
├──────────────┬──────────────────────────────┬───────────────┤
│ PRIMITIVES   │                              │ PROPERTIES    │
│ ┌──────────┐ │                              │ ┌───────────┐ │
│ │ □ Box    │ │      3D VIEWPORT             │ │ Position  │ │
│ │ ○ Sphere │ │                              │ │ X: 0.0    │ │
│ │ ⬡ Cylinder│ │         ┌───┐               │ │ Y: 0.5    │ │
│ │ △ Cone   │ │         │   │               │ │ Z: 0.0    │ │
│ │ ⬭ Capsule│ │         │   │               │ ├───────────┤ │
│ └──────────┘ │         └───┘               │ │ Scale     │ │
│              │                              │ │ X: 1.0    │ │
│ HIERARCHY    │                              │ │ Y: 3.0    │ │
│ ┌──────────┐ │                              │ │ Z: 0.2    │ │
│ │ ▼ Root   │ │                              │ ├───────────┤ │
│ │  ├ Blade │ │                              │ │ Material  │ │
│ │  ├ Guard │ │                              │ │ Color: ■  │ │
│ │  └ Handle│ │                              │ │ Metal: 0.8│ │
│ └──────────┘ │                              │ └───────────┘ │
├──────────────┴──────────────────────────────┴───────────────┤
│ [Move] [Rotate] [Scale]    Grid: 0.25    Snap: ON           │
└─────────────────────────────────────────────────────────────┘
```

### Data Format

Items are saved as scenes with metadata:

```gdscript
# ItemDefinition resource
class_name ItemDefinition
extends Resource

@export var item_name: String
@export var item_type: ItemType
@export var primitives: Array[PrimitiveData]
@export var collision_shapes: Array[Shape3D]
@export var held_offset: Vector3
@export var held_rotation: Vector3
```

### Primitive Data Structure

```gdscript
class_name PrimitiveData
extends Resource

@export var shape_type: ShapeType
@export var transform: Transform3D
@export var size: Vector3
@export var material: StandardMaterial3D
@export var parent_index: int = -1  # For hierarchy
```

---

## Animation Editor

The Animation Editor provides keyframe-based animation creation for items and characters.

### Keyframe System

#### Supported Properties
- **Transform**: Position, rotation, scale
- **Material**: Color, emission, opacity
- **Custom**: Any exported property

#### Interpolation Types
- **Linear**: Constant rate
- **Ease In**: Slow start
- **Ease Out**: Slow end
- **Ease In-Out**: Slow start and end
- **Cubic**: Smooth bezier
- **Bounce**: Bouncy effect
- **Elastic**: Spring-like

### Timeline Features

- **Multi-track editing**: Multiple properties simultaneously
- **Onion skinning**: See previous/next frames
- **Loop preview**: Test looping animations
- **Beat markers**: Align keyframes to beat grid

### Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [File] [Edit]      Animation: "Sword Swing"    FPS: 30     │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────┐ │
│ │                   3D PREVIEW                             │ │
│ │                      ╱──╲                                │ │
│ │                     ╱    ╲                               │ │
│ │                    ●──────                               │ │
│ └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│ TRACKS          │ 0   │ 10  │ 20  │ 30  │ 40  │ 50  │ 60  │ │
│ ├─ Position.X   │ ◆───────────◆                       │     │
│ ├─ Position.Y   │ ◆───────◆───────◆                   │     │
│ ├─ Rotation.Z   │ ◆───────────────────────◆           │     │
│ └─ Scale        │ ◆   │     │     │     │     │     │ │     │
├─────────────────────────────────────────────────────────────┤
│ Frame: 15/60   [◄◄] [◄] [▶] [►►]   [🔁 Loop]  [🔊 Sound]   │
└─────────────────────────────────────────────────────────────┘
```

### Data Format

```gdscript
# AnimationData resource for editor-created animations
class_name EditorAnimation
extends Resource

@export var animation_name: String
@export var duration_frames: int
@export var fps: float = 30.0
@export var tracks: Array[AnimationTrack]
@export var loop_mode: Animation.LoopMode
@export var sync_to_beat: bool = false
@export var beat_alignment: int = 0  # Which beat to align to
```

### Track Structure

```gdscript
class_name AnimationTrack
extends Resource

@export var target_path: NodePath
@export var property_name: String
@export var keyframes: Array[Keyframe]
@export var interpolation: Tween.TransitionType
@export var easing: Tween.EaseType
```

---

## Color Palette Editor

The Color Palette Editor defines game-wide color schemes that affect all visual elements.

### Palette Structure

Each palette contains named color roles:

#### UI Colors
- `ui_primary`: Main UI accent
- `ui_secondary`: Secondary UI elements
- `ui_background`: Panel backgrounds
- `ui_text`: Text color
- `ui_text_dim`: Dimmed text

#### Gameplay Colors
- `player_primary`: Player character main color
- `player_secondary`: Player accent color
- `enemy_primary`: Enemy main color
- `enemy_warning`: Danger indication
- `hit_flash`: Damage feedback

#### Environment Colors
- `floor_base`: Default floor color
- `floor_beat`: Beat-reactive floor highlight
- `ambient_light`: Scene ambient color
- `fog_color`: Distance fog

### Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ [File] [Edit]        Palette: "Neon Cyber"                  │
├─────────────────────────────────────────────────────────────┤
│ ┌───────────────────┐  ┌─────────────────────────────────┐  │
│ │ UI COLORS         │  │        COLOR PICKER             │  │
│ │ ■ primary   #FF00FF│  │  ┌─────────────────────────┐   │  │
│ │ ■ secondary #00FFFF│  │  │                         │   │  │
│ │ ■ background#1A1A2E│  │  │      [Color Wheel]      │   │  │
│ │ ■ text      #FFFFFF│  │  │                         │   │  │
│ ├───────────────────┤  │  └─────────────────────────┘   │  │
│ │ GAMEPLAY          │  │  H: 300  S: 100  V: 100        │  │
│ │ ■ player    #00FF88│  │  R: 255  G: 0    B: 255        │  │
│ │ ■ enemy     #FF4444│  │  #FF00FF                       │  │
│ │ ■ warning   #FFAA00│  └─────────────────────────────────┘  │
│ ├───────────────────┤                                        │
│ │ ENVIRONMENT       │  ┌─────────────────────────────────┐  │
│ │ ■ floor     #2A2A4A│  │         LIVE PREVIEW           │  │
│ │ ■ beat      #8800FF│  │    ┌───────────────────┐       │  │
│ │ ■ ambient   #4A4A6A│  │    │   [Game Scene]    │       │  │
│ └───────────────────┘  │    └───────────────────┘       │  │
│                        └─────────────────────────────────┘  │
├─────────────────────────────────────────────────────────────┤
│ [Generate Harmony]  [Import Image]  [Export]  [Apply]       │
└─────────────────────────────────────────────────────────────┘
```

### Color Harmony Generation

The editor can auto-generate harmonious colors:
- **Complementary**: Opposite on color wheel
- **Analogous**: Adjacent colors
- **Triadic**: Three evenly spaced
- **Split-Complementary**: Base + two adjacent to complement
- **Tetradic**: Four colors forming rectangle

### Data Format

```gdscript
class_name ColorPaletteDefinition
extends Resource

@export var palette_name: String

## UI Colors
@export_group("UI")
@export var ui_primary: Color = Color.MAGENTA
@export var ui_secondary: Color = Color.CYAN
@export var ui_background: Color = Color(0.1, 0.1, 0.18)
@export var ui_text: Color = Color.WHITE
@export var ui_text_dim: Color = Color(0.7, 0.7, 0.7)

## Gameplay Colors
@export_group("Gameplay")
@export var player_primary: Color = Color(0, 1, 0.53)
@export var player_secondary: Color = Color.WHITE
@export var enemy_primary: Color = Color(1, 0.27, 0.27)
@export var enemy_warning: Color = Color(1, 0.67, 0)
@export var hit_flash: Color = Color.WHITE

## Environment Colors
@export_group("Environment")
@export var floor_base: Color = Color(0.16, 0.16, 0.29)
@export var floor_beat: Color = Color(0.53, 0, 1)
@export var ambient_light: Color = Color(0.29, 0.29, 0.42)
@export var fog_color: Color = Color(0.1, 0.1, 0.2)
```

### Runtime Application

```gdscript
# PaletteManager autoload
class_name PaletteManager
extends Node

signal palette_changed(palette: ColorPaletteDefinition)

var current_palette: ColorPaletteDefinition

func apply_palette(palette: ColorPaletteDefinition) -> void:
    current_palette = palette
    palette_changed.emit(palette)
    _update_all_materials()
    _update_ui_theme()

func get_color(role: String) -> Color:
    return current_palette.get(role)
```

---

## Shared Editor Features

### Undo/Redo System

All editors share a common undo/redo stack:

```gdscript
class_name EditorHistory
extends RefCounted

var _undo_stack: Array[EditorAction] = []
var _redo_stack: Array[EditorAction] = []

func execute(action: EditorAction) -> void:
    action.execute()
    _undo_stack.push_back(action)
    _redo_stack.clear()

func undo() -> void:
    if _undo_stack.is_empty():
        return
    var action := _undo_stack.pop_back()
    action.undo()
    _redo_stack.push_back(action)

func redo() -> void:
    if _redo_stack.is_empty():
        return
    var action := _redo_stack.pop_back()
    action.execute()
    _undo_stack.push_back(action)
```

### Save/Load System

Editors save to user-accessible directories:

```
user://
├── patterns/
│   └── *.tres
├── items/
│   └── *.tres
├── animations/
│   └── *.tres
└── palettes/
    └── *.tres
```

### Export Formats

- **Pattern**: `.tres` (Godot resource) or `.json` for sharing
- **Item**: `.tres` with embedded meshes or `.glb` for external use
- **Animation**: `.tres` or convert to standard Godot Animation
- **Palette**: `.tres` or `.json` for import/export

---

## Implementation Status

| Editor | Status | Notes |
|--------|--------|-------|
| Pattern Editor | Planned | Core Pattern resource exists |
| Item Editor | Planned | Primitive system needed |
| Animation Editor | Planned | Build on Godot's animation system |
| Color Palette Editor | Planned | ColorPaletteDefinition resource exists |

See `docs/plans/` for detailed implementation roadmaps.
