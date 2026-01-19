# Environment & Visual Effects

## Overview

The environment system provides:
- **Lighting Floor**: Beat-synchronized grid lighting
- **Screen Effects**: Post-process effects for feedback
- **Pulse Visualizer**: Beat-reactive visual elements
- **Camera Effects**: Shake and FOV effects

## Lighting Floor

### Purpose
- Grid-based floor with beat-synchronized lighting
- Multiple reaction types (pulse, ripple, wave, strobe)
- Color palette support

### Floor Tile Component

```gdscript
# environment/floor_tile.gd
class_name BeatFloorTileComponent
extends Node3D

signal color_changed(new_color: Color)

@export var tile_mesh: MeshInstance3D
@export var base_color: Color = Color.WHITE
@export var emissive_intensity: float = 0.0

var _material: StandardMaterial3D
var _current_color: Color
var _target_color: Color
var _color_lerp_speed: float = 5.0
var _target_emissive: float = 0.0
var _emissive_lerp_speed: float = 10.0

func _ready():
    _setup_material()
    _current_color = base_color
    _target_color = base_color

func _setup_material():
    if tile_mesh:
        _material = StandardMaterial3D.new()
        _material.albedo_color = base_color
        _material.emission_enabled = true
        _material.emission = base_color
        _material.emission_energy_multiplier = emissive_intensity
        tile_mesh.material_override = _material

func _process(delta: float):
    # Lerp color
    _current_color = _current_color.lerp(_target_color, _color_lerp_speed * delta)
    _material.albedo_color = _current_color
    _material.emission = _current_color

    # Lerp emissive
    emissive_intensity = move_toward(emissive_intensity, _target_emissive, _emissive_lerp_speed * delta)
    _material.emission_energy_multiplier = emissive_intensity

func set_color(color: Color, instant: bool = false):
    _target_color = color
    if instant:
        _current_color = color
        _material.albedo_color = color
        _material.emission = color
    color_changed.emit(color)

func set_emissive(intensity: float, instant: bool = false):
    _target_emissive = intensity
    if instant:
        emissive_intensity = intensity
        _material.emission_energy_multiplier = intensity

func pulse(color: Color, intensity: float, duration: float):
    set_color(color, true)
    set_emissive(intensity, true)

    # Fade back
    var tween = create_tween()
    tween.tween_property(self, "_target_emissive", 0.0, duration)
    tween.parallel().tween_property(self, "_target_color", base_color, duration)

func get_grid_position() -> Vector2i:
    # Stored by parent
    return get_meta("grid_position", Vector2i.ZERO)
```

### Color Palette

```gdscript
# environment/color_palette.gd
class_name BeatColorPalette
extends Resource

@export var palette_name: String = ""
@export var colors: Array[Color] = [
    Color.RED,
    Color.ORANGE,
    Color.YELLOW,
    Color.GREEN,
    Color.CYAN,
    Color.BLUE,
    Color.PURPLE
]

func get_color(index: int) -> Color:
    if colors.is_empty():
        return Color.WHITE
    return colors[index % colors.size()]

func get_random_color() -> Color:
    if colors.is_empty():
        return Color.WHITE
    return colors[randi() % colors.size()]

func get_color_for_quant_type(type: Quant.Type) -> Color:
    # Map quant types to colors
    match type:
        Quant.Type.KICK:
            return get_color(0)  # Red
        Quant.Type.SNARE:
            return get_color(3)  # Green
        Quant.Type.HAT:
            return get_color(5)  # Blue
        Quant.Type.CRASH:
            return get_color(1)  # Orange
        _:
            return Color.WHITE
```

### Floor Reaction Script

