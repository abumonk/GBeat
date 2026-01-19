# BeatBeat Development Plan

## Overview

This document outlines the phased development approach for implementing BeatBeat in Godot Engine 4.x, based on the original UE5 documentation.

---

## Phase 1: Core Foundation

**Goal**: Establish the fundamental beat sequencer system that all other systems depend on.

### 1.1 Project Setup
- [ ] Initialize Godot 4.x project with recommended settings
- [ ] Configure project structure (folders as per documentation)
- [ ] Set up AutoLoad singletons in project.godot
- [ ] Configure input mappings for movement, combat, and abilities

### 1.2 Core Data Structures
- [ ] Implement `Quant` resource class with Type enum and properties
- [ ] Implement `QuantCursor` for position tracking
- [ ] Implement `Bar` helper class for bar caching
- [ ] Implement `SequencerEvent` for event data

### 1.3 Pattern System
- [ ] Implement `Pattern` resource with:
  - JSON serialization/deserialization
  - Bar and layer caching
  - Position-based quant lookup
- [ ] Implement `PatternCollection` for pattern registry
- [ ] Implement `WaveCollection` for audio registry

### 1.4 Deck System
- [ ] Implement `Deck` node with state machine (IDLE, READY, PLAYING, PAUSED, QUEUED_TRANSITION)
- [ ] Implement precise timing using `_process()` or AudioServer
- [ ] Implement pattern transition at bar boundaries
- [ ] Implement audio playback synchronization

### 1.5 Subscription Store
- [ ] Implement `SubscriptionStore` with callback management
- [ ] Implement filtering by deck and quant type
- [ ] Implement required layers validation

### 1.6 Sequencer Singleton
- [ ] Implement `Sequencer` AutoLoad with:
  - Menu and Game decks
  - Subscription API
  - Pattern playback API
  - Query API for timing information

**Deliverable**: Working beat sequencer that can play patterns and emit events to subscribers.

---

## Phase 2: Character & Movement

**Goal**: Implement the player character with beat-quantized movement.

### 2.1 Player Character Base
- [ ] Create Player scene (CharacterBody3D)
- [ ] Set up collision shape and visual mesh
- [ ] Configure AnimationPlayer
- [ ] Implement dual camera system (top-down and side view)

### 2.2 Input System
- [ ] Implement `InputBuffer` for raw input capture
- [ ] Implement `PlayerController` with:
  - Continuous input capture
  - Input quantization (dead zones, magnitude steps, 8-direction)
  - Camera-relative direction transformation
  - Beat-boundary latching

### 2.3 Movement Component
- [ ] Implement `BeatMovementComponent` with:
  - Sequencer subscriptions for speed quants
  - Velocity application
  - Rotation handling

### 2.4 Movement Animation System
- [ ] Create `MovementStepDefinition` resource with:
  - Animation reference
  - Root motion data
  - Foot contact tracking
  - Speed ranges and facing limits
- [ ] Implement `BeatMovementAnimComponent` with:
  - Candidate filtering
  - Direction and continuity scoring
  - Playback plan generation
- [ ] Create `MovementStepPlaybackPlan` for execution data

### 2.5 Camera Controller
- [ ] Implement camera switching with smooth blends
- [ ] Configure SpringArm3D for both camera modes

**Deliverable**: Playable character with beat-synchronized movement and camera control.

---

## Phase 3: Combat System

**Goal**: Implement rhythm-based combat with timing feedback.

### 3.1 Combat Types
- [ ] Create combat type enums (ActionType, TimingRating, WindowType)
- [ ] Implement `CombatStepDefinition` extending movement steps
- [ ] Implement `CombatStepPlaybackPlan` with damage and timing data
- [ ] Implement `BeatHitResult` for hit information

### 3.2 Combat Animation Component
- [ ] Implement `BeatCombatAnimComponent` with:
  - Action window management (open/close/timing)
  - Timing quality calculation
  - Combat step selection based on range and combo
  - Timing multiplier application

### 3.3 Combo System
- [ ] Implement combo counter with multiplier
- [ ] Implement combo timeout and drop mechanics
- [ ] Implement combo link validation for step chaining

