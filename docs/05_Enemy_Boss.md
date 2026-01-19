# Enemy & Boss Systems

## Overview

The enemy system provides:
- **Beat-Aware Enemies**: Attacks synchronized to the music
- **Telegraph System**: Visual warnings before attacks
- **Health & Stun**: Standard damage model with stun mechanics
- **Boss Phases**: Multi-phase boss battles with health thresholds

## Enemy Base Class

### Purpose
- Base enemy character with health management
- Target detection and tracking
- Visual state feedback
- Combat component integration

### Implementation

```gdscript
# enemy/beat_enemy.gd
class_name BeatEnemy
extends CharacterBody3D

signal on_death()
signal on_damaged(damage: float, source: Node3D)
signal on_stunned(duration: float)
signal on_stun_ended()
signal health_changed(current: float, max_health: float)

# Health
@export var max_health: float = 100.0
var current_health: float

# Detection
@export var detection_range: float = 1000.0
@export var detection_angle: float = 120.0  # degrees
@export var can_detect_behind: bool = false

# Stun
var is_stunned: bool = false
var stun_time_remaining: float = 0.0

# Visual feedback colors
@export var idle_color: Color = Color.WHITE
@export var telegraph_color: Color = Color.YELLOW
@export var attack_color: Color = Color.RED
@export var stunned_color: Color = Color.BLUE

# Components
@onready var combat_component: BeatEnemyCombatComponent = $BeatEnemyCombatComponent
@onready var mesh: MeshInstance3D = $Mesh
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Current target
var target: Node3D = null

func _ready():
    current_health = max_health

    combat_component.state_changed.connect(_on_combat_state_changed)

func _process(delta: float):
    if is_stunned:
        stun_time_remaining -= delta
        if stun_time_remaining <= 0:
            _end_stun()

    _update_visuals()

# === Health System ===

func get_health_percent() -> float:
    return current_health / max_health

func is_alive() -> bool:
    return current_health > 0

func take_damage(amount: float, source: Node3D = null):
    if not is_alive():
        return

    current_health = max(0, current_health - amount)
    health_changed.emit(current_health, max_health)
    on_damaged.emit(amount, source)

    if current_health <= 0:
        _die()

func take_beat_damage(hit_result: BeatHitResult):
    # Apply damage with timing information
    take_damage(hit_result.final_damage, hit_result.hit_actor)

    # Check for stun on critical hit
    if hit_result.is_critical:
        stun(0.5)

func heal(amount: float):
    current_health = min(max_health, current_health + amount)
    health_changed.emit(current_health, max_health)

func _die():
    combat_component.set_state(BeatEnemyCombatComponent.State.DEAD)
    on_death.emit()

    # Play death animation
    if animation_player.has_animation("death"):
        animation_player.play("death")
        await animation_player.animation_finished

    queue_free()

# === Stun System ===

func stun(duration: float):
    if is_stunned:
        stun_time_remaining = max(stun_time_remaining, duration)
        return

    is_stunned = true
    stun_time_remaining = duration
    combat_component.set_state(BeatEnemyCombatComponent.State.STUNNED)
    on_stunned.emit(duration)

func _end_stun():
    is_stunned = false
    stun_time_remaining = 0.0
    combat_component.set_state(BeatEnemyCombatComponent.State.IDLE)
    on_stun_ended.emit()

func get_stun_time_remaining() -> float:
    return stun_time_remaining

# === Target Detection ===

func find_target(potential_targets: Array[Node3D]) -> Node3D:
    var best_target: Node3D = null
    var best_distance: float = INF

    for potential in potential_targets:
        if can_detect_actor(potential):
            var dist = global_position.distance_to(potential.global_position)
            if dist < best_distance:
                best_distance = dist
                best_target = potential

    target = best_target
    return target

func can_detect_actor(actor: Node3D) -> bool:
    if not actor:
        return false

    var to_actor = actor.global_position - global_position
    var distance = to_actor.length()

    # Range check
    if distance > detection_range:
        return false

    # Angle check
    var forward = -global_transform.basis.z
    var dot = forward.dot(to_actor.normalized())
    var angle = rad_to_deg(acos(dot))

    if angle > detection_angle / 2.0 and not can_detect_behind:
        return false

    return true

# === Visual Feedback ===

func _update_visuals():
    var target_color: Color

    match combat_component.current_state:
        BeatEnemyCombatComponent.State.IDLE:
            target_color = idle_color
        BeatEnemyCombatComponent.State.TELEGRAPHING:
            target_color = telegraph_color
        BeatEnemyCombatComponent.State.ATTACKING:
            target_color = attack_color
        BeatEnemyCombatComponent.State.STUNNED:
            target_color = stunned_color
        BeatEnemyCombatComponent.State.DEAD:
            target_color = Color.BLACK

    # Apply color to mesh material
    if mesh and mesh.material_override:
        mesh.material_override.albedo_color = target_color

func _on_combat_state_changed(old_state: BeatEnemyCombatComponent.State, new_state: BeatEnemyCombatComponent.State):
    _update_visuals()
```