```gdscript
# environment/floor_reaction_script.gd
class_name BeatFloorReactionScript
extends Resource

enum ReactionType {
    PULSE,      # Single tile flash
    RIPPLE,     # Expanding from center
    WAVE,       # Directional wave
    RANDOM,     # Random tiles
    STROBE,     # All tiles flash
    PATTERN     # Custom pattern
}

class ReactionEvent:
    var quant_type: Quant.Type
    var reaction_type: ReactionType
    var use_quant_value: bool = true
    var base_intensity: float = 1.0
    var color_override: Color = Color(-1, -1, -1, -1)  # Invalid = use palette
    var animate_tiles: bool = true
    var duration: float = 0.5

@export var reactions: Array[Resource] = []  # Array of ReactionEvent resources

func get_reaction_for_quant(quant_type: Quant.Type) -> ReactionEvent:
    for reaction in reactions:
        if reaction.quant_type == quant_type:
            return reaction
    return null
```

### Lighting Floor Actor

```gdscript
# environment/lighting_floor.gd
class_name BeatLightingFloorActor
extends Node3D

signal reaction_triggered(reaction_type: BeatFloorReactionScript.ReactionType)

# Grid settings
@export_range(1, 64) var grid_size_x: int = 16
@export_range(1, 64) var grid_size_y: int = 16
@export var tile_size: float = 100.0
@export var tile_gap: float = 5.0

# Visuals
@export var tile_mesh: Mesh
@export var tile_material: Material
@export var color_palette: BeatColorPalette

# Reactions
@export var reaction_script: BeatFloorReactionScript
@export var auto_subscribe: bool = true
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME

var tiles: Array[BeatFloorTileComponent] = []
var _subscription_handles: Array[int] = []

func _ready():
    build_grid()

    if auto_subscribe:
        _subscribe_to_quants()

func _exit_tree():
    for handle in _subscription_handles:
        Sequencer.unsubscribe(handle)

func build_grid():
    # Clear existing
    for tile in tiles:
        tile.queue_free()
    tiles.clear()

    # Calculate offset to center grid
    var total_width = grid_size_x * (tile_size + tile_gap) - tile_gap
    var total_depth = grid_size_y * (tile_size + tile_gap) - tile_gap
    var offset = Vector3(-total_width / 2.0, 0, -total_depth / 2.0)

    # Create tiles
    for y in range(grid_size_y):
        for x in range(grid_size_x):
            var tile = _create_tile(x, y, offset)
            tiles.append(tile)

func _create_tile(x: int, y: int, offset: Vector3) -> BeatFloorTileComponent:
    var tile_node = Node3D.new()
    tile_node.name = "Tile_%d_%d" % [x, y]
    add_child(tile_node)

    # Position
    var pos = Vector3(
        x * (tile_size + tile_gap) + tile_size / 2.0,
        0,
        y * (tile_size + tile_gap) + tile_size / 2.0
    ) + offset
    tile_node.position = pos

    # Mesh
    var mesh_instance = MeshInstance3D.new()
    mesh_instance.mesh = tile_mesh if tile_mesh else _create_default_mesh()
    tile_node.add_child(mesh_instance)

    # Tile component
    var tile_comp = BeatFloorTileComponent.new()
    tile_comp.tile_mesh = mesh_instance
    tile_node.add_child(tile_comp)

    tile_comp.set_meta("grid_position", Vector2i(x, y))

    return tile_comp

func _create_default_mesh() -> Mesh:
    var plane = PlaneMesh.new()
    plane.size = Vector2(tile_size, tile_size)
    return plane

func _subscribe_to_quants():
    if not reaction_script:
        return

    # Subscribe to each quant type in reaction script
    var subscribed_types: Array[Quant.Type] = []

    for reaction in reaction_script.reactions:
        if reaction.quant_type in subscribed_types:
            continue

        var handle = Sequencer.subscribe(
            sequencer_deck,
            reaction.quant_type,
            _on_quant_event
        )
        _subscription_handles.append(handle)
        subscribed_types.append(reaction.quant_type)

func _on_quant_event(event: SequencerEvent):
    if not reaction_script:
        return

    var reaction = reaction_script.get_reaction_for_quant(event.quant.type)
    if not reaction:
        return

    var intensity = reaction.base_intensity
    if reaction.use_quant_value:
        intensity *= event.quant.value

    var color = reaction.color_override
    if color.a < 0:  # Invalid color = use palette
        color = color_palette.get_color_for_quant_type(event.quant.type) if color_palette else Color.WHITE

    trigger_reaction(reaction.reaction_type, color, intensity, reaction.duration)

# === Public API ===

func get_tile_at(x: int, y: int) -> BeatFloorTileComponent:
    var index = y * grid_size_x + x
    if index >= 0 and index < tiles.size():
        return tiles[index]
    return null

func set_all_tiles_color(color: Color, instant: bool = false):
    for tile in tiles:
        tile.set_color(color, instant)

func set_tile_color(x: int, y: int, color: Color, instant: bool = false):
    var tile = get_tile_at(x, y)
    if tile:
        tile.set_color(color, instant)

func set_tile_emissive(x: int, y: int, intensity: float, instant: bool = false):
    var tile = get_tile_at(x, y)
    if tile:
        tile.set_emissive(intensity, instant)

func trigger_reaction(type: BeatFloorReactionScript.ReactionType, color: Color, intensity: float, duration: float):
    match type:
        BeatFloorReactionScript.ReactionType.PULSE:
            _trigger_pulse(color, intensity, duration)
        BeatFloorReactionScript.ReactionType.RIPPLE:
            _trigger_ripple(color, intensity, duration)
        BeatFloorReactionScript.ReactionType.WAVE:
            _trigger_wave(color, intensity, duration)
        BeatFloorReactionScript.ReactionType.RANDOM:
            _trigger_random(color, intensity, duration)
        BeatFloorReactionScript.ReactionType.STROBE:
            _trigger_strobe(color, intensity, duration)

    reaction_triggered.emit(type)

func _trigger_pulse(color: Color, intensity: float, duration: float):
    # Pulse center tile
    var center_x = grid_size_x / 2
    var center_y = grid_size_y / 2
    var tile = get_tile_at(center_x, center_y)
    if tile:
        tile.pulse(color, intensity, duration)

func _trigger_ripple(color: Color, intensity: float, duration: float):
    var center = Vector2(grid_size_x / 2.0, grid_size_y / 2.0)
    var max_dist = center.length()

    for tile in tiles:
        var pos = tile.get_grid_position()
        var dist = Vector2(pos).distance_to(center)
        var delay = (dist / max_dist) * duration * 0.5

        # Delayed pulse
        get_tree().create_timer(delay).timeout.connect(
            func(): tile.pulse(color, intensity * (1.0 - dist / max_dist), duration * 0.5)
        )

func _trigger_wave(color: Color, intensity: float, duration: float):
    # Wave from left to right
    for x in range(grid_size_x):
        var delay = (float(x) / grid_size_x) * duration * 0.5

        for y in range(grid_size_y):
            var tile = get_tile_at(x, y)
            if tile:
                get_tree().create_timer(delay).timeout.connect(
                    func(): tile.pulse(color, intensity, duration * 0.3)
                )

func _trigger_random(color: Color, intensity: float, duration: float):
    # Random subset of tiles
    var count = int(tiles.size() * 0.3)
    var indices = range(tiles.size())
    indices.shuffle()

    for i in range(count):
        tiles[indices[i]].pulse(color, intensity, duration)

func _trigger_strobe(color: Color, intensity: float, duration: float):
    for tile in tiles:
        tile.pulse(color, intensity, duration)

# === Convenience Methods ===

func pulse_tile(x: int, y: int, color: Color, intensity: float, duration: float):
    var tile = get_tile_at(x, y)
    if tile:
        tile.pulse(color, intensity, duration)

func trigger_ripple_from(center_x: int, center_y: int, color: Color, intensity: float, duration: float):
    var center = Vector2(center_x, center_y)
    var max_dist = Vector2(grid_size_x, grid_size_y).length()

    for tile in tiles:
        var pos = tile.get_grid_position()
        var dist = Vector2(pos).distance_to(center)
        var delay = (dist / max_dist) * duration * 0.5

        get_tree().create_timer(delay).timeout.connect(
            func(): tile.pulse(color, intensity * (1.0 - dist / max_dist), duration * 0.5)
        )
```

