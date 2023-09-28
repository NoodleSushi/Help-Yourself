extends Area2D

enum BUTTON {
	PLAYER,
	GHOST,
	PLAYERANDGHOST
}

export(Texture) var tile_texture
export(BUTTON) var button_type
var original_voltage = false
var recordable = false

signal voltage_sent(voltage)

onready var real_voltage = original_voltage setget set_real_voltage

var player_count = 0
var ghost_count = 0

func _ready() -> void:
	$Sprite.texture = load((["res://Assets/Tiles/Button_Player.png","res://Assets/Tiles/Button_Ghost.png","res://Assets/Tiles/Button_Player&Ghost.png"])[button_type])
	reset()

func reset():
	$Timer.stop()
	set_real_voltage(original_voltage)
	update_voltage()


func set_real_voltage(val):
	real_voltage = val
	emit_signal("voltage_sent", val)
	if !get_parent().get_parent().setting_up:
		$SwitchSound.play()

func update_voltage(is_timer : bool = false):
	var new_voltage = (player_count + ghost_count) > 0
	if new_voltage != real_voltage:
		if !new_voltage && !is_timer && !get_parent().get_parent().setting_up:
			$Timer.start()
			return
		$Sprite.frame = int(new_voltage)
		set_real_voltage(new_voltage)


func _on_Button_area_entered(_area: Area2D) -> void:
	if [BUTTON.GHOST, BUTTON.PLAYERANDGHOST].has(button_type):
		ghost_count += 1
		update_voltage()


func _on_Button_area_exited(_area: Area2D) -> void:
	if [BUTTON.GHOST, BUTTON.PLAYERANDGHOST].has(button_type):
		ghost_count -= 1
		update_voltage()


func _on_Button_body_entered(_body: Node) -> void:
	if [BUTTON.PLAYER, BUTTON.PLAYERANDGHOST].has(button_type):
		player_count += 1
		update_voltage()


func _on_Button_body_exited(_body: Node) -> void:
	if [BUTTON.PLAYER, BUTTON.PLAYERANDGHOST].has(button_type):
		player_count -= 1
		update_voltage()