## Enemy Combat Component

### Purpose
- Manages enemy attack patterns
- Handles attack telegraphing
- Selects attacks based on context

### Enemy States

```
IDLE ──detect target──▶ TELEGRAPHING ──timer──▶ ATTACKING ──complete──▶ IDLE
  ▲                                                                       │
  └───────────recover──────────▶ STUNNED ◀─────take damage────────────────┘
                                    │
                                    ▼
                                  DEAD
```

### Attack Definition

```gdscript
# enemy/enemy_attack.gd
class_name BeatEnemyAttack
extends Resource

@export var attack_name: String = ""
@export var animation_sequence: Animation

# Timing
@export var telegraph_duration: float = 1.0  # Warning time
@export var attack_duration: float = 0.5     # Active attack window

# Damage
@export var damage: float = 20.0

# Range
@export var attack_range: float = 200.0
@export var attack_radius: float = 0.0  # AoE radius (0 = single target)

# Targeting
@export var requires_target: bool = true
@export var tracks_target_during_telegraph: bool = true
```

### Implementation

```gdscript
# enemy/enemy_combat.gd
class_name BeatEnemyCombatComponent
extends Node

signal state_changed(old_state: State, new_state: State)
signal attack_started(attack: BeatEnemyAttack)
signal attack_completed(attack: BeatEnemyAttack)
signal telegraph_started(attack: BeatEnemyAttack)

enum State { IDLE, TELEGRAPHING, ATTACKING, STUNNED, DEAD }

@export var attacks: Array[BeatEnemyAttack] = []
@export var attack_cooldown: float = 2.0
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

var current_state: State = State.IDLE
var current_attack: BeatEnemyAttack = null
var state_timer: float = 0.0
var cooldown_timer: float = 0.0

@onready var enemy: BeatEnemy = get_parent()

var _subscription_handle: int = -1

func _ready():
    # Subscribe to animation quants for attack timing
    _subscription_handle = Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.ANIMATION,
        _on_animation_quant
    )

func _exit_tree():
    if _subscription_handle >= 0:
        Sequencer.unsubscribe(_subscription_handle)

func _process(delta: float):
    # Update cooldown
    if cooldown_timer > 0:
        cooldown_timer -= delta

    # Update state timer
    match current_state:
        State.TELEGRAPHING:
            state_timer -= delta
            if state_timer <= 0:
                _start_attack()

        State.ATTACKING:
            state_timer -= delta
            if state_timer <= 0:
                _complete_attack()

func _on_animation_quant(event: SequencerEvent):
    # Try to start attack on beat
    if current_state == State.IDLE and cooldown_timer <= 0:
        _try_start_attack()

func _try_start_attack():
    if not enemy.target:
        return

    # Select attack based on context
    var attack = _select_attack()
    if not attack:
        return

    _start_telegraph(attack)

func _select_attack() -> BeatEnemyAttack:
    var target_distance = enemy.global_position.distance_to(enemy.target.global_position)

    var valid_attacks: Array[BeatEnemyAttack] = []

    for attack in attacks:
        if target_distance <= attack.attack_range:
            valid_attacks.append(attack)

    if valid_attacks.is_empty():
        return null

    # Random selection (could be weighted)
    return valid_attacks[randi() % valid_attacks.size()]

func _start_telegraph(attack: BeatEnemyAttack):
    current_attack = attack
    state_timer = attack.telegraph_duration
    set_state(State.TELEGRAPHING)
    telegraph_started.emit(attack)

func _start_attack():
    if not current_attack:
        return

    state_timer = current_attack.attack_duration
    set_state(State.ATTACKING)
    attack_started.emit(current_attack)

    # Deal damage at end of attack
    # (Or use hitbox component for more accurate detection)

func _complete_attack():
    var completed = current_attack
    current_attack = null
    cooldown_timer = attack_cooldown
    set_state(State.IDLE)
    attack_completed.emit(completed)

func set_state(new_state: State):
    var old_state = current_state
    current_state = new_state
    state_changed.emit(old_state, new_state)

# === External Control ===

func force_attack(attack: BeatEnemyAttack):
    if current_state != State.IDLE:
        return
    _start_telegraph(attack)

func cancel_attack():
    current_attack = null
    set_state(State.IDLE)
```