## Screen Effects

### Purpose
- Post-process effects for gameplay feedback
- Health-based visual indicators
- Timing and damage feedback

### Implementation

```gdscript
# vfx/screen_effects.gd
class_name BeatScreenEffectsComponent
extends Node

enum ScreenEffect {
    FLASH,
    CHROMATIC_ABERRATION,
    RADIAL_BLUR,
    SATURATION,
    DAMAGE_VIGNETTE
}

@export var camera: Camera3D
@export var environment: Environment

# Health vignette
@export var low_health_threshold: float = 0.3
@export var vignette_pulse_rate: float = 2.0
@export var max_vignette_intensity: float = 0.5

var _flash_overlay: ColorRect
var _vignette_material: ShaderMaterial
var _current_health: float = 1.0
var _vignette_time: float = 0.0

func _ready():
    _setup_flash_overlay()
    _setup_vignette()

func _setup_flash_overlay():
    _flash_overlay = ColorRect.new()
    _flash_overlay.color = Color(1, 1, 1, 0)
    _flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _flash_overlay.anchors_preset = Control.PRESET_FULL_RECT

    # Add to CanvasLayer for screen-space
    var canvas = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)
    canvas.add_child(_flash_overlay)

func _setup_vignette():
    # Vignette would be a shader on a full-screen ColorRect
    # or part of the Environment's post-processing
    pass

func _process(delta: float):
    _update_damage_vignette(delta)

func _update_damage_vignette(delta: float):
    if _current_health > low_health_threshold:
        return

    _vignette_time += delta * vignette_pulse_rate
    var pulse = (sin(_vignette_time * TAU) + 1.0) * 0.5

    var health_factor = 1.0 - (_current_health / low_health_threshold)
    var intensity = health_factor * max_vignette_intensity * pulse

    # Apply to vignette material/shader
    if _vignette_material:
        _vignette_material.set_shader_parameter("intensity", intensity)

# === Public API ===

func trigger_effect(effect: ScreenEffect, intensity: float = 1.0, duration: float = 0.2):
    match effect:
        ScreenEffect.FLASH:
            flash_screen(Color.WHITE, duration, intensity)
        ScreenEffect.CHROMATIC_ABERRATION:
            set_chromatic_aberration(intensity, duration)
        ScreenEffect.RADIAL_BLUR:
            set_radial_blur(intensity, duration)
        ScreenEffect.SATURATION:
            set_saturation(intensity, duration)

func flash_screen(color: Color, duration: float, intensity: float = 1.0):
    _flash_overlay.color = Color(color.r, color.g, color.b, intensity)

    var tween = create_tween()
    tween.tween_property(_flash_overlay, "color:a", 0.0, duration)

func set_damage_vignette(health_percent: float):
    _current_health = health_percent

func set_chromatic_aberration(intensity: float, duration: float = 0.0):
    # Would apply to post-process shader
    pass

func set_radial_blur(intensity: float, duration: float = 0.0):
    # Would apply to post-process shader
    pass

func set_saturation(value: float, duration: float = 0.0):
    if environment:
        var tween = create_tween()
        tween.tween_property(environment, "adjustment_saturation", value, duration)

func clear_all_effects():
    _flash_overlay.color.a = 0
    _current_health = 1.0
    if environment:
        environment.adjustment_saturation = 1.0
```

