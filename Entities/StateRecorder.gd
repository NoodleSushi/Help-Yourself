extends Node
class_name StateRecorder

var is_recording:bool = true

var keys: = []

var old_timer: = 0.0
var timer: = 0.0

var state_animation = Animation.new()

onready var root = get_parent()

var properties = [
	#[track path, record path]
	#["Node2D:position", "grp_Player:position", true/false]
	#[2] to indicate if you want to record first frame
]

var property_

var property_values = []

var checker: AudioStreamPlayer = AudioStreamPlayer.new()

#func _ready() -> void:
#	add_child(checker)
#	checker.stream = load("res://checker.wav")
#	start(get_parent(), properties)


func start(_root: Node, new_properties: Array, _new_animation : bool = false) -> void:
	state_animation = state_animation.duplicate()
	is_recording = true
	root = _root
	old_timer = 0.0
	timer = 0.0
	keys = []
	properties = new_properties
	for property in properties:
		var track_index: int = state_animation.find_track(property[0])
		if track_index == -1:
			track_index = state_animation.add_track(Animation.TYPE_VALUE)
		var track_path = property[0]
		var record_path = property[0] if property.size() == 1 else property[1]
		var value = get_property_from_node_path(root, record_path)
		state_animation.track_set_path(track_index, property[0])
		keys.append({
			track_index = track_index,
			track_path = track_path,
			record_path = record_path,
			value = value,
			latest_time = 0
		})
		if typeof(value) == TYPE_BOOL:
			state_animation.value_track_set_update_mode(track_index,Animation.UPDATE_TRIGGER)
		if (property.size() == 2 || property[2]) && typeof(value) == TYPE_BOOL:
			state_animation.track_insert_key(track_index, 0.0, value)


func _process(delta: float) -> void:
	if !is_recording:
		return
	
	timer += delta
	for i in range(keys.size()):
		var key = keys[i]
		#If the key is the same then ignore
		if key.value == get_property_from_node_path(root, key.record_path):
			continue
		#update key
		var new_value = get_property_from_node_path(root, key.record_path)
		if key.latest_time != old_timer:
			#state_animation.track_insert_key(key.track_index, old_timer, key.value)
			var key_index = state_animation.track_get_key_count(key.track_index)-1
			state_animation.track_set_key_transition(key.track_index, key_index, 0)
#		if typeof(key.value) == TYPE_BOOL:
#			print("ok")
		state_animation.track_insert_key(key.track_index, timer, new_value)
		#update key's latest timer and value
		key.value = get_property_from_node_path(root, key.record_path)
		key.latest_time = timer
		checker.play()
		keys[i] = key
#		if key.track_index == 2:
#			print(state_animation.track_get_key_count(key.track_index))
	#UPDATE ANIMATION LATEST TIME
	state_animation.length = max(state_animation.length, timer)
	old_timer = timer
#	if Input.is_action_just_pressed("mouse_left"):
#		is_recording = false
#		var anim_player: AnimationPlayer = root.grp_AnimationPlayer
#		anim_player.add_animation("thing", state_animation)
#		anim_player.play("thing")

func get_animation() -> Animation:
	return state_animation

func get_property_from_node_path(_root, path: NodePath):
	var out = _root.get_node(path)
	for sub in range(path.get_subname_count()):
		var subname = path.get_subname(sub)
		out = out[subname]
#		if out is Vector2 || out is Vector3:
#			out = out[subname]
#		else:
#			out = out.get(subname)
	return out
