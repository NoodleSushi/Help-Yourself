extends Area2D


var is_touching_ghost = false

func _on_GhostBusters_area_entered(area: Area2D) -> void:
	is_touching_ghost = true


func _on_GhostBusters_area_exited(area: Area2D) -> void:
	is_touching_ghost = false
