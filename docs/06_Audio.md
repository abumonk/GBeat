# Audio System

## Overview

The audio system provides:
- **Beat Detection**: Real-time analysis for dynamic patterns
- **Music Layers**: State-based dynamic music mixing
- **Quartz Bridge**: Synchronization between beat detection and sequencer
- **Reactive Audio**: Gameplay-responsive sound events

## Audio Types

```gdscript
# audio/audio_types.gd
class_name BeatAudioTypes

enum FrequencyBand {
    SUB_BASS,    # 20-60 Hz
    BASS,        # 60-250 Hz
    LOW_MID,     # 250-500 Hz
    MID,         # 500-2000 Hz
    HIGH_MID,    # 2000-4000 Hz
    PRESENCE,    # 4000-6000 Hz
    BRILLIANCE   # 6000-20000 Hz
}

enum MusicState {
    EXPLORATION,
    COMBAT,
    COMBAT_INTENSE,
    BOSS,
    VICTORY,
    DEFEAT
}

enum MusicLayer {
    AMBIENT,
    RHYTHM,
    MELODY,
    INTENSITY,
    BOSS
}
```

### Audio Snapshot

```gdscript
class_name BeatAudioSnapshot
extends RefCounted

var total_energy: float = 0.0
var band_energies: Array[float] = []  # 7 bands
var instant_bpm: float = 0.0
var beat_detected: bool = false
var beat_intensity: float = 0.0
var time_since_last_beat: float = 0.0
```

### Audio Event

```gdscript
class_name BeatAudioEvent
extends Resource

@export var sound: AudioStream
@export var sync_to_beat: bool = true
@export var pitch_variation: float = 0.0  # +/- range
@export var volume_multiplier: float = 1.0
@export var priority: int = 0
```

### Music Layer Configuration

```gdscript
class_name BeatMusicLayerConfig
extends Resource

@export var layer: BeatAudioTypes.MusicLayer
@export var sound: AudioStream
@export var base_volume: float = 1.0
@export var fade_in_time: float = 0.5
@export var fade_out_time: float = 0.5
@export var looping: bool = true
```

### Music State Configuration

```gdscript
class_name BeatMusicStateConfig
extends Resource

@export var state: BeatAudioTypes.MusicState
@export var layer_volumes: Dictionary = {}  # MusicLayer -> float
@export var transition_time: float = 1.0
```

## Beat Detection Component

### Purpose
- Analyzes audio in real-time
- Detects beat events
- Calculates frequency band energies
- Estimates BPM

### Implementation

