## DebugConsole - Command-line style debug console
class_name DebugConsole
extends CanvasLayer


signal command_executed(command: String, result: String)


@export var toggle_action: String = "debug_console"
@export var max_history: int = 100
@export var max_output_lines: int = 50

## UI
var _panel: PanelContainer
var _output: RichTextLabel
var _input: LineEdit
var _visible := false

## Command history
var _command_history: Array[String] = []
var _history_index: int = -1

## Registered commands
var _commands: Dictionary = {}


func _ready() -> void:
	layer = 101

	_create_ui()
	_hide_console()
	_register_default_commands()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(toggle_action):
		_toggle_visibility()
		get_viewport().set_input_as_handled()

	if not _visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_UP:
			_history_up()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_DOWN:
			_history_down()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_TAB:
			_autocomplete()
			get_viewport().set_input_as_handled()


func _create_ui() -> void:
	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_panel.offset_top = -250
	add_child(_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.9)
	style.set_corner_radius_all(5)
	style.set_content_margin_all(10)
	_panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 5)
	_panel.add_child(vbox)

	# Output area
	_output = RichTextLabel.new()
	_output.bbcode_enabled = true
	_output.scroll_following = true
	_output.selection_enabled = true
	_output.custom_minimum_size = Vector2(0, 180)
	_output.add_theme_color_override("default_color", Color.WHITE)
	vbox.add_child(_output)

	# Input area
	var input_box := HBoxContainer.new()
	vbox.add_child(input_box)

	var prompt := Label.new()
	prompt.text = "> "
	prompt.add_theme_color_override("font_color", Color.GREEN)
	input_box.add_child(prompt)

	_input = LineEdit.new()
	_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_input.text_submitted.connect(_on_command_submitted)
	input_box.add_child(_input)

	# Welcome message
	_print_line("[color=cyan]=== GBeat Debug Console ===[/color]")
	_print_line("Type 'help' for available commands\n")


func _toggle_visibility() -> void:
	_visible = not _visible
	if _visible:
		_show_console()
	else:
		_hide_console()


func _show_console() -> void:
	_panel.visible = true
	_visible = true
	_input.grab_focus()


func _hide_console() -> void:
	_panel.visible = false
	_visible = false


func _on_command_submitted(text: String) -> void:
	_input.clear()

	if text.strip_edges().is_empty():
		return

	# Add to history
	_command_history.append(text)
	if _command_history.size() > max_history:
		_command_history.remove_at(0)
	_history_index = -1

	# Echo command
	_print_line("[color=green]> %s[/color]" % text)

	# Parse and execute
	var parts := text.split(" ", false)
	var cmd := parts[0].to_lower()
	var args := parts.slice(1)

	_execute_command(cmd, args)


func _execute_command(cmd: String, args: Array) -> void:
	if _commands.has(cmd):
		var command_info: Dictionary = _commands[cmd]
		var result: String = command_info.callback.call(args)
		if not result.is_empty():
			_print_line(result)
		command_executed.emit(cmd, result)
	else:
		_print_line("[color=red]Unknown command: %s[/color]" % cmd)


func _history_up() -> void:
	if _command_history.is_empty():
		return

	if _history_index < 0:
		_history_index = _command_history.size() - 1
	elif _history_index > 0:
		_history_index -= 1

	_input.text = _command_history[_history_index]
	_input.caret_column = _input.text.length()


func _history_down() -> void:
	if _history_index < 0:
		return

	_history_index += 1
	if _history_index >= _command_history.size():
		_history_index = -1
		_input.text = ""
	else:
		_input.text = _command_history[_history_index]

	_input.caret_column = _input.text.length()


func _autocomplete() -> void:
	var text := _input.text.to_lower()
	if text.is_empty():
		return

	var matches: Array[String] = []
	for cmd in _commands.keys():
		if cmd.begins_with(text):
			matches.append(cmd)

	if matches.size() == 1:
		_input.text = matches[0] + " "
		_input.caret_column = _input.text.length()
	elif matches.size() > 1:
		_print_line("Matches: " + ", ".join(matches))


func _print_line(text: String) -> void:
	_output.append_text(text + "\n")

	# Limit output lines
	while _output.get_line_count() > max_output_lines:
		var current := _output.text
		var newline_pos := current.find("\n")
		if newline_pos > 0:
			_output.text = current.substr(newline_pos + 1)


## Register a new command
func register_command(name: String, callback: Callable, description: String = "", usage: String = "") -> void:
	_commands[name.to_lower()] = {
		"callback": callback,
		"description": description,
		"usage": usage,
	}


