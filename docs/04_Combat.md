# Combat System

## Overview

The combat system provides:
- **Action Windows**: Time-limited opportunities to perform combat actions
- **Timing Feedback**: Rating system based on action timing relative to beats
- **Combo System**: Chaining attacks for damage multipliers
- **Hitbox Management**: Frame-accurate hit detection

```
Beat ──▶ Window Opens ──▶ Player Input ──▶ Timing Grade ──▶ Step Select ──▶ Hitbox Active ──▶ Hit Result
```

## Combat Types

### Action Types

```gdscript
# combat/combat_types.gd
class_name CombatTypes

enum ActionType {
    NONE,
    MOVE,
    LIGHT_ATTACK,
    HEAVY_ATTACK,
    BLOCK,
    PARRY,
    DODGE
}

enum TimingRating {
    MISS,
    EARLY,
    LATE,
    GOOD,
    GREAT,
    PERFECT
}

enum WindowType {
    NONE,
    ATTACK,
    BLOCK,
    DODGE
}
```

### Combat Step Definition

```gdscript
class_name CombatStepDefinition
extends MovementStepDefinition

@export var action_type: CombatTypes.ActionType = CombatTypes.ActionType.NONE
@export var base_damage: float = 10.0
@export var perfect_timing_multiplier: float = 2.0

# Hitbox timing (frame numbers)
@export var hitbox_active_start_frame: int = 5
@export var hitbox_active_end_frame: int = 15

# Range
@export var min_range: float = 0.0
@export var max_range: float = 200.0

# Combo chaining
@export var valid_previous_links: Array[String] = []

# Weapon requirement
@export var required_weapon_type: String = ""

# Hitbox volume (local space)
@export var hitbox_half_extent: Vector3 = Vector3(50, 50, 50)
@export var hitbox_offset: Vector3 = Vector3(0, 0, 100)
```

### Combat Playback Plan

```gdscript
class_name CombatStepPlaybackPlan
extends MovementStepPlaybackPlan

var action_type: CombatTypes.ActionType
var base_damage: float
var timing_multiplier: float
var timing_quality: float  # 0.0 - 1.0
var timing_rating: CombatTypes.TimingRating

var hitbox_start_frame: int
var hitbox_end_frame: int
var hitbox_half_extent: Vector3
var hitbox_offset: Vector3

var combo_link: String  # Tag for next step chaining
```

### Hit Result

```gdscript
class_name BeatHitResult
extends RefCounted

var hit_actor: Node3D
var base_damage: float
var final_damage: float
var timing_quality: float
var timing_rating: CombatTypes.TimingRating
var combo_count: int
var is_critical: bool
var hit_location: Vector3
var hit_normal: Vector3
```

## Combat Animation Component

### Purpose
- Manages action windows and combo state
- Selects combat steps based on context
- Tracks timing quality and applies multipliers

### Implementation