```gdscript
# audio/beat_detection.gd
class_name BeatDetectionComponent
extends Node

signal beat_detected(intensity: float)
signal bpm_changed(bpm: float)
signal snapshot_updated(snapshot: BeatAudioSnapshot)

@export var audio_bus_name: String = "Master"
@export var sensitivity: float = 1.5
@export var min_beat_interval: float = 0.2  # seconds

# Analysis settings
@export var fft_size: int = 1024
@export var band_count: int = 7

var _spectrum_analyzer: AudioEffectSpectrumAnalyzerInstance
var _last_beat_time: float = 0.0
var _energy_history: Array[float] = []
var _history_size: int = 43  # ~1 second at 60fps

# BPM detection
var _beat_times: Array[float] = []
var _estimated_bpm: float = 120.0

var current_snapshot: BeatAudioSnapshot = BeatAudioSnapshot.new()

func _ready():
    # Get spectrum analyzer from audio bus
    var bus_idx = AudioServer.get_bus_index(audio_bus_name)
    if bus_idx >= 0:
        for i in range(AudioServer.get_bus_effect_count(bus_idx)):
            var effect = AudioServer.get_bus_effect(bus_idx, i)
            if effect is AudioEffectSpectrumAnalyzer:
                _spectrum_analyzer = AudioServer.get_bus_effect_instance(bus_idx, i)
                break

    current_snapshot.band_energies.resize(band_count)

func _process(delta: float):
    if not _spectrum_analyzer:
        return

    _analyze_spectrum()
    _detect_beat(delta)
    snapshot_updated.emit(current_snapshot)

func _analyze_spectrum():
    # Get frequency magnitudes for each band
    var band_ranges = [
        Vector2(20, 60),     # Sub bass
        Vector2(60, 250),    # Bass
        Vector2(250, 500),   # Low mid
        Vector2(500, 2000),  # Mid
        Vector2(2000, 4000), # High mid
        Vector2(4000, 6000), # Presence
        Vector2(6000, 20000) # Brilliance
    ]

    var total = 0.0

    for i in range(band_count):
        var mag = _spectrum_analyzer.get_magnitude_for_frequency_range(
            band_ranges[i].x,
            band_ranges[i].y
        ).length()

        current_snapshot.band_energies[i] = mag
        total += mag

    current_snapshot.total_energy = total

func _detect_beat(delta: float):
    current_snapshot.time_since_last_beat += delta
    current_snapshot.beat_detected = false

    # Use bass energy for beat detection
    var bass_energy = current_snapshot.band_energies[BeatAudioTypes.FrequencyBand.BASS]

    # Add to history
    _energy_history.append(bass_energy)
    if _energy_history.size() > _history_size:
        _energy_history.pop_front()

    # Calculate average
    var avg = 0.0
    for e in _energy_history:
        avg += e
    avg /= _energy_history.size()

    # Detect beat if energy exceeds threshold
    var threshold = avg * sensitivity
    var current_time = Time.get_ticks_msec() / 1000.0

    if bass_energy > threshold and (current_time - _last_beat_time) > min_beat_interval:
        _last_beat_time = current_time
        current_snapshot.beat_detected = true
        current_snapshot.beat_intensity = bass_energy / max(threshold, 0.001)
        current_snapshot.time_since_last_beat = 0.0

        _register_beat_for_bpm(current_time)
        beat_detected.emit(current_snapshot.beat_intensity)

func _register_beat_for_bpm(time: float):
    _beat_times.append(time)

    # Keep last 16 beats
    while _beat_times.size() > 16:
        _beat_times.pop_front()

    if _beat_times.size() >= 4:
        _calculate_bpm()

func _calculate_bpm():
    var intervals: Array[float] = []

    for i in range(1, _beat_times.size()):
        intervals.append(_beat_times[i] - _beat_times[i-1])

    # Average interval
    var avg_interval = 0.0
    for interval in intervals:
        avg_interval += interval
    avg_interval /= intervals.size()

    var new_bpm = 60.0 / avg_interval

    # Clamp to reasonable range
    new_bpm = clamp(new_bpm, 60, 200)

    if abs(new_bpm - _estimated_bpm) > 5:
        _estimated_bpm = new_bpm
        current_snapshot.instant_bpm = new_bpm
        bpm_changed.emit(new_bpm)

# === Public API ===

func get_band_energy(band: BeatAudioTypes.FrequencyBand) -> float:
    if band < current_snapshot.band_energies.size():
        return current_snapshot.band_energies[band]
    return 0.0

func get_total_energy() -> float:
    return current_snapshot.total_energy

func get_estimated_bpm() -> float:
    return _estimated_bpm

func is_beat() -> bool:
    return current_snapshot.beat_detected
```

## Quartz Bridge

### Purpose
- Bridges beat detection with sequencer timing
- Provides beat phase for timing calculations
- Syncs Quartz clock to detected BPM

### Implementation

```gdscript
# audio/quartz_bridge.gd
class_name BeatQuartzBridge
extends Node

signal on_beat_phase_update(phase: float)
signal timing_grade_calculated(grade: CombatTypes.TimingRating)

@export var beat_detection: BeatDetectionComponent
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

# Timing tolerance
@export var on_beat_tolerance: float = 0.1  # seconds

# Auto sync
@export var auto_sync_bpm: bool = false
@export var bpm_sync_threshold: float = 5.0  # BPM difference to trigger sync

# State
var current_bpm: float = 120.0
var time_to_next_beat: float = 0.0
var time_since_last_beat: float = 0.0
var beat_phase: float = 0.0  # 0-1 normalized
var is_on_beat: bool = false

func _ready():
    if beat_detection:
        beat_detection.beat_detected.connect(_on_beat_detected)
        beat_detection.bpm_changed.connect(_on_bpm_changed)

func _process(delta: float):
    _update_beat_phase(delta)

func _update_beat_phase(delta: float):
    time_since_last_beat += delta

    var beat_duration = 60.0 / current_bpm
    beat_phase = fmod(time_since_last_beat, beat_duration) / beat_duration
    time_to_next_beat = beat_duration - fmod(time_since_last_beat, beat_duration)

    is_on_beat = time_to_next_beat < on_beat_tolerance or time_since_last_beat < on_beat_tolerance

    on_beat_phase_update.emit(beat_phase)

func _on_beat_detected(intensity: float):
    time_since_last_beat = 0.0

func _on_bpm_changed(new_bpm: float):
    if auto_sync_bpm and abs(new_bpm - current_bpm) > bpm_sync_threshold:
        sync_to_bpm(new_bpm)

func sync_to_bpm(bpm: float):
    current_bpm = bpm

    # Update sequencer deck's pattern BPM
    var deck = Sequencer.get_deck(sequencer_deck)
    if deck and deck.current_pattern:
        deck.current_pattern.bpm = bpm
        # Deck would need to recalculate quant duration

func connect_to_detection(detection: BeatDetectionComponent):
    if beat_detection:
        beat_detection.beat_detected.disconnect(_on_beat_detected)
        beat_detection.bpm_changed.disconnect(_on_bpm_changed)

    beat_detection = detection
    beat_detection.beat_detected.connect(_on_beat_detected)
    beat_detection.bpm_changed.connect(_on_bpm_changed)

func set_bpm(bpm: float):
    current_bpm = bpm

# === Timing Grade ===

func get_timing_grade() -> CombatTypes.TimingRating:
    var beat_duration = 60.0 / current_bpm

    # Distance from nearest beat
    var distance = min(time_since_last_beat, time_to_next_beat)
    var normalized = distance / (beat_duration / 2.0)

    # Convert to quality (1 = perfect, 0 = worst)
    var quality = 1.0 - normalized

    if quality >= 0.95:
        return CombatTypes.TimingRating.PERFECT
    elif quality >= 0.85:
        return CombatTypes.TimingRating.GREAT
    elif quality >= 0.65:
        return CombatTypes.TimingRating.GOOD
    elif time_since_last_beat < time_to_next_beat:
        return CombatTypes.TimingRating.LATE
    else:
        return CombatTypes.TimingRating.EARLY

func get_beat_phase() -> float:
    return beat_phase

func get_time_to_next_beat() -> float:
    return time_to_next_beat
```

