## NetworkTypes - Network message and data type definitions
class_name NetworkTypes
extends RefCounted


## Message types for network communication
enum MessageType {
	## Connection
	PLAYER_INFO,
	PLAYER_READY,
	PLAYER_LEFT,

	## Sync
	TIME_SYNC_REQUEST,
	TIME_SYNC_RESPONSE,
	BEAT_SYNC,

	## Gameplay
	PLAYER_INPUT,
	PLAYER_STATE,
	ENEMY_STATE,
	DAMAGE_EVENT,
	SCORE_UPDATE,

	## Game flow
	GAME_START,
	GAME_PAUSE,
	GAME_RESUME,
	GAME_END,
	WAVE_START,
	WAVE_END,
}


## Player info sent during connection
class PlayerNetworkInfo:
	var peer_id: int = 0
	var display_name: String = "Player"
	var color: Color = Color.WHITE
	var is_ready: bool = false
	var is_host: bool = false

	func to_dict() -> Dictionary:
		return {
			"peer_id": peer_id,
			"display_name": display_name,
			"color": color.to_html(),
			"is_ready": is_ready,
			"is_host": is_host,
		}

	static func from_dict(data: Dictionary) -> PlayerNetworkInfo:
		var info := PlayerNetworkInfo.new()
		info.peer_id = data.get("peer_id", 0)
		info.display_name = data.get("display_name", "Player")
		info.color = Color.html(data.get("color", "#ffffff"))
		info.is_ready = data.get("is_ready", false)
		info.is_host = data.get("is_host", false)
		return info


## Input snapshot for network replication
class InputSnapshot:
	var sequence: int = 0
	var timestamp: float = 0.0
	var movement_direction: Vector2 = Vector2.ZERO
	var is_attacking: bool = false
	var is_dodging: bool = false
	var action_pressed: Array[String] = []

	func to_dict() -> Dictionary:
		return {
			"seq": sequence,
			"ts": timestamp,
			"move": [movement_direction.x, movement_direction.y],
			"atk": is_attacking,
			"dodge": is_dodging,
			"actions": action_pressed,
		}

	static func from_dict(data: Dictionary) -> InputSnapshot:
		var snap := InputSnapshot.new()
		snap.sequence = data.get("seq", 0)
		snap.timestamp = data.get("ts", 0.0)
		var move: Array = data.get("move", [0, 0])
		snap.movement_direction = Vector2(move[0], move[1])
		snap.is_attacking = data.get("atk", false)
		snap.is_dodging = data.get("dodge", false)
		snap.action_pressed = []
		var actions: Array = data.get("actions", [])
		for a in actions:
			snap.action_pressed.append(a)
		return snap


## Player state snapshot for network sync
class PlayerStateSnapshot:
	var peer_id: int = 0
	var sequence: int = 0
	var timestamp: float = 0.0
	var position: Vector3 = Vector3.ZERO
	var rotation: float = 0.0
	var velocity: Vector3 = Vector3.ZERO
	var health: float = 100.0
	var is_alive: bool = true
	var current_animation: String = ""
	var combo_count: int = 0

	func to_dict() -> Dictionary:
		return {
			"id": peer_id,
			"seq": sequence,
			"ts": timestamp,
			"pos": [position.x, position.y, position.z],
			"rot": rotation,
			"vel": [velocity.x, velocity.y, velocity.z],
			"hp": health,
			"alive": is_alive,
			"anim": current_animation,
			"combo": combo_count,
		}

	static func from_dict(data: Dictionary) -> PlayerStateSnapshot:
		var state := PlayerStateSnapshot.new()
		state.peer_id = data.get("id", 0)
		state.sequence = data.get("seq", 0)
		state.timestamp = data.get("ts", 0.0)
		var pos: Array = data.get("pos", [0, 0, 0])
		state.position = Vector3(pos[0], pos[1], pos[2])
		state.rotation = data.get("rot", 0.0)
		var vel: Array = data.get("vel", [0, 0, 0])
		state.velocity = Vector3(vel[0], vel[1], vel[2])
		state.health = data.get("hp", 100.0)
		state.is_alive = data.get("alive", true)
		state.current_animation = data.get("anim", "")
		state.combo_count = data.get("combo", 0)
		return state


## Enemy state for network sync
class EnemyStateSnapshot:
	var enemy_id: int = 0
	var position: Vector3 = Vector3.ZERO
	var rotation: float = 0.0
	var health: float = 100.0
	var is_alive: bool = true
	var current_state: String = ""
	var target_peer_id: int = 0

	func to_dict() -> Dictionary:
		return {
			"id": enemy_id,
			"pos": [position.x, position.y, position.z],
			"rot": rotation,
			"hp": health,
			"alive": is_alive,
			"state": current_state,
			"target": target_peer_id,
		}

	static func from_dict(data: Dictionary) -> EnemyStateSnapshot:
		var state := EnemyStateSnapshot.new()
		state.enemy_id = data.get("id", 0)
		var pos: Array = data.get("pos", [0, 0, 0])
		state.position = Vector3(pos[0], pos[1], pos[2])
		state.rotation = data.get("rot", 0.0)
		state.health = data.get("hp", 100.0)
		state.is_alive = data.get("alive", true)
		state.current_state = data.get("state", "")
		state.target_peer_id = data.get("target", 0)
		return state


## Damage event for network sync
class DamageEvent:
	var source_peer_id: int = 0
	var target_type: String = ""  # "player", "enemy"
	var target_id: int = 0
	var damage_amount: float = 0.0
	var timing_rating: int = 0
	var position: Vector3 = Vector3.ZERO

	func to_dict() -> Dictionary:
		return {
			"src": source_peer_id,
			"tgt_type": target_type,
			"tgt_id": target_id,
			"dmg": damage_amount,
			"rating": timing_rating,
			"pos": [position.x, position.y, position.z],
		}

	static func from_dict(data: Dictionary) -> DamageEvent:
		var event := DamageEvent.new()
		event.source_peer_id = data.get("src", 0)
		event.target_type = data.get("tgt_type", "")
		event.target_id = data.get("tgt_id", 0)
		event.damage_amount = data.get("dmg", 0.0)
		event.timing_rating = data.get("rating", 0)
		var pos: Array = data.get("pos", [0, 0, 0])
		event.position = Vector3(pos[0], pos[1], pos[2])
		return event


## Score update for network sync
class ScoreUpdate:
	var peer_id: int = 0
	var score: int = 0
	var combo: int = 0
	var max_combo: int = 0
	var style_rank: String = "D"

	func to_dict() -> Dictionary:
		return {
			"id": peer_id,
			"score": score,
			"combo": combo,
			"max_combo": max_combo,
			"rank": style_rank,
		}

	static func from_dict(data: Dictionary) -> ScoreUpdate:
		var update := ScoreUpdate.new()
		update.peer_id = data.get("id", 0)
		update.score = data.get("score", 0)
		update.combo = data.get("combo", 0)
		update.max_combo = data.get("max_combo", 0)
		update.style_rank = data.get("rank", "D")
		return update