## Boss System

### Purpose
- Multi-phase boss battles
- Health-based phase transitions
- Special attack system
- Invulnerability periods

### Boss Definition

```gdscript
# boss/boss_types.gd
class_name BeatBossTypes

class BossPhase:
    var phase_name: String = ""
    var health_threshold: float = 1.0  # Phase triggers when health drops below this %
    var attacks: Array[BeatEnemyAttack] = []
    var duration_seconds: float = 0.0  # 0 = until health threshold
    var can_use_special_attacks: bool = false

class BossDefinition:
    var boss_name: String = ""
    var phases: Array[BossPhase] = []
```

### Boss Implementation

```gdscript
# boss/beat_boss.gd
class_name BeatBoss
extends BeatEnemy

signal phase_changed(old_phase: int, new_phase: int)
signal boss_defeated()
signal special_attack_executed(attack_name: String)

enum BossState { INACTIVE, ACTIVE, TRANSITIONING, DEFEATED }

@export var boss_definition: Resource  # BeatBossDefinition resource

var boss_state: BossState = BossState.INACTIVE
var current_phase_index: int = 0
var is_invulnerable: bool = false

# Special attack cooldowns
var attack_cooldowns: Dictionary = {}  # attack_name -> remaining_cooldown

func _ready():
    super._ready()
    health_changed.connect(_on_health_changed)

func _process(delta: float):
    super._process(delta)

    # Update special attack cooldowns
    for attack_name in attack_cooldowns.keys():
        attack_cooldowns[attack_name] -= delta
        if attack_cooldowns[attack_name] <= 0:
            attack_cooldowns.erase(attack_name)

func activate():
    if boss_state != BossState.INACTIVE:
        return

    boss_state = BossState.ACTIVE
    current_phase_index = 0
    _apply_phase(0)

func _on_health_changed(current: float, max_hp: float):
    if boss_state != BossState.ACTIVE:
        return

    var health_percent = current / max_hp

    # Check for phase transition
    _check_phase_transition(health_percent)

    # Check for defeat
    if current <= 0:
        _defeat()

func _check_phase_transition(health_percent: float):
    var phases = boss_definition.phases if boss_definition else []

    for i in range(current_phase_index + 1, phases.size()):
        var phase = phases[i]
        if health_percent <= phase.health_threshold:
            _transition_to_phase(i)
            return

func _transition_to_phase(phase_index: int):
    if phase_index == current_phase_index:
        return

    boss_state = BossState.TRANSITIONING
    is_invulnerable = true

    # Play transition animation
    if animation_player.has_animation("phase_transition"):
        animation_player.play("phase_transition")
        await animation_player.animation_finished

    var old_phase = current_phase_index
    current_phase_index = phase_index

    _apply_phase(phase_index)

    is_invulnerable = false
    boss_state = BossState.ACTIVE

    phase_changed.emit(old_phase, phase_index)

func _apply_phase(phase_index: int):
    var phases = boss_definition.phases if boss_definition else []
    if phase_index >= phases.size():
        return

    var phase = phases[phase_index]

    # Update combat component's attack list
    combat_component.attacks = phase.attacks

func _defeat():
    boss_state = BossState.DEFEATED
    is_invulnerable = true
    combat_component.set_state(BeatEnemyCombatComponent.State.DEAD)
    boss_defeated.emit()

# === Special Attacks ===

func execute_special_attack(attack_name: String):
    if boss_state != BossState.ACTIVE:
        return

    if attack_cooldowns.has(attack_name):
        return  # Still on cooldown

    var phases = boss_definition.phases if boss_definition else []
    var current_phase = phases[current_phase_index] if current_phase_index < phases.size() else null

    if not current_phase or not current_phase.can_use_special_attacks:
        return

    # Find and execute special attack
    # (Implementation depends on how special attacks are defined)

    special_attack_executed.emit(attack_name)

# === Override Damage ===

func take_damage(amount: float, source: Node3D = null):
    if is_invulnerable:
        return

    super.take_damage(amount, source)

# === State Queries ===

func get_current_phase() -> int:
    return current_phase_index

func get_phase_count() -> int:
    var phases = boss_definition.phases if boss_definition else []
    return phases.size()

func is_in_phase_transition() -> bool:
    return boss_state == BossState.TRANSITIONING

func set_invulnerable(value: bool):
    is_invulnerable = value
```

