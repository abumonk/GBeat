## Main scene - Tests the Sequencer and Movement systems
extends Node3D

@onready var bpm_label: Label = $UI/VBoxContainer/BPMLabel
@onready var position_label: Label = $UI/VBoxContainer/PositionLabel
@onready var state_label: Label = $UI/VBoxContainer/StateLabel
@onready var speed_label: Label = $UI/VBoxContainer/SpeedLabel
@onready var beat_label: Label = $UI/VBoxContainer/BeatLabel
@onready var beat_visualizer: MeshInstance3D = $BeatVisualizer

@onready var player: Player = $Player
@onready var camera_controller: CameraController = $CameraController

var _kick_handle: int = -1
var _snare_handle: int = -1
var _animation_handle: int = -1

var _base_visualizer_scale: Vector3
var _beat_flash_time: float = 0.0


func _ready() -> void:
	_base_visualizer_scale = beat_visualizer.scale

	# Setup camera controller
	camera_controller.target = player
	camera_controller.top_down_camera = $CameraController/TopDownCamera
	camera_controller.side_camera = $CameraController/SideCamera

	# Setup player controller to use camera for relative movement
	player.controller.camera = camera_controller.get_active_camera()

	# Setup movement component
	player.movement.character = player
	player.movement.controller = player.controller

	# Subscribe to beat events
	_kick_handle = Sequencer.subscribe_to_kick(Sequencer.DeckType.GAME, _on_kick)
	_snare_handle = Sequencer.subscribe_to_snare(Sequencer.DeckType.GAME, _on_snare)
	_animation_handle = Sequencer.subscribe_to_animation(Sequencer.DeckType.GAME, _on_animation)

	# Connect to deck state changes
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)
	deck.state_changed.connect(_on_deck_state_changed)

	# Connect to camera switch
	camera_controller.camera_switched.connect(_on_camera_switched)

	beat_label.modulate.a = 0.0

	# Auto-start the beat for movement testing
	Sequencer.play_pattern_by_name(Sequencer.DeckType.GAME, "Basic4_4")


func _exit_tree() -> void:
	if _kick_handle >= 0:
		Sequencer.unsubscribe(_kick_handle)
	if _snare_handle >= 0:
		Sequencer.unsubscribe(_snare_handle)
	if _animation_handle >= 0:
		Sequencer.unsubscribe(_animation_handle)


func _process(delta: float) -> void:
	_update_ui()
	_update_visualizer(delta)


func _update_ui() -> void:
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)

	bpm_label.text = "BPM: %.0f" % deck.get_current_bpm()
	position_label.text = "Position: %d / Bar: %d / Loop: %d" % [
		deck.get_current_position(),
		deck.get_current_bar(),
		deck.get_loop_count()
	]

	var state_text := "Idle"
	match deck.state:
		Deck.State.IDLE:
			state_text = "Idle"
		Deck.State.READY:
			state_text = "Ready"
		Deck.State.PLAYING:
			state_text = "Playing"
		Deck.State.PAUSED:
			state_text = "Paused"
		Deck.State.QUEUED_TRANSITION:
			state_text = "Transitioning"

	state_label.text = "State: %s" % state_text

	# Show player speed
	if player and player.movement:
		speed_label.text = "Speed: %.1f" % player.movement.get_speed()


func _update_visualizer(delta: float) -> void:
	# Decay flash
	if _beat_flash_time > 0:
		_beat_flash_time -= delta * 4.0
		_beat_flash_time = max(0, _beat_flash_time)

		var t := _beat_flash_time
		beat_visualizer.scale = _base_visualizer_scale * (1.0 + t * 0.5)
		beat_label.modulate.a = t


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dodge"):  # Space
		_toggle_playback()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_P:
			_toggle_pause()


func _toggle_playback() -> void:
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)

	if deck.is_playing() or deck.is_paused():
		Sequencer.stop(Sequencer.DeckType.GAME)
	else:
		# Play the default pattern
		Sequencer.play_pattern_by_name(Sequencer.DeckType.GAME, "Basic4_4")


func _toggle_pause() -> void:
	var deck := Sequencer.get_deck(Sequencer.DeckType.GAME)

	if deck.is_playing():
		Sequencer.pause(Sequencer.DeckType.GAME)
	elif deck.is_paused():
		Sequencer.resume(Sequencer.DeckType.GAME)


func _on_kick(_event: SequencerEvent) -> void:
	_beat_flash_time = 1.0
	beat_label.text = "KICK"
	beat_label.modulate = Color.RED

	# Visual feedback on sphere
	var mat := beat_visualizer.get_surface_override_material(0)
	if not mat:
		mat = StandardMaterial3D.new()
		beat_visualizer.set_surface_override_material(0, mat)
	mat.albedo_color = Color.RED
	mat.emission_enabled = true
	mat.emission = Color.RED
	mat.emission_energy_multiplier = 2.0


func _on_snare(_event: SequencerEvent) -> void:
	_beat_flash_time = 1.0
	beat_label.text = "SNARE"
	beat_label.modulate = Color.GREEN

	var mat := beat_visualizer.get_surface_override_material(0)
	if mat:
		mat.albedo_color = Color.GREEN
		mat.emission = Color.GREEN


func _on_animation(_event: SequencerEvent) -> void:
	# Animation quants happen on every beat
	pass


func _on_deck_state_changed(old_state: Deck.State, new_state: Deck.State) -> void:
	print("Deck state changed: %s -> %s" % [
		Deck.State.keys()[old_state],
		Deck.State.keys()[new_state]
	])


func _on_camera_switched(is_top_down: bool) -> void:
	# Update player controller camera reference
	player.controller.camera = camera_controller.get_active_camera()
	print("Camera switched to: %s" % ("Top-Down" if is_top_down else "Side"))
