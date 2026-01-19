## SequencerEvent - Data emitted when a quant boundary is reached
class_name SequencerEvent
extends RefCounted

var deck: Node                    ## The Deck that emitted this event
var pattern: Resource            ## The Pattern being played
var quant: Quant                 ## The quant that triggered
var event_time_seconds: float    ## Time when event occurred
var quant_index: int             ## Position within bar (0-31)
var bar_index: int               ## Which bar in the pattern
var pattern_loop_index: int      ## How many times pattern has looped
var absolute_quant_index: int    ## Total quants since playback started


func _init() -> void:
	pass


static func create(
	p_deck: Node,
	p_pattern: Resource,
	p_quant: Quant,
	p_cursor: QuantCursor
) -> SequencerEvent:
	var event := SequencerEvent.new()
	event.deck = p_deck
	event.pattern = p_pattern
	event.quant = p_quant
	event.event_time_seconds = Time.get_ticks_msec() / 1000.0
	event.quant_index = p_cursor.position
	event.bar_index = p_cursor.bar_index
	event.pattern_loop_index = p_cursor.loop_count
	event.absolute_quant_index = p_cursor.step_count
	return event
