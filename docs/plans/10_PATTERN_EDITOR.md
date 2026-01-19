# In-Game Pattern Editor

## Overview
A visual editor for creating and editing beat patterns directly in-game. Users can load WAV files, set tempo/bars, and place quants on a timeline grid.

## Core Components

### 1. Audio Waveform Display
```
┌─────────────────────────────────────────────────────────────────┐
│ [Load WAV] [Save] [Play/Stop] [BPM: 120] [Bars: 4] [Snap: 1/4]  │
├─────────────────────────────────────────────────────────────────┤
│ ▁▂▃▅▇▅▃▂▁▂▃▅▇▅▃▂▁▂▃▅▇▅▃▂▁▂▃▅▇▅▃▂▁ (waveform visualization)     │
├─────────────────────────────────────────────────────────────────┤
│ |1      |2      |3      |4      |1      |2      |3      |4      │
│ ●───────●───────●───────●───────●───────●───────●───────●─────  │ Kick
│ ────●───────●───────●───────●───────●───────●───────●───────●─  │ Snare
│ ●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●─●  │ Hat
│ ────────────────●───────────────────────────────●───────────────│ Animation
│ ●───────────────────────●───────────────────────●───────────────│ Hit
└─────────────────────────────────────────────────────────────────┘
```

### 2. UI Structure

#### Main Panels
- **Toolbar**: File operations, playback controls, tempo settings
- **Waveform Panel**: Visual representation of loaded audio
- **Timeline Panel**: Grid for placing quants
- **Quant Palette**: Available quant types to place
- **Properties Panel**: Selected quant properties

#### File Structure
```
ui/
  editors/
    pattern_editor/
      pattern_editor.gd          # Main editor controller
      pattern_editor.tscn        # Scene layout
      waveform_display.gd        # Audio waveform rendering
      timeline_grid.gd           # Beat grid with snap
      quant_lane.gd              # Single quant type lane
      quant_marker.gd            # Draggable quant on timeline
      pattern_toolbar.gd         # Top toolbar controls
      quant_palette.gd           # Quant type selector
```

### 3. Core Classes

#### PatternEditor
```gdscript
class_name PatternEditor extends Control

# Audio
var audio_stream: AudioStream
var audio_player: AudioStreamPlayer
var waveform_data: PackedFloat32Array

# Pattern data
var pattern: Pattern
var bpm: float = 120.0
var bars: int = 4
var time_signature: Vector2i = Vector2i(4, 4)

# Editing
var snap_division: int = 4  # 1/4, 1/8, 1/16, etc.
var selected_quant_type: Quant.Type
var selected_markers: Array[QuantMarker]

# Methods
func load_wav(path: String) -> void
func save_pattern(path: String) -> void
func set_bpm(value: float) -> void
func set_bars(value: int) -> void
func add_quant(type: Quant.Type, beat: float) -> void
func remove_quant(marker: QuantMarker) -> void
func move_quant(marker: QuantMarker, new_beat: float) -> void
```

#### WaveformDisplay
```gdscript
class_name WaveformDisplay extends Control

var audio_data: PackedFloat32Array
var samples_per_pixel: int
var playhead_position: float

func generate_waveform(stream: AudioStream) -> void
func set_zoom(level: float) -> void
func set_playhead(time: float) -> void
func _draw() -> void  # Custom waveform rendering
```

#### TimelineGrid
```gdscript
class_name TimelineGrid extends Control

var bpm: float
var bars: int
var snap_division: int
var lanes: Array[QuantLane]

func pixel_to_beat(x: float) -> float
func beat_to_pixel(beat: float) -> float
func snap_to_grid(beat: float) -> float
func get_beat_at_position(pos: Vector2) -> float
```

#### QuantMarker
```gdscript
class_name QuantMarker extends Control

var quant_type: Quant.Type
var beat_position: float
var duration: float
var data: Dictionary

signal moved(new_beat: float)
signal selected()
signal deleted()

func _gui_input(event: InputEvent) -> void  # Drag handling
```

