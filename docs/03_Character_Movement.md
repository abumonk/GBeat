# Character & Movement System

## Overview

The character system combines:
- **Input Buffering**: Raw input captured continuously, latched at beat boundaries
- **Quantized Movement**: Movement applied in discrete steps aligned to beats
- **Animation-Driven Movement**: Animation selection based on direction and continuity

```
Raw Input ──▶ Buffer ──▶ Latch @ Beat ──▶ Step Selection ──▶ Animation ──▶ Movement
```

## Player Character

### Purpose
- Main player-controlled character
- Dual camera system (top-down and side view)
- Integrates movement, combat, and animation components

### Implementation

```gdscript
# character/player.gd
class_name Player
extends CharacterBody3D

signal camera_switched(mode: CameraMode)
signal movement_step_triggered(plan: MovementStepPlaybackPlan)

enum CameraMode { TOP_DOWN, SIDE }

# Components
@onready var movement_component: BeatMovementComponent = $BeatMovementComponent
@onready var movement_anim_component: BeatMovementAnimComponent = $BeatMovementAnimComponent
@onready var combat_anim_component: BeatCombatAnimComponent = $BeatCombatAnimComponent
@onready var melee_hitbox: BeatMeleeHitboxComponent = $BeatMeleeHitboxComponent
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Cameras
@onready var arm_top_down: SpringArm3D = $ArmTopDown
@onready var cam_top_down: Camera3D = $ArmTopDown/CameraTopDown
@onready var arm_side: SpringArm3D = $ArmSide
@onready var cam_side: Camera3D = $ArmSide/CameraSide

# State
var current_camera_mode: CameraMode = CameraMode.TOP_DOWN
var use_animation_driven_movement: bool = true

# Cached input (latched at quant boundaries)
var cached_movement_direction: Vector3 = Vector3.ZERO
var cached_target_direction: Vector3 = Vector3.ZERO

func _ready():
    # Subscribe to animation quants for movement steps
    Sequencer.subscribe(
        Sequencer.DeckType.GAME,
        Quant.Type.ANIMATION,
        _on_animation_quant
    )

    # Subscribe to combat window quants
    Sequencer.subscribe(
        Sequencer.DeckType.GAME,
        Quant.Type.ANIMATION,
        _on_combat_window_quant
    )

    # Connect melee hitbox
    melee_hitbox.hit_detected.connect(_on_melee_hit)

func switch_camera(mode: CameraMode):
    current_camera_mode = mode

    match mode:
        CameraMode.TOP_DOWN:
            cam_top_down.make_current()
        CameraMode.SIDE:
            cam_side.make_current()

    camera_switched.emit(mode)

func cache_movement_directions(move_dir: Vector3, target_dir: Vector3):
    cached_movement_direction = move_dir
    cached_target_direction = target_dir

func _on_animation_quant(event: SequencerEvent):
    if not use_animation_driven_movement:
        return

    # Build movement step from cached input
    var plan = movement_anim_component.build_step_plan_from_inputs(
        cached_movement_direction,
        cached_target_direction,
        velocity.length()
    )

    if plan:
        _execute_movement_step(plan)
        movement_step_triggered.emit(plan)

func _execute_movement_step(plan: MovementStepPlaybackPlan):
    # Play animation
    if plan.animation:
        animation_player.play(plan.animation.resource_name)
        animation_player.speed_scale = plan.play_rate

    # Apply root motion (scaled by input magnitude)
    var movement_delta = plan.adjusted_movement_delta
    velocity = movement_delta / plan.quantized_duration_seconds

    # Apply rotation
    var rotation_delta = plan.adjusted_rotation_delta
    rotate_y(deg_to_rad(rotation_delta.y))

func _on_combat_window_quant(event: SequencerEvent):
    # Open combat action window
    combat_anim_component.open_window(BeatCombatAnimComponent.WindowType.ATTACK, 0.5)

func _on_melee_hit(hit_result: BeatHitResult):
    # Handle successful hit
    combat_anim_component.register_combo_hit()
    # Apply damage to target, VFX, etc.
```

## Player Controller

### Purpose
- Captures raw input from player
- Buffers input until beat boundaries
- Latches input when quant events occur
- Triggers combat actions with timing feedback

### Input Buffer Structure

```gdscript
class_name InputBuffer
extends RefCounted

var raw_move: Vector2 = Vector2.ZERO
var raw_look: Vector2 = Vector2.ZERO
var latched_move: Vector2 = Vector2.ZERO
var latched_look: Vector2 = Vector2.ZERO
var move_forward_scale: float = 1.0
var move_right_scale: float = 1.0
var rotation_speed_degrees: float = 180.0
```

