extends Node2D

signal reset

var cell_size: Vector2 = Vector2(GameRule.UNIT_SIZE,GameRule.UNIT_SIZE)

var grp_Ghosts_instance: PackedScene = load("res://Entities/Ghost/Ghost.tscn")

var grp_AnimationPlayer: = AnimationPlayer.new()
var grp_Ghosts: = Node.new()
var grp_StaticBodies: = TileMap.new()
var grp_Props: = TileMap.new()
var grp_Player: KinematicBody2D = load("res://Entities/Player/Player.tscn").instance()
var grp_Entities: = Node.new()
var grp_Inputs: = Node.new()
var grp_Logic: = Node.new()
var grp_Outputs: = Node.new()
var grp_StateRecorder: = StateRecorder.new()
var timer: = Timer.new()
var input_ends = {}

var level_data = GameRule.game_level_data

var grp_StateRecorder_properties = []

var countdown = 0
var coin_counter = 0
var win = false
var setting_up = true
func _ready() -> void:
	setting_up = true
	$CanvasLayer/Control/Back2LvlEditor.visible = GameRule.is_editing_level
	$CanvasLayer/Control/Restart.visible = GameRule.is_editing_level
	$CanvasLayer/Control/Banner/Back.visible = !GameRule.is_editing_level
	$CanvasLayer/Control/Banner/Rewind.visible = !GameRule.is_editing_level
	if GameRule.level_num >= 11 || GameRule.is_editing_level:
		$CanvasLayer/Control/WinScreen/ColorRect/NxtLvl/WinNxtLvlButton.visible = false
		$CanvasLayer/Control/WinScreen/ColorRect/NxtLvl.visible = false
	if GameRule.is_editing_level:
		$CanvasLayer/Control/LevelName.text = ""
	else:
		$CanvasLayer/Control/LevelName.text = GameRule.level_name
	#WINDOW SIZE CHANGER
	# get_tree().get_root().connect("size_changed", self, "_size_changed")
	# _size_changed()
	
	load_groups()
	add_child(timer)
	timer.connect("timeout", self, "respawn")
	setting_up = false

func win() -> void:
	grp_Player.set_active(false, false)
	grp_AnimationPlayer.stop()
	$AudioStreamPlayer.stop()
	$WinSound.play()
	$CanvasLayer/Control/AnimationPlayer.play("Win")
	# var second = fmod(countdown,60.0)
	# var minute = int(countdown)/60
	# var mili = "%02.2f" % [countdown]
	var string = "YOU WIN!\n\nTIME: "+$CanvasLayer/Control/Banner/min.text+":"+$CanvasLayer/Control/Banner/sec.text+"."+$CanvasLayer/Control/Banner/mili.text+"\nCOINS: "+$CanvasLayer/Control/Banner/coin_count.text+"\n"
	
	$CanvasLayer/Control/WinScreen/ColorRect/INFO.text = string
	win = true

func update_countdown(delta: float) -> void:
	countdown += delta
	var second = fmod(countdown,60.0)
	var minute = int(countdown)/60
	
	#$CanvasLayer/Control/Banner/Countdown.text = "%02d : %02.2f" % [minute, second]
	$CanvasLayer/Control/Banner/sec.text = "%02d" % [second]
	$CanvasLayer/Control/Banner/min.text = "%02d" % [minute]
	var mili = "%02.2f" % [countdown]
	$CanvasLayer/Control/Banner/mili.text = mili.substr(mili.length()-2)

