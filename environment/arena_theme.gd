## ArenaTheme - Defines visual theme for an arena environment
class_name ArenaTheme
extends Resource


## Theme identity
@export var theme_name: String = "Nightclub"
@export var description: String = ""

## Colors
@export_group("Colors")
@export var background_color: Color = Color(0.02, 0.02, 0.05)
@export var ambient_color: Color = Color(0.1, 0.1, 0.15)
@export var floor_base_color: Color = Color(0.05, 0.05, 0.1)
@export var floor_pulse_color: Color = Color(1.0, 0.2, 0.6)
@export var primary_light_color: Color = Color(0.8, 0.8, 1.0)
@export var accent_light_color: Color = Color(1.0, 0.0, 0.5)
@export var fog_color: Color = Color(0.1, 0.1, 0.2)

## Lighting
@export_group("Lighting")
@export var ambient_energy: float = 0.3
@export var primary_light_energy: float = 0.5
@export var emission_energy: float = 3.0
@export var glow_enabled: bool = true
@export var glow_intensity: float = 0.8
@export var glow_bloom: float = 0.3

## Fog
@export_group("Fog")
@export var fog_enabled: bool = false
@export var fog_density: float = 0.01

## Props and decorations
@export_group("Decorations")
@export var decoration_scenes: Array[PackedScene] = []
@export var prop_density: float = 0.5

## Audio ambience
@export_group("Audio")
@export var ambient_sound: AudioStream
@export var ambient_volume: float = -10.0


## Apply theme to environment
func apply_to_environment(env: Environment) -> void:
	env.background_mode = Environment.BG_COLOR
	env.background_color = background_color

	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = ambient_color
	env.ambient_light_energy = ambient_energy

	env.glow_enabled = glow_enabled
	env.glow_intensity = glow_intensity
	env.glow_bloom = glow_bloom

	if fog_enabled:
		env.fog_enabled = true
		env.fog_light_color = fog_color
		env.fog_density = fog_density


## Apply theme to lighting floor
func apply_to_floor(floor: LightingFloor) -> void:
	floor.base_color = floor_base_color
	floor.pulse_color = floor_pulse_color
	floor.emission_energy = emission_energy


## Create preset themes
static func create_nightclub() -> ArenaTheme:
	var theme := ArenaTheme.new()
	theme.theme_name = "Nightclub"
	theme.background_color = Color(0.02, 0.02, 0.05)
	theme.floor_pulse_color = Color(1.0, 0.2, 0.6)
	theme.accent_light_color = Color(1.0, 0.0, 0.5)
	return theme


static func create_cyber() -> ArenaTheme:
	var theme := ArenaTheme.new()
	theme.theme_name = "Cyber Arena"
	theme.background_color = Color(0.0, 0.02, 0.05)
	theme.floor_base_color = Color(0.0, 0.05, 0.1)
	theme.floor_pulse_color = Color(0.0, 1.0, 1.0)
	theme.accent_light_color = Color(0.0, 1.0, 0.8)
	return theme


static func create_concert() -> ArenaTheme:
	var theme := ArenaTheme.new()
	theme.theme_name = "Concert Stage"
	theme.background_color = Color(0.0, 0.0, 0.0)
	theme.floor_pulse_color = Color(1.0, 1.0, 1.0)
	theme.primary_light_energy = 1.0
	theme.glow_intensity = 1.2
	return theme


static func create_retro() -> ArenaTheme:
	var theme := ArenaTheme.new()
	theme.theme_name = "Retro Arcade"
	theme.background_color = Color(0.05, 0.0, 0.08)
	theme.floor_base_color = Color(0.1, 0.0, 0.15)
	theme.floor_pulse_color = Color(1.0, 0.0, 1.0)
	theme.accent_light_color = Color(0.0, 1.0, 0.0)
	return theme