### Implementation

```gdscript
# character/player_controller.gd
class_name PlayerController
extends Node

signal input_latched(move: Vector2, look: Vector2)
signal combat_action_attempted(action: BeatCombatAnimComponent.ActionType, timing_quality: float)

@export var player: Player
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
@export var quantization_layer: Quant.Type = Quant.Type.ANIMATION

# Input settings
@export var move_dead_zone: float = 0.15
@export var look_dead_zone: float = 0.1
@export var move_magnitude_step: float = 0.25  # Quantize to 0, 0.25, 0.5, 0.75, 1.0
@export var look_magnitude_step: float = 0.25

var input_buffer: InputBuffer = InputBuffer.new()
var _subscription_handle: int = -1

func _ready():
    # Subscribe to quantization layer
    _subscription_handle = Sequencer.subscribe(
        sequencer_deck,
        quantization_layer,
        _on_quant_event
    )

func _exit_tree():
    if _subscription_handle >= 0:
        Sequencer.unsubscribe(_subscription_handle)

func _process(_delta: float):
    # Continuously capture raw input
    _capture_raw_input()

func _capture_raw_input():
    input_buffer.raw_move = Input.get_vector("move_left", "move_right", "move_up", "move_down")
    input_buffer.raw_look = Input.get_vector("look_left", "look_right", "look_up", "look_down")

func _on_quant_event(event: SequencerEvent):
    _latch_input()
    _process_quant_boundary(event)

func _latch_input():
    # Apply dead zones and quantize
    input_buffer.latched_move = _quantize_vector(input_buffer.raw_move, move_dead_zone, move_magnitude_step)
    input_buffer.latched_look = _quantize_vector(input_buffer.raw_look, look_dead_zone, look_magnitude_step)

    input_latched.emit(input_buffer.latched_move, input_buffer.latched_look)

func _quantize_vector(raw: Vector2, dead_zone: float, step: float) -> Vector2:
    var magnitude = raw.length()

    # Apply dead zone
    if magnitude < dead_zone:
        return Vector2.ZERO

    # Quantize magnitude to steps
    var quantized_mag = ceil(magnitude / step) * step
    quantized_mag = clamp(quantized_mag, 0.0, 1.0)

    # Quantize direction to 8 directions
    var angle = raw.angle()
    var quantized_angle = round(angle / (PI / 4)) * (PI / 4)

    return Vector2.from_angle(quantized_angle) * quantized_mag

func _process_quant_boundary(event: SequencerEvent):
    # Convert 2D input to 3D world directions based on camera
    var move_3d = _input_to_world_direction(input_buffer.latched_move)
    var look_3d = _input_to_world_direction(input_buffer.latched_look)

    # Apply speed scales from pattern
    move_3d *= input_buffer.move_forward_scale

    # Send to character
    player.cache_movement_directions(move_3d, look_3d)

    # Also update speed scales from current quant values
    var pattern = event.pattern
    var position = event.quant_index

    input_buffer.move_forward_scale = pattern.try_get_quant_value(Quant.Type.MOVE_FORWARD_SPEED, position)
    input_buffer.move_right_scale = pattern.try_get_quant_value(Quant.Type.MOVE_RIGHT_SPEED, position)
    input_buffer.rotation_speed_degrees = pattern.try_get_quant_value(Quant.Type.ROTATION_SPEED, position) * 360.0

func _input_to_world_direction(input_2d: Vector2) -> Vector3:
    # Get camera forward and right vectors (flattened to XZ plane)
    var camera = get_viewport().get_camera_3d()
    if not camera:
        return Vector3(input_2d.x, 0, -input_2d.y)

    var cam_forward = -camera.global_transform.basis.z
    var cam_right = camera.global_transform.basis.x

    cam_forward.y = 0
    cam_right.y = 0
    cam_forward = cam_forward.normalized()
    cam_right = cam_right.normalized()

    return (cam_right * input_2d.x + cam_forward * -input_2d.y).normalized() * input_2d.length()

# === Combat Actions ===

func _unhandled_input(event: InputEvent):
    if event.is_action_pressed("light_attack"):
        _try_combat_action(BeatCombatAnimComponent.ActionType.LIGHT_ATTACK)
    elif event.is_action_pressed("heavy_attack"):
        _try_combat_action(BeatCombatAnimComponent.ActionType.HEAVY_ATTACK)
    elif event.is_action_pressed("block"):
        _try_combat_action(BeatCombatAnimComponent.ActionType.BLOCK)
    elif event.is_action_pressed("dodge"):
        _try_combat_action(BeatCombatAnimComponent.ActionType.DODGE)

func _try_combat_action(action_type: BeatCombatAnimComponent.ActionType):
    var timing_quality = player.combat_anim_component.try_action_in_window(action_type)
    combat_action_attempted.emit(action_type, timing_quality)
```

