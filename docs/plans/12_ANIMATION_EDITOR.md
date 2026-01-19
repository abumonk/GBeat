# In-Game Animation Editor

## Overview
A frame-based animation editor for creating movement and combat animations for humanoid characters. Uses keyframe interpolation with bone transforms.

## Core Components

### 1. Editor Layout
```
┌──────────────────────────────────────────────────────────────────────────────┐
│ [New] [Load] [Save] [Type: Movement ▼] [FPS: 30] [◄ Prev] [▶ Play] [Next ►] │
├───────────────────────┬──────────────────────────────────────────────────────┤
│                       │                    Timeline                           │
│    Character View     │  Frame: 0    5    10   15   20   25   30             │
│                       │  ├────┼────┼────┼────┼────┼────┼────┤               │
│          O            │                                                       │
│         /|\           │  Pelvis    ●─────────────────●─────────●             │
│         / \           │  Spine     ●───────●─────────●─────────●             │
│                       │  Head      ●───────●───────●───────────●             │
│    [Front] [Side]     │  Arm_L     ●─●─────────●───────────────●             │
│    [Top]  [Free]      │  Arm_R     ●─────●─────────●───────────●             │
│                       │  Leg_L     ●─────────●─────────────────●             │
│                       │  Leg_R     ●───────────────●───────────●             │
├───────────────────────┼──────────────────────────────────────────────────────┤
│   Animation List      │                 Keyframe Properties                   │
│                       │                                                       │
│ ▸ idle (60 frames)    │  Bone: [Left Arm       ▼]  Frame: [15]               │
│ ▸ walk (30 frames)    │                                                       │
│ ▸ run  (20 frames)    │  Position:  X [0.0]  Y [0.5]  Z [0.0]                │
│ ▸ punch (15 frames)   │  Rotation:  X [45°]  Y [0°]   Z [0°]                 │
│ ▸ kick  (20 frames)   │                                                       │
│                       │  Easing: [Ease In-Out ▼]   [Copy] [Paste] [Delete]   │
│ [+ New Animation]     │                                                       │
└───────────────────────┴──────────────────────────────────────────────────────┘
```

### 2. File Structure
```
ui/
  editors/
    animation_editor/
      animation_editor.gd        # Main editor controller
      animation_editor.tscn      # Scene layout
      character_viewport.gd      # 3D character preview
      timeline_panel.gd          # Frame timeline
      bone_track.gd              # Single bone animation track
      keyframe_marker.gd         # Keyframe on timeline
      bone_selector.gd           # Bone hierarchy picker
      properties_panel.gd        # Keyframe properties
      animation_list.gd          # Saved animations list
      playback_controls.gd       # Play/pause/scrub
```

### 3. Core Classes

#### AnimationEditor
```gdscript
class_name AnimationEditor extends Control

var current_animation: CharacterAnimation
var preview_character: HumanoidCharacter
var selected_bone: String
var current_frame: int
var is_playing: bool

func new_animation(type: AnimationType) -> void
func load_animation(path: String) -> void
func save_animation(path: String) -> void
func set_keyframe(bone: String, frame: int, transform: Transform3D) -> void
func delete_keyframe(bone: String, frame: int) -> void
func copy_keyframe(bone: String, frame: int) -> void
func paste_keyframe(bone: String, frame: int) -> void
func play() -> void
func pause() -> void
func seek(frame: int) -> void
```

#### CharacterAnimation
```gdscript
class_name CharacterAnimation extends Resource

enum AnimationType {
    MOVEMENT,  # Walk, run, jump, etc.
    COMBAT,    # Attack, defend, hit reactions
    DANCE,     # Dance moves synced to beats
    EMOTE,     # Expressions, gestures
    IDLE,      # Standing, breathing
}

@export var name: String
@export var type: AnimationType
@export var frame_count: int = 30
@export var fps: float = 30.0
@export var loop: bool = true
@export var tracks: Dictionary  # bone_name -> Array[Keyframe]

func get_duration() -> float:
    return frame_count / fps

func sample_bone(bone: String, frame: float) -> Transform3D:
    # Interpolate between keyframes
    pass
```