## Arena Management

### Purpose
- Manages enemy spawning and lifecycle
- Tracks arena state (waves, enemies remaining)
- Handles wave completion logic

### Spawn Configuration

```gdscript
# level/arena_spawn_config.gd
class_name ArenaSpawnConfig
extends Resource

@export var spawn_point: Node3D
@export var enemy_class: PackedScene
@export var count: int = 1
@export var delay_between_spawns: float = 0.5
```

### Arena Manager

```gdscript
# level/arena_manager.gd
class_name BeatArenaManagerComponent
extends Node

signal arena_state_changed(old_state: ArenaState, new_state: ArenaState)
signal enemy_defeated(enemy: BeatEnemy)
signal arena_cleared()
signal wave_started(wave_number: int)

enum ArenaState { INACTIVE, ACTIVE, WAVECLEAR, COOLDOWN }

@export var arena_bounds: Vector3 = Vector3(1000, 500, 1000)
@export var spawn_points: Array[Node3D] = []
@export var post_clear_delay: float = 2.0

var arena_state: ArenaState = ArenaState.INACTIVE
var enemies_remaining: int = 0
var total_enemies_spawned: int = 0
var total_enemies_defeated: int = 0
var current_wave: int = 0

var _active_enemies: Array[BeatEnemy] = []

func activate():
    arena_state = ArenaState.ACTIVE
    arena_state_changed.emit(ArenaState.INACTIVE, ArenaState.ACTIVE)

func deactivate():
    var old_state = arena_state
    arena_state = ArenaState.INACTIVE
    arena_state_changed.emit(old_state, ArenaState.INACTIVE)

func spawn_wave(configs: Array[ArenaSpawnConfig]):
    if arena_state != ArenaState.ACTIVE:
        return

    current_wave += 1
    wave_started.emit(current_wave)

    for config in configs:
        spawn_enemies(config)

func spawn_enemies(config: ArenaSpawnConfig):
    for i in range(config.count):
        await get_tree().create_timer(config.delay_between_spawns).timeout
        _spawn_single(config)

func _spawn_single(config: ArenaSpawnConfig):
    var enemy_instance = config.enemy_class.instantiate() as BeatEnemy
    if not enemy_instance:
        return

    # Position at spawn point
    var spawn_pos = config.spawn_point.global_position if config.spawn_point else Vector3.ZERO
    enemy_instance.global_position = spawn_pos

    # Register and track
    register_enemy(enemy_instance)

    # Add to scene
    get_tree().current_scene.add_child(enemy_instance)

func register_enemy(enemy: BeatEnemy):
    if enemy in _active_enemies:
        return

    _active_enemies.append(enemy)
    enemies_remaining += 1
    total_enemies_spawned += 1

    enemy.on_death.connect(_on_enemy_death.bind(enemy))

func _on_enemy_death(enemy: BeatEnemy):
    _active_enemies.erase(enemy)
    enemies_remaining -= 1
    total_enemies_defeated += 1

    enemy_defeated.emit(enemy)

    _check_arena_cleared()

func _check_arena_cleared():
    if enemies_remaining <= 0 and arena_state == ArenaState.ACTIVE:
        _on_wave_clear()

func _on_wave_clear():
    arena_state = ArenaState.WAVECLEAR
    arena_state_changed.emit(ArenaState.ACTIVE, ArenaState.WAVECLEAR)
    arena_cleared.emit()

    # Cooldown before next wave
    arena_state = ArenaState.COOLDOWN

    await get_tree().create_timer(post_clear_delay).timeout

    arena_state = ArenaState.ACTIVE

# === Queries ===

func get_enemies_remaining() -> int:
    return enemies_remaining

func get_active_enemies() -> Array[BeatEnemy]:
    return _active_enemies

func is_arena_active() -> bool:
    return arena_state == ArenaState.ACTIVE
```