## Camera Effects

```gdscript
# vfx/camera_effects.gd
class_name BeatCameraEffectsComponent
extends Node

@export var camera: Camera3D

var _original_fov: float
var _shake_intensity: float = 0.0
var _shake_decay: float = 5.0
var _original_position: Vector3

func _ready():
    if camera:
        _original_fov = camera.fov
        _original_position = camera.position

func _process(delta: float):
    if _shake_intensity > 0:
        _apply_shake()
        _shake_intensity = max(0, _shake_intensity - _shake_decay * delta)
    else:
        camera.position = _original_position

func _apply_shake():
    var offset = Vector3(
        randf_range(-1, 1) * _shake_intensity,
        randf_range(-1, 1) * _shake_intensity,
        0
    )
    camera.position = _original_position + offset

func shake(intensity: float, decay: float = 5.0):
    _shake_intensity = max(_shake_intensity, intensity)
    _shake_decay = decay

func set_fov(fov: float, duration: float = 0.0):
    if duration > 0:
        var tween = create_tween()
        tween.tween_property(camera, "fov", fov, duration)
    else:
        camera.fov = fov

func reset_fov(duration: float = 0.0):
    set_fov(_original_fov, duration)

func punch_fov(amount: float, duration: float = 0.2):
    var target = _original_fov + amount
    set_fov(target, duration * 0.3)

    await get_tree().create_timer(duration * 0.3).timeout
    reset_fov(duration * 0.7)
```

