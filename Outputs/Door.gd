extends StaticBody2D

enum DOOR {
	TILE,
	BASE,
	MID
}

export(Texture) var tile_texture
export(DOOR) var door_type

var new_voltage = true
var current_voltage = true

func recieve_voltage(voltage: bool, index: int):
	new_voltage = voltage

func _ready() -> void:
	$AnimationPlayer.play(str(current_voltage))
	match door_type:
		DOOR.TILE:
			$Sprite.texture = load("res://Assets/Tiles/Door_tile.png")
		DOOR.BASE:
			$Sprite.texture = load("res://Assets/Tiles/Door_base.png")
		DOOR.MID:
			$Sprite.texture = load("res://Assets/Tiles/Door_mid.png")

func _process(delta: float) -> void:
	if new_voltage != current_voltage:
		current_voltage = new_voltage
		$CollisionShape2D.disabled = !current_voltage
		$AnimationPlayer.play(str(current_voltage))
		if new_voltage:
			$Close.play()
		else:
			$Open.play()
