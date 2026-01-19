## SubscriptionStore - Manages callbacks for quant events
## Routes events to matching subscribers based on deck and quant type
class_name SubscriptionStore
extends RefCounted


class Subscription:
	var handle: int
	var deck: Deck
	var quant_type: Quant.Type
	var required_layers: Array[Quant.Type]
	var callback: Callable
	var active: bool = true


var _subscriptions: Dictionary = {}  ## handle -> Subscription
var _by_deck_and_type: Dictionary = {}  ## deck -> quant_type -> Array[Subscription]
var _next_handle: int = 1


func add_subscription(
	deck: Deck,
	quant_type: Quant.Type,
	callback: Callable,
	required_layers: Array[Quant.Type] = []
) -> int:
	var sub := Subscription.new()
	sub.handle = _next_handle
	sub.deck = deck
	sub.quant_type = quant_type
	sub.required_layers = required_layers
	sub.callback = callback
	sub.active = true

	_subscriptions[sub.handle] = sub

	# Index by deck and type for fast lookup
	if not _by_deck_and_type.has(deck):
		_by_deck_and_type[deck] = {}
	if not _by_deck_and_type[deck].has(quant_type):
		_by_deck_and_type[deck][quant_type] = []
	_by_deck_and_type[deck][quant_type].append(sub)

	_next_handle += 1
	return sub.handle


func remove_subscription(handle: int) -> void:
	if not _subscriptions.has(handle):
		return

	var sub: Subscription = _subscriptions[handle]
	sub.active = false
	_subscriptions.erase(handle)

	# Remove from index
	if _by_deck_and_type.has(sub.deck):
		if _by_deck_and_type[sub.deck].has(sub.quant_type):
			_by_deck_and_type[sub.deck][sub.quant_type].erase(sub)


func dispatch(event: SequencerEvent) -> void:
	var deck: Deck = event.deck
	var quant_type: Quant.Type = event.quant.type

	if not _by_deck_and_type.has(deck):
		return
	if not _by_deck_and_type[deck].has(quant_type):
		return

	var subs: Array = _by_deck_and_type[deck][quant_type]
	for sub in subs:
		if not sub.active:
			continue

		# Check required layers
		if _check_required_layers(event, sub.required_layers):
			if sub.callback.is_valid():
				sub.callback.call(event)


func _check_required_layers(event: SequencerEvent, required: Array[Quant.Type]) -> bool:
	if required.is_empty():
		return true

	# Check if pattern has quants of all required types at this position
	var pattern: Pattern = event.pattern
	var position: int = event.quant_index

	for req_type in required:
		var found := false
		for quant in pattern.get_quants_at_position(position):
			if quant.type == req_type:
				found = true
				break
		if not found:
			return false

	return true


func has_subscription(handle: int) -> bool:
	return _subscriptions.has(handle)


func get_subscription_count() -> int:
	return _subscriptions.size()


func get_subscription_count_for_deck(deck: Deck) -> int:
	if not _by_deck_and_type.has(deck):
		return 0

	var count := 0
	for type_subs in _by_deck_and_type[deck].values():
		count += type_subs.size()
	return count


func clear_subscriptions_for_deck(deck: Deck) -> void:
	if not _by_deck_and_type.has(deck):
		return

	# Remove all subscriptions for this deck
	for type_subs in _by_deck_and_type[deck].values():
		for sub in type_subs:
			sub.active = false
			_subscriptions.erase(sub.handle)

	_by_deck_and_type.erase(deck)


func clear_all() -> void:
	_subscriptions.clear()
	_by_deck_and_type.clear()
	# Don't reset _next_handle to avoid reusing handles


func set_subscription_active(handle: int, active: bool) -> void:
	if _subscriptions.has(handle):
		_subscriptions[handle].active = active