```gdscript
# combat/combat_component.gd
class_name BeatCombatAnimComponent
extends Node

signal window_opened(window_type: CombatTypes.WindowType)
signal window_closed(window_type: CombatTypes.WindowType)
signal action_executed(plan: CombatStepPlaybackPlan)
signal timing_feedback(rating: CombatTypes.TimingRating, quality: float)
signal combo_changed(count: int, multiplier: float)
signal combo_dropped()

# Combat step library
@export var combat_steps: Array[CombatStepDefinition] = []

# Scoring weights
@export var range_match_weight: float = 0.3
@export var direction_match_weight: float = 0.3
@export var combo_link_bonus: float = 0.2
@export var package_bonus: float = 0.1

# Timing thresholds
const PERFECT_THRESHOLD: float = 0.95
const GREAT_THRESHOLD: float = 0.85
const GOOD_THRESHOLD: float = 0.65

# Window state
var active_window_type: CombatTypes.WindowType = CombatTypes.WindowType.NONE
var window_time_remaining: float = 0.0
var window_start_time: float = 0.0
var window_duration: float = 0.0

# Combo state
var combo_count: int = 0
var combo_multiplier: float = 1.0
var current_combo_link: String = ""

@export var combo_drop_timeout: float = 2.0
@export var combo_multiplier_increment: float = 0.1
@export var max_combo_multiplier: float = 3.0

var _combo_timer: float = 0.0

# Combat context
var target_distance: float = 0.0
var target_direction: Vector3 = Vector3.FORWARD

# Weapon
var equipped_weapon: MeleeWeaponData = null

func _process(delta: float):
    # Update window timer
    if active_window_type != CombatTypes.WindowType.NONE:
        window_time_remaining -= delta
        if window_time_remaining <= 0:
            close_window()

    # Update combo timer
    if combo_count > 0:
        _combo_timer += delta
        if _combo_timer >= combo_drop_timeout:
            drop_combo()

# === Window Management ===

func open_window(window_type: CombatTypes.WindowType, duration: float):
    if active_window_type != CombatTypes.WindowType.NONE:
        close_window()

    active_window_type = window_type
    window_duration = duration
    window_time_remaining = duration
    window_start_time = Time.get_ticks_msec() / 1000.0

    window_opened.emit(window_type)

func close_window():
    var closed_type = active_window_type
    active_window_type = CombatTypes.WindowType.NONE
    window_time_remaining = 0.0

    window_closed.emit(closed_type)

func is_window_open() -> bool:
    return active_window_type != CombatTypes.WindowType.NONE

func get_active_window_type() -> CombatTypes.WindowType:
    return active_window_type

# === Action Execution ===

func try_action_in_window(action_type: CombatTypes.ActionType) -> float:
    if not is_window_open():
        return -1.0

    # Validate action matches window
    if not _action_matches_window(action_type, active_window_type):
        return -1.0

    # Calculate timing quality
    var timing_quality = _calculate_timing_quality()
    var timing_rating = _get_timing_rating(timing_quality)

    # Build combat step plan
    var plan = build_combat_step_plan(action_type, timing_quality, timing_rating)

    if plan:
        action_executed.emit(plan)
        timing_feedback.emit(timing_rating, timing_quality)

        # Reset combo timer
        _combo_timer = 0.0

    close_window()

    return timing_quality

func _action_matches_window(action: CombatTypes.ActionType, window: CombatTypes.WindowType) -> bool:
    match window:
        CombatTypes.WindowType.ATTACK:
            return action in [CombatTypes.ActionType.LIGHT_ATTACK, CombatTypes.ActionType.HEAVY_ATTACK]
        CombatTypes.WindowType.BLOCK:
            return action in [CombatTypes.ActionType.BLOCK, CombatTypes.ActionType.PARRY]
        CombatTypes.WindowType.DODGE:
            return action == CombatTypes.ActionType.DODGE
    return false

func _calculate_timing_quality() -> float:
    # Quality based on how close to center of window
    var elapsed = (Time.get_ticks_msec() / 1000.0) - window_start_time
    var window_center = window_duration / 2.0
    var distance_from_center = abs(elapsed - window_center)
    var max_distance = window_duration / 2.0

    return 1.0 - (distance_from_center / max_distance)

func _get_timing_rating(quality: float) -> CombatTypes.TimingRating:
    if quality >= PERFECT_THRESHOLD:
        return CombatTypes.TimingRating.PERFECT
    elif quality >= GREAT_THRESHOLD:
        return CombatTypes.TimingRating.GREAT
    elif quality >= GOOD_THRESHOLD:
        return CombatTypes.TimingRating.GOOD
    elif quality < GOOD_THRESHOLD:
        # Determine early or late
        var elapsed = (Time.get_ticks_msec() / 1000.0) - window_start_time
        if elapsed < window_duration / 2.0:
            return CombatTypes.TimingRating.EARLY
        else:
            return CombatTypes.TimingRating.LATE
    return CombatTypes.TimingRating.MISS

# === Step Selection ===

func build_combat_step_plan(
    action_type: CombatTypes.ActionType,
    timing_quality: float,
    timing_rating: CombatTypes.TimingRating
) -> CombatStepPlaybackPlan:

    # Filter candidates
    var candidates = _filter_combat_candidates(action_type)

    if candidates.is_empty():
        return null

    # Score and select best
    var best_step = _select_best_combat_step(candidates)

    if not best_step:
        return null

    # Build plan
    var plan = CombatStepPlaybackPlan.new()
    plan.step_name = best_step.step_name
    plan.animation = best_step.animation
    plan.play_rate = 1.0
    plan.quantized_duration_seconds = best_step.base_duration_seconds
    plan.adjusted_movement_delta = best_step.movement_delta
    plan.adjusted_rotation_delta = best_step.rotation_delta

    plan.action_type = action_type
    plan.base_damage = best_step.base_damage
    plan.timing_quality = timing_quality
    plan.timing_rating = timing_rating

    # Apply timing multiplier
    plan.timing_multiplier = _get_timing_multiplier(timing_rating, best_step.perfect_timing_multiplier)

    plan.hitbox_start_frame = best_step.hitbox_active_start_frame
    plan.hitbox_end_frame = best_step.hitbox_active_end_frame
    plan.hitbox_half_extent = best_step.hitbox_half_extent
    plan.hitbox_offset = best_step.hitbox_offset
    plan.combo_link = best_step.link

    # Update combo link for next step
    current_combo_link = best_step.link

    return plan

func _filter_combat_candidates(action_type: CombatTypes.ActionType) -> Array[CombatStepDefinition]:
    var candidates: Array[CombatStepDefinition] = []

    for step in combat_steps:
        # Action type must match
        if step.action_type != action_type:
            continue

        # Range check
        if target_distance < step.min_range or target_distance > step.max_range:
            continue

        # Weapon requirement
        if not step.required_weapon_type.is_empty():
            if not equipped_weapon or equipped_weapon.weapon_type != step.required_weapon_type:
                continue

        # Combo link requirement
        if not step.valid_previous_links.is_empty():
            if not current_combo_link in step.valid_previous_links:
                continue

        candidates.append(step)

    return candidates

func _select_best_combat_step(candidates: Array[CombatStepDefinition]) -> CombatStepDefinition:
    var best_step: CombatStepDefinition = null
    var best_score: float = -INF

    for step in candidates:
        var score = _score_combat_step(step)
        if score > best_score:
            best_score = score
            best_step = step

    return best_step

func _score_combat_step(step: CombatStepDefinition) -> float:
    var score: float = 0.0

    # Range match (prefer steps that match target distance)
    var range_center = (step.min_range + step.max_range) / 2.0
    var range_score = 1.0 - abs(target_distance - range_center) / (step.max_range - step.min_range + 0.01)
    score += range_score * range_match_weight

    # Direction match
    var step_direction = step.get_movement_direction()
    var direction_dot = step_direction.dot(target_direction)
    score += direction_dot * direction_match_weight

    # Combo link bonus
    if step.link == current_combo_link and not current_combo_link.is_empty():
        score += combo_link_bonus

    # Package continuity
    # (Would check last_step_package here)

    return score

func _get_timing_multiplier(rating: CombatTypes.TimingRating, perfect_mult: float) -> float:
    match rating:
        CombatTypes.TimingRating.PERFECT:
            return perfect_mult
        CombatTypes.TimingRating.GREAT:
            return lerp(1.0, perfect_mult, 0.5)
        CombatTypes.TimingRating.GOOD:
            return 1.0
        _:
            return 0.75  # Early/Late penalty

# === Combo System ===

func register_combo_hit():
    combo_count += 1
    combo_multiplier = min(1.0 + combo_count * combo_multiplier_increment, max_combo_multiplier)
    _combo_timer = 0.0

    combo_changed.emit(combo_count, combo_multiplier)

func drop_combo():
    combo_count = 0
    combo_multiplier = 1.0
    current_combo_link = ""
    _combo_timer = 0.0

    combo_dropped.emit()

func get_combo_count() -> int:
    return combo_count

func get_combo_multiplier() -> float:
    return combo_multiplier

# === Weapon System ===

func equip_weapon(weapon: MeleeWeaponData):
    equipped_weapon = weapon

func get_equipped_weapon() -> MeleeWeaponData:
    return equipped_weapon

func get_weapon_damage_multiplier() -> float:
    if equipped_weapon:
        return equipped_weapon.damage_multiplier
    return 1.0

func get_weapon_speed_multiplier() -> float:
    if equipped_weapon:
        return equipped_weapon.speed_multiplier
    return 1.0

func get_weapon_reach() -> float:
    if equipped_weapon:
        return equipped_weapon.reach
    return 100.0

# === Context Updates ===

func set_target_context(distance: float, direction: Vector3):
    target_distance = distance
    target_direction = direction.normalized()
```

