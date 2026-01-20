## Test cases for VFX Types
extends TestBase


func test_pulse_modes() -> bool:
	var modes := [
		VFXTypes.PulseMode.ON_BEAT,
		VFXTypes.PulseMode.ON_BAR,
		VFXTypes.PulseMode.ON_QUANT,
		VFXTypes.PulseMode.CONTINUOUS,
	]

	if not assert_equal(modes.size(), 4, "Should have 4 pulse modes"):
		return false

	return true


func test_blend_modes() -> bool:
	var modes := [
		VFXTypes.BlendMode.ADD,
		VFXTypes.BlendMode.MULTIPLY,
		VFXTypes.BlendMode.SCREEN,
		VFXTypes.BlendMode.OVERLAY,
	]

	if not assert_equal(modes.size(), 4, "Should have 4 blend modes"):
		return false

	return true


func test_screen_effect_types() -> bool:
	var types := [
		VFXTypes.ScreenEffectType.CHROMATIC_ABERRATION,
		VFXTypes.ScreenEffectType.VIGNETTE,
		VFXTypes.ScreenEffectType.SCREEN_SHAKE,
		VFXTypes.ScreenEffectType.FLASH,
		VFXTypes.ScreenEffectType.RADIAL_BLUR,
		VFXTypes.ScreenEffectType.COLOR_SHIFT,
	]

	if not assert_equal(types.size(), 6, "Should have 6 screen effect types"):
		return false

	return true


func test_pulse_config() -> bool:
	var config := VFXTypes.PulseConfig.new()

	if not assert_equal(config.mode, VFXTypes.PulseMode.ON_BEAT, "Default mode should be ON_BEAT"):
		return false
	if not assert_approximately(config.intensity, 1.0):
		return false
	if not assert_approximately(config.duration, 0.1):
		return false

	config.mode = VFXTypes.PulseMode.ON_BAR
	config.intensity = 0.8
	config.duration = 0.2

	if not assert_equal(config.mode, VFXTypes.PulseMode.ON_BAR):
		return false
	if not assert_approximately(config.intensity, 0.8):
		return false

	return true


func test_color_palette() -> bool:
	var palette := VFXTypes.VFXColorPalette.new()

	# Check default colors exist and are valid
	if not assert_not_null(palette.primary):
		return false
	if not assert_not_null(palette.secondary):
		return false
	if not assert_not_null(palette.accent):
		return false
	if not assert_not_null(palette.background):
		return false

	# Verify colors have valid components
	if not assert_in_range(palette.primary.r, 0.0, 1.0):
		return false
	if not assert_in_range(palette.primary.g, 0.0, 1.0):
		return false
	if not assert_in_range(palette.primary.b, 0.0, 1.0):
		return false

	return true


func test_combat_palette() -> bool:
	var palette := VFXTypes.get_combat_palette()

	if not assert_not_null(palette):
		return false

	# Combat palette should have warm/aggressive colors
	if not assert_greater(palette.primary.r, 0.5, "Combat primary should be reddish"):
		return false

	return true


func test_exploration_palette() -> bool:
	var palette := VFXTypes.get_exploration_palette()

	if not assert_not_null(palette):
		return false

	# Exploration palette should have cool colors
	if not assert_greater(palette.primary.b, 0.5, "Exploration primary should be bluish"):
		return false

	return true


func test_boss_palette() -> bool:
	var palette := VFXTypes.get_boss_palette()

	if not assert_not_null(palette):
		return false

	# Boss palette should be dramatic
	if not assert_greater(palette.primary.r, 0.5, "Boss primary should have red"):
		return false

	return true