## Beat Movement Component

### Purpose
- Extended movement component that consumes quantized input
- Subscribes to speed quants for movement parameters
- Applies discrete velocity updates

### Implementation

```gdscript
# character/movement/beat_movement.gd
class_name BeatMovementComponent
extends Node

signal movement_applied(direction: Vector3, magnitude: float)

@export var character: CharacterBody3D
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

# Movement settings
@export var base_speed: float = 600.0
@export var default_rotation_rate_yaw: float = 360.0  # degrees per second

# State
var latched_direction: Vector3 = Vector3.ZERO
var latched_magnitude: float = 0.0
var current_rotation_rate: float = 360.0

var _forward_speed_handle: int = -1
var _right_speed_handle: int = -1
var _rotation_handle: int = -1

func _ready():
    _forward_speed_handle = Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.MOVE_FORWARD_SPEED,
        _on_forward_speed_quant
    )

    _right_speed_handle = Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.MOVE_RIGHT_SPEED,
        _on_right_speed_quant
    )

    _rotation_handle = Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.ROTATION_SPEED,
        _on_rotation_speed_quant
    )

func _exit_tree():
    Sequencer.unsubscribe(_forward_speed_handle)
    Sequencer.unsubscribe(_right_speed_handle)
    Sequencer.unsubscribe(_rotation_handle)

func _on_forward_speed_quant(event: SequencerEvent):
    # Forward speed is embedded in quant value
    pass  # Handled by player controller

func _on_right_speed_quant(event: SequencerEvent):
    pass  # Handled by player controller

func _on_rotation_speed_quant(event: SequencerEvent):
    current_rotation_rate = event.quant.value * default_rotation_rate_yaw

func apply_latched_move(direction: Vector3, magnitude: float):
    latched_direction = direction
    latched_magnitude = magnitude

    # Apply velocity
    character.velocity = latched_direction * latched_magnitude * base_speed

    movement_applied.emit(direction, magnitude)

func set_sequencer_deck(deck: Sequencer.DeckType):
    # Unsubscribe from old deck, subscribe to new
    Sequencer.unsubscribe(_forward_speed_handle)
    Sequencer.unsubscribe(_right_speed_handle)
    Sequencer.unsubscribe(_rotation_handle)

    sequencer_deck = deck

    _forward_speed_handle = Sequencer.subscribe(sequencer_deck, Quant.Type.MOVE_FORWARD_SPEED, _on_forward_speed_quant)
    _right_speed_handle = Sequencer.subscribe(sequencer_deck, Quant.Type.MOVE_RIGHT_SPEED, _on_right_speed_quant)
    _rotation_handle = Sequencer.subscribe(sequencer_deck, Quant.Type.ROTATION_SPEED, _on_rotation_speed_quant)
```

## Beat Movement Animation Component

### Purpose
- Selects best animation step based on desired movement
- Maintains animation continuity (foot contact, package)
- Produces playback plans with adjusted root motion

### Movement Step Definition

```gdscript
# character/movement/movement_types.gd
class_name MovementStepDefinition
extends Resource

@export var package: String = ""          # Animation set grouping
@export var step_name: String = ""        # Debug identifier
@export var link: String = ""             # Chaining tag

@export var animation: Animation
@export var step_start_frame: int = 0
@export var step_end_frame: int = 0
@export var step_process_times: Array[float] = []  # Key moments (seconds)

enum FootContact { NONE = 0, LEFT = 1, RIGHT = 2, BOTH = 3 }
@export var step_start_foot_contact: FootContact = FootContact.NONE
@export var step_end_foot_contact: FootContact = FootContact.NONE

@export var movement_delta: Vector3 = Vector3.ZERO      # Root motion translation
@export var rotation_delta: Vector3 = Vector3.ZERO      # Root motion rotation (euler)

@export var step_start_velocity: Vector2 = Vector2.ZERO  # 2D velocity at start
@export var step_end_velocity: Vector2 = Vector2.ZERO    # 2D velocity at end

@export var max_facing_delta_degrees: float = 45.0       # Max turn per step
@export var min_desired_speed: float = 0.0               # Min input speed
@export var max_desired_speed: float = 600.0             # Max input speed

@export var base_duration_seconds: float = 0.5
@export var base_duration_frames: int = 30

func get_movement_direction() -> Vector3:
    return movement_delta.normalized()

func get_movement_speed() -> float:
    return movement_delta.length() / base_duration_seconds
```

