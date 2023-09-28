extends CanvasLayer

signal is_done_opening

func is_running() -> bool:
	return $AnimationPlayer.is_playing()

func open() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play("open")

func close() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play("close")
