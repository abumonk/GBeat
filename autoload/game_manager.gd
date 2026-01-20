## GameManager - Central game state and flow control
## Note: No class_name because this is an autoload singleton
extends Node


signal game_started()
signal game_paused()
signal game_resumed()
signal game_over(victory: bool)
signal level_loaded(level_name: String)
signal level_completed(level_name: String, score: int)
signal player_died()
signal player_respawned()


## Game States
enum GameState {
	MAIN_MENU,
	LOADING,
	PLAYING,
	PAUSED,
	GAME_OVER,
	CUTSCENE,
	EDITOR
}


## Current state
var current_state: GameState = GameState.MAIN_MENU
var previous_state: GameState = GameState.MAIN_MENU

## Game data
var current_level: String = ""
var current_score: int = 0
var session_playtime: float = 0.0

## Player reference
var player: Node = null

## Pause state
var _pause_stack: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		session_playtime += delta


## === State Management ===

func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	match new_state:
		GameState.MAIN_MENU:
			_on_enter_main_menu()
		GameState.LOADING:
			_on_enter_loading()
		GameState.PLAYING:
			_on_enter_playing()
		GameState.PAUSED:
			_on_enter_paused()
		GameState.GAME_OVER:
			_on_enter_game_over()
		GameState.EDITOR:
			_on_enter_editor()


func _on_enter_main_menu() -> void:
	get_tree().paused = false
	_pause_stack = 0


func _on_enter_loading() -> void:
	pass


func _on_enter_playing() -> void:
	get_tree().paused = false
	game_started.emit()


func _on_enter_paused() -> void:
	get_tree().paused = true
	game_paused.emit()


func _on_enter_game_over() -> void:
	game_over.emit(false)


func _on_enter_editor() -> void:
	get_tree().paused = false


## === Pause System ===

func push_pause() -> void:
	_pause_stack += 1
	if _pause_stack == 1 and current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)


func pop_pause() -> void:
	_pause_stack = max(0, _pause_stack - 1)
	if _pause_stack == 0 and current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		game_resumed.emit()


func is_paused() -> bool:
	return current_state == GameState.PAUSED or get_tree().paused


## === Level Management ===

func load_level(level_path: String) -> void:
	change_state(GameState.LOADING)
	current_level = level_path

	# Use deferred scene change
	await get_tree().process_frame
	get_tree().change_scene_to_file(level_path)

	await get_tree().process_frame
	change_state(GameState.PLAYING)
	level_loaded.emit(level_path)


func reload_current_level() -> void:
	if not current_level.is_empty():
		load_level(current_level)


func complete_level(score: int) -> void:
	current_score = score
	level_completed.emit(current_level, score)


func return_to_main_menu() -> void:
	change_state(GameState.LOADING)
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	change_state(GameState.MAIN_MENU)


## === Player Management ===

func register_player(player_node: Node) -> void:
	player = player_node

	# Connect to player signals if available
	if player.has_signal("died"):
		player.died.connect(_on_player_died)


func unregister_player() -> void:
	player = null


func _on_player_died() -> void:
	player_died.emit()


func respawn_player() -> void:
	player_respawned.emit()


func get_player() -> Node:
	return player


## === Score Management ===

func add_score(amount: int) -> void:
	current_score += amount


func reset_score() -> void:
	current_score = 0


func get_score() -> int:
	return current_score


## === Game Flow ===

func start_new_game() -> void:
	reset_score()
	session_playtime = 0.0
	load_level("res://scenes/main.tscn")


func quit_game() -> void:
	get_tree().quit()


## === Input Handling ===

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if current_state == GameState.PLAYING:
			push_pause()
		elif current_state == GameState.PAUSED:
			pop_pause()


## === Queries ===

func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_in_menu() -> bool:
	return current_state == GameState.MAIN_MENU


func is_in_editor() -> bool:
	return current_state == GameState.EDITOR


func get_session_playtime() -> float:
	return session_playtime