#### Keyframe
```gdscript
class_name Keyframe extends Resource

enum EasingType {
    LINEAR,
    EASE_IN,
    EASE_OUT,
    EASE_IN_OUT,
    BOUNCE,
    ELASTIC,
}

@export var frame: int
@export var position: Vector3
@export var rotation: Vector3  # Euler angles
@export var scale: Vector3 = Vector3.ONE
@export var easing: EasingType = EasingType.LINEAR

func interpolate_to(other: Keyframe, t: float) -> Transform3D:
    var eased_t = _apply_easing(t, easing)
    var pos = position.lerp(other.position, eased_t)
    var rot = rotation.lerp(other.rotation, eased_t)
    var scl = scale.lerp(other.scale, eased_t)
    return Transform3D(Basis.from_euler(rot).scaled(scl), pos)
```

#### BoneTrack
```gdscript
class_name BoneTrack extends Control

var bone_name: String
var keyframes: Array[Keyframe]
var track_color: Color

signal keyframe_selected(frame: int)
signal keyframe_moved(from: int, to: int)
signal keyframe_added(frame: int)

func add_keyframe(frame: int, kf: Keyframe) -> void
func remove_keyframe(frame: int) -> void
func get_keyframe_at(frame: int) -> Keyframe
func _draw() -> void  # Draw track with keyframe markers
```

### 4. Animation Types

#### Movement Animations
```gdscript
const MOVEMENT_PRESETS = {
    "idle": {
        "frames": 60,
        "loop": true,
        "description": "Standing still, subtle breathing"
    },
    "walk": {
        "frames": 30,
        "loop": true,
        "description": "Walking forward"
    },
    "run": {
        "frames": 20,
        "loop": true,
        "description": "Running forward"
    },
    "jump": {
        "frames": 40,
        "loop": false,
        "description": "Jump up and land"
    },
    "crouch": {
        "frames": 15,
        "loop": false,
        "description": "Transition to crouch"
    },
}
```

#### Combat Animations
```gdscript
const COMBAT_PRESETS = {
    "punch": {
        "frames": 15,
        "loop": false,
        "hit_frame": 8,
        "description": "Quick jab"
    },
    "kick": {
        "frames": 20,
        "loop": false,
        "hit_frame": 12,
        "description": "Front kick"
    },
    "block": {
        "frames": 10,
        "loop": false,
        "description": "Defensive block pose"
    },
    "hit_react": {
        "frames": 20,
        "loop": false,
        "description": "Getting hit stagger"
    },
    "dodge": {
        "frames": 15,
        "loop": false,
        "description": "Quick sidestep"
    },
}
```

### 5. Features

#### Timeline
- Frame-by-frame scrubbing
- Zoom in/out on timeline
- Loop region selection
- Onion skinning (ghost frames)
- Frame markers for hit/event timing

#### Bone Manipulation
- Direct manipulation in 3D view
- Rotation handles (gizmo)
- IK hints for limbs
- Mirror pose (left/right)
- Copy pose to other bones

#### Keyframe Editing
- Insert keyframe at current frame
- Delete selected keyframes
- Move keyframes by dragging
- Copy/paste between bones
- Easing curve editor

#### Preview
- Real-time playback
- Step forward/backward
- Loop toggle
- Speed control (0.5x, 1x, 2x)
- Multiple camera angles

### 6. Data Format

#### Animation Resource (.tres)
```gdscript
[gd_resource type="Resource" script_class="CharacterAnimation"]

[resource]
name = "walk_cycle"
type = 0  # MOVEMENT
frame_count = 30
fps = 30.0
loop = true
tracks = {
    "Pelvis": [
        {"frame": 0, "position": Vector3(0, 0, 0), "rotation": Vector3(0, 0, 0)},
        {"frame": 15, "position": Vector3(0, 0.05, 0), "rotation": Vector3(0, 0, 0)},
        {"frame": 30, "position": Vector3(0, 0, 0), "rotation": Vector3(0, 0, 0)}
    ],
    "Thigh_L": [
        {"frame": 0, "rotation": Vector3(-30, 0, 0)},
        {"frame": 15, "rotation": Vector3(30, 0, 0)},
        {"frame": 30, "rotation": Vector3(-30, 0, 0)}
    ],
    # ... more bones
}
```

