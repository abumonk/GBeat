## Sequencer - Global singleton managing beat timing and event distribution
## This is the heart of BeatBeat's rhythm system
extends Node

signal calibration_completed(delay_seconds: float)

enum DeckType { MENU, GAME }

var decks: Dictionary = {}  ## DeckType -> Deck
var subscription_store: SubscriptionStore
var pattern_collection: PatternCollection
var wave_collection: WaveCollection

var audio_delay_seconds: float = 0.0


func _ready() -> void:
	subscription_store = SubscriptionStore.new()
	pattern_collection = PatternCollection.new()
	wave_collection = WaveCollection.new()

	# Create both decks
	decks[DeckType.MENU] = _create_deck("MenuDeck")
	decks[DeckType.GAME] = _create_deck("GameDeck")

	# Create a default pattern for testing
	var default_pattern := Pattern.create_basic_4_4(120.0)
	pattern_collection.add_pattern(default_pattern)


func _create_deck(deck_name: String) -> Deck:
	var deck := Deck.new()
	deck.name = deck_name
	deck.quant_event.connect(_on_deck_quant_event.bind(deck))
	add_child(deck)
	return deck


func _on_deck_quant_event(event: SequencerEvent, _deck: Deck) -> void:
	subscription_store.dispatch(event)


## === Subscription API ===

func subscribe(
	deck_type: DeckType,
	quant_type: Quant.Type,
	callback: Callable,
	required_layers: Array[Quant.Type] = []
) -> int:
	var deck: Deck = decks[deck_type]
	return subscription_store.add_subscription(deck, quant_type, callback, required_layers)


func unsubscribe(handle: int) -> void:
	subscription_store.remove_subscription(handle)


func set_subscription_active(handle: int, active: bool) -> void:
	subscription_store.set_subscription_active(handle, active)


## === Deck Control API ===

func set_next_pattern(deck_type: DeckType, pattern: Pattern) -> void:
	decks[deck_type].set_next_pattern(pattern)


func start(deck_type: DeckType) -> void:
	decks[deck_type].start()


func stop(deck_type: DeckType) -> void:
	decks[deck_type].stop()


func pause(deck_type: DeckType) -> void:
	decks[deck_type].pause()


func resume(deck_type: DeckType) -> void:
	decks[deck_type].resume()


## === Pattern API ===

func play_pattern_by_name(deck_type: DeckType, pattern_name: String) -> void:
	var pattern := pattern_collection.get_pattern(pattern_name)
	if pattern:
		set_next_pattern(deck_type, pattern)
		start(deck_type)
	else:
		push_error("Pattern not found: %s" % pattern_name)


func play_pattern(deck_type: DeckType, pattern: Pattern) -> void:
	set_next_pattern(deck_type, pattern)
	start(deck_type)


func register_pattern(pattern: Pattern) -> void:
	pattern_collection.add_pattern(pattern)


func get_pattern(pattern_name: String) -> Pattern:
	return pattern_collection.get_pattern(pattern_name)


## === Query API ===

func get_next_quant_of_type(deck_type: DeckType, quant_type: Quant.Type) -> Quant:
	var deck: Deck = decks[deck_type]
	if deck.current_pattern:
		return deck.current_pattern.get_next_quant(quant_type, deck.cursor.position)
	return null


func get_beats_to_quant(deck_type: DeckType, quant_type: Quant.Type) -> float:
	var deck: Deck = decks[deck_type]
	if deck.current_pattern:
		return deck.current_pattern.get_beats_to_quant(quant_type, deck.cursor.position)
	return -1.0


func get_deck(deck_type: DeckType) -> Deck:
	return decks[deck_type]


func get_current_bpm(deck_type: DeckType) -> float:
	return decks[deck_type].get_current_bpm()


func get_current_position(deck_type: DeckType) -> int:
	return decks[deck_type].get_current_position()


func get_current_bar(deck_type: DeckType) -> int:
	return decks[deck_type].get_current_bar()


func get_time_to_next_beat(deck_type: DeckType) -> float:
	return decks[deck_type].get_time_to_next_beat()


func is_playing(deck_type: DeckType) -> bool:
	return decks[deck_type].is_playing()


## === Audio Calibration ===

func calibrate_audio_delay(iterations: int = 5, tone_seconds: float = 0.1, silence_seconds: float = 0.5) -> void:
	# Implementation would play tones and measure round-trip latency
	# Simplified: just set a default value
	audio_delay_seconds = 0.02  # 20ms default
	calibration_completed.emit(audio_delay_seconds)


func set_audio_delay(delay: float) -> void:
	audio_delay_seconds = delay


func get_audio_delay() -> float:
	return audio_delay_seconds


## === Convenience Functions ===

func subscribe_to_kick(deck_type: DeckType, callback: Callable) -> int:
	return subscribe(deck_type, Quant.Type.KICK, callback)


func subscribe_to_snare(deck_type: DeckType, callback: Callable) -> int:
	return subscribe(deck_type, Quant.Type.SNARE, callback)


func subscribe_to_animation(deck_type: DeckType, callback: Callable) -> int:
	return subscribe(deck_type, Quant.Type.ANIMATION, callback)


func subscribe_to_tick(deck_type: DeckType, callback: Callable) -> int:
	return subscribe(deck_type, Quant.Type.TICK, callback)
