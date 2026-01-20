# Gameplay Expansion

This document describes planned gameplay features for expanding BeatBeat's core mechanics.

## Combo System

### Combo Chains

Successful beat-timed actions build combo chains that multiply score and unlock special abilities.

#### Combo Mechanics

```gdscript
class_name ComboSystem
extends Node

signal combo_changed(count: int, multiplier: float)
signal combo_broken()
signal combo_milestone(milestone: int)

var combo_count: int = 0
var combo_multiplier: float = 1.0
var combo_timer: float = 0.0

const COMBO_TIMEOUT := 2.0  # Beats to maintain combo
const MILESTONES := [10, 25, 50, 100, 200]

func add_combo(rating: CombatTypes.TimingRating) -> void:
    var points := _rating_to_points(rating)
    if points > 0:
        combo_count += 1
        combo_timer = COMBO_TIMEOUT
        _update_multiplier()
        combo_changed.emit(combo_count, combo_multiplier)
        _check_milestones()
    else:
        break_combo()

func _update_multiplier() -> void:
    # Multiplier increases every 10 hits
    combo_multiplier = 1.0 + (combo_count / 10) * 0.5
```

#### Combo Windows

Different timing windows affect combo building:

| Rating | Combo Points | Multiplier Bonus |
|--------|-------------|------------------|
| PERFECT | 3 | +0.1 |
| GREAT | 2 | +0.05 |
| GOOD | 1 | +0.0 |
| EARLY/LATE | 0 | Breaks combo |

### Combo Milestones

Reaching combo milestones triggers special effects:

- **10 hits**: Screen flash, bonus points
- **25 hits**: Speed boost available
- **50 hits**: Ultimate charge bonus
- **100 hits**: Invincibility frames
- **200 hits**: Maximum multiplier lock

---

## Style System

### Style Meter

A persistent style gauge that tracks player performance and unlocks rewards.

#### Style Points

```gdscript
enum StyleAction {
    PERFECT_HIT,      # +100
    GREAT_HIT,        # +50
    GOOD_HIT,         # +25
    DODGE,            # +75
    PARRY,            # +150
    AIR_COMBO,        # +200
    FINISHER,         # +300
    NO_DAMAGE_CLEAR,  # +500
}

const STYLE_VALUES := {
    StyleAction.PERFECT_HIT: 100,
    StyleAction.GREAT_HIT: 50,
    StyleAction.GOOD_HIT: 25,
    StyleAction.DODGE: 75,
    StyleAction.PARRY: 150,
    StyleAction.AIR_COMBO: 200,
    StyleAction.FINISHER: 300,
    StyleAction.NO_DAMAGE_CLEAR: 500,
}
```

#### Style Ranks

| Rank | Points Required | Bonus |
|------|-----------------|-------|
| D | 0 | None |
| C | 1,000 | +10% XP |
| B | 3,000 | +25% XP |
| A | 6,000 | +50% XP |
| S | 10,000 | +100% XP |
| SS | 15,000 | +150% XP, Special FX |
| SSS | 25,000 | +200% XP, Unique rewards |

### Style Decay

Style points decay over time to encourage continuous action:

```gdscript
func _process(delta: float) -> void:
    # Decay 5% per second when not gaining style
    if time_since_last_action > 1.0:
        style_points *= 1.0 - (0.05 * delta)
```

---

## Environmental Interaction

### Beat-Reactive Hazards

Environmental elements that sync to the music:

#### Hazard Types

| Hazard | Behavior | Pattern |
|--------|----------|---------|
| Pulsing Spikes | Extend on KICK | 1-beat warning |
| Laser Grids | Rotate on BAR | Predictable paths |
| Floor Panels | Drop on SNARE | Visual cues |
| Energy Walls | Toggle on beats | Musical sync |

#### Hazard Implementation

```gdscript
class_name BeatHazard
extends Area3D

@export var active_on_quant: Quant.Type = Quant.Type.KICK
@export var warning_beats: float = 1.0
@export var active_duration: float = 0.5

var _warning_active := false
var _hazard_active := false

func _on_tick(event: SequencerEvent) -> void:
    if event.quant.type == active_on_quant:
        _activate_hazard()

    # Pre-warning
    var time_to_next := Sequencer.get_time_to_next_quant(active_on_quant)
    if time_to_next <= warning_beats * event.beat_duration:
        _show_warning()
```

### Interactive Objects

Objects that respond to player beat-timed actions:

- **Beat Switches**: Activate on perfect timing
- **Rhythm Platforms**: Move on specific beats
- **Musical Doors**: Open with correct input sequence
- **Combo Triggers**: Require combo threshold

---

## Multiplayer Modes

### Cooperative Mode

Two players share the arena, combining efforts against enemies.

#### Co-op Mechanics

- **Shared Combo**: Both players contribute to combo count
- **Revive System**: Down players can be revived on beat
- **Sync Bonuses**: Simultaneous perfect hits grant bonus damage
- **Split Aggro**: Enemies divide attention

#### Co-op Implementation