### 3.4 Hitbox Component
- [ ] Implement `BeatMeleeHitboxComponent` with:
  - Frame-accurate activation
  - ShapeCast3D-based detection
  - Hit cooldown per target
  - Hit result building

### 3.5 Weapon System
- [ ] Create `MeleeWeaponData` resource
- [ ] Implement weapon equipment and stats application

### 3.6 Combat UI
- [ ] Implement `TimingFeedbackUI` for rating display
- [ ] Implement `ComboCounterUI` for combo visualization

**Deliverable**: Functional combat system with timing feedback and combo mechanics.

---

## Phase 4: Enemy System

**Goal**: Implement beat-aware enemies with telegraph and attack patterns.

### 4.1 Enemy Base Class
- [ ] Implement `BeatEnemy` (CharacterBody3D) with:
  - Health system with damage/heal
  - Target detection (range and angle)
  - Stun mechanics
  - Visual state feedback (color changes)

### 4.2 Enemy Combat Component
- [ ] Create `BeatEnemyAttack` resource for attack definitions
- [ ] Implement `BeatEnemyCombatComponent` with:
  - State machine (IDLE, TELEGRAPHING, ATTACKING, STUNNED, DEAD)
  - Beat-synchronized attack initiation
  - Attack selection based on range

### 4.3 Enemy AI (Optional)
- [ ] Implement `BeatEnemyAI` with basic states:
  - IDLE, PURSUE, ATTACK, RETREAT, PATROL
  - Navigation and target tracking

### 4.4 Arena Management
- [ ] Implement `BeatSpawnPoint` marker
- [ ] Implement `ArenaSpawnConfig` resource
- [ ] Implement `BeatArenaManagerComponent` with:
  - Wave spawning
  - Enemy registration and tracking
  - Arena state management

**Deliverable**: Functional enemies that attack in sync with beats.

---

## Phase 5: Audio Integration

**Goal**: Implement real-time beat detection and dynamic music.

### 5.1 Audio Types
- [ ] Create audio type enums (FrequencyBand, MusicState, MusicLayer)
- [ ] Implement `BeatAudioSnapshot` for analysis data
- [ ] Implement `BeatAudioEvent` resource for sound events

### 5.2 Beat Detection
- [ ] Implement `BeatDetectionComponent` with:
  - Spectrum analyzer integration
  - Frequency band analysis (7 bands)
  - Beat detection based on bass energy
  - BPM estimation

### 5.3 Quartz Bridge
- [ ] Implement `BeatQuartzBridge` for:
  - Beat phase calculation
  - Timing grade calculation
  - Optional BPM auto-sync

### 5.4 Music Layer System
- [ ] Create `BeatMusicLayerConfig` resource
- [ ] Create `BeatMusicStateConfig` resource
- [ ] Implement `BeatMusicLayerComponent` with:
  - Multiple layer management
  - State-based volume transitions
  - Smooth fading

### 5.5 Reactive Audio
- [ ] Implement `BeatReactiveAudioComponent` with:
  - Sound event dictionary
  - Beat-synced playback queue
  - Pitch and volume variation

### 5.6 Audio Bus Setup
- [ ] Configure audio buses (Master, Music, SFX)
- [ ] Add SpectrumAnalyzer effect to Music bus

**Deliverable**: Dynamic music system responding to gameplay state.

---

## Phase 6: Environment & VFX

**Goal**: Implement beat-reactive visual feedback.

### 6.1 Lighting Floor
- [ ] Implement `BeatFloorTileComponent` with:
  - Color and emissive lerping
  - Pulse animation
- [ ] Implement `BeatColorPalette` resource
- [ ] Implement `BeatFloorReactionScript` resource
- [ ] Implement `BeatLightingFloorActor` with:
  - Dynamic grid generation
  - Reaction types (pulse, ripple, wave, random, strobe)
  - Automatic quant subscriptions

### 6.2 Screen Effects
- [ ] Implement `BeatScreenEffectsComponent` with:
  - Flash overlay
  - Damage vignette
  - Chromatic aberration
  - Saturation control

