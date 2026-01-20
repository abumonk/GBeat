## HUD - Main heads-up display for gameplay
class_name HUD
extends CanvasLayer


signal pause_requested()


## References
@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var combo_counter: ComboCounter = $MarginContainer/VBoxContainer/TopBar/ComboCounter
@onready var score_label: Label = $MarginContainer/VBoxContainer/TopBar/ScoreLabel
@onready var ability_bar: AbilityBar = $MarginContainer/VBoxContainer/BottomBar/AbilityBar
@onready var timing_indicator: TimingIndicator = $CenterContainer/TimingIndicator
@onready var beat_indicator: BeatIndicator = $MarginContainer/VBoxContainer/TopBar/BeatIndicator

## State
var _player: Node
var _score: int = 0


func _ready() -> void:
	_connect_signals()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		pause_requested.emit()


func _connect_signals() -> void:
	# Connect to sequencer for beat visualization
	Sequencer.subscribe_to_tick(Sequencer.DeckType.GAME, _on_beat)


func _on_beat(event: SequencerEvent) -> void:
	if beat_indicator:
		beat_indicator.pulse(event.quant.value)


## Bind to player for updates
func bind_player(player: Node) -> void:
	_player = player

	# Connect player signals if available
	if player.has_signal("health_changed"):
		player.health_changed.connect(_on_player_health_changed)
	if player.has_signal("combo_changed"):
		player.combo_changed.connect(_on_combo_changed)
	if player.has_signal("timing_result"):
		player.timing_result.connect(_on_timing_result)


func _on_player_health_changed(current: float, max_health: float) -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current


func _on_combo_changed(combo: int, multiplier: float) -> void:
	if combo_counter:
		combo_counter.set_combo(combo, multiplier)


func _on_timing_result(rating: String, accuracy: float) -> void:
	if timing_indicator:
		timing_indicator.show_rating(rating, accuracy)


func add_score(amount: int) -> void:
	_score += amount
	if score_label:
		score_label.text = "Score: %d" % _score


func get_score() -> int:
	return _score


func reset() -> void:
	_score = 0
	if score_label:
		score_label.text = "Score: 0"
	if combo_counter:
		combo_counter.reset()
	if health_bar:
		health_bar.value = health_bar.max_value
