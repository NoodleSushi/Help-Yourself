extends AnimationPlayer

func _process(delta: float) -> void:
	if is_active():
		advance(delta)
	pass