## Default commands
func _register_default_commands() -> void:
	register_command("help", _cmd_help, "Show available commands", "help [command]")
	register_command("clear", _cmd_clear, "Clear console output")
	register_command("god", _cmd_god, "Toggle god mode")
	register_command("noclip", _cmd_noclip, "Toggle noclip")
	register_command("speed", _cmd_speed, "Set game speed", "speed <multiplier>")
	register_command("heal", _cmd_heal, "Heal player to full")
	register_command("kill", _cmd_kill, "Kill all enemies")
	register_command("spawn", _cmd_spawn, "Spawn enemy", "spawn <type>")
	register_command("beat", _cmd_beat, "Show/set beat position", "beat [position]")
	register_command("tp", _cmd_teleport, "Teleport player", "tp <x> <y> <z>")
	register_command("give", _cmd_give, "Give item/ability", "give <item>")
	register_command("stats", _cmd_stats, "Show game stats")
	register_command("quit", _cmd_quit, "Quit the game")


func _cmd_help(args: Array) -> String:
	if args.size() > 0:
		var cmd := args[0].to_lower()
		if _commands.has(cmd):
			var info: Dictionary = _commands[cmd]
			var result := "[color=yellow]%s[/color]: %s" % [cmd, info.description]
			if not info.usage.is_empty():
				result += "\nUsage: " + info.usage
			return result
		return "[color=red]Unknown command: %s[/color]" % cmd

	var result := "[color=cyan]Available commands:[/color]\n"
	var names := _commands.keys()
	names.sort()
	for name in names:
		var info: Dictionary = _commands[name]
		result += "  [color=yellow]%s[/color] - %s\n" % [name, info.description]
	return result


func _cmd_clear(_args: Array) -> String:
	_output.clear()
	return ""


func _cmd_god(_args: Array) -> String:
	var player := _get_player()
	if player and player.has_method("set_invincible"):
		var current: bool = player.get("is_invincible") if "is_invincible" in player else false
		player.set_invincible(not current)
		return "God mode: %s" % ("ON" if not current else "OFF")
	return "Cannot toggle god mode"


func _cmd_noclip(_args: Array) -> String:
	var player := _get_player()
	if player and player is CharacterBody3D:
		var collision := player.get_node_or_null("CollisionShape3D")
		if collision:
			collision.disabled = not collision.disabled
			return "Noclip: %s" % ("ON" if collision.disabled else "OFF")
	return "Cannot toggle noclip"


func _cmd_speed(args: Array) -> String:
	if args.is_empty():
		return "Current speed: %.2fx" % Engine.time_scale

	var speed := float(args[0])
	Engine.time_scale = clampf(speed, 0.1, 5.0)
	return "Game speed set to %.2fx" % Engine.time_scale


func _cmd_heal(_args: Array) -> String:
	var player := _get_player()
	if player and player.has_node("HealthComponent"):
		var health = player.get_node("HealthComponent")
		if health.has_method("heal_full"):
			health.heal_full()
			return "Player healed to full"
	return "Cannot heal player"


func _cmd_kill(_args: Array) -> String:
	var enemies := get_tree().get_nodes_in_group("enemy")
	var count := enemies.size()
	for enemy in enemies:
		if enemy.has_method("die"):
			enemy.die()
	return "Killed %d enemies" % count


func _cmd_spawn(args: Array) -> String:
	if args.is_empty():
		return "Usage: spawn <enemy_type>"
	return "Spawn not implemented: %s" % args[0]


func _cmd_beat(args: Array) -> String:
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)
	if not deck:
		return "No active deck"

	if args.is_empty():
		return "Bar: %d, Position: %d/32, BPM: %.0f" % [
			deck.get_current_bar(),
			deck.get_current_position(),
			deck.current_pattern.bpm if deck.current_pattern else 0
		]

	return "Beat seek not implemented"


func _cmd_teleport(args: Array) -> String:
	if args.size() < 3:
		return "Usage: tp <x> <y> <z>"

	var player := _get_player()
	if player:
		var pos := Vector3(float(args[0]), float(args[1]), float(args[2]))
		player.global_position = pos
		return "Teleported to (%.1f, %.1f, %.1f)" % [pos.x, pos.y, pos.z]

	return "No player found"


func _cmd_give(args: Array) -> String:
	if args.is_empty():
		return "Usage: give <item>"
	return "Give not implemented: %s" % args[0]


func _cmd_stats(_args: Array) -> String:
	var result := "[color=cyan]Game Stats:[/color]\n"
	result += "FPS: %d\n" % Engine.get_frames_per_second()
	result += "Memory: %.1f MB\n" % (OS.get_static_memory_usage() / 1048576.0)
	result += "Objects: %d\n" % Performance.get_monitor(Performance.OBJECT_COUNT)
	result += "Nodes: %d\n" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	return result


func _cmd_quit(_args: Array) -> String:
	get_tree().quit()
	return "Goodbye!"


func _get_player() -> Node3D:
	var players := get_tree().get_nodes_in_group("player")
	return players[0] if not players.is_empty() else null