### 4. Features

#### Audio Loading
- Support WAV files from `beats/wav/` folder
- Auto-detect BPM (optional)
- Display duration and sample rate
- Waveform peak analysis for visualization

#### Grid System
- Configurable snap: 1/1, 1/2, 1/4, 1/8, 1/16, 1/32
- Beat/bar markers with numbers
- Measure lines (bold on downbeat)
- Playhead following audio position

#### Quant Editing
- Click to add quant at position
- Drag to move quants
- Right-click to delete
- Multi-select with Shift+Click
- Copy/Paste selected quants
- Undo/Redo support

#### Quant Types Available
```gdscript
enum Type {
    KICK,      # Bass drum hits
    SNARE,     # Snare hits
    HAT,       # Hi-hat
    ANIMATION, # Character animation triggers
    TICK,      # Metronome/timing reference
    HIT,       # Combat/action triggers
    ACCENT,    # Musical accents
    FILL,      # Drum fills
    BREAK,     # Pattern breaks
}
```

#### Playback
- Play/Pause/Stop controls
- Loop selection
- Metronome option
- Visual feedback on active quants

### 5. Data Format

#### Pattern JSON Structure
```json
{
    "name": "MyPattern",
    "bpm": 128,
    "bars": 4,
    "time_signature": [4, 4],
    "audio_file": "beats/wav/MyPattern.wav",
    "quants": [
        {"type": "Kick", "beat": 0.0},
        {"type": "Kick", "beat": 1.0},
        {"type": "Snare", "beat": 0.5},
        {"type": "Hat", "beat": 0.0},
        {"type": "Hat", "beat": 0.25}
    ]
}
```

### 6. Keyboard Shortcuts

| Key | Action |
|-----|--------|
| Space | Play/Pause |
| S | Save pattern |
| Ctrl+Z | Undo |
| Ctrl+Y | Redo |
| Delete | Delete selected |
| Ctrl+A | Select all |
| Ctrl+C | Copy |
| Ctrl+V | Paste |
| 1-9 | Select quant type |
| +/- | Zoom in/out |
| [ / ] | Decrease/Increase snap |

### 7. Implementation Phases

#### Phase 1: Basic Editor
- Load WAV file
- Display simple waveform
- Grid with configurable BPM/bars
- Add/remove quants by clicking
- Save/Load pattern JSON

#### Phase 2: Enhanced Editing
- Drag quants to move
- Multi-select and batch operations
- Undo/Redo system
- Copy/Paste

#### Phase 3: Advanced Features
- Auto BPM detection
- Zoom and scroll
- Loop regions
- Metronome
- Pattern preview with game elements

#### Phase 4: Polish
- Keyboard shortcuts
- Visual themes
- Pattern templates
- Import/Export formats

### 8. Integration Points

- **AudioManager**: Load and play WAV files
- **Pattern**: Core pattern data structure
- **Quant**: Quant type definitions
- **SaveManager**: Persist editor settings
- **ResourceLoader**: Load existing patterns

### 9. UI Theme

```gdscript
# Colors for quant types in editor
const QUANT_COLORS = {
    Quant.Type.KICK: Color(1.0, 0.3, 0.3),      # Red
    Quant.Type.SNARE: Color(0.3, 1.0, 0.3),     # Green
    Quant.Type.HAT: Color(0.3, 0.3, 1.0),       # Blue
    Quant.Type.ANIMATION: Color(1.0, 1.0, 0.3), # Yellow
    Quant.Type.TICK: Color(0.7, 0.7, 0.7),      # Gray
    Quant.Type.HIT: Color(1.0, 0.5, 0.0),       # Orange
}
```

### 10. Testing Checklist

- [ ] Load various WAV formats (8/16/24 bit, mono/stereo)
- [ ] Save and reload patterns maintain accuracy
- [ ] Snap works correctly at all divisions
- [ ] Playhead syncs with audio
- [ ] Undo/Redo handles all operations
- [ ] Large patterns (100+ bars) perform well
- [ ] Quant timing matches playback