#### JSON Export
```json
{
    "name": "walk_cycle",
    "type": "MOVEMENT",
    "frame_count": 30,
    "fps": 30.0,
    "loop": true,
    "tracks": {
        "Pelvis": [
            {"frame": 0, "position": [0, 0, 0], "rotation": [0, 0, 0], "easing": "LINEAR"},
            {"frame": 15, "position": [0, 0.05, 0], "rotation": [0, 0, 0], "easing": "EASE_IN_OUT"},
            {"frame": 30, "position": [0, 0, 0], "rotation": [0, 0, 0], "easing": "LINEAR"}
        ],
        "Thigh_L": [
            {"frame": 0, "rotation": [-30, 0, 0], "easing": "EASE_IN_OUT"},
            {"frame": 15, "rotation": [30, 0, 0], "easing": "EASE_IN_OUT"},
            {"frame": 30, "rotation": [-30, 0, 0], "easing": "EASE_IN_OUT"}
        ]
    },
    "events": [
        {"frame": 7, "type": "footstep", "side": "left"},
        {"frame": 22, "type": "footstep", "side": "right"}
    ]
}
```

### 7. Bone Hierarchy

```
Root
├── Pelvis
│   ├── Spine_Lower
│   │   ├── Spine_Upper
│   │   │   ├── Chest
│   │   │   │   ├── Neck
│   │   │   │   │   └── Head
│   │   │   │   ├── Shoulder_L
│   │   │   │   │   └── Upper_Arm_L
│   │   │   │   │       └── Lower_Arm_L
│   │   │   │   │           └── Hand_L
│   │   │   │   └── Shoulder_R
│   │   │   │       └── Upper_Arm_R
│   │   │   │           └── Lower_Arm_R
│   │   │   │               └── Hand_R
│   ├── Thigh_L
│   │   └── Calf_L
│   │       └── Foot_L
│   └── Thigh_R
│       └── Calf_R
│           └── Foot_R
```

### 8. Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Play/Pause |
| ← / → | Previous/Next frame |
| Shift+← / → | Previous/Next keyframe |
| K | Insert keyframe |
| Delete | Delete keyframe |
| Ctrl+C | Copy keyframe |
| Ctrl+V | Paste keyframe |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| M | Mirror pose |
| O | Toggle onion skin |
| 1-4 | Camera views |
| +/- | Zoom timeline |
| Home/End | Go to start/end |

### 9. Implementation Phases

#### Phase 1: Basic Editor
- 3D character preview
- Timeline with frame scrubbing
- Add/remove keyframes
- Basic bone transforms
- Save/Load animations

#### Phase 2: Enhanced Editing
- Bone tracks visualization
- Easing curves
- Copy/Paste keyframes
- Onion skinning
- Event markers

#### Phase 3: Advanced Features
- IK assistance
- Pose mirroring
- Animation blending preview
- Template animations
- Batch operations

#### Phase 4: Polish
- Smooth playback
- Undo/Redo stack
- Animation thumbnails
- Search and categorize
- Import from common formats

### 10. Integration Points

- **HumanoidSkeleton**: Bone structure and transforms
- **HumanoidCharacter**: Apply animations
- **DanceMoves**: Dance animation library
- **CombatTypes**: Hit timing and events
- **MovementTypes**: Movement state animations
- **BeatDetector**: Sync animations to beats

### 11. Animation Events

```gdscript
class AnimationEvent:
    enum EventType {
        FOOTSTEP,      # Sound trigger
        HIT_START,     # Attack hitbox active
        HIT_END,       # Attack hitbox inactive
        EFFECT,        # VFX trigger
        SOUND,         # Sound effect
        BEAT_SYNC,     # Sync point for beat matching
    }

    var frame: int
    var type: EventType
    var data: Dictionary
```

### 12. Testing Checklist

- [ ] All bones can be selected and transformed
- [ ] Keyframes interpolate smoothly
- [ ] Timeline scrubbing is responsive
- [ ] Animations loop correctly
- [ ] Save/Load preserves all keyframe data
- [ ] Event markers trigger at correct frames
- [ ] Easing curves apply correctly
- [ ] Mirror pose works for all bones
- [ ] Undo/Redo handles complex edits
- [ ] Performance with many keyframes
