# Gameplay Expansion Plan

## Overview
This document outlines potential expansions to GBeat's core gameplay mechanics.

---

## 1. Advanced Combo System

### Current State
- Basic combo counter with timeout
- Timing-based multipliers (Perfect, Great, Good)

### Proposed Enhancements

#### 1.1 Combo Chains
- **Chain Types**: Define specific attack sequences that grant bonuses
- **Finishers**: Special moves available at high combo counts
- **Branch Points**: Allow combo paths to split based on input

```
Light → Light → Heavy (Standard)
Light → Light → Dodge → Heavy (Advanced)
Light → Heavy → Light → Special (Expert)
```

#### 1.2 Rhythm Chains
- Execute attacks on consecutive perfect beats for chain bonus
- Miss a beat = chain breaks
- Chain multiplier stacks with combo multiplier

#### 1.3 Style System
- Track variety of attacks used
- Higher style rank = better rewards
- Penalize repetitive spam

---

## 2. Environmental Interaction

### 2.1 Reactive Arena Elements
- **Hazard Tiles**: Activate on specific beats
- **Jump Pads**: Launch player on beat sync
- **Shield Walls**: Temporary cover that pulses with music
- **Energy Wells**: Restore health/ability on beat

### 2.2 Destructible Environment
- Breakable objects tied to rhythm
- Chain destruction combos
- Environmental damage to enemies

### 2.3 Dynamic Level Events
- Platforms that move to beat
- Rotating obstacles
- Rising/falling floor sections

---

## 3. Multiplayer Modes

### 3.1 Cooperative
- 2-4 player co-op
- Synchronized attacks for bonus damage
- Revival mechanics tied to beat timing
- Shared combo meter

### 3.2 Competitive
- **Rhythm Duel**: Face-off combat with shared beat
- **Score Attack**: Compete for highest combo/style
- **Battle Royale**: Last dancer standing
- **Dance Battle**: Non-combat style competition

### 3.3 Asymmetric
- One player controls boss/DJ
- DJ controls music layers and hazards
- Players try to survive/defeat

---

## 4. Progression Systems

### 4.1 Character Progression
- Experience from combat
- Unlock new abilities
- Stat upgrades (health, damage, speed)
- Cosmetic rewards

### 4.2 Weapon Mastery
- Weapon-specific skill trees
- Unlock combos by using weapons
- Mastery bonuses

### 4.3 Achievement System
- Combo milestones
- Perfect run achievements
- Style challenges
- Secret discoveries

---

## 5. Game Modes

### 5.1 Story Mode
- Campaign with narrative
- Boss encounters with unique mechanics
- Cutscenes synced to music

### 5.2 Endless Mode
- Survive as long as possible
- Escalating difficulty
- Random pattern generation

### 5.3 Challenge Mode
- Specific objectives
- Time attacks
- No-damage runs
- Handicap challenges

### 5.4 Practice Mode
- Slow motion option
- Visual beat guides
- Combo practice
- Boss pattern learning

---

## 6. Accessibility Features

### 6.1 Visual Aids
- Beat indicators on screen
- Color-blind modes
- High contrast option
- Screen flash reduction

### 6.2 Audio Aids
- Haptic feedback for beats
- Audio cues for timing
- Adjustable timing windows

### 6.3 Difficulty Options
- Timing window adjustment
- Damage scaling
- Auto-combo option
- Assist mode

---

## Implementation Priority

| Feature | Effort | Impact | Priority |
|---------|--------|--------|----------|
| Combo Chains | Medium | High | 1 |
| Practice Mode | Low | High | 1 |
| Environmental Hazards | Medium | Medium | 2 |
| Accessibility | Medium | High | 2 |
| Co-op Multiplayer | High | High | 3 |
| Endless Mode | Low | Medium | 3 |
| Competitive Modes | High | Medium | 4 |
| Story Mode | Very High | High | 5 |

---

## Technical Requirements

- Network code for multiplayer
- Level editor for custom arenas
- Replay system for sharing
- Leaderboard backend
- Analytics for balancing