## Melee Hitbox Component

### Purpose
- Detects hits during active hitbox frames
- Applies damage with timing information
- Prevents duplicate hits on same target

### Implementation

```gdscript
# combat/hitbox.gd
class_name BeatMeleeHitboxComponent
extends Node3D

signal hit_detected(result: BeatHitResult)

@export var owner_character: CharacterBody3D
@export var combat_component: BeatCombatAnimComponent

# Collision settings
@export var collision_mask: int = 2  # Layer for hittable entities
@export var hit_cooldown: float = 0.1  # Prevent multi-hit on same target

var _active: bool = false
var _current_plan: CombatStepPlaybackPlan = null
var _current_frame: int = 0
var _hit_targets: Dictionary = {}  # Node -> timestamp
var _shape_cast: ShapeCast3D

func _ready():
    _shape_cast = ShapeCast3D.new()
    _shape_cast.enabled = false
    _shape_cast.collision_mask = collision_mask
    add_child(_shape_cast)

func _physics_process(delta: float):
    if not _active or not _current_plan:
        return

    # Check if in active frames
    if _current_frame >= _current_plan.hitbox_start_frame and _current_frame <= _current_plan.hitbox_end_frame:
        _check_hits()

    _current_frame += 1

    # Check if past end frame
    if _current_frame > _current_plan.hitbox_end_frame:
        deactivate()

func activate(plan: CombatStepPlaybackPlan):
    _current_plan = plan
    _current_frame = 0
    _active = true
    _hit_targets.clear()

    # Configure hitbox shape
    var box_shape = BoxShape3D.new()
    box_shape.size = plan.hitbox_half_extent * 2
    _shape_cast.shape = box_shape
    _shape_cast.position = plan.hitbox_offset
    _shape_cast.enabled = true

func deactivate():
    _active = false
    _current_plan = null
    _shape_cast.enabled = false

func _check_hits():
    _shape_cast.force_shapecast_update()

    if not _shape_cast.is_colliding():
        return

    var current_time = Time.get_ticks_msec() / 1000.0

    for i in range(_shape_cast.get_collision_count()):
        var collider = _shape_cast.get_collider(i)

        # Skip owner
        if collider == owner_character:
            continue

        # Check cooldown
        if _hit_targets.has(collider):
            if current_time - _hit_targets[collider] < hit_cooldown:
                continue

        # Record hit
        _hit_targets[collider] = current_time

        # Build hit result
        var result = _build_hit_result(collider, _shape_cast.get_collision_point(i), _shape_cast.get_collision_normal(i))

        hit_detected.emit(result)

func _build_hit_result(target: Node3D, point: Vector3, normal: Vector3) -> BeatHitResult:
    var result = BeatHitResult.new()

    result.hit_actor = target
    result.base_damage = _current_plan.base_damage
    result.timing_quality = _current_plan.timing_quality
    result.timing_rating = _current_plan.timing_rating
    result.combo_count = combat_component.get_combo_count()

    # Calculate final damage
    var timing_mult = _current_plan.timing_multiplier
    var combo_mult = combat_component.get_combo_multiplier()
    var weapon_mult = combat_component.get_weapon_damage_multiplier()

    result.final_damage = result.base_damage * timing_mult * combo_mult * weapon_mult

    # Critical on perfect timing
    result.is_critical = _current_plan.timing_rating == CombatTypes.TimingRating.PERFECT

    result.hit_location = point
    result.hit_normal = normal

    return result
```

