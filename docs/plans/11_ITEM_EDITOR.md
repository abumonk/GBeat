# In-Game Item Editor

## Overview
A visual editor for creating and customizing character items (clothing, accessories, weapons) using simple geometric shapes and colors.

## Core Components

### 1. Editor Layout
```
┌──────────────────────────────────────────────────────────────────────────┐
│ [New] [Load] [Save] [Category: Hat ▼] [Slot: Head ▼]                     │
├────────────────────┬─────────────────────────────────┬───────────────────┤
│   Shape Library    │         3D Preview              │    Properties     │
│                    │                                 │                   │
│ ┌──┐ ┌──┐ ┌──┐    │         ┌─────────┐            │ Name: [TopHat   ] │
│ │▢ │ │◯ │ │△ │    │         │  ████   │            │ Slot: [Head     ] │
│ └──┘ └──┘ └──┘    │         │ ██████  │            │ Color: [■ Black ] │
│ ┌──┐ ┌──┐ ┌──┐    │         │████████ │            │                   │
│ │▭ │ │◇ │ │⬡ │    │         │████████ │            │ Size:             │
│ └──┘ └──┘ └──┘    │         └─────────┘            │ X: [1.0] Y: [2.0] │
│                    │                                 │ Z: [1.0]         │
│ ──────────────     │    [◄] [▶] Rotate              │                   │
│ Recent Items:      │                                 │ Offset:          │
│ • Cap              │                                 │ X: [0.0] Y: [0.2]│
│ • Sword            │                                 │ Z: [0.0]         │
│ • Glasses          │                                 │                   │
├────────────────────┼─────────────────────────────────┼───────────────────┤
│   Part List        │      Character Preview          │   Material        │
│                    │                                 │                   │
│ [+] Add Part       │            O                    │ Category:         │
│                    │           /|\                   │ [HAT        ▼]   │
│ ▸ Brim (Cylinder)  │           / \                   │                   │
│ ▸ Crown (Box)      │                                 │ Color: [■■■■■■]  │
│                    │      [Wear Preview]             │ Metallic: [0.0]  │
│                    │                                 │ Roughness: [0.8] │
└────────────────────┴─────────────────────────────────┴───────────────────┘
```

### 2. File Structure
```
ui/
  editors/
    item_editor/
      item_editor.gd           # Main editor controller
      item_editor.tscn         # Scene layout
      shape_library.gd         # Available primitive shapes
      item_preview_3d.gd       # 3D viewport for item
      character_preview.gd     # Character wearing item
      part_list.gd             # Hierarchical part list
      item_part.gd             # Single item component
      properties_panel.gd      # Property inspector
      material_panel.gd        # Material/color settings
```

### 3. Core Classes

#### ItemEditor
```gdscript
class_name ItemEditor extends Control

var current_item: ItemDefinition
var selected_part: ItemPart
var preview_character: HumanoidCharacter

func new_item(slot: HumanoidTypes.ClothingSlot) -> void
func load_item(path: String) -> void
func save_item(path: String) -> void
func add_part(shape: ShapeType) -> ItemPart
func remove_part(part: ItemPart) -> void
func duplicate_part(part: ItemPart) -> ItemPart
func update_preview() -> void
```

#### ItemDefinition
```gdscript
class_name ItemDefinition extends Resource

@export var name: String
@export var slot: HumanoidTypes.ClothingSlot
@export var color_category: HumanoidTypes.ColorCategory
@export var parts: Array[ItemPartData]
@export var attachment_bone: String
@export var offset: Vector3
@export var rotation: Vector3
@export var scale: Vector3 = Vector3.ONE
```

#### ItemPartData
```gdscript
class_name ItemPartData extends Resource

enum ShapeType {
    BOX,
    SPHERE,
    CYLINDER,
    CAPSULE,
    CONE,
    PRISM,
    TORUS,
}

@export var shape: ShapeType
@export var size: Vector3 = Vector3.ONE
@export var position: Vector3
@export var rotation: Vector3
@export var color_override: Color = Color.WHITE
@export var use_category_color: bool = true
```

#### ShapeLibrary
```gdscript
class_name ShapeLibrary extends Control

signal shape_selected(shape: ItemPartData.ShapeType)

const SHAPES = {
    ItemPartData.ShapeType.BOX: "Box",
    ItemPartData.ShapeType.SPHERE: "Sphere",
    ItemPartData.ShapeType.CYLINDER: "Cylinder",
    ItemPartData.ShapeType.CAPSULE: "Capsule",
    ItemPartData.ShapeType.CONE: "Cone",
    ItemPartData.ShapeType.PRISM: "Prism (Triangle)",
    ItemPartData.ShapeType.TORUS: "Torus (Ring)",
}

func _create_shape_buttons() -> void
func _on_shape_clicked(shape: ItemPartData.ShapeType) -> void
```

### 4. Item Categories

#### Clothing Slots
```gdscript
enum ClothingSlot {
    HEAD,        # Hats, helmets, hair accessories
    FACE,        # Glasses, masks, face paint
    TORSO,       # Shirts, jackets, armor
    LEGS,        # Pants, skirts, leg armor
    FEET,        # Shoes, boots
    HAND_L,      # Left hand items, gloves
    HAND_R,      # Right hand items, weapons
    BACK,        # Backpacks, capes, wings
    NECK,        # Necklaces, scarves
    WAIST,       # Belts, holsters
}
```

