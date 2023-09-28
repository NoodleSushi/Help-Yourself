extends Actor

enum STATE {
	IDLE,
	MOVE,
	JUMP,
	FALL
}

signal interacted

export(bool) var active = true setget set_active
export(float) var max_jump_height_scale = 2.3
export(float) var min_jump_height_scale = 1
export(float) var jump_duration = 0.25#0.3
export(PackedScene) var death_particles

var max_jump_velocity: = 0.0
var min_jump_velocity: = 0.0
var snap: = Vector2()
var face = 1


var state = STATE.IDLE
var old_state = null

func set_active(val, is_kill: bool = true):
	active = val
	visible = active
	if has_node("CollisionShape"):
		$CollisionShape.disabled = !active
	if !active:
		$AnimationPlayer.stop()
	if !active && is_kill:
		$Die.play()
		var particle: CPUParticles2D = death_particles.instance()
		get_parent().add_child(particle)
		particle.emitting = true
		particle.global_position = global_position
		
func pickup() -> void:
	$AudioStreamPlayer.play()

func _ready() -> void:
#	$PlayerTimeRecorder.start()
#	Engine.time_scale = 0.25
	init_jump_extensions(0.1, 0.1)
	mass = compute_mass(max_jump_height_scale, jump_duration, gravity)
	max_jump_velocity = compute_jump_velocity(max_jump_height_scale, mass, gravity)
	min_jump_velocity = compute_jump_velocity(min_jump_height_scale, mass, gravity)
	change_state(STATE.IDLE)
	

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("interact"):
		emit_signal("interacted")
#	if Input.is_action_just_pressed("test_restart"):
#		get_tree().reload_current_scene()
#
#	if Input.is_action_just_pressed("play_dat_shit"):
#		var animation_player : AnimationPlayer = $"/root/Node2D/Node2D/AnimationPlayer"
#		animation_player.stop()
#		animation_player.remove_animation("new_animation")
#
#		var data = $PlayerTimeRecorder.action_data
#		var length = $PlayerTimeRecorder.length
#		$PlayerTimeRecorder.reset()
#
#		var animation: = Animation.new()
#		animation.length = data.back().time
#		var track_index = animation.add_track(Animation.TYPE_VALUE)
#		animation.track_set_path(track_index, ".:position")
#		for data_part in data:
#			animation.track_insert_key(track_index, data_part.time, data_part.data.position, data_part.trans)
#
#
#		animation_player.add_animation("new_animation", animation)
#		animation_player.play("new_animation")


func _physics_process(delta: float) -> void:
	if !active:
		return
	if get_direction() != 0:
		face = get_direction()
	$ColorRect2.rect_scale.x = face
	match state:
		STATE.IDLE:
			var data = move(delta, get_direction())
			if velocity.y > 0 && !is_on_floor():
				change_state(STATE.FALL)
			if data.jump_data.has_jumped:
				change_state(STATE.JUMP)
			elif velocity.length() > speed_scale * GameRule.UNIT_SIZE * 0.25:
				change_state(STATE.MOVE)
		
		STATE.MOVE:
			var data = move(delta, get_direction())
#			$AnimationPlayer.playback_speed = velocity.length()/300
			if velocity.y > 0 && !is_on_floor():
				change_state(STATE.FALL)
			elif data.jump_data.has_jumped:
				change_state(STATE.JUMP)
			elif velocity.length() <= speed_scale * GameRule.UNIT_SIZE * 0.25:
				change_state(STATE.IDLE)
		
		STATE.JUMP:
			move(delta, get_direction())
			if velocity.y >= 0:
				change_state(STATE.FALL)
		
		STATE.FALL:
			var data = move(delta, get_direction())
			if data.jump_data.has_jumped:
				change_state(STATE.JUMP)
			elif is_on_floor() && get_direction() == 0:
				change_state(STATE.IDLE)
			elif is_on_floor() && get_direction() != 0:
				change_state(STATE.MOVE)
				
#	if $PlayerTimeRecorder.record(delta,
#		{
#			"position" : global_position.round()
#		}
#	):
#		$AudioStreamPlayer.play()


func _state_entered(new_state, old_state) -> void:
	match new_state:
#		STATE.IDLE:
#			$AnimationPlayer.play("Idle")
		STATE.JUMP:
			$AnimationPlayer.stop()
			$AnimationPlayer.play("Jump")
#		STATE.FALL:
#			$AnimationPlayer.stop()
#			$AnimationPlayer.play("Fall")
		STATE.MOVE:
			$AnimationPlayer.play("Move")
	pass


func _state_exited(old_state, new_state) -> void:
	match old_state:
		STATE.FALL:
			$AnimationPlayer.stop()
			$AnimationPlayer.play("Fall")
		STATE.MOVE:
			$AnimationPlayer.play("INIT")
	pass

###############################################################################################

func move(delta: float, direction: float) -> Dictionary:
	velocity = calculate_move_velocity(
			velocity, 
			direction, 
			mass, 
			gravity,
			speed_scale * GameRule.UNIT_SIZE, 
			delta
	)
	var jump_data = calculate_jump_velocity( velocity,
		is_on_floor(),
		Input.is_action_just_pressed("jump"),
		Input.is_action_just_released("jump"),
		max_jump_velocity,
		min_jump_velocity,
		velocity.y >= 0 && $GhostBusters.is_touching_ghost
	)
	
	velocity = jump_data.velocity
	snap = jump_data.snap
	$PlatformDetector.force_raycast_update()
	velocity = move_and_slide_with_snap(velocity, snap, FLOOR_NORMAL, !$PlatformDetector.is_colliding(), 4, 0.9, false)
#	velocity = calculate_velocity_fix_and_move(
#		velocity,
#		move_and_slide_with_snap(velocity, snap, FLOOR_NORMAL, !$PlatformDetector.is_colliding(), 4, 0.9, false),
#		is_on_ceiling(),
#		is_on_floor(),
#		delta
#	)
	return {
		jump_data = jump_data,
		direction = direction
	}
	
###############################################################################################

func change_state(new_state) -> void:
	old_state = state
	state = new_state
	
	if old_state != null:
		_state_exited(old_state, new_state)
	if new_state != null:
		_state_entered(new_state, old_state)

###############################################################################################

func get_direction() -> float:
	return Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left")
