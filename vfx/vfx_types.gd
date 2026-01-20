## VFXTypes - Enums and data classes for visual effects
class_name VFXTypes
extends RefCounted


enum PulseMode {
	ON_BEAT,       ## Pulse on every beat
	ON_BAR,        ## Pulse on bar start
	ON_QUANT,      ## Pulse on specific quant type
	CONTINUOUS,    ## Continuous pulse based on audio
}


enum BlendMode {
	ADD,
	MULTIPLY,
	SCREEN,
	OVERLAY,
}


enum ScreenEffectType {
	CHROMATIC_ABERRATION,
	VIGNETTE,
	SCREEN_SHAKE,
	FLASH,
	RADIAL_BLUR,
	COLOR_SHIFT,
}


class PulseConfig:
	var mode: PulseMode = PulseMode.ON_BEAT
	var quant_type: Quant.Type = Quant.Type.KICK
	var intensity: float = 1.0
	var duration: float = 0.1
	var ease_type: Tween.EaseType = Tween.EASE_OUT
	var trans_type: Tween.TransitionType = Tween.TRANS_EXPO


class VFXColorPalette:
	var primary: Color = Color(1.0, 0.2, 0.4)       ## Hot pink/magenta
	var secondary: Color = Color(0.2, 0.8, 1.0)     ## Cyan
	var accent: Color = Color(1.0, 0.8, 0.2)        ## Yellow/gold
	var background: Color = Color(0.05, 0.05, 0.1)  ## Dark blue


## Default palettes for different intensities
static func get_combat_palette() -> VFXColorPalette:
	var p := VFXColorPalette.new()
	p.primary = Color(1.0, 0.1, 0.2)      ## Red
	p.secondary = Color(1.0, 0.5, 0.0)    ## Orange
	p.accent = Color(1.0, 1.0, 0.0)       ## Yellow
	p.background = Color(0.1, 0.02, 0.02)
	return p


static func get_exploration_palette() -> VFXColorPalette:
	var p := VFXColorPalette.new()
	p.primary = Color(0.2, 0.6, 1.0)      ## Blue
	p.secondary = Color(0.4, 0.2, 0.8)    ## Purple
	p.accent = Color(0.0, 1.0, 0.8)       ## Teal
	p.background = Color(0.02, 0.02, 0.08)
	return p


static func get_boss_palette() -> VFXColorPalette:
	var p := VFXColorPalette.new()
	p.primary = Color(0.8, 0.0, 0.4)      ## Magenta
	p.secondary = Color(0.0, 0.0, 0.0)    ## Black
	p.accent = Color(1.0, 0.0, 0.0)       ## Pure red
	p.background = Color(0.05, 0.0, 0.05)
	return p