#### Preset Templates
```gdscript
const TEMPLATES = {
    "cap": {
        "slot": ClothingSlot.HEAD,
        "parts": [
            {"shape": "cylinder", "size": Vector3(0.5, 0.1, 0.5)},  # Brim
            {"shape": "sphere", "size": Vector3(0.4, 0.3, 0.4), "position": Vector3(0, 0.15, 0)},  # Crown
        ]
    },
    "sword": {
        "slot": ClothingSlot.HAND_R,
        "parts": [
            {"shape": "box", "size": Vector3(0.05, 0.8, 0.02)},  # Blade
            {"shape": "box", "size": Vector3(0.15, 0.05, 0.05), "position": Vector3(0, -0.4, 0)},  # Guard
            {"shape": "cylinder", "size": Vector3(0.03, 0.15, 0.03), "position": Vector3(0, -0.5, 0)},  # Handle
        ]
    },
}
```

### 5. Features

#### Shape Manipulation
- Click to select part
- Drag handles to resize
- Rotation gizmo (X/Y/Z axes)
- Position with arrow keys or drag
- Snap to grid option

#### Part Hierarchy
- Parent-child relationships
- Group multiple parts
- Copy/Paste parts
- Mirror parts (left/right)

#### Color System
- Use category color (inherits from palette)
- Override with custom color
- Per-part color options
- Preview with different palettes

#### Preview Modes
- Item only (isolated)
- On character (equipped)
- Rotating turntable
- Multiple angles

### 6. Data Format

#### Item Resource (.tres)
```gdscript
[gd_resource type="Resource" script_class="ItemDefinition"]

[resource]
name = "Cowboy Hat"
slot = 0  # HEAD
color_category = 6  # HAT
parts = [
    {
        "shape": 2,  # CYLINDER
        "size": Vector3(0.6, 0.05, 0.6),
        "position": Vector3(0, 0, 0),
        "use_category_color": true
    },
    {
        "shape": 2,  # CYLINDER
        "size": Vector3(0.35, 0.25, 0.35),
        "position": Vector3(0, 0.15, 0),
        "use_category_color": true
    }
]
attachment_bone = "Head"
offset = Vector3(0, 0.1, 0)
```

#### JSON Export
```json
{
    "name": "Cowboy Hat",
    "slot": "HEAD",
    "color_category": "HAT",
    "parts": [
        {
            "shape": "CYLINDER",
            "size": [0.6, 0.05, 0.6],
            "position": [0, 0, 0],
            "rotation": [0, 0, 0],
            "use_category_color": true
        },
        {
            "shape": "CYLINDER",
            "size": [0.35, 0.25, 0.35],
            "position": [0, 0.15, 0],
            "rotation": [0, 0, 0],
            "use_category_color": true
        }
    ],
    "attachment_bone": "Head",
    "offset": [0, 0.1, 0],
    "rotation": [0, 0, 0],
    "scale": [1, 1, 1]
}
```

### 7. Keyboard Shortcuts

| Key | Action |
|-----|--------|
| N | New item |
| Ctrl+S | Save |
| Ctrl+O | Open |
| Delete | Delete selected part |
| Ctrl+D | Duplicate part |
| G | Move mode |
| R | Rotate mode |
| S | Scale mode |
| X/Y/Z | Constrain to axis |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| F | Focus on selection |
| H | Hide/Show part |

### 8. Implementation Phases

#### Phase 1: Basic Editor
- Shape library with primitives
- Add/remove parts
- Basic transforms (position, rotation, scale)
- Save/Load item definitions

#### Phase 2: Visual Editing
- 3D preview with manipulation handles
- Character preview with item equipped
- Part hierarchy tree
- Color assignment

#### Phase 3: Advanced Features
- Templates and presets
- Part mirroring
- Snap and grid
- Undo/Redo

#### Phase 4: Polish
- Import/Export formats
- Item thumbnails
- Category browser
- Search and filter

### 9. Integration Points

- **HumanoidCharacter**: Equip items on character
- **HumanoidTypes**: Slot and color definitions
- **ColorPalette**: Apply palette colors to items
- **SaveManager**: Persist custom items
- **ResourceLoader**: Load item definitions

### 10. Mesh Generation

```gdscript
class ItemMeshGenerator:
    static func create_shape_mesh(part: ItemPartData) -> Mesh:
        var mesh: Mesh
        match part.shape:
            ItemPartData.ShapeType.BOX:
                mesh = BoxMesh.new()
                mesh.size = part.size
            ItemPartData.ShapeType.SPHERE:
                mesh = SphereMesh.new()
                mesh.radius = part.size.x / 2.0
                mesh.height = part.size.y
            ItemPartData.ShapeType.CYLINDER:
                mesh = CylinderMesh.new()
                mesh.top_radius = part.size.x / 2.0
                mesh.bottom_radius = part.size.z / 2.0
                mesh.height = part.size.y
            ItemPartData.ShapeType.CAPSULE:
                mesh = CapsuleMesh.new()
                mesh.radius = part.size.x / 2.0
                mesh.height = part.size.y
            ItemPartData.ShapeType.CONE:
                mesh = CylinderMesh.new()
                mesh.top_radius = 0.0
                mesh.bottom_radius = part.size.x / 2.0
                mesh.height = part.size.y
        return mesh
```

### 11. Testing Checklist

- [ ] All shape types render correctly
- [ ] Transforms apply accurately
- [ ] Items attach to correct bones
- [ ] Color categories work with palettes
- [ ] Save/Load preserves all data
- [ ] Items display on character preview
- [ ] Part hierarchy functions correctly
- [ ] Undo/Redo handles all operations
