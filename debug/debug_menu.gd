## DebugMenu - In-game debug overlay
class_name DebugMenu
extends CanvasLayer


signal command_executed(command: String, args: Array)


@export var toggle_action: String = "debug_toggle"
@export var show_fps: bool = true
@export var show_beat_info: bool = true
@export var show_player_state: bool = true
@export var show_enemy_count: bool = true

## Colors
const COLOR_GOOD := Color.GREEN
const COLOR_WARNING := Color.YELLOW
const COLOR_BAD := Color.RED
const COLOR_INFO := Color.WHITE

## UI Components
var _panel: PanelContainer
var _vbox: VBoxContainer
var _labels: Dictionary = {}
var _console_input: LineEdit
var _visible := false

## Profiler reference
var _profiler: DebugProfiler


func _ready() -> void:
	layer = 100  # On top of everything

	_create_ui()
	_hide_ui()

	# Create profiler
	_profiler = DebugProfiler.new()
	add_child(_profiler)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle_visibility()
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _visible:
		return

	_update_display()


func _create_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_panel.position = Vector2(10, 10)
	_panel.modulate.a = 0.9
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.8)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)

	_vbox = VBoxContainer.new()
	_vbox.add_theme_constant_override("separation", 4)
	_panel.add_child(_vbox)

	# Title
	var title := Label.new()
	title.text = "=== DEBUG ==="
	title.add_theme_color_override("font_color", Color.CYAN)
	_vbox.add_child(title)

	# Stats labels
	_create_label("fps", "FPS: --")
	_create_label("frame_time", "Frame: --ms")
	_create_separator()
	_create_label("beat_bar", "Bar: --")
	_create_label("beat_pos", "Position: --")
	_create_label("beat_bpm", "BPM: --")
	_create_separator()
	_create_label("player_pos", "Player: --")
	_create_label("player_vel", "Velocity: --")
	_create_label("player_state", "State: --")
	_create_separator()
	_create_label("enemy_count", "Enemies: --")
	_create_label("memory", "Memory: --")

	# Console input
	_create_separator()
	_console_input = LineEdit.new()
	_console_input.placeholder_text = "Enter command..."
	_console_input.text_submitted.connect(_on_command_submitted)
	_vbox.add_child(_console_input)


func _create_label(id: String, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 14)
	_vbox.add_child(label)
	_labels[id] = label


func _create_separator() -> void:
	var sep := HSeparator.new()
	sep.modulate = Color(1, 1, 1, 0.3)
	_vbox.add_child(sep)


func _toggle_visibility() -> void:
	_visible = not _visible
	if _visible:
		_show_ui()
	else:
		_hide_ui()


func _show_ui() -> void:
	_panel.visible = true
	_visible = true


func _hide_ui() -> void:
	_panel.visible = false
	_visible = false


func _update_display() -> void:
	# FPS
	if show_fps:
		var fps := Engine.get_frames_per_second()
		var fps_color := COLOR_GOOD if fps >= 55 else (COLOR_WARNING if fps >= 30 else COLOR_BAD)
		_set_label("fps", "FPS: %d" % fps, fps_color)

		var frame_time := 1000.0 / maxf(fps, 1)
		_set_label("frame_time", "Frame: %.2fms" % frame_time)

	# Beat info
	if show_beat_info:
		var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)
		if deck:
			_set_label("beat_bar", "Bar: %d" % deck.get_current_bar())
			_set_label("beat_pos", "Position: %d/32" % deck.get_current_position())
			if deck.current_pattern:
				_set_label("beat_bpm", "BPM: %.0f" % deck.current_pattern.bpm)

	# Player state
	if show_player_state:
		var player := _get_player()
		if player:
			var pos := player.global_position
			_set_label("player_pos", "Player: (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z])

			if player is CharacterBody3D:
				var vel := player.velocity
				_set_label("player_vel", "Velocity: %.1f" % vel.length())

			if player.has_method("get_state_name"):
				_set_label("player_state", "State: %s" % player.get_state_name())

	# Enemy count
	if show_enemy_count:
		var enemies := get_tree().get_nodes_in_group("enemy")
		_set_label("enemy_count", "Enemies: %d" % enemies.size())

	# Memory
	var memory_mb := OS.get_static_memory_usage() / 1048576.0
	_set_label("memory", "Memory: %.1f MB" % memory_mb)


func _set_label(id: String, text: String, color: Color = COLOR_INFO) -> void:
	if _labels.has(id):
		_labels[id].text = text
		_labels[id].add_theme_color_override("font_color", color)


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		return players[0]
	return null


func _on_command_submitted(command: String) -> void:
	_console_input.clear()

	var parts := command.split(" ", false)
	if parts.is_empty():
		return

	var cmd := parts[0].to_lower()
	var args := parts.slice(1)

	_execute_command(cmd, args)


func _execute_command(cmd: String, args: Array) -> void:
	print("Debug: %s %s" % [cmd, args])

	match cmd:
		"god":
			_toggle_god_mode()
		"noclip":
			_toggle_noclip()
		"speed":
			if args.size() > 0:
				_set_game_speed(float(args[0]))
		"spawn":
			if args.size() > 0:
				_spawn_enemy(args[0])
		"heal":
			_heal_player()
		"kill":
			_kill_all_enemies()
		"beat":
			if args.size() > 0:
				_jump_to_beat(int(args[0]))
		"fps":
			show_fps = not show_fps
		"help":
			_print_help()
		_:
			print("Unknown command: %s" % cmd)

	command_executed.emit(cmd, args)


func _toggle_god_mode() -> void:
	var player := _get_player()
	if player and player.has_method("set_invincible"):
		var current: bool = player.get("is_invincible") if "is_invincible" in player else false
		player.set_invincible(not current)
		print("God mode: %s" % ("ON" if not current else "OFF"))


func _toggle_noclip() -> void:
	var player := _get_player()
	if player and player is CharacterBody3D:
		var collision := player.get_node_or_null("CollisionShape3D")
		if collision:
			collision.disabled = not collision.disabled
			print("Noclip: %s" % ("ON" if collision.disabled else "OFF"))


func _set_game_speed(speed: float) -> void:
	Engine.time_scale = clampf(speed, 0.1, 5.0)
	print("Game speed: %.1fx" % Engine.time_scale)


func _spawn_enemy(enemy_type: String) -> void:
	print("Spawn enemy: %s (not implemented)" % enemy_type)


func _heal_player() -> void:
	var player := _get_player()
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if health.has_method("heal_full"):
			health.heal_full()
			print("Player healed")


func _kill_all_enemies() -> void:
	var enemies := get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy.has_method("die"):
			enemy.die()
	print("Killed %d enemies" % enemies.size())


func _jump_to_beat(beat: int) -> void:
	print("Jump to beat: %d (not implemented)" % beat)


func _print_help() -> void:
	print("=== Debug Commands ===")
	print("god      - Toggle invincibility")
	print("noclip   - Toggle collision")
	print("speed X  - Set game speed (0.1-5.0)")
	print("spawn X  - Spawn enemy type")
	print("heal     - Heal player to full")
	print("kill     - Kill all enemies")
	print("beat X   - Jump to beat position")
	print("fps      - Toggle FPS display")
	print("help     - Show this help")
