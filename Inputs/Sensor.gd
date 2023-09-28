extends Area2D

enum SENSOR {
	PLAYER,
	GHOST,
	PLAYERANDGHOST
}

export(Texture) var tile_texture
export(SENSOR) var sensor_type
var original_voltage = false
var recordable = false

signal voltage_sent(voltage)

onready var real_voltage = original_voltage setget set_real_voltage

var player_count = 0
var ghost_count = 0

func _ready() -> void:
	$Sprite.frame = sensor_type
	reset()

func reset():
	set_real_voltage(original_voltage)


func set_real_voltage(val):
	real_voltage = val
	emit_signal("voltage_sent", val)

func update_voltage():
	var new_voltage = (player_count + ghost_count) > 0
	if new_voltage != real_voltage:
		set_real_voltage(new_voltage)
		if !get_parent().get_parent().setting_up:
			$SwitchSound.play()

func _on_Sensor_body_entered(body: Node) -> void:
	if [SENSOR.PLAYER, SENSOR.PLAYERANDGHOST].has(sensor_type):
		player_count += 1
		update_voltage()
	


func _on_Sensor_body_exited(body: Node) -> void:
	if [SENSOR.PLAYER, SENSOR.PLAYERANDGHOST].has(sensor_type):
		player_count -= 1
		update_voltage()


func _on_Sensor_area_entered(area: Area2D) -> void:
	if [SENSOR.GHOST, SENSOR.PLAYERANDGHOST].has(sensor_type):
		ghost_count += 1
		update_voltage()


func _on_Sensor_area_exited(area: Area2D) -> void:
	if [SENSOR.GHOST, SENSOR.PLAYERANDGHOST].has(sensor_type):
		ghost_count -= 1
		update_voltage()