func load_groups() -> void:
	#reserved for player
	for _i in range(2):
		grp_StateRecorder_properties.append([])
	
	#LOAD ANIMATION PLAYER GROUP
	grp_AnimationPlayer = load("res://Scenes/grp_AnimationPlayer.tscn").instance()
	add_child(grp_AnimationPlayer)
	grp_AnimationPlayer.name = "grp_AnimationPlayer"
	
	#LOAD PROPS GROUP
	grp_Props.tile_set = GameRule.TILESET.PROP
	grp_Props.cell_size = cell_size
	if level_data.has("props"):
		for prop in level_data.props:
			grp_Props.set_cell(prop[0], prop[1], prop[2], prop[3], prop[4], prop[5])
	add_child(grp_Props)
	grp_Props.name = "grp_Props"
	grp_Props.collision_layer = 0
	grp_Props.collision_mask = 0
	
	#LOAD STATIC BODIES GROUP
	grp_StaticBodies.tile_set = GameRule.TILESET.STATIC
	grp_StaticBodies.cell_size = cell_size
	if level_data.has("static_bodies"):
		for static_body in level_data.static_bodies:
			grp_StaticBodies.set_cell(static_body[0], static_body[1], static_body[2], static_body[3], static_body[4], static_body[5])
	add_child(grp_StaticBodies)
	grp_StaticBodies.name = "grp_StaticBodies"
	grp_StaticBodies.collision_layer = 0
	grp_StaticBodies.set_collision_layer_bit(1, true)
	grp_StaticBodies.collision_mask = 0
	
	#LOAD GHOSTS GROUP
	add_child(grp_Ghosts)
	grp_Ghosts.name = "grp_Ghosts"
	grp_StateRecorder_properties[0] = [
			"grp_Ghosts/0:position", "grp_Player:position"]
	grp_StateRecorder_properties[1] = [
			"grp_Ghosts/0:active", "grp_Player:active"]
	
	#LOAD PLAYER SPAWN
	add_child(grp_Player)
	grp_Player_set2defpos()
	grp_Player.name = "grp_Player"
	
	#LOAD ENTITIES
	add_child(grp_Entities)
	grp_Entities.name = "grp_Entities"
	if level_data.has("entities"):
		for entity_data in level_data.entities:
			var new_entity = get_child_from_scene(GameRule.ENTITYSET, entity_data[2])
			var entity_position = Vector2(entity_data[0], entity_data[1])*cell_size+cell_size*Vector2(0.5,0.5)
			new_entity.position = entity_position
			new_entity.default_position = entity_position
			grp_Entities.add_child(new_entity)
			connect("reset", new_entity, "reset")
	
	
	#LOAD INPUTS
	add_child(grp_Inputs)
	grp_Inputs.name = "grp_Inputs"
	if level_data.has("inputs"):
		for input_data in level_data.inputs:
			var new_input = get_child_from_scene(GameRule.INPUTSET, input_data[2])
			var map_input_position = Vector2(input_data[0], input_data[1])
			var input_position = map_input_position*cell_size+cell_size*Vector2(0.5,0.5)
			new_input.position = input_position
			grp_Inputs.add_child(new_input)
			new_input.scale = get_tile_scale(input_data)
			new_input.rotation = get_tile_rotation(input_data)
			#CONFIGURE PATH
			var path = str(get_path_to(new_input))
			if new_input.recordable:
				grp_StateRecorder_properties.append(
					[path+":global_interact", path+":player_interact", false]
				)
			connect("reset", new_input, "reset")
			#Add Input End
			for input_end_position in input_data[6]:
				add_input_end(Vector2(input_end_position[0], input_end_position[1]), new_input)
	
	add_child(grp_Logic)
	var logic_gates = []
	grp_Logic.name = "grp_Logic"
	if level_data.has("logic"):
		for logic_data in level_data.logic:
			var new_logic_gate = get_child_from_scene(GameRule.LOGICSET, logic_data[2])
			var map_logic_gate_position = Vector2(logic_data[0], logic_data[1])
			grp_Logic.add_child(new_logic_gate)
			#Add Input Ends
			for logic_gate_end_pos in logic_data[3]:
				add_input_end(Vector2(logic_gate_end_pos[0], logic_gate_end_pos[1]), new_logic_gate)
			logic_gates.append([map_logic_gate_position, new_logic_gate])
	for logic_gate in logic_gates:
		connect_to_input_ends(logic_gate[0], logic_gate[1])
			
	
	#LOAD OUTPUTS
	add_child(grp_Outputs)
	grp_Outputs.name = "grp_Outputs"
	if level_data.has("outputs"):
		for output_data in level_data.outputs:
			var new_output = get_child_from_scene(GameRule.OUTPUTSET, output_data[2])
			var map_output_position = Vector2(output_data[0], output_data[1])
			var output_position = map_output_position*cell_size+cell_size*Vector2(0.5,0.5)
			new_output.position = output_position
			grp_Outputs.add_child(new_output)
			new_output.scale = get_tile_scale(output_data)
			new_output.rotation = get_tile_rotation(output_data)
			connect_to_input_ends(map_output_position, new_output)
			#CONFIGURE PATH
#			var path = str(get_path_to(new_output))
#			grp_StateRecorder_properties.append(
#				[path+":global_interact", path+":player_interact", false]
#			)
#			connect("reset", new_output, "reset")
	emit_signal("reset")
	
	#LOAD STATE RECORDER
	add_child(grp_StateRecorder)
	grp_StateRecorder.name = "grp_StateRecorder"
	grp_StateRecorder.start(self, grp_StateRecorder_properties)