```gdscript
class_name CoopManager
extends Node

var player_1: Player
var player_2: Player
var shared_combo: ComboSystem

func _on_player_action(player: Player, rating: CombatTypes.TimingRating) -> void:
    shared_combo.add_combo(rating)

    # Check for sync bonus
    if _both_hit_simultaneously():
        _apply_sync_bonus()
```

### Competitive Mode

Players compete for score while surviving the same challenges.

#### Versus Mechanics

- **Separate Scores**: Individual tracking
- **Sabotage Items**: Power-ups that affect opponent
- **Steal Mechanic**: Take combo on opponent miss
- **Sudden Death**: Final round elimination

### Online Features

- **Leaderboards**: Global and friend rankings
- **Ghost Racing**: Compete against recorded runs
- **Daily Challenges**: Rotating competitive events
- **Replay Sharing**: Save and share best runs

---

## Progression Systems

### Experience & Leveling

```gdscript
class_name ProgressionSystem
extends Node

signal level_up(new_level: int)
signal xp_gained(amount: int)

var current_level: int = 1
var current_xp: int = 0

func xp_for_level(level: int) -> int:
    # Exponential curve
    return int(100 * pow(level, 1.5))

func add_xp(amount: int) -> void:
    current_xp += amount
    xp_gained.emit(amount)

    while current_xp >= xp_for_level(current_level):
        current_xp -= xp_for_level(current_level)
        current_level += 1
        level_up.emit(current_level)
```

### Unlockables

| Category | Examples |
|----------|----------|
| Characters | New player skins, models |
| Weapons | Combat style variations |
| Abilities | Special moves, passives |
| Cosmetics | Trails, hit effects, emotes |
| Music | Additional tracks, remixes |
| Arenas | New environment themes |

### Achievement System

```gdscript
class_name Achievement
extends Resource

@export var achievement_id: String
@export var display_name: String
@export var description: String
@export var icon: Texture2D
@export var requirement_type: RequirementType
@export var requirement_value: int
@export var reward_xp: int
@export var unlock_item: String

enum RequirementType {
    COMBO_COUNT,
    STYLE_RANK,
    ENEMIES_DEFEATED,
    BOSS_NO_DAMAGE,
    PERFECT_HITS,
    LEVELS_COMPLETED,
}
```

---

## Game Modes

### Story Mode

Linear progression through themed worlds with narrative elements.

#### Story Structure

- **Worlds**: 5 themed environments
- **Levels per World**: 5 standard + 1 boss
- **Cutscenes**: Animated story beats between worlds
- **Difficulty Curve**: Progressive challenge increase

### Endless Mode

Survive as long as possible with increasing difficulty.

#### Endless Mechanics

```gdscript
class_name EndlessMode
extends Node

var wave_number: int = 0
var difficulty_multiplier: float = 1.0

func _next_wave() -> void:
    wave_number += 1
    difficulty_multiplier = 1.0 + (wave_number * 0.1)

    # Increase enemy count and speed
    var enemy_count := 3 + wave_number / 2
    var enemy_speed := 1.0 + (wave_number * 0.05)

    # Every 5 waves: mini-boss
    if wave_number % 5 == 0:
        _spawn_miniboss()
    else:
        _spawn_wave(enemy_count, enemy_speed)
```

### Challenge Mode

Specific objectives with constraints.

#### Challenge Types

| Challenge | Description |
|-----------|-------------|
| Speed Run | Complete level under time limit |
| Pacifist | Win without attacking |
| Perfect | No hits taken |
| Minimalist | Limited abilities |
| Reversed | Music plays backwards |

### Practice Mode

- Select specific sections to repeat
- Slow motion option
- Visual timing guides
- Detailed performance stats

---

## Accessibility Features

### Visual Accessibility

- **Colorblind Modes**: Protanopia, Deuteranopia, Tritanopia filters
- **High Contrast**: Enhanced visibility option
- **Screen Shake**: Adjustable or disable
- **Flash Reduction**: Minimize strobing effects
- **UI Scaling**: Adjustable interface size

### Audio Accessibility

- **Visual Beat Cues**: On-screen beat indicators
- **Haptic Feedback**: Controller vibration for beats
- **Separate Volume**: Music, SFX, Voice individually adjustable
- **Mono Audio**: Stereo to mono conversion

### Input Accessibility

- **Fully Remappable**: All controls customizable
- **One-Hand Mode**: Simplified control scheme
- **Auto-Timing Assist**: Wider timing windows
- **Hold vs Toggle**: Choice for sustained inputs

### Gameplay Accessibility

- **Difficulty Settings**: Story, Normal, Hard, Expert
- **Invincibility Option**: For story experience
- **Skip Encounters**: Optional combat skip
- **Practice Sections**: Isolate difficult areas

---

## Implementation Status

| Feature | Status | Priority |
|---------|--------|----------|
| Combo System | Partial | High |
| Style System | Planned | Medium |
| Environmental Hazards | Partial | Medium |
| Co-op Mode | Planned | Low |
| Versus Mode | Planned | Low |
| Progression | Partial | High |
| Story Mode | Planned | Medium |
| Endless Mode | Partial | High |
| Challenge Mode | Planned | Medium |
| Accessibility | Planned | High |

See `docs/plans/01_GAMEPLAY_EXPANSION.md` for detailed implementation roadmap.
