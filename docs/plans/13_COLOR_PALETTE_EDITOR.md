# In-Game Color Palette Editor

## Overview
A visual editor for creating and managing color palettes used throughout the game - for characters, scenes, patterns, UI, and effects.

## Core Components

### 1. Editor Layout
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [New] [Load] [Save] [Import] [Export]  Palette: [Neon Cyberpunk ▼]          │
├────────────────────────┬─────────────────────────────────────────────────────┤
│    Category Colors     │              Live Preview                           │
│                        │                                                     │
│ SKIN      [████████]  │         ┌─────────────────────────┐                │
│ HAIR      [████████]  │         │                         │                │
│ EYE       [████████]  │         │      Character          │                │
│ SHIRT     [████████]  │         │         O               │                │
│ PANTS     [████████]  │         │        /|\              │                │
│ SHOES     [████████]  │         │        / \              │                │
│ HAT       [████████]  │         │                         │                │
│ ACCESSORY [████████]  │         └─────────────────────────┘                │
│ WEAPON_1  [████████]  │                                                     │
│ WEAPON_2  [████████]  │         [Character] [Scene] [Pattern] [Effects]    │
├────────────────────────┼─────────────────────────────────────────────────────┤
│    Color Picker        │              Scene Colors                           │
│                        │                                                     │
│ ┌──────────────────┐  │  BACKGROUND   [████████]  Primary                  │
│ │ ░░░░▓▓▓▓████████ │  │  FLOOR_BASE   [████████]  Floor tiles              │
│ │ ░░░░▓▓▓▓████████ │  │  FLOOR_ACCENT [████████]  Active tiles             │
│ │ ░░░░▓▓▓▓████████ │  │  LIGHT_MAIN   [████████]  Main light               │
│ │ ░░░░▓▓▓▓████████ │  │  LIGHT_ACCENT [████████]  Beat reactive            │
│ └──────────────────┘  │  FOG          [████████]  Atmosphere               │
│                        │  UI_PRIMARY   [████████]  UI elements              │
│ H: [180]  S: [80]     │  UI_SECONDARY [████████]  UI accents               │
│ V: [100]  A: [255]    │                                                     │
│ #[00FFFF]             │                                                     │
├────────────────────────┴─────────────────────────────────────────────────────┤
│  Palette History: [■ ■ ■ ■ ■ ■ ■ ■ ■ ■]  [Generate Harmony] [Randomize]    │
└──────────────────────────────────────────────────────────────────────────────┘
```

### 2. File Structure
```
ui/
  editors/
    palette_editor/
      palette_editor.gd          # Main editor controller
      palette_editor.tscn        # Scene layout
      color_picker_panel.gd      # HSV/RGB color picker
      category_list.gd           # Color category assignments
      color_swatch.gd            # Clickable color display
      preview_character.gd       # Character with palette
      preview_scene.gd           # Scene with palette
      preview_pattern.gd         # Pattern visualization
      harmony_generator.gd       # Color harmony algorithms
      palette_history.gd         # Recent colors
```

### 3. Core Classes

#### PaletteEditor
```gdscript
class_name PaletteEditor extends Control

var current_palette: GamePalette
var selected_category: String
var preview_mode: PreviewMode

enum PreviewMode {
    CHARACTER,
    SCENE,
    PATTERN,
    EFFECTS,
    ALL,
}

func new_palette() -> void
func load_palette(path: String) -> void
func save_palette(path: String) -> void
func set_color(category: String, color: Color) -> void
func generate_harmony(base: Color, type: HarmonyType) -> void
func randomize_palette() -> void
func apply_to_preview() -> void
```

#### GamePalette
```gdscript
class_name GamePalette extends Resource

@export var name: String
@export var description: String

