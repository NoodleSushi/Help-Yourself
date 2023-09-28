extends Area2D

export(bool) var active = true setget set_active

func set_active(val):
	active = val
	modulate = ColorN("white", 0.5) if active else ColorN("red", 0.5)
	if !has_node("AnimationPlayer") || !has_node("StaticBody2D/CollisionShape2D"):
		return
	if !active:
		$AnimationPlayer.stop()
	else:
		$AnimationPlayer.play("New Anim")
	$StaticBody2D/CollisionShape2D.disabled = active
