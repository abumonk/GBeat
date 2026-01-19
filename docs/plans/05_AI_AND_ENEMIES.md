# AI & Enemy System Plan

## Overview
Plans for creating intelligent, beat-aware enemies and challenging boss encounters.

---

## 1. Enemy Types

### 1.1 Basic Enemies

#### Grunt
- **Role**: Fodder enemy
- **Behavior**: Simple attack patterns
- **Beat Sync**: Attacks on every 4th beat
- **Weakness**: Any combo starter

#### Dancer
- **Role**: Evasive enemy
- **Behavior**: Dodges attacks, counterattacks
- **Beat Sync**: Dodges on offbeats
- **Weakness**: Feints and delays

#### Heavy
- **Role**: Tank enemy
- **Behavior**: Slow, powerful attacks
- **Beat Sync**: Attacks on bar starts
- **Weakness**: Requires combo to stagger

#### Sniper
- **Role**: Ranged enemy
- **Behavior**: Keeps distance, precise shots
- **Beat Sync**: Fires on specific pattern positions
- **Weakness**: Close combat

### 1.2 Elite Enemies

#### DJ
- **Role**: Support enemy
- **Behavior**: Buffs allies, changes music
- **Beat Sync**: Abilities on phrase changes
- **Weakness**: Focus fire when casting

#### Beatmaster
- **Role**: Mini-boss
- **Behavior**: Complex combo patterns
- **Beat Sync**: Full pattern awareness
- **Weakness**: Off-beat windows

#### Chorus
- **Role**: Group enemy
- **Behavior**: Coordinated attacks
- **Beat Sync**: Synchronized group patterns
- **Weakness**: Break formation

---

## 2. Enemy AI System

### 2.1 Beat Awareness
```gdscript
class EnemyAI:
    var beat_phase: float       # Current beat position
    var attack_beats: Array     # Preferred attack timings
    var dodge_beats: Array      # Preferred dodge timings
    var pattern_memory: Array   # Learned player patterns
```

### 2.2 Decision Making
```
Input
├── Beat Phase
├── Player Distance
├── Player State
├── Health %
├── Ally State
└── Pattern Position

Output
├── Attack
├── Defend
├── Dodge
├── Special
├── Retreat
└── Support
```

### 2.3 Difficulty Scaling

| Difficulty | Reaction Time | Pattern Complexity | Aggression |
|------------|---------------|-------------------|------------|
| Easy | Slow | Simple | Low |
| Normal | Medium | Standard | Medium |
| Hard | Fast | Complex | High |
| Expert | Instant | Adaptive | Max |

---

## 3. Boss Design

### 3.1 Boss Structure
```
Boss
├── Phase 1 (100-70% HP)
│   ├── Basic patterns
│   ├── 2-3 attack types
│   └── Generous windows
├── Phase 2 (70-40% HP)
│   ├── New attacks unlock
│   ├── Faster patterns
│   └── Environment changes
├── Phase 3 (40-10% HP)
│   ├── Full moveset
│   ├── Combo attacks
│   └── Desperation moves
└── Final Stand (10-0% HP)
    ├── Ultimate attack
    ├── Enrage mode
    └── Dramatic finale
```

### 3.2 Boss Types

#### The Conductor
- **Theme**: Classical/orchestral
- **Mechanic**: Controls music tempo
- **Attacks**: Sweeping area attacks
- **Gimmick**: Beat changes mid-fight

#### The Drop
- **Theme**: EDM/dubstep
- **Mechanic**: Build-up and drop
- **Attacks**: Builds pressure, huge burst
- **Gimmick**: Survive the drop

#### The Remix
- **Theme**: Multi-genre
- **Mechanic**: Style switching
- **Attacks**: Adapts to player style
- **Gimmick**: Learns your patterns

#### The Silence
- **Theme**: Ambient/horror
- **Mechanic**: Music fades
- **Attacks**: Attacks in silence
- **Gimmick**: No beat to help timing

### 3.3 Boss Telegraphs
- Visual indicator (glow, pose)
- Audio cue (buildup sound)
- Beat alignment (always on beat)
- Safe zone hints

---

## 4. AI Behaviors

### 4.1 Combat States
```
IDLE
├── Wait for aggro
└── Ambient animation

ALERT
├── Player detected
└── Move to engage

COMBAT
├── Attack execution
├── Defense timing
└── Pattern following

STAGGER
├── Vulnerable
└── Recovery animation

RETREAT
├── Low health
└── Reposition

SUPPORT
├── Buff allies
└── Heal/revive
```

### 4.2 Group Behaviors
- **Flanking**: Surround player
- **Focus Fire**: All attack together
- **Rotation**: Take turns attacking
- **Protection**: Guard weaker allies

### 4.3 Adaptive AI
- Track player tendencies
- Counter common patterns
- Adjust to player skill
- Learn from deaths

---

## 5. Encounter Design

### 5.1 Wave Structure
```
Wave 1: Introduction
├── 2-3 basic enemies
└── Learning opportunity

Wave 2: Escalation
├── 4-6 mixed enemies
└── New type introduced

Wave 3: Challenge
├── Elite + basics
└── Environmental hazards

Boss Wave:
├── Boss + occasional adds
└── Full mechanics
```

### 5.2 Spawn Patterns
- Beat-synced spawns
- Musical phrases = waves
- Crescendo = difficulty spike
- Bridge = rest period

### 5.3 Composition Rules
- Maximum simultaneous enemies
- Required enemy types
- Spawn point management
- Fair challenge principles

---

## 6. Enemy Visuals

### 6.1 Design Language
- Enemies pulse with beat
- Attack telegraphs glow
- Different colors = different types
- Clear silhouettes

### 6.2 Beat Visualization
- Enemies dance when idle
- Attack anticipation poses
- Hit reactions sync to beat
- Death animations musical

### 6.3 Feedback
- Clear hit confirmation
- Damage numbers optional
- Health bar design
- Stagger indicator

---

## 7. Technical Implementation

### 7.1 AI Architecture
```
EnemyManager
├── Spawn Controller
├── Group Coordinator
├── Beat Sync Handler
└── Difficulty Manager

Individual Enemy
├── State Machine
├── Beat Listener
├── Pattern Executor
└── Perception System
```

### 7.2 Performance
- Behavior tree optimization
- Pooled enemy instances
- LOD for distant enemies
- Batch AI updates

### 7.3 Debug Tools
- AI state visualizer
- Pattern debugger
- Timing analyzer
- Heat maps

---

## 8. Balance Considerations

### 8.1 Damage Numbers
- Player damage: 10-50 base
- Enemy health: 50-500
- Boss health: 5000-50000
- Scaling per difficulty

### 8.2 Timing Windows
| Window | Duration | Difficulty |
|--------|----------|------------|
| Early | 200ms | Easy |
| Core | 100ms | Normal |
| Perfect | 50ms | Hard |
| Frame | 16ms | Expert |

### 8.3 Recovery Times
- Player recovery: 0.5-1s
- Enemy recovery: 1-2s
- Boss recovery: 2-5s
- Stagger duration: 3-5s
