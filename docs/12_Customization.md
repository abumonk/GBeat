# Character Customization

This document describes the character customization system for BeatBeat, enabling players to create unique avatars.

## Overview

The customization system provides:
- **Body Customization**: Physical proportions and features
- **Clothing System**: Layered outfit components
- **Material System**: Colors, patterns, and effects
- **Accessories**: Additional visual elements

---

## Body Customization

### Body Sliders

Morphable parameters that adjust character proportions:

```gdscript
class_name BodyCustomization
extends Resource

## Overall proportions
@export_range(0.8, 1.2) var height: float = 1.0
@export_range(0.8, 1.2) var body_width: float = 1.0
@export_range(0.8, 1.2) var body_depth: float = 1.0

## Head
@export_range(0.8, 1.2) var head_size: float = 1.0
@export_range(0.9, 1.1) var head_width: float = 1.0

## Torso
@export_range(0.8, 1.2) var shoulder_width: float = 1.0
@export_range(0.8, 1.2) var chest_size: float = 1.0
@export_range(0.8, 1.2) var waist_size: float = 1.0
@export_range(0.8, 1.2) var hip_width: float = 1.0

## Limbs
@export_range(0.8, 1.2) var arm_length: float = 1.0
@export_range(0.8, 1.2) var arm_thickness: float = 1.0
@export_range(0.8, 1.2) var leg_length: float = 1.0
@export_range(0.8, 1.2) var leg_thickness: float = 1.0

## Hands and feet
@export_range(0.8, 1.2) var hand_size: float = 1.0
@export_range(0.8, 1.2) var foot_size: float = 1.0
```

### Blend Shape System

Body customization uses blend shapes (morph targets) for smooth deformation:

```gdscript
class_name BodyMorphController
extends Node3D

@export var mesh_instance: MeshInstance3D
@export var customization: BodyCustomization

# Blend shape indices
const BLEND_HEIGHT := "height"
const BLEND_SHOULDER := "shoulder_width"
const BLEND_CHEST := "chest_size"
# ... etc

func apply_customization() -> void:
    if not mesh_instance or not customization:
        return

    # Apply each slider to corresponding blend shape
    _set_blend(BLEND_HEIGHT, customization.height - 1.0)
    _set_blend(BLEND_SHOULDER, customization.shoulder_width - 1.0)
    _set_blend(BLEND_CHEST, customization.chest_size - 1.0)
    # ... apply all sliders

func _set_blend(name: String, value: float) -> void:
    var idx := mesh_instance.find_blend_shape_by_name(name)
    if idx >= 0:
        mesh_instance.set_blend_shape_value(idx, value)
```

### Presets

Quick-start body presets:

| Preset | Description |
|--------|-------------|
| Default | Balanced proportions |
| Athletic | Broader shoulders, longer limbs |
| Compact | Shorter, wider build |
| Slender | Taller, thinner proportions |
| Heroic | Exaggerated heroic proportions |

---

## Clothing System

### Clothing Slots

Characters have multiple attachment points for clothing:

```gdscript
enum ClothingSlot {
    HEAD,           # Hats, helmets, hair
    FACE,           # Masks, glasses
    UPPER_BODY,     # Shirts, jackets
    LOWER_BODY,     # Pants, skirts
    HANDS,          # Gloves
    FEET,           # Shoes, boots
    BACK,           # Capes, backpacks
    FULL_BODY,      # Full suits (overrides upper/lower)
}
```

### Clothing Definition

```gdscript
class_name ClothingItem
extends Resource

@export var item_id: String
@export var display_name: String
@export var slot: ClothingSlot
@export var mesh: Mesh
@export var skeleton_path: NodePath
@export var material_slots: Array[String]  # Customizable material zones
@export var hide_body_parts: Array[String]  # Body parts to hide
@export var incompatible_slots: Array[ClothingSlot]  # Mutual exclusions
@export var unlock_requirement: String  # How to unlock
```

### Layering System

Clothing layers in a specific order to handle overlap:

```
Layer Order (bottom to top):
1. Body mesh (base)
2. Underwear/base layer
3. Lower body (pants/skirt)
4. Upper body (shirt)
5. Outer layer (jacket)
6. Accessories (belt, jewelry)
7. Head/face items
8. Back items
```