func grp_Player_set2defpos():
	grp_Player.velocity = Vector2.ZERO
	grp_Player.position = Vector2(
			level_data.player_spawn[0],
			level_data.player_spawn[1]
		)*cell_size+cell_size*Vector2(0.5,1)

func _process(delta: float) -> void:
	if grp_Player.global_position.y > GameRule.WINDOW_DIMENSIONS.y+128:
		kill_player()
	if !win:
		update_countdown(delta)
	if Input.is_action_just_pressed("back"):
		_on_WinBackButton_pressed() 
	if Input.is_action_just_pressed("restart"):
		_on_Restart_pressed()

func update_coin_counter() -> void:
	coin_counter += 1
	$CanvasLayer/Control/Banner/coin_count.text = "%02d" % [coin_counter]

func add_input_end(pos: Vector2, node: Node) -> void:
	if !input_ends.has(pos):
		input_ends[pos] = []
	input_ends[pos].append(node)

func connect_to_input_ends(pos: Vector2, node: Node) -> void:
	if !input_ends.has(pos):
		return
	var index = 0
	for input_node in input_ends[pos]:
		input_node.connect("voltage_sent", node, "recieve_voltage", [index])
		index += 1

func kill_player() -> void:
	if !timer.is_stopped() || win:
		return
	grp_Player.set_active(false)
	timer.stop()
	timer.one_shot = true
	timer.wait_time = 2
	timer.start()

func respawn() -> void:
	setting_up = true
	var new_ghost = grp_Ghosts_instance.instance()
	new_ghost.name = str(grp_Ghosts.get_child_count())
	grp_Ghosts.add_child(new_ghost)
	var new_ghost_name: String = str(grp_Ghosts.get_child_count())
	grp_Player_set2defpos()
	grp_Player.set_active(true)
	grp_AnimationPlayer.stop()
	grp_AnimationPlayer.add_animation("playback", grp_StateRecorder.get_animation())
	grp_AnimationPlayer.play("playback")
	grp_StateRecorder_properties[0] = [
		"grp_Ghosts/"+new_ghost_name+":position", "grp_Player:position"]
	grp_StateRecorder_properties[1] = [
		"grp_Ghosts/"+new_ghost_name+":active", "grp_Player:active"]
	emit_signal("reset")
	grp_StateRecorder.start(self, grp_StateRecorder_properties)
	setting_up = false


func get_child_from_scene(scene, idx):
	var new_instance = scene.instance()
	var something = new_instance.get_child(idx)
	new_instance.remove_child(something)
	return something


func get_tile_rotation(data) -> float:
	return -int(data[5])*PI*0.5


func get_tile_scale(data) -> Vector2:
	var _hflip = !data[4] if data[5] else data[3]
	var _vflip = data[3] if data[5] else data[4]
	return Vector2(1+int(_hflip)*-2 , 1+int(_vflip)*-2)


# func _size_changed():
# 	var new_x_position = (GameRule.WINDOW_DIMENSIONS.x-get_viewport_rect().size.x)/2.0
# 	#$Camera2D.position.x = new_x_position
	

func _on_Back2LvlEditor_pressed() -> void:
	GameRule.go_back_to_editor()


func _on_Restart_pressed() -> void:
	get_tree().reload_current_scene()


func _on_Back_pressed() -> void:
	if Transition.is_running():
		return
	Transition.close()
	yield(Transition, "is_done_opening")
	get_tree().change_scene("res://Scenes/MainMenu.tscn")

func _on_Rewind_pressed() -> void:
	_on_Restart_pressed()


func _on_WinBackButton_pressed() -> void:
	if GameRule.is_editing_level:
		_on_Back2LvlEditor_pressed()
	else:
		_on_Back_pressed()


func _on_WinNxtLvlButton_pressed() -> void:
	if Transition.is_running():
		return
	var level = GameRule.level_num+1
	GameRule.is_editing_level = false
	GameRule.game_level_data = GameRule.string2game(GameRule.levels_data[level].data)
	GameRule.level_name = GameRule.levels_data[level].name
	GameRule.level_num = level
	Transition.close()
	yield(Transition, "is_done_opening")
	get_tree().change_scene("res://Scenes/LevelPlayer.tscn")
