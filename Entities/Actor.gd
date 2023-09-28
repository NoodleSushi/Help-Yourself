extends KinematicBody2D
class_name Actor

const FLOOR_NORMAL: = Vector2.UP

export(float) var speed_scale: = 8.0


var gravity: = GameRule.GRAVITY
var mass: = 2.0

var velocity: = Vector2()
var jump_extended = false

func compute_mass(jump_height_scale: float, jump_duration: float, gravity: float) -> float:
	#jump_height_scale is also max_height_scale
	return (2 * jump_height_scale * GameRule.UNIT_SIZE / pow(jump_duration, 2)) / gravity

func compute_jump_velocity(jump_height_scale: float, mass: float, gravity: float) -> float:
	return -sqrt(2 * gravity * mass * jump_height_scale * GameRule.UNIT_SIZE)

func calculate_move_velocity(
		linear_velocity: Vector2,
		direction: float,
		mass: float,
		gravity: float,
		speed: float,
		delta: float
	) -> Vector2:
	var new_vel: = linear_velocity
	#new_vel.x = lerpd(new_vel.x, speed * direction , 1e-12, delta)
	#new_vel.x = damp(new_vel.x, speed*direction, 50, delta)
	new_vel.x = speed*direction
	new_vel.y += gravity * mass * delta
	return new_vel

func init_jump_extensions(has_jumped_countdown: = 0.2, has_grounded_countdown: = 0.2) -> void:
	jump_extended = true
	for timer_name in [["HasJumpedTimer", has_jumped_countdown], ["HasGroundedTimer", has_grounded_countdown]]:
		var new_timer: = Timer.new()
		new_timer.name = timer_name[0]
		new_timer.wait_time = timer_name[1]
		new_timer.one_shot = true
		new_timer.process_mode = Timer.TIMER_PROCESS_PHYSICS
		add_child(new_timer)


func calculate_jump_velocity(
		linear_velocity: Vector2,
		on_floor: bool,
		jump_just_pressed: bool,
		jump_just_released: bool,
		max_vel: float,
		min_vel: float = 1,
		air_jump: bool = false
	) -> Dictionary:
	var new_vel: = linear_velocity
	var new_snap: = Vector2(0, GameRule.UNIT_SIZE)*0.25
	var has_jumped_out: = false
	#set min to max if == 1
	min_vel = max_vel if min_vel == 1 else min_vel
	#Grounded Setup
	if on_floor && jump_extended:
		$HasGroundedTimer.start()
	#Early Jump Setup
	if jump_just_pressed && !on_floor && jump_extended:
		$HasJumpedTimer.start()
	
	var jumped_timer_up:bool = !$HasJumpedTimer.is_stopped() if jump_extended else false
	var grounded_timer_up:bool = !$HasGroundedTimer.is_stopped() if jump_extended else false
	
	#Jump Max Velocity and NULLIFY SNAP
	if ((jump_just_pressed || jumped_timer_up) && (on_floor || air_jump)) || (jump_just_pressed && grounded_timer_up):
		new_vel.y = max_vel
		has_jumped_out = true
		new_snap = Vector2()
	#Release Min Velocity if rising
	if jump_just_released && !on_floor && linear_velocity.y < min_vel:
		new_vel.y = min_vel
	#SNAP TO FLOOR IF FALLING
#	if new_vel.y > 0:
#		new_snap = Vector2(0, GameRule.UNIT_SIZE)
	return {
		velocity = new_vel,
		snap = new_snap,
		has_jumped = has_jumped_out
	}

func calculate_velocity_fix_and_move(
		old_velocity: Vector2,
		new_velocity: Vector2,
		is_on_ceiling: bool, 
		is_on_floor: bool,
		delta: float
	) -> Vector2:
	var out_velocity: = old_velocity
	if is_on_ceiling:
		if out_velocity.y < 0:
			out_velocity.y = 0
		position.y += out_velocity.y*delta
	elif old_velocity.y < 0 && is_on_floor:
		out_velocity.x = new_velocity.x
		position.y += out_velocity.y*delta
	else:
		out_velocity = new_velocity
	return out_velocity

static func lerpd(a: float, b: float, c: float, delta: float) -> float:
	return lerp(a, b, 1 - pow(c, delta))

static func damp(a: float, b: float, lambda: float, delta: float) -> float:
	return lerp(a, b, 1 - exp(-lambda * delta))