### 6.3 Camera Effects
- [ ] Implement `BeatCameraEffectsComponent` with:
  - Screen shake
  - FOV punch

### 6.4 Pulse Visualizer
- [ ] Implement `BeatPulseVisualizerComponent` for scale-based beat visualization

### 6.5 Shaders
- [ ] Create vignette shader
- [ ] Create chromatic aberration shader
- [ ] Create tile emissive shader

**Deliverable**: Visually reactive environment synchronized to beats.

---

## Phase 7: Save System & Abilities

**Goal**: Implement persistence and special abilities.

### 7.1 Save Data Structures
- [ ] Implement `PlayerProfile` class
- [ ] Implement `BeatSaveGame` resource

### 7.2 Save Manager
- [ ] Implement `BeatSaveManagerComponent` with:
  - Multiple save slots
  - Save/load operations (sync and async)
  - Auto-save functionality
  - Play time tracking
  - Statistics and achievements

### 7.3 Ability System
- [ ] Create `BeatAbilityData` resource
- [ ] Implement `BeatAbilityTypes` with definitions and states
- [ ] Implement `BeatAbilityComponent` with:
  - Ability registration
  - Slot equipment (4 slots)
  - Cooldown tracking (beat-based)
  - Resource management (mana/stamina)
  - Unlock conditions checking

### 7.4 Ability UI
- [ ] Implement `AbilitySlotUI` for slot display
- [ ] Implement `ResourceBarUI` for resource display

**Deliverable**: Working save system and ability management.

---

## Phase 8: Boss System

**Goal**: Implement multi-phase boss encounters.

### 8.1 Boss Definition
- [ ] Create `BossPhase` class with health threshold and attacks
- [ ] Create `BossDefinition` resource

### 8.2 Boss Implementation
- [ ] Implement `BeatBoss` extending BeatEnemy with:
  - Phase transitions based on health
  - Invulnerability during transitions
  - Phase-specific attack sets
  - Special attack system with cooldowns

### 8.3 Boss UI
- [ ] Implement boss health bar with phase indicators
- [ ] Implement phase transition visuals

**Deliverable**: Epic multi-phase boss battles.

---

## Phase 9: Polish & Integration

**Goal**: Final integration, optimization, and polish.

### 9.1 Game Flow
- [ ] Implement main menu scene
- [ ] Implement game scene with HUD
- [ ] Implement pause menu
- [ ] Implement game over / victory screens

### 9.2 HUD Integration
- [ ] Create unified HUD with:
  - Health bar
  - Combo counter
  - Ability slots
  - Resource bar
  - Timing feedback

### 9.3 Optimization
- [ ] Implement object pooling for enemies and effects
- [ ] Profile and optimize hot paths
- [ ] Optimize subscription filtering

### 9.4 Debug Tools
- [ ] Implement beat visualizer
- [ ] Implement state inspector
- [ ] Add debug overlay toggles

### 9.5 Testing
- [ ] Write unit tests for core systems
- [ ] Write integration tests for combat flow
- [ ] Playtest timing and feel

### 9.6 Export
- [ ] Configure export presets
- [ ] Build release version
- [ ] Test exported build

**Deliverable**: Polished, playable game ready for release.

---

## Implementation Priority Summary

1. **Sequencer System** - Foundation for everything (Phase 1)
2. **Pattern & Deck** - Beat playback (Phase 1)
3. **Character & Movement** - Player control (Phase 2)
4. **Combat System** - Core gameplay (Phase 3)
5. **Enemy System** - Opposition (Phase 4)
6. **Audio Integration** - Music sync (Phase 5)
7. **Environment** - Visual feedback (Phase 6)
8. **Save System** - Persistence (Phase 7)
9. **Boss System** - Advanced encounters (Phase 8)
10. **Polish** - Final touches (Phase 9)

---

## Notes

- Each phase builds on previous phases
- Test thoroughly before moving to next phase
- Keep performance in mind from the start
- Reference documentation in `/docs` for implementation details
- Use GUT for unit testing