## Spawn Points

```gdscript
# level/spawn_point.gd
class_name BeatSpawnPoint
extends Marker3D

@export var spawn_radius: float = 50.0
@export var spawn_facing: Vector3 = Vector3.FORWARD

func get_spawn_position() -> Vector3:
    var offset = Vector3(
        randf_range(-spawn_radius, spawn_radius),
        0,
        randf_range(-spawn_radius, spawn_radius)
    )
    return global_position + offset

func get_spawn_rotation() -> float:
    return atan2(spawn_facing.x, spawn_facing.z)
```

## Enemy AI Behavior Tree (Optional)

For more complex enemy behavior, consider a simple state-based AI:

```gdscript
# enemy/enemy_ai.gd
class_name BeatEnemyAI
extends Node

enum AIState { IDLE, PURSUE, ATTACK, RETREAT, PATROL }

@export var enemy: BeatEnemy
@export var pursue_range: float = 800.0
@export var attack_range: float = 200.0
@export var retreat_health_threshold: float = 0.2

var ai_state: AIState = AIState.IDLE
var patrol_points: Array[Vector3] = []
var current_patrol_index: int = 0

func _process(delta: float):
    _update_ai_state()
    _execute_ai_state(delta)

func _update_ai_state():
    if not enemy.is_alive():
        return

    if enemy.is_stunned:
        return

    # Check for retreat
    if enemy.get_health_percent() <= retreat_health_threshold:
        ai_state = AIState.RETREAT
        return

    # Check for target
    if not enemy.target:
        ai_state = AIState.PATROL if patrol_points.size() > 0 else AIState.IDLE
        return

    var distance = enemy.global_position.distance_to(enemy.target.global_position)

    if distance <= attack_range:
        ai_state = AIState.ATTACK
    elif distance <= pursue_range:
        ai_state = AIState.PURSUE
    else:
        ai_state = AIState.IDLE

func _execute_ai_state(delta: float):
    match ai_state:
        AIState.IDLE:
            _do_idle()
        AIState.PURSUE:
            _do_pursue(delta)
        AIState.ATTACK:
            _do_attack()
        AIState.RETREAT:
            _do_retreat(delta)
        AIState.PATROL:
            _do_patrol(delta)

func _do_idle():
    # Stand still, look for targets
    pass

func _do_pursue(delta: float):
    if not enemy.target:
        return

    var direction = (enemy.target.global_position - enemy.global_position).normalized()
    enemy.velocity = direction * 300.0
    enemy.move_and_slide()

    # Face target
    enemy.look_at(enemy.target.global_position)

func _do_attack():
    # Combat component handles actual attack timing
    pass

func _do_retreat(delta: float):
    if not enemy.target:
        return

    var direction = (enemy.global_position - enemy.target.global_position).normalized()
    enemy.velocity = direction * 200.0
    enemy.move_and_slide()

func _do_patrol(delta: float):
    if patrol_points.is_empty():
        return

    var target_point = patrol_points[current_patrol_index]
    var direction = (target_point - enemy.global_position).normalized()
    enemy.velocity = direction * 150.0
    enemy.move_and_slide()

    # Check if reached point
    if enemy.global_position.distance_to(target_point) < 50.0:
        current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
```

## Scene Structure

### Enemy Scene
```
BeatEnemy (CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D
├── AnimationPlayer
├── BeatEnemyCombatComponent
├── BeatEnemyAI (optional)
├── HealthBar3D (optional)
└── TelegraphIndicator (optional)
```

### Boss Scene
```
BeatBoss (CharacterBody3D)
├── CollisionShape3D
├── MeshInstance3D
├── AnimationPlayer
├── BeatEnemyCombatComponent
├── BossHealthBar
├── PhaseIndicator
└── SpecialAttackVFX
```

### Arena Scene
```
Arena (Node3D)
├── BeatArenaManagerComponent
├── SpawnPoints
│   ├── SpawnPoint1
│   ├── SpawnPoint2
│   └── SpawnPoint3
├── ArenaBounds (Area3D)
├── Hazards (optional)
│   ├── Hazard1
│   └── Hazard2
└── ArenaHUD
```