# Character colors
@export var skin: Color = Color(0.96, 0.80, 0.69)
@export var hair: Color = Color(0.2, 0.1, 0.05)
@export var eye: Color = Color(0.3, 0.5, 0.8)
@export var shirt: Color = Color(0.2, 0.4, 0.8)
@export var pants: Color = Color(0.15, 0.15, 0.2)
@export var shoes: Color = Color(0.1, 0.1, 0.1)
@export var hat: Color = Color(0.3, 0.2, 0.1)
@export var accessory: Color = Color(1.0, 0.8, 0.0)
@export var weapon_primary: Color = Color(0.7, 0.7, 0.75)
@export var weapon_secondary: Color = Color(0.4, 0.2, 0.1)

# Scene colors
@export var background: Color = Color(0.05, 0.05, 0.1)
@export var floor_base: Color = Color(0.1, 0.1, 0.15)
@export var floor_accent: Color = Color(0.0, 1.0, 1.0)
@export var light_main: Color = Color(1.0, 1.0, 1.0)
@export var light_accent: Color = Color(1.0, 0.0, 0.5)
@export var fog: Color = Color(0.1, 0.1, 0.2)

# UI colors
@export var ui_primary: Color = Color(0.9, 0.9, 0.95)
@export var ui_secondary: Color = Color(0.0, 0.8, 1.0)
@export var ui_accent: Color = Color(1.0, 0.3, 0.5)
@export var ui_background: Color = Color(0.1, 0.1, 0.15, 0.9)

# Pattern/beat colors
@export var beat_kick: Color = Color(1.0, 0.2, 0.2)
@export var beat_snare: Color = Color(0.2, 1.0, 0.2)
@export var beat_hat: Color = Color(0.2, 0.2, 1.0)
@export var beat_accent: Color = Color(1.0, 1.0, 0.2)

func get_color(category: String) -> Color:
    return get(category.to_lower())

func set_color(category: String, color: Color) -> void:
    set(category.to_lower(), color)

func get_all_categories() -> Array[String]:
    return [
        "skin", "hair", "eye", "shirt", "pants", "shoes",
        "hat", "accessory", "weapon_primary", "weapon_secondary",
        "background", "floor_base", "floor_accent",
        "light_main", "light_accent", "fog",
        "ui_primary", "ui_secondary", "ui_accent", "ui_background",
        "beat_kick", "beat_snare", "beat_hat", "beat_accent"
    ]
```

#### HarmonyGenerator
```gdscript
class_name HarmonyGenerator extends RefCounted

enum HarmonyType {
    COMPLEMENTARY,    # Opposite on wheel
    ANALOGOUS,        # Adjacent colors
    TRIADIC,          # Three evenly spaced
    SPLIT_COMPLEMENT, # Base + two adjacent to complement
    TETRADIC,         # Four evenly spaced
    MONOCHROMATIC,    # Variations of one hue
}

static func generate(base: Color, type: HarmonyType) -> Array[Color]:
    var colors: Array[Color] = [base]
    var h = base.h
    var s = base.s
    var v = base.v

    match type:
        HarmonyType.COMPLEMENTARY:
            colors.append(Color.from_hsv(fmod(h + 0.5, 1.0), s, v))
        HarmonyType.ANALOGOUS:
            colors.append(Color.from_hsv(fmod(h + 0.083, 1.0), s, v))
            colors.append(Color.from_hsv(fmod(h - 0.083 + 1.0, 1.0), s, v))
        HarmonyType.TRIADIC:
            colors.append(Color.from_hsv(fmod(h + 0.333, 1.0), s, v))
            colors.append(Color.from_hsv(fmod(h + 0.666, 1.0), s, v))
        HarmonyType.SPLIT_COMPLEMENT:
            colors.append(Color.from_hsv(fmod(h + 0.416, 1.0), s, v))
            colors.append(Color.from_hsv(fmod(h + 0.583, 1.0), s, v))
        HarmonyType.TETRADIC:
            colors.append(Color.from_hsv(fmod(h + 0.25, 1.0), s, v))
            colors.append(Color.from_hsv(fmod(h + 0.5, 1.0), s, v))
            colors.append(Color.from_hsv(fmod(h + 0.75, 1.0), s, v))
        HarmonyType.MONOCHROMATIC:
            colors.append(Color.from_hsv(h, s * 0.5, v))
            colors.append(Color.from_hsv(h, s, v * 0.7))
            colors.append(Color.from_hsv(h, s * 0.7, v * 0.5))

    return colors
