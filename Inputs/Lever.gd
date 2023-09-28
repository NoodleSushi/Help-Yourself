extends Area2D


export(Texture) var tile_texture
export(bool) var original_voltage = false
export(bool) var player_interact = false setget set_player_interact
export(bool) var global_interact = false setget set_global_interact
export(bool) var recordable = true

signal voltage_sent(voltage)

onready var real_voltage = original_voltage setget set_real_voltage


func _ready() -> void:
	reset()
	if recordable:
		$Sprite.texture = load("res://Assets/Tiles/ghost lever.png")
	else:
		$Sprite.texture = load("res://Assets/Tiles/lever.png")
	#$Interactable.connect("has_interacted", self, "_on_Interactable_has_interacted")

func reset():
	set_real_voltage(original_voltage)

func set_global_interact(val):
	global_interact = val
	set_real_voltage(!real_voltage)


func set_real_voltage(val):
	real_voltage = val
	emit_signal("voltage_sent", val)
	if !get_parent().get_parent().setting_up:
		$SwitchSound.play()
	$AnimationPlayer.play(str(real_voltage))

func _on_Lever_body_entered(body: Node) -> void:
	body.connect("interacted", self, "_on_Player_interacted")


func _on_Lever_body_exited(body: Node) -> void:
	body.disconnect("interacted", self, "_on_Player_interacted")


func _on_Player_interacted():
	set_player_interact(!player_interact)

func set_player_interact(val):
	player_interact = val
	set_real_voltage(!real_voltage)