## Pulse Visualizer

```gdscript
# vfx/pulse_visualizer.gd
class_name BeatPulseVisualizerComponent
extends Node3D

@export var target_mesh: MeshInstance3D
@export var pulse_scale: float = 1.2
@export var pulse_duration: float = 0.2
@export var sequencer_deck: Sequencer.DeckType = Sequencer.DeckType.GAME
@export var pulse_on_quant_type: Quant.Type = Quant.Type.KICK

var _base_scale: Vector3
var _subscription_handle: int = -1

func _ready():
    if target_mesh:
        _base_scale = target_mesh.scale

    _subscription_handle = Sequencer.subscribe(
        sequencer_deck,
        pulse_on_quant_type,
        _on_quant
    )

func _exit_tree():
    if _subscription_handle >= 0:
        Sequencer.unsubscribe(_subscription_handle)

func _on_quant(event: SequencerEvent):
    pulse(event.quant.value)

func pulse(intensity: float = 1.0):
    if not target_mesh:
        return

    var target_scale = _base_scale * (1.0 + (pulse_scale - 1.0) * intensity)

    target_mesh.scale = target_scale

    var tween = create_tween()
    tween.tween_property(target_mesh, "scale", _base_scale, pulse_duration).set_ease(Tween.EASE_OUT)
```

## Scene Structure

```
Environment (Node3D)
├── BeatLightingFloorActor
│   └── Tiles (generated dynamically)
├── WorldEnvironment
│   └── Environment (with post-process)
└── CanvasLayer
    └── ScreenEffects (ColorRect for overlays)

Camera3D
├── BeatCameraEffectsComponent
└── BeatScreenEffectsComponent

VisualElement (Node3D)
└── BeatPulseVisualizerComponent
    └── MeshInstance3D
```

## Shader Examples

### Vignette Shader

```glsl
shader_type canvas_item;

uniform float intensity : hint_range(0, 1) = 0.0;
uniform vec4 vignette_color : source_color = vec4(1, 0, 0, 1);
uniform float vignette_radius : hint_range(0, 1) = 0.5;
uniform float vignette_softness : hint_range(0, 1) = 0.5;

void fragment() {
    vec2 uv = UV - 0.5;
    float dist = length(uv);

    float vignette = smoothstep(vignette_radius, vignette_radius - vignette_softness, dist);
    vignette = 1.0 - vignette;

    COLOR = vec4(vignette_color.rgb, vignette * intensity);
}
```

### Chromatic Aberration Shader

```glsl
shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float intensity : hint_range(0, 0.1) = 0.0;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 offset = (uv - 0.5) * intensity;

    float r = texture(screen_texture, uv + offset).r;
    float g = texture(screen_texture, uv).g;
    float b = texture(screen_texture, uv - offset).b;

    COLOR = vec4(r, g, b, 1.0);
}
```