## Music Layer Component

### Purpose
- Manages multiple music layers
- Transitions between music states
- Fades layers in/out based on gameplay

### Implementation

```gdscript
# audio/music_layer.gd
class_name BeatMusicLayerComponent
extends Node

signal state_changed(old_state: BeatAudioTypes.MusicState, new_state: BeatAudioTypes.MusicState)
signal layer_volume_changed(layer: BeatAudioTypes.MusicLayer, volume: float)

@export var layer_configs: Array[BeatMusicLayerConfig] = []
@export var state_configs: Array[BeatMusicStateConfig] = []
@export var initial_state: BeatAudioTypes.MusicState = BeatAudioTypes.MusicState.EXPLORATION

var current_state: BeatAudioTypes.MusicState
var _layer_players: Dictionary = {}  # MusicLayer -> AudioStreamPlayer
var _layer_volumes: Dictionary = {}  # MusicLayer -> current volume
var _target_volumes: Dictionary = {} # MusicLayer -> target volume
var _fade_speeds: Dictionary = {}    # MusicLayer -> fade speed

func _ready():
    _setup_layers()
    set_music_state(initial_state)

func _process(delta: float):
    _update_fades(delta)

func _setup_layers():
    for config in layer_configs:
        var player = AudioStreamPlayer.new()
        player.stream = config.sound
        player.volume_db = linear_to_db(0.0)  # Start silent

        if config.looping and config.sound is AudioStreamOggVorbis:
            config.sound.loop = true

        add_child(player)
        player.play()

        _layer_players[config.layer] = player
        _layer_volumes[config.layer] = 0.0
        _target_volumes[config.layer] = 0.0
        _fade_speeds[config.layer] = 1.0 / config.fade_in_time

func _update_fades(delta: float):
    for layer in _layer_volumes.keys():
        var current = _layer_volumes[layer]
        var target = _target_volumes[layer]

        if abs(current - target) < 0.01:
            _layer_volumes[layer] = target
        else:
            var speed = _fade_speeds[layer]
            _layer_volumes[layer] = move_toward(current, target, speed * delta)

        # Apply to player
        var player = _layer_players[layer] as AudioStreamPlayer
        if player:
            player.volume_db = linear_to_db(_layer_volumes[layer])

func set_music_state(state: BeatAudioTypes.MusicState):
    var old_state = current_state
    current_state = state

    # Find state config
    var config: BeatMusicStateConfig = null
    for sc in state_configs:
        if sc.state == state:
            config = sc
            break

    if not config:
        return

    # Apply layer volumes
    for layer in _layer_players.keys():
        var target_vol = config.layer_volumes.get(layer, 0.0)
        _target_volumes[layer] = target_vol

        # Calculate fade speed
        var layer_config = _get_layer_config(layer)
        if layer_config:
            var fade_time = target_vol > _layer_volumes[layer] ? layer_config.fade_in_time : layer_config.fade_out_time
            _fade_speeds[layer] = 1.0 / max(fade_time, 0.01)

    state_changed.emit(old_state, state)

func _get_layer_config(layer: BeatAudioTypes.MusicLayer) -> BeatMusicLayerConfig:
    for config in layer_configs:
        if config.layer == layer:
            return config
    return null

func set_layer_volume(layer: BeatAudioTypes.MusicLayer, volume: float, fade_time: float = 0.5):
    _target_volumes[layer] = volume
    _fade_speeds[layer] = 1.0 / max(fade_time, 0.01)
    layer_volume_changed.emit(layer, volume)

func get_layer_volume(layer: BeatAudioTypes.MusicLayer) -> float:
    return _layer_volumes.get(layer, 0.0)

func stop_all():
    for player in _layer_players.values():
        player.stop()

func restart_all():
    for player in _layer_players.values():
        player.play()
```