```

### 4. Color Categories

#### Character Categories
```gdscript
const CHARACTER_CATEGORIES = {
    "SKIN": "Skin tone for body",
    "HAIR": "Hair color",
    "EYE": "Eye/iris color",
    "SHIRT": "Upper body clothing",
    "PANTS": "Lower body clothing",
    "SHOES": "Footwear",
    "HAT": "Head accessories",
    "ACCESSORY": "Jewelry, bags, etc.",
    "WEAPON_PRIMARY": "Main weapon color",
    "WEAPON_SECONDARY": "Weapon accents",
}
```

#### Scene Categories
```gdscript
const SCENE_CATEGORIES = {
    "BACKGROUND": "Sky/backdrop color",
    "FLOOR_BASE": "Default floor tile",
    "FLOOR_ACCENT": "Active/lit floor tile",
    "LIGHT_MAIN": "Primary light source",
    "LIGHT_ACCENT": "Reactive/beat light",
    "FOG": "Atmospheric fog",
}
```

#### UI Categories
```gdscript
const UI_CATEGORIES = {
    "UI_PRIMARY": "Main text/icons",
    "UI_SECONDARY": "Secondary elements",
    "UI_ACCENT": "Highlights/selected",
    "UI_BACKGROUND": "Panel backgrounds",
}
```

#### Pattern Categories
```gdscript
const PATTERN_CATEGORIES = {
    "BEAT_KICK": "Bass drum visualization",
    "BEAT_SNARE": "Snare visualization",
    "BEAT_HAT": "Hi-hat visualization",
    "BEAT_ACCENT": "Accent hits",
}
```

### 5. Features

#### Color Picker
- HSV color wheel
- RGB sliders
- Hex input field
- Alpha channel support
- Eyedropper tool
- Recent colors history

#### Harmony Generation
- Select base color
- Choose harmony type
- Auto-fill related categories
- Manual adjustment after

#### Palette Presets
```gdscript
const PRESET_PALETTES = {
    "neon_cyberpunk": {
        "shirt": Color(0.0, 1.0, 1.0),
        "floor_accent": Color(1.0, 0.0, 1.0),
        "light_accent": Color(0.0, 1.0, 0.5),
        "background": Color(0.05, 0.0, 0.1),
    },
    "sunset_warm": {
        "shirt": Color(1.0, 0.5, 0.2),
        "floor_accent": Color(1.0, 0.3, 0.1),
        "light_accent": Color(1.0, 0.8, 0.3),
        "background": Color(0.1, 0.05, 0.1),
    },
    "forest_natural": {
        "shirt": Color(0.2, 0.5, 0.2),
        "floor_accent": Color(0.4, 0.8, 0.3),
        "light_accent": Color(0.8, 1.0, 0.6),
        "background": Color(0.05, 0.1, 0.05),
    },
    "monochrome": {
        "shirt": Color(0.7, 0.7, 0.7),
        "floor_accent": Color(1.0, 1.0, 1.0),
        "light_accent": Color(0.9, 0.9, 0.9),
        "background": Color(0.1, 0.1, 0.1),
    },
}
```

#### Preview Modes
- **Character**: Humanoid with current palette
- **Scene**: Dance floor with lighting
- **Pattern**: Timeline with beat colors
- **Effects**: VFX with palette colors
- **All**: Split view of everything

### 6. Data Format

#### Palette Resource (.tres)
```gdscript
[gd_resource type="Resource" script_class="GamePalette"]

