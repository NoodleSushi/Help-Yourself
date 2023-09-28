extends Area2D

export(Texture) var tile_texture
var default_position = Vector2()
func _on_Coin_body_entered(body: Node) -> void:
	get_parent().get_parent().update_coin_counter()
	body.pickup()
	queue_free()