## Reactive Audio Component

### Purpose
- Plays sound events in response to gameplay
- Supports beat-synced playback
- Handles pitch/volume variation

### Implementation

```gdscript
# audio/reactive_audio.gd
class_name BeatReactiveAudioComponent
extends Node

@export var audio_events: Dictionary = {}  # event_name -> BeatAudioEvent
@export var max_simultaneous_sounds: int = 8
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

var _players: Array[AudioStreamPlayer] = []
var _queued_events: Array[BeatAudioEvent] = []

func _ready():
    # Create player pool
    for i in range(max_simultaneous_sounds):
        var player = AudioStreamPlayer.new()
        add_child(player)
        _players.append(player)

    # Subscribe to tick for beat-synced playback
    Sequencer.subscribe(
        sequencer_deck,
        Quant.Type.TICK,
        _on_tick
    )

func _on_tick(event: SequencerEvent):
    # Play queued beat-synced events
    for audio_event in _queued_events:
        _play_event_now(audio_event)
    _queued_events.clear()

func play_event(event_name: String):
    var audio_event = audio_events.get(event_name) as BeatAudioEvent
    if not audio_event:
        return

    if audio_event.sync_to_beat:
        _queued_events.append(audio_event)
    else:
        _play_event_now(audio_event)

func play_audio_event(audio_event: BeatAudioEvent):
    if audio_event.sync_to_beat:
        _queued_events.append(audio_event)
    else:
        _play_event_now(audio_event)

func _play_event_now(audio_event: BeatAudioEvent):
    var player = _get_available_player()
    if not player:
        return

    player.stream = audio_event.sound

    # Apply pitch variation
    if audio_event.pitch_variation > 0:
        player.pitch_scale = 1.0 + randf_range(-audio_event.pitch_variation, audio_event.pitch_variation)
    else:
        player.pitch_scale = 1.0

    # Apply volume
    player.volume_db = linear_to_db(audio_event.volume_multiplier)

    player.play()

func _get_available_player() -> AudioStreamPlayer:
    for player in _players:
        if not player.playing:
            return player

    # All busy - steal lowest priority (simplified: just return first)
    return _players[0]

func stop_all():
    for player in _players:
        player.stop()
    _queued_events.clear()
```

## Audio Bus Setup

For proper audio analysis, set up the Godot audio bus:

```
Master
├── Music
│   └── SpectrumAnalyzer (AudioEffectSpectrumAnalyzer)
├── SFX
└── Voice
```

## Usage Example

```gdscript
# game_manager.gd
extends Node

@onready var beat_detection: BeatDetectionComponent = $BeatDetection
@onready var quartz_bridge: BeatQuartzBridge = $QuartzBridge
@onready var music_layers: BeatMusicLayerComponent = $MusicLayers
@onready var reactive_audio: BeatReactiveAudioComponent = $ReactiveAudio

func _ready():
    # Connect beat detection to visual effects
    beat_detection.beat_detected.connect(_on_beat)

    # Start with exploration music
    music_layers.set_music_state(BeatAudioTypes.MusicState.EXPLORATION)

func _on_beat(intensity: float):
    # Pulse visuals on beat
    $LightingFloor.trigger_pulse(intensity)

func enter_combat():
    music_layers.set_music_state(BeatAudioTypes.MusicState.COMBAT)

func enter_boss_fight():
    music_layers.set_music_state(BeatAudioTypes.MusicState.BOSS)

func play_hit_sound():
    reactive_audio.play_event("hit_normal")

func play_perfect_hit_sound():
    reactive_audio.play_event("hit_perfect")
```

## Scene Structure

```
AudioManager (Node)
├── BeatDetectionComponent
├── BeatQuartzBridge
├── BeatMusicLayerComponent
│   └── (AudioStreamPlayers created dynamically)
└── BeatReactiveAudioComponent
    └── (AudioStreamPlayer pool)
```
