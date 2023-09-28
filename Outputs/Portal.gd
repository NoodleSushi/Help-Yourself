extends Area2D

export(Texture) var tile_texture

var new_voltage = true
var current_voltage = true

func recieve_voltage(voltage: bool, index: int):
	new_voltage = voltage

func _ready() -> void:
	$AnimationPlayer.play(str(current_voltage))

func _process(delta: float) -> void:
	if new_voltage != current_voltage:
		current_voltage = new_voltage
		$CollisionShape2D.disabled = !current_voltage
		$AnimationPlayer.play(str(current_voltage))


func _on_Portal_body_entered(body: Node) -> void:
	get_parent().get_parent().win()