### Playback Plan

```gdscript
class_name MovementStepPlaybackPlan
extends RefCounted

var step_name: String
var animation: Animation
var play_rate: float = 1.0
var quantized_duration_seconds: float
var quant_count: int
var adjusted_movement_delta: Vector3
var adjusted_rotation_delta: Vector3
```

### Implementation

```gdscript
# character/movement/movement_anim.gd
class_name BeatMovementAnimComponent
extends Node

signal step_selected(plan: MovementStepPlaybackPlan)

@export var movement_database: Array[MovementStepDefinition] = []

# Scoring weights
@export var movement_direction_weight: float = 0.7
@export var target_direction_tolerance_degrees: float = 30.0

# Continuity tracking
var current_foot_contact: MovementStepDefinition.FootContact = MovementStepDefinition.FootContact.NONE
var last_step_package: String = ""
var last_step_animation: Animation = null
var last_step_end_frame: int = 0
var last_step_link: String = ""

# Duration filtering
@export var filter_by_duration: bool = false
@export var max_play_rate_deviation: float = 0.3  # +/- 30%

# Root motion scaling
@export var enable_root_motion_scaling: bool = true

func build_step_plan_from_inputs(
    desired_movement: Vector3,
    desired_facing: Vector3,
    current_speed: float
) -> MovementStepPlaybackPlan:

    if movement_database.is_empty():
        return null

    # Filter candidates
    var candidates = _filter_candidates(desired_movement, desired_facing, current_speed)

    if candidates.is_empty():
        return null

    # Score and select best
    var best_step = _select_best_step(candidates, desired_movement, desired_facing)

    if not best_step:
        return null

    # Build playback plan
    var plan = _build_plan(best_step, desired_movement)

    # Update continuity state
    _update_continuity(best_step)

    step_selected.emit(plan)
    return plan

func build_step_plan_from_inputs_with_duration(
    desired_movement: Vector3,
    desired_facing: Vector3,
    current_speed: float,
    target_duration: float
) -> MovementStepPlaybackPlan:
    # Same as above but with duration constraint
    # Filter steps that can't match duration within play rate limits
    pass

func _filter_candidates(
    desired_movement: Vector3,
    desired_facing: Vector3,
    current_speed: float
) -> Array[MovementStepDefinition]:

    var candidates: Array[MovementStepDefinition] = []

    for step in movement_database:
        # Direction match
        var direction_dot = step.get_movement_direction().dot(desired_movement.normalized())
        if direction_dot < 0.0:  # Reject opposite directions
            continue

        # Speed range
        if current_speed < step.min_desired_speed or current_speed > step.max_desired_speed:
            continue

        # Facing delta
        var facing_delta = _calculate_facing_delta(desired_facing, step)
        if facing_delta > step.max_facing_delta_degrees:
            continue

        # Foot contact continuity (optional)
        if current_foot_contact != MovementStepDefinition.FootContact.NONE:
            # Prefer steps that start with opposite foot
            if not _foot_contact_compatible(current_foot_contact, step.step_start_foot_contact):
                continue

        candidates.append(step)

    return candidates

func _select_best_step(
    candidates: Array[MovementStepDefinition],
    desired_movement: Vector3,
    desired_facing: Vector3
) -> MovementStepDefinition:

    var best_step: MovementStepDefinition = null
    var best_score: float = -INF

    for step in candidates:
        var score = _score_step(step, desired_movement, desired_facing)

        if score > best_score:
            best_score = score
            best_step = step

    return best_step

func _score_step(
    step: MovementStepDefinition,
    desired_movement: Vector3,
    desired_facing: Vector3
) -> float:

    var score: float = 0.0

    # Direction score
    var direction_dot = step.get_movement_direction().dot(desired_movement.normalized())
    score += direction_dot * movement_direction_weight

    # Rotation score
    var rotation_score = 1.0 - (_calculate_facing_delta(desired_facing, step) / 180.0)
    score += rotation_score * (1.0 - movement_direction_weight)

    # Frame match bonus
    if step.step_start_frame == last_step_end_frame:
        score += 0.1

    # Same package bonus
    if step.package == last_step_package:
        score += 0.05

    # Same animation bonus
    if step.animation == last_step_animation:
        score += 0.02

    # Link match bonus
    if step.link == last_step_link and not step.link.is_empty():
        score += 0.08

    return score

func _build_plan(step: MovementStepDefinition, desired_movement: Vector3) -> MovementStepPlaybackPlan:
    var plan = MovementStepPlaybackPlan.new()

    plan.step_name = step.step_name
    plan.animation = step.animation
    plan.play_rate = 1.0
    plan.quantized_duration_seconds = step.base_duration_seconds
    plan.quant_count = 1

    # Apply root motion scaling based on input magnitude
    if enable_root_motion_scaling:
        var input_magnitude = desired_movement.length()
        plan.adjusted_movement_delta = step.movement_delta * input_magnitude
    else:
        plan.adjusted_movement_delta = step.movement_delta

    plan.adjusted_rotation_delta = step.rotation_delta

    return plan

func _update_continuity(step: MovementStepDefinition):
    current_foot_contact = step.step_end_foot_contact
    last_step_package = step.package
    last_step_animation = step.animation
    last_step_end_frame = step.step_end_frame
    last_step_link = step.link

func _calculate_facing_delta(desired_facing: Vector3, step: MovementStepDefinition) -> float:
    if desired_facing.length_squared() < 0.01:
        return 0.0

    var step_rotation = step.rotation_delta.y
    return abs(step_rotation)

func _foot_contact_compatible(current: MovementStepDefinition.FootContact, next_start: MovementStepDefinition.FootContact) -> bool:
    # Natural walking: alternate feet
    match current:
        MovementStepDefinition.FootContact.LEFT:
            return next_start == MovementStepDefinition.FootContact.RIGHT or next_start == MovementStepDefinition.FootContact.NONE
        MovementStepDefinition.FootContact.RIGHT:
            return next_start == MovementStepDefinition.FootContact.LEFT or next_start == MovementStepDefinition.FootContact.NONE
        _:
            return true

func reset_step_context():
    current_foot_contact = MovementStepDefinition.FootContact.NONE
    last_step_package = ""
    last_step_animation = null
    last_step_end_frame = 0
    last_step_link = ""
```