[resource]
name = "Neon Cyberpunk"
description = "High contrast neon colors for cyberpunk aesthetic"
skin = Color(0.96, 0.80, 0.69, 1)
hair = Color(0.0, 0.8, 1.0, 1)
eye = Color(1.0, 0.0, 0.5, 1)
shirt = Color(0.0, 1.0, 1.0, 1)
pants = Color(0.1, 0.1, 0.15, 1)
shoes = Color(0.05, 0.05, 0.1, 1)
hat = Color(1.0, 0.0, 1.0, 1)
background = Color(0.02, 0.0, 0.05, 1)
floor_base = Color(0.05, 0.05, 0.1, 1)
floor_accent = Color(1.0, 0.0, 1.0, 1)
light_main = Color(0.8, 0.8, 1.0, 1)
light_accent = Color(0.0, 1.0, 0.8, 1)
```

#### JSON Export
```json
{
    "name": "Neon Cyberpunk",
    "description": "High contrast neon colors for cyberpunk aesthetic",
    "character": {
        "skin": "#F5CDB0",
        "hair": "#00CCFF",
        "eye": "#FF0080",
        "shirt": "#00FFFF",
        "pants": "#1A1A26",
        "shoes": "#0D0D1A",
        "hat": "#FF00FF",
        "accessory": "#FFD700",
        "weapon_primary": "#B3B3BF",
        "weapon_secondary": "#663319"
    },
    "scene": {
        "background": "#05000D",
        "floor_base": "#0D0D1A",
        "floor_accent": "#FF00FF",
        "light_main": "#CCCCFF",
        "light_accent": "#00FFCC",
        "fog": "#1A1A33"
    },
    "ui": {
        "primary": "#E6E6F2",
        "secondary": "#00CCFF",
        "accent": "#FF4D80",
        "background": "#1A1A26E6"
    },
    "pattern": {
        "kick": "#FF3333",
        "snare": "#33FF33",
        "hat": "#3333FF",
        "accent": "#FFFF33"
    }
}
```

### 7. Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Ctrl+N | New palette |
| Ctrl+S | Save palette |
| Ctrl+O | Open palette |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| R | Randomize all |
| H | Generate harmony |
| E | Eyedropper mode |
| 1-4 | Switch preview mode |
| Tab | Next category |
| Shift+Tab | Previous category |
| C | Copy color |
| V | Paste color |

### 8. Implementation Phases

#### Phase 1: Basic Editor
- Color picker (HSV wheel + sliders)
- Category list with swatches
- Character preview
- Save/Load palettes

#### Phase 2: Enhanced Features
- Scene preview
- Pattern preview
- Harmony generator
- Preset palettes

#### Phase 3: Advanced Tools
- Eyedropper from preview
- Batch color operations
- Export to image
- Import from image

#### Phase 4: Polish
- Undo/Redo
- Color history
- Search and filter palettes
- Palette comparison view

### 9. Integration Points

- **HumanoidTypes.ColorCategory**: Character color mapping
- **HumanoidCharacter**: Apply palette to character
- **LightingFloor**: Apply scene colors
- **BeatLight**: Apply beat colors
- **UITheme**: Apply UI colors
- **PatternEditor**: Apply pattern colors
- **VFX System**: Apply effect colors

### 10. Automatic Palette Application

```gdscript
class PaletteManager:
    static var current_palette: GamePalette

    static func apply_to_scene(scene: Node) -> void:
        # Find all palette-aware nodes and apply colors
        for node in scene.get_tree().get_nodes_in_group("palette_target"):
            if node.has_method("apply_palette"):
                node.apply_palette(current_palette)

    static func apply_to_character(character: HumanoidCharacter) -> void:
        character.color_palette.skin = current_palette.skin
        character.color_palette.hair = current_palette.hair
        # ... etc
        character.refresh_colors()
```

### 11. Testing Checklist

- [ ] Color picker produces accurate colors
- [ ] All categories can be edited
- [ ] Palettes save and load correctly
- [ ] Harmony generation creates valid colors
- [ ] Character preview updates in real-time
- [ ] Scene preview reflects changes
- [ ] Pattern colors display correctly
- [ ] Export/Import preserves colors
- [ ] Undo/Redo works for all operations
- [ ] Eyedropper picks correct color
