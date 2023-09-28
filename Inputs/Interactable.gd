extends Node

export(bool) var interact = false setget set_interact
signal has_interacted

func set_interact(val):
	interact = val
	emit_signal("has_interacted")
