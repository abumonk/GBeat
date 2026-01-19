## Test cases for Boss Types
extends TestBase


func test_boss_states() -> bool:
	var states := [
		BossTypes.BossState.INACTIVE,
		BossTypes.BossState.INTRO,
		BossTypes.BossState.FIGHTING,
		BossTypes.BossState.PHASE_TRANSITION,
		BossTypes.BossState.STAGGERED,
		BossTypes.BossState.DEFEATED,
	]

	if not assert_equal(states.size(), 6, "Should have 6 boss states"):
		return false

	return true


func test_phase_transition_types() -> bool:
	var types := [
		BossTypes.PhaseTransitionType.IMMEDIATE,
		BossTypes.PhaseTransitionType.HEALTH_GATE,
		BossTypes.PhaseTransitionType.TIMED,
		BossTypes.PhaseTransitionType.PATTERN_COMPLETE,
	]

	if not assert_equal(types.size(), 4, "Should have 4 phase transition types"):
		return false

	return true


func test_attack_patterns() -> bool:
	var patterns := [
		BossTypes.AttackPattern.SEQUENCE,
		BossTypes.AttackPattern.RANDOM,
		BossTypes.AttackPattern.ADAPTIVE,
		BossTypes.AttackPattern.SCRIPTED,
	]

	if not assert_equal(patterns.size(), 4, "Should have 4 attack patterns"):
		return false

	return true


func test_boss_stats_creation() -> bool:
	var stats := BossTypes.BossStats.new()

	if not assert_approximately(stats.max_health, 1000.0):
		return false
	if not assert_approximately(stats.current_health, 1000.0):
		return false

	return true


func test_boss_stats_health_percent() -> bool:
	var stats := BossTypes.BossStats.new()
	stats.max_health = 100.0
	stats.current_health = 75.0

	var percent := stats.get_health_percent()

	if not assert_approximately(percent, 0.75, 0.001):
		return false

	return true


func test_boss_stats_take_damage() -> bool:
	var stats := BossTypes.BossStats.new()
	stats.max_health = 100.0
	stats.current_health = 100.0
	stats.defense = 5.0

	var actual := stats.take_damage(20.0)

	# 20 - 5 defense = 15 actual damage
	if not assert_approximately(actual, 15.0, 0.001, "Should deal 15 damage after defense"):
		return false
	if not assert_approximately(stats.current_health, 85.0, 0.001, "Health should be 85"):
		return false

	return true


func test_boss_stats_take_lethal_damage() -> bool:
	var stats := BossTypes.BossStats.new()
	stats.max_health = 100.0
	stats.current_health = 10.0
	stats.defense = 0.0

	stats.take_damage(50.0)

	if not assert_approximately(stats.current_health, 0.0, 0.001, "Health should not go below 0"):
		return false

	return true


func test_boss_stats_stagger() -> bool:
	var stats := BossTypes.BossStats.new()
	stats.stagger_threshold = 50.0
	stats.stagger_buildup = 0.0

	# First hit - not enough to stagger
	var staggered := stats.add_stagger(30.0)
	if not assert_false(staggered, "Should not stagger at 30/50"):
		return false
	if not assert_approximately(stats.stagger_buildup, 30.0):
		return false

	# Second hit - triggers stagger
	staggered = stats.add_stagger(25.0)
	if not assert_true(staggered, "Should stagger at 55/50"):
		return false
	if not assert_approximately(stats.stagger_buildup, 0.0, 0.001, "Stagger should reset"):
		return false

	return true


func test_boss_phase_config() -> bool:
	var config := BossTypes.BossPhaseConfig.new()
	config.phase_number = 2
	config.health_threshold = 0.5
	config.speed_multiplier = 1.5
	config.damage_multiplier = 1.25

	if not assert_equal(config.phase_number, 2):
		return false
	if not assert_approximately(config.health_threshold, 0.5):
		return false
	if not assert_approximately(config.speed_multiplier, 1.5):
		return false

	return true


func test_boss_attack_config() -> bool:
	var config := BossTypes.BossAttackConfig.new()
	config.attack_name = "slam"
	config.telegraph_duration = 1.5
	config.damage = 30.0
	config.is_unblockable = true

	if not assert_equal(config.attack_name, "slam"):
		return false
	if not assert_approximately(config.telegraph_duration, 1.5):
		return false
	if not assert_true(config.is_unblockable):
		return false

	return true
