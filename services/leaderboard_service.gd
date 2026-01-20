## LeaderboardService - Score submission and leaderboard management
## Stub implementation - replace with actual backend integration
class_name LeaderboardService
extends Node


signal scores_received(scores: Array, leaderboard_id: String)
signal score_submitted(rank: int, leaderboard_id: String)
signal submission_failed(error: String)
signal friend_scores_received(scores: Array, leaderboard_id: String)


## Leaderboard types
enum LeaderboardType {
	GLOBAL,
	FRIENDS,
	WEEKLY,
	DAILY,
}


## Score entry structure
class LeaderboardEntry:
	var rank: int = 0
	var player_id: String = ""
	var player_name: String = ""
	var score: int = 0
	var max_combo: int = 0
	var style_rank: String = "D"
	var submitted_at: String = ""

	func to_dict() -> Dictionary:
		return {
			"rank": rank,
			"player_id": player_id,
			"player_name": player_name,
			"score": score,
			"max_combo": max_combo,
			"style_rank": style_rank,
			"submitted_at": submitted_at,
		}

	static func from_dict(data: Dictionary) -> LeaderboardEntry:
		var entry := LeaderboardEntry.new()
		entry.rank = data.get("rank", 0)
		entry.player_id = data.get("player_id", "")
		entry.player_name = data.get("player_name", "Unknown")
		entry.score = data.get("score", 0)
		entry.max_combo = data.get("max_combo", 0)
		entry.style_rank = data.get("style_rank", "D")
		entry.submitted_at = data.get("submitted_at", "")
		return entry


## Local mock data
var _mock_leaderboards: Dictionary = {}


func _ready() -> void:
	_generate_mock_data()


func _generate_mock_data() -> void:
	# Generate mock leaderboard entries for testing
	var names := ["BeatMaster", "RhythmKing", "ComboQueen", "GrooveMachine",
				  "SyncStorm", "TempoTitan", "FlowState", "PulseRider"]

	for level_id in ["level_1_1", "level_1_2", "level_boss_1"]:
		var entries: Array = []
		for i in range(100):
			var entry := LeaderboardEntry.new()
			entry.rank = i + 1
			entry.player_id = "player_%d" % i
			entry.player_name = names[i % names.size()] + str(i / names.size())
			entry.score = 100000 - (i * 500) + randi() % 200
			entry.max_combo = 50 - (i / 2) + randi() % 10
			entry.style_rank = ["SSS", "SS", "S", "A", "B", "C", "D"][mini(i / 15, 6)]
			entry.submitted_at = Time.get_datetime_string_from_system()
			entries.append(entry)

		_mock_leaderboards[level_id] = entries


## === Score Submission ===

func submit_score(level_id: String, score: int, max_combo: int = 0, style_rank: String = "D", replay_data: PackedByteArray = PackedByteArray()) -> void:
	# STUB: Replace with actual backend call
	print("LeaderboardService: Submitting score %d for %s" % [score, level_id])

	await get_tree().create_timer(0.3).timeout

	# Calculate mock rank
	var rank := 1
	if _mock_leaderboards.has(level_id):
		for entry in _mock_leaderboards[level_id]:
			if score <= entry.score:
				rank += 1
			else:
				break

	score_submitted.emit(rank, level_id)


## === Fetch Leaderboards ===

func get_global_scores(level_id: String, count: int = 100, offset: int = 0) -> void:
	# STUB: Replace with actual backend call
	print("LeaderboardService: Fetching global scores for %s" % level_id)

	await get_tree().create_timer(0.2).timeout

	var scores: Array = []
	if _mock_leaderboards.has(level_id):
		var entries: Array = _mock_leaderboards[level_id]
		for i in range(offset, mini(offset + count, entries.size())):
			scores.append(entries[i].to_dict())

	scores_received.emit(scores, level_id)


func get_friend_scores(level_id: String) -> void:
	# STUB: Replace with actual backend call
	print("LeaderboardService: Fetching friend scores for %s" % level_id)

	await get_tree().create_timer(0.2).timeout

	# Return empty for now (no friends system)
	var scores: Array = []
	friend_scores_received.emit(scores, level_id)


func get_scores_around_player(level_id: String, player_id: String, range_size: int = 10) -> void:
	# STUB: Returns scores around the player's rank
	print("LeaderboardService: Fetching scores around player for %s" % level_id)

	await get_tree().create_timer(0.2).timeout

	var scores: Array = []
	# For now, return top scores
	if _mock_leaderboards.has(level_id):
		var entries: Array = _mock_leaderboards[level_id]
		for i in range(mini(range_size * 2, entries.size())):
			scores.append(entries[i].to_dict())

	scores_received.emit(scores, level_id)


func get_weekly_scores(level_id: String, count: int = 100) -> void:
	# STUB: Same as global for now
	get_global_scores(level_id, count)


func get_daily_scores(level_id: String, count: int = 100) -> void:
	# STUB: Same as global for now
	get_global_scores(level_id, count)


## === Player Stats ===

func get_player_best_score(level_id: String, player_id: String) -> int:
	# STUB: Return 0 for now
	return 0


func get_player_rank(level_id: String, player_id: String) -> int:
	# STUB: Return -1 (unranked) for now
	return -1
