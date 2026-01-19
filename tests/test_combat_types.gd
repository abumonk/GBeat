## Test cases for Combat Types
extends TestBase


func test_action_types() -> bool:
	var types := [
		CombatTypes.ActionType.NONE,
		CombatTypes.ActionType.LIGHT_ATTACK,
		CombatTypes.ActionType.HEAVY_ATTACK,
		CombatTypes.ActionType.BLOCK,
		CombatTypes.ActionType.DODGE,
		CombatTypes.ActionType.SPECIAL,
	]

	if not assert_equal(types.size(), 6, "Should have 6 action types"):
		return false

	return true


func test_timing_ratings() -> bool:
	var ratings := [
		CombatTypes.TimingRating.MISS,
		CombatTypes.TimingRating.EARLY,
		CombatTypes.TimingRating.LATE,
		CombatTypes.TimingRating.GOOD,
		CombatTypes.TimingRating.GREAT,
		CombatTypes.TimingRating.PERFECT,
	]

	if not assert_equal(ratings.size(), 6, "Should have 6 timing ratings"):
		return false

	return true


func test_timing_multiplier_perfect() -> bool:
	var multiplier := CombatTypes.get_timing_multiplier(CombatTypes.TimingRating.PERFECT)
	if not assert_approximately(multiplier, 1.5, 0.001, "Perfect should give 1.5x multiplier"):
		return false
	return true


func test_timing_multiplier_great() -> bool:
	var multiplier := CombatTypes.get_timing_multiplier(CombatTypes.TimingRating.GREAT)
	if not assert_approximately(multiplier, 1.25, 0.001, "Great should give 1.25x multiplier"):
		return false
	return true


func test_timing_multiplier_good() -> bool:
	var multiplier := CombatTypes.get_timing_multiplier(CombatTypes.TimingRating.GOOD)
	if not assert_approximately(multiplier, 1.0, 0.001, "Good should give 1.0x multiplier"):
		return false
	return true


func test_timing_multiplier_miss() -> bool:
	var multiplier := CombatTypes.get_timing_multiplier(CombatTypes.TimingRating.MISS)
	if not assert_approximately(multiplier, 0.0, 0.001, "Miss should give 0.0x multiplier"):
		return false
	return true


func test_beat_hit_result() -> bool:
	var result := CombatTypes.BeatHitResult.new()
	result.base_damage = 10.0
	result.timing_multiplier = 1.5
	result.combo_multiplier = 1.2
	result.is_critical = true

	result.calculate_final_damage()

	# 10 * 1.5 * 1.2 = 18
	if not assert_approximately(result.final_damage, 18.0, 0.001, "Final damage should be 18"):
		return false

	return true


func test_combo_link_types() -> bool:
	var types := [
		CombatTypes.ComboLinkType.ANY,
		CombatTypes.ComboLinkType.LIGHT_ONLY,
		CombatTypes.ComboLinkType.HEAVY_ONLY,
		CombatTypes.ComboLinkType.LIGHT_CHAIN,
		CombatTypes.ComboLinkType.HEAVY_CHAIN,
	]

	if not assert_equal(types.size(), 5, "Should have 5 combo link types"):
		return false

	return true


func test_window_types() -> bool:
	var types := [
		CombatTypes.WindowType.NONE,
		CombatTypes.WindowType.ATTACK,
		CombatTypes.WindowType.BLOCK,
		CombatTypes.WindowType.DODGE,
		CombatTypes.WindowType.COMBO,
	]

	if not assert_equal(types.size(), 5, "Should have 5 window types"):
		return false

	return true
