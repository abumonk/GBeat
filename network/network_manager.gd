## NetworkManager - Core multiplayer networking singleton
## Add to autoload as "NetworkManager"
extends Node


signal connected_to_server()
signal connection_failed()
signal server_disconnected()
signal player_joined(peer_id: int, player_info: Dictionary)
signal player_left(peer_id: int)
signal all_players_ready()


enum NetworkState {
	OFFLINE,
	HOSTING,
	JOINING,
	CONNECTED,
}


const DEFAULT_PORT := 7777
const MAX_PLAYERS := 4


## Network state
var current_state: NetworkState = NetworkState.OFFLINE
var is_server: bool = false
var local_peer_id: int = 0

## Connected players
var players: Dictionary = {}  # peer_id -> PlayerInfo
var players_ready: Dictionary = {}  # peer_id -> bool

## Local player info
var local_player_info: Dictionary = {
	"name": "Player",
	"color": Color.WHITE,
}

## Network peer
var _peer: ENetMultiplayerPeer


func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


## === Host/Join ===

func host_game(port: int = DEFAULT_PORT, max_clients: int = MAX_PLAYERS) -> Error:
	if current_state != NetworkState.OFFLINE:
		push_warning("NetworkManager: Already in a network session")
		return ERR_ALREADY_IN_USE

	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_server(port, max_clients)

	if error != OK:
		push_error("NetworkManager: Failed to create server: %s" % error_string(error))
		return error

	multiplayer.multiplayer_peer = _peer
	is_server = true
	local_peer_id = 1
	current_state = NetworkState.HOSTING

	# Add host as player
	players[1] = local_player_info.duplicate()
	players_ready[1] = false

	print("NetworkManager: Server started on port %d" % port)
	return OK


func join_game(address: String, port: int = DEFAULT_PORT) -> Error:
	if current_state != NetworkState.OFFLINE:
		push_warning("NetworkManager: Already in a network session")
		return ERR_ALREADY_IN_USE

	_peer = ENetMultiplayerPeer.new()
	var error := _peer.create_client(address, port)

	if error != OK:
		push_error("NetworkManager: Failed to connect to %s:%d" % [address, port])
		return error

	multiplayer.multiplayer_peer = _peer
	is_server = false
	current_state = NetworkState.JOINING

	print("NetworkManager: Connecting to %s:%d" % [address, port])
	return OK


func disconnect_from_game() -> void:
	if current_state == NetworkState.OFFLINE:
		return

	multiplayer.multiplayer_peer = null
	_peer = null

	players.clear()
	players_ready.clear()
	current_state = NetworkState.OFFLINE
	is_server = false
	local_peer_id = 0

	print("NetworkManager: Disconnected")


## === Connection Callbacks ===

func _on_peer_connected(peer_id: int) -> void:
	print("NetworkManager: Peer %d connected" % peer_id)

	if is_server:
		# Send existing player list to new player
		_send_player_list.rpc_id(peer_id)


func _on_peer_disconnected(peer_id: int) -> void:
	print("NetworkManager: Peer %d disconnected" % peer_id)

	if players.has(peer_id):
		players.erase(peer_id)
		players_ready.erase(peer_id)
		player_left.emit(peer_id)


func _on_connected_to_server() -> void:
	print("NetworkManager: Connected to server")
	local_peer_id = multiplayer.get_unique_id()
	current_state = NetworkState.CONNECTED

	# Send our info to server
	_register_player.rpc_id(1, local_player_info)

	connected_to_server.emit()


func _on_connection_failed() -> void:
	print("NetworkManager: Connection failed")
	current_state = NetworkState.OFFLINE
	_peer = null

	connection_failed.emit()


func _on_server_disconnected() -> void:
	print("NetworkManager: Server disconnected")
	disconnect_from_game()

	server_disconnected.emit()


## === RPC Functions ===

@rpc("any_peer", "reliable")
func _register_player(info: Dictionary) -> void:
	var sender_id := multiplayer.get_remote_sender_id()

	players[sender_id] = info
	players_ready[sender_id] = false

	print("NetworkManager: Player %d registered: %s" % [sender_id, info.get("name", "Unknown")])

	# Notify all clients about new player
	if is_server:
		_broadcast_player_joined.rpc(sender_id, info)


@rpc("authority", "reliable")
func _broadcast_player_joined(peer_id: int, info: Dictionary) -> void:
	players[peer_id] = info
	players_ready[peer_id] = false

	player_joined.emit(peer_id, info)


@rpc("authority", "reliable")
func _send_player_list() -> void:
	# Server sends full player list to joining client
	for peer_id in players.keys():
		_broadcast_player_joined.rpc_id(multiplayer.get_remote_sender_id(), peer_id, players[peer_id])


@rpc("any_peer", "reliable")
func _set_player_ready(ready: bool) -> void:
	var sender_id := multiplayer.get_remote_sender_id()
	if sender_id == 0:
		sender_id = local_peer_id

	players_ready[sender_id] = ready

	if is_server:
		_check_all_ready()


func _check_all_ready() -> void:
	if players_ready.is_empty():
		return

	for peer_id in players_ready.keys():
		if not players_ready[peer_id]:
			return

	all_players_ready.emit()


## === Public API ===

func set_local_player_info(info: Dictionary) -> void:
	local_player_info = info

	if current_state == NetworkState.CONNECTED:
		_register_player.rpc_id(1, info)


func set_ready(ready: bool) -> void:
	players_ready[local_peer_id] = ready

	if current_state == NetworkState.CONNECTED or current_state == NetworkState.HOSTING:
		_set_player_ready.rpc(ready)


func get_player_info(peer_id: int) -> Dictionary:
	return players.get(peer_id, {})


func get_all_players() -> Dictionary:
	return players.duplicate()


func get_player_count() -> int:
	return players.size()


func is_all_players_ready() -> bool:
	for peer_id in players_ready.keys():
		if not players_ready[peer_id]:
			return false
	return not players_ready.is_empty()


func is_host() -> bool:
	return is_server


func is_connected_to_network() -> bool:
	return current_state == NetworkState.CONNECTED or current_state == NetworkState.HOSTING


func get_state() -> NetworkState:
	return current_state


func get_local_peer_id() -> int:
	return local_peer_id
