extends Node

var is_running: bool = false
var old_timer: float = 0.0
var new_timer: float = 0.0
var length: float = 0.0

"""
{
	data = {
		position: Vector2
	},
	time: float
}
"""



var action_data: Array = []

func start() -> void:
	is_running = true

func stop() -> void:
	is_running = false

func reset() -> void:
	action_data = []
	old_timer = 0.0
	new_timer = 0.0

func record(delta: float, new_data: Dictionary) -> bool:
	if !is_running:
		return false
	old_timer = new_timer
	new_timer += delta
	
	#if data is empty, init new data
	if action_data == []:
		action_data.append(
			{
				data = new_data,
				time = new_timer,
				trans = 1
			}
		)
		length = new_timer
		return true
	
	#if the latest data is different and the time is not long: because ease and stuff and stops
	if action_data.back().data.hash() != new_data.hash():
		if action_data.back().time != old_timer:
#			action_data.append(action_data.back())
			action_data.back().trans = 0
		
		action_data.append(
			{
				data = new_data,
				time = new_timer,
				trans = 1
			}
		)
		length = new_timer
		return true
		
	return false