## Camera System

### Purpose
- Dual camera modes for different gameplay situations
- Smooth blending between modes
- Input direction transformation based on active camera

### Implementation

```gdscript
# character/camera_controller.gd
class_name CameraController
extends Node3D

@export var player: Player

@onready var arm_top_down: SpringArm3D = $ArmTopDown
@onready var cam_top_down: Camera3D = $ArmTopDown/CameraTopDown
@onready var arm_side: SpringArm3D = $ArmSide
@onready var cam_side: Camera3D = $ArmSide/CameraSide

var blend_duration: float = 0.5
var _blend_progress: float = 0.0
var _blending: bool = false
var _blend_from: Camera3D
var _blend_to: Camera3D

func switch_to_top_down():
    _start_blend(cam_top_down)
    player.current_camera_mode = Player.CameraMode.TOP_DOWN

func switch_to_side():
    _start_blend(cam_side)
    player.current_camera_mode = Player.CameraMode.SIDE

func _start_blend(target_camera: Camera3D):
    _blend_from = get_viewport().get_camera_3d()
    _blend_to = target_camera
    _blend_progress = 0.0
    _blending = true

func _process(delta: float):
    if _blending:
        _blend_progress += delta / blend_duration

        if _blend_progress >= 1.0:
            _blend_to.make_current()
            _blending = false
        else:
            # Interpolate camera transform
            # (In practice, Godot's camera interpolation or tween would be better)
            pass
```

## Input Configuration

### Recommended Input Map

```
# project.godot [input] section

move_left = Key.A, JoyAxis.LEFT_X (negative)
move_right = Key.D, JoyAxis.LEFT_X (positive)
move_up = Key.W, JoyAxis.LEFT_Y (negative)
move_down = Key.S, JoyAxis.LEFT_Y (positive)

look_left = JoyAxis.RIGHT_X (negative)
look_right = JoyAxis.RIGHT_X (positive)
look_up = JoyAxis.RIGHT_Y (negative)
look_down = JoyAxis.RIGHT_Y (positive)

light_attack = Key.J, JoyButton.X
heavy_attack = Key.K, JoyButton.Y
block = Key.L, JoyButton.LEFT_SHOULDER
dodge = Key.SPACE, JoyButton.A

switch_camera = Key.TAB, JoyButton.BACK
```

## Scene Structure

```
Player (CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D (character model)
├── AnimationPlayer
├── BeatMovementComponent
├── BeatMovementAnimComponent
├── BeatCombatAnimComponent
├── BeatMeleeHitboxComponent
├── ArmTopDown (SpringArm3D)
│   └── CameraTopDown (Camera3D)
├── ArmSide (SpringArm3D)
│   └── CameraSide (Camera3D)
└── PlayerController (Node)
```