## Weapon Data

### Melee Weapon

```gdscript
# combat/melee_weapon_data.gd
class_name MeleeWeaponData
extends Resource

@export var weapon_name: String = ""
@export var weapon_type: String = "sword"  # sword, axe, hammer, etc.

@export var damage_multiplier: float = 1.0
@export var speed_multiplier: float = 1.0
@export var reach: float = 100.0

@export var hitbox_half_extent: Vector3 = Vector3(50, 50, 100)
@export var hitbox_offset: Vector3 = Vector3(0, 0, 100)

# Visual
@export var mesh: Mesh
@export var trail_material: Material
```

## Combat UI Feedback

### Timing Rating Display

```gdscript
# ui/timing_feedback.gd
class_name TimingFeedbackUI
extends Control

@onready var label: Label = $Label
@onready var animation_player: AnimationPlayer = $AnimationPlayer

var rating_colors: Dictionary = {
    CombatTypes.TimingRating.PERFECT: Color.GOLD,
    CombatTypes.TimingRating.GREAT: Color.GREEN,
    CombatTypes.TimingRating.GOOD: Color.YELLOW,
    CombatTypes.TimingRating.EARLY: Color.ORANGE,
    CombatTypes.TimingRating.LATE: Color.ORANGE,
    CombatTypes.TimingRating.MISS: Color.RED
}

var rating_texts: Dictionary = {
    CombatTypes.TimingRating.PERFECT: "PERFECT!",
    CombatTypes.TimingRating.GREAT: "GREAT!",
    CombatTypes.TimingRating.GOOD: "GOOD",
    CombatTypes.TimingRating.EARLY: "EARLY",
    CombatTypes.TimingRating.LATE: "LATE",
    CombatTypes.TimingRating.MISS: "MISS"
}

func show_rating(rating: CombatTypes.TimingRating):
    label.text = rating_texts[rating]
    label.modulate = rating_colors[rating]

    animation_player.play("popup")

func _on_combat_component_timing_feedback(rating: CombatTypes.TimingRating, _quality: float):
    show_rating(rating)
```