### Physics-Enabled Clothing

Some clothing items have physics simulation:

```gdscript
class_name ClothPhysics
extends Node3D

@export var cloth_mesh: MeshInstance3D
@export var softbody: SoftBody3D
@export var bone_attachments: Array[BoneAttachment3D]

## Physics properties
@export var stiffness: float = 0.5
@export var damping: float = 0.1
@export var wind_influence: float = 0.3
```

---

## Material System

### Material Zones

Each clothing item can have multiple customizable zones:

```gdscript
class_name MaterialZone
extends Resource

@export var zone_name: String  # e.g., "Primary", "Accent", "Trim"
@export var default_color: Color
@export var accepts_patterns: bool = true
@export var accepts_emission: bool = false
```

### Material Properties

```gdscript
class_name CustomMaterial
extends Resource

@export var base_color: Color = Color.WHITE
@export var pattern: Texture2D  # Optional pattern overlay
@export var pattern_scale: float = 1.0
@export var pattern_color: Color = Color.BLACK

@export_range(0.0, 1.0) var metallic: float = 0.0
@export_range(0.0, 1.0) var roughness: float = 0.5
@export_range(0.0, 1.0) var emission_strength: float = 0.0
@export var emission_color: Color = Color.WHITE
```

### Pattern Library

Built-in patterns for customization:

| Pattern Type | Examples |
|--------------|----------|
| Solid | Single color |
| Stripes | Horizontal, vertical, diagonal |
| Geometric | Checkers, triangles, hexagons |
| Organic | Camo, marble, wood grain |
| Tech | Circuit, grid, scan lines |
| Special | Holographic, animated, reactive |

### Beat-Reactive Materials

Special materials that respond to music:

```gdscript
class_name BeatReactiveMaterial
extends CustomMaterial

@export var pulse_on_beat: bool = true
@export var pulse_intensity: float = 0.5
@export var pulse_property: String = "emission_strength"
@export var react_to_quant: Quant.Type = Quant.Type.KICK

func _on_tick(event: SequencerEvent) -> void:
    if event.quant.type == react_to_quant:
        _pulse()

func _pulse() -> void:
    # Animate the reactive property
    var tween := create_tween()
    tween.tween_property(self, pulse_property,
        get(pulse_property) + pulse_intensity, 0.05)
    tween.tween_property(self, pulse_property,
        get(pulse_property), 0.2)
```

---

## Accessories

### Accessory Types

```gdscript
enum AccessoryType {
    JEWELRY,        # Earrings, necklaces, rings
    EYEWEAR,        # Glasses, visors, goggles
    HEADWEAR,       # Hats, headbands, horns
    ATTACHMENTS,    # Wings, tails, floating orbs
    EFFECTS,        # Auras, particles, trails
}
```

### Accessory Definition

```gdscript
class_name AccessoryItem
extends Resource

@export var item_id: String
@export var display_name: String
@export var accessory_type: AccessoryType
@export var attachment_bone: String
@export var offset: Vector3
@export var rotation: Vector3
@export var scale: Vector3 = Vector3.ONE
@export var mesh: Mesh
@export var particles: PackedScene  # Optional particle effect
@export var material_zones: Array[MaterialZone]
```

### Effect Accessories

Non-physical visual enhancements:

```gdscript
class_name EffectAccessory
extends AccessoryItem

@export var particle_scene: PackedScene
@export var trail_material: Material
@export var aura_shader: Shader
@export var animate_with_movement: bool = true
@export var beat_reactive: bool = true
```

---

## Customization UI

### Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│ CHARACTER CUSTOMIZATION                    [Save] [Load]    │
├─────────────────────────────────────────────────────────────┤
│ ┌───────────────┐ ┌─────────────────────────────────────┐   │
│ │               │ │ [Body] [Clothing] [Materials] [Acc] │   │
│ │               │ ├─────────────────────────────────────┤   │
│ │   3D PREVIEW  │ │ BODY SLIDERS                        │   │
│ │               │ │ Height    ├────────●────────┤       │   │
│ │    ┌─────┐    │ │ Shoulders ├──────────●──────┤       │   │
│ │    │     │    │ │ Chest     ├────●────────────┤       │   │
│ │    │  T  │    │ │ Waist     ├──────●──────────┤       │   │
│ │    │ /│\ │    │ │ Hips      ├────────●────────┤       │   │
│ │    │  │  │    │ │ Arms      ├──────────●──────┤       │   │
│ │    │ / \ │    │ │ Legs      ├────────●────────┤       │   │
│ │    └─────┘    │ ├─────────────────────────────────────┤   │
│ │               │ │ PRESETS                             │   │
│ │ [◄] [Rotate] [►]│ │ [Default] [Athletic] [Compact]     │   │
│ └───────────────┘ └─────────────────────────────────────┘   │
├─────────────────────────────────────────────────────────────┤
│ [Randomize]  [Reset]  [Mirror]       Outfit: "My Style 1"   │
└─────────────────────────────────────────────────────────────┘
```

### Preview Features

- **360° Rotation**: Spin character view
- **Zoom**: Close-up details
- **Poses**: Preview in different stances
- **Animation**: See movement with current outfit
- **Lighting**: Different environment lighting
- **Beat Preview**: See beat-reactive effects

---

## Save System Integration

### Character Save Data

```gdscript
class_name CharacterAppearance
extends Resource

@export var body: BodyCustomization
@export var clothing: Dictionary  # ClothingSlot -> ClothingItem
@export var materials: Dictionary  # zone_id -> CustomMaterial
@export var accessories: Array[AccessoryItem]
@export var preset_name: String

func serialize() -> Dictionary:
    return {
        "body": body.serialize(),
        "clothing": _serialize_clothing(),
        "materials": _serialize_materials(),
        "accessories": _serialize_accessories(),
    }

static func deserialize(data: Dictionary) -> CharacterAppearance:
    var appearance := CharacterAppearance.new()
    appearance.body = BodyCustomization.deserialize(data.body)
    # ... restore other properties
    return appearance
```

### Outfit Presets

Players can save multiple outfit configurations:

```gdscript
class_name OutfitManager
extends Node

const MAX_OUTFITS := 10

var saved_outfits: Array[CharacterAppearance] = []
var current_outfit_index: int = 0

func save_outfit(name: String) -> void:
    var outfit := _capture_current_appearance()
    outfit.preset_name = name
    saved_outfits.append(outfit)

func load_outfit(index: int) -> void:
    if index < saved_outfits.size():
        _apply_appearance(saved_outfits[index])
        current_outfit_index = index

func quick_switch() -> void:
    current_outfit_index = (current_outfit_index + 1) % saved_outfits.size()
    _apply_appearance(saved_outfits[current_outfit_index])
```

---

## Unlock System

### Unlock Methods

| Method | Description |
|--------|-------------|
| Story Progress | Complete campaign levels |
| Achievements | Reach specific milestones |
| Style Points | Accumulate style score |
| Challenges | Complete special objectives |
| Secrets | Find hidden collectibles |

### Unlock Definition

```gdscript
class_name UnlockRequirement
extends Resource

enum UnlockType {
    LEVEL_COMPLETE,
    ACHIEVEMENT,
    STYLE_POINTS,
    CHALLENGE,
    COLLECTIBLE,
    COMBO_MILESTONE,
}

@export var unlock_type: UnlockType
@export var requirement_id: String  # Achievement ID, level name, etc.
@export var requirement_value: int  # For numeric requirements
@export var hint_text: String       # Shown when locked
```

---

## Implementation Status

| Feature | Status | Notes |
|---------|--------|-------|
| Body Sliders | Planned | Requires blend shapes in models |
| Clothing Slots | Planned | Basic structure defined |
| Material Zones | Planned | Shader work needed |
| Beat-Reactive | Planned | Integrate with Sequencer |
| Accessories | Planned | Attachment system needed |
| UI | Planned | 3D preview viewport |
| Save/Load | Partial | Save system exists |
| Unlocks | Partial | Achievement system needed |

See `docs/plans/03_CHARACTER_CUSTOMIZATION.md` for detailed implementation roadmap.
