## ColorPalette - Defines color schemes for the game
class_name ColorPalette
extends Resource


## Palette name for identification
@export var palette_name: String = "Default"

## Primary colors
@export var primary: Color = Color(1.0, 0.2, 0.6)      # Main accent (pink/magenta)
@export var secondary: Color = Color(0.0, 0.8, 1.0)   # Secondary accent (cyan)
@export var tertiary: Color = Color(1.0, 0.8, 0.0)    # Tertiary accent (yellow)

## Background colors
@export var background_dark: Color = Color(0.02, 0.02, 0.05)
@export var background_mid: Color = Color(0.05, 0.05, 0.1)
@export var background_light: Color = Color(0.1, 0.1, 0.15)

## Beat/timing colors
@export var beat_kick: Color = Color(1.0, 0.2, 0.4)    # Strong beat
@export var beat_snare: Color = Color(1.0, 0.6, 0.2)   # Snare
@export var beat_hat: Color = Color(0.4, 0.8, 1.0)     # Hi-hat
@export var beat_tick: Color = Color(0.6, 0.6, 0.7)    # General tick

## Combat colors
@export var damage_player: Color = Color(1.0, 0.2, 0.2)
@export var damage_enemy: Color = Color(1.0, 0.8, 0.2)
@export var heal: Color = Color(0.2, 1.0, 0.4)
@export var shield: Color = Color(0.2, 0.6, 1.0)

## Timing feedback colors
@export var timing_perfect: Color = Color(1.0, 0.9, 0.2)  # Gold
@export var timing_great: Color = Color(0.2, 1.0, 0.4)    # Green
@export var timing_good: Color = Color(0.2, 0.8, 1.0)     # Blue
@export var timing_miss: Color = Color(0.5, 0.5, 0.5)     # Gray

## UI colors
@export var ui_text: Color = Color(0.9, 0.9, 0.95)
@export var ui_text_dim: Color = Color(0.5, 0.5, 0.55)
@export var ui_border: Color = Color(0.3, 0.3, 0.35)
@export var ui_highlight: Color = Color(1.0, 0.2, 0.6)


## Get color for a specific quant type
func get_color_for_quant_type(quant_type: Quant.Type) -> Color:
	match quant_type:
		Quant.Type.KICK:
			return beat_kick
		Quant.Type.SNARE:
			return beat_snare
		Quant.Type.HAT:
			return beat_hat
		Quant.Type.TICK:
			return beat_tick
		_:
			return primary


## Get color for timing rating
func get_timing_color(rating: CombatTypes.TimingRating) -> Color:
	match rating:
		CombatTypes.TimingRating.PERFECT:
			return timing_perfect
		CombatTypes.TimingRating.GREAT:
			return timing_great
		CombatTypes.TimingRating.GOOD:
			return timing_good
		CombatTypes.TimingRating.MISS:
			return timing_miss
		_:
			return timing_miss


## Create default neon palette
static func create_neon() -> ColorPalette:
	var palette := ColorPalette.new()
	palette.palette_name = "Neon"
	palette.primary = Color(1.0, 0.0, 0.8)
	palette.secondary = Color(0.0, 1.0, 1.0)
	palette.tertiary = Color(1.0, 1.0, 0.0)
	return palette


## Create synthwave palette
static func create_synthwave() -> ColorPalette:
	var palette := ColorPalette.new()
	palette.palette_name = "Synthwave"
	palette.primary = Color(1.0, 0.3, 0.5)
	palette.secondary = Color(0.5, 0.2, 1.0)
	palette.tertiary = Color(0.2, 0.8, 1.0)
	palette.background_dark = Color(0.05, 0.0, 0.1)
	palette.background_mid = Color(0.1, 0.0, 0.15)
	return palette


## Create minimal palette
static func create_minimal() -> ColorPalette:
	var palette := ColorPalette.new()
	palette.palette_name = "Minimal"
	palette.primary = Color(1.0, 1.0, 1.0)
	palette.secondary = Color(0.8, 0.8, 0.8)
	palette.tertiary = Color(0.6, 0.6, 0.6)
	palette.background_dark = Color(0.0, 0.0, 0.0)
	palette.background_mid = Color(0.1, 0.1, 0.1)
	palette.background_light = Color(0.2, 0.2, 0.2)
	return palette


## Lerp between two palettes
static func lerp_palettes(from: ColorPalette, to: ColorPalette, weight: float) -> ColorPalette:
	var result := ColorPalette.new()
	result.palette_name = "Lerped"

	result.primary = from.primary.lerp(to.primary, weight)
	result.secondary = from.secondary.lerp(to.secondary, weight)
	result.tertiary = from.tertiary.lerp(to.tertiary, weight)
	result.background_dark = from.background_dark.lerp(to.background_dark, weight)
	result.background_mid = from.background_mid.lerp(to.background_mid, weight)
	result.background_light = from.background_light.lerp(to.background_light, weight)
	result.beat_kick = from.beat_kick.lerp(to.beat_kick, weight)
	result.beat_snare = from.beat_snare.lerp(to.beat_snare, weight)
	result.beat_hat = from.beat_hat.lerp(to.beat_hat, weight)
	result.beat_tick = from.beat_tick.lerp(to.beat_tick, weight)

	return result