### Combo Counter

```gdscript
# ui/combo_counter.gd
class_name ComboCounterUI
extends Control

@onready var count_label: Label = $CountLabel
@onready var multiplier_label: Label = $MultiplierLabel
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func update_combo(count: int, multiplier: float):
    if count == 0:
        hide()
        return

    show()
    count_label.text = str(count)
    multiplier_label.text = "x%.1f" % multiplier

    animation_player.play("hit")

func _on_combat_component_combo_changed(count: int, multiplier: float):
    update_combo(count, multiplier)

func _on_combat_component_combo_dropped():
    animation_player.play("drop")
    await animation_player.animation_finished
    hide()
```

## Combat Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            COMBAT FLOW                                       │
└─────────────────────────────────────────────────────────────────────────────┘

1. WINDOW PHASE
   Beat arrives ──▶ Open attack window (0.5s duration)

2. INPUT PHASE
   Player presses attack ──▶ Check window open ──▶ Calculate timing quality

3. STEP SELECTION
   Filter candidates by:
   ├── Action type matches
   ├── Range to target
   ├── Weapon requirement
   └── Combo link validity

   Score by:
   ├── Range match
   ├── Direction match
   └── Combo link bonus

4. EXECUTION
   Play animation ──▶ Apply root motion ──▶ Activate hitbox at start frame

5. HIT DETECTION
   Shape cast each frame ──▶ Build hit result ──▶ Emit signal

6. DAMAGE APPLICATION
   Base damage × Timing mult × Combo mult × Weapon mult = Final damage

7. COMBO UPDATE
   Hit successful ──▶ Increment combo ──▶ Reset timer
   OR
   Window missed / Damage taken ──▶ Drop combo
```

## Best Practices

1. **Window Timing**: Keep windows short (0.3-0.5s) to require precise timing
2. **Combo Links**: Design attack chains that flow naturally
3. **Range Tuning**: Ensure min/max ranges create distinct attack choices
4. **Visual Feedback**: Always show timing rating immediately
5. **Audio Cues**: Play different sounds for each timing grade
6. **Hitbox Timing**: Start hitbox after wind-up frames, end before recovery
