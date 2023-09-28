extends Area2D

enum {
	IDLE,
	SEEK
}


export(Texture) var tile_texture
export(float) var speed_scale = 1


onready var player: KinematicBody2D = get_parent().get_parent().grp_Player


var state: int = IDLE
var move: float = 0
var default_position: Vector2 = Vector2()
var active = true
var death_particles = load("res://Entities/Player/BloodSplatter.tscn")
func reset():
	global_position = default_position
	active = true

func _process(delta: float) -> void:
	visible = active
	if !active:
		return
	var player_center: Vector2 = player.get_node("Center").global_position
	$Sprite.flip_h = player_center.x > global_position.x
	var facing: bool = player.face != sign(global_position.x - player_center.x)
	match state:
		IDLE:
			if facing && player.active:
				state = SEEK
				$AnimationPlayer.play("Chomping")
		SEEK:
			var seek = 1-global_position.distance_to(player_center)/(GameRule.UNIT_SIZE*8)
			seek = clamp(seek, 0, 1)
			$AnimationPlayer.seek(seek, true)
			if !facing || !player.active:
				state = IDLE
				$AnimationPlayer.play("Norm")
	move = damp(move, state, 2, delta)
	position += move*speed_scale*GameRule.UNIT_SIZE*global_position.direction_to(player_center)*delta


static func damp(a: float, b: float, lambda: float, delta: float) -> float:
	return lerp(a, b, 1 - exp(-lambda * delta))




func _on_Chomper_body_entered(_body: Node) -> void:
	if !active:
		return
	$Audio.play()
	get_parent().get_parent().kill_player()


func _on_Chomper_area_entered(_area: Area2D) -> void:
	if !active:
		return
	active = false
	var particle: CPUParticles2D = death_particles.instance()
	get_parent().add_child(particle)
	particle.emitting = true
	particle.global_position = global_position
