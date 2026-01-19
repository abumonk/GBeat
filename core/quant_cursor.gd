## QuantCursor - Tracks current playback position within a pattern
class_name QuantCursor
extends RefCounted

var position: int = 0      ## 0-31 within bar
var bar_index: int = 0     ## Current bar number
var loop_count: int = 0    ## How many times pattern has looped
var step_count: int = 0    ## Absolute step count since start


func reset() -> void:
	position = 0
	bar_index = 0
	loop_count = 0
	step_count = 0


func get_absolute_position() -> int:
	return bar_index * 32 + position


func advance(bar_count: int) -> void:
	position += 1
	step_count += 1

	if position >= 32:
		position = 0
		bar_index += 1

		if bar_index >= bar_count:
			bar_index = 0
			loop_count += 1


func duplicate_cursor() -> QuantCursor:
	var c := QuantCursor.new()
	c.position = position
	c.bar_index = bar_index
	c.loop_count = loop_count
	c.step_count = step_count
	return c
