extends Control

enum GROUP {
	PROP,
	STATIC,
	PLAYER_SPAWN
	ENTITY,
	INPUT,
	OUTPUT,
	WIRING,
	LOGIC
}

enum INDEX{
	TYPE,
	FLIPX,
	FLIPY,
	TRANS
}

var timer = Timer.new()
var mouse_is_focused = false
var mouse_is_midclick = false
var grid_size: = Vector2(GameRule.UNIT_SIZE,GameRule.UNIT_SIZE)
var texref = {}
var tile_list: = []
var cursor_select: = 0
var cursor_position: = Vector2()
var cursor_transpose: = false
var cursor_fliph: = false
var cursor_flipv: = false
var level_data: = {}
var canvas_offset: = Vector2(0,88)
var canvas_latest_win_off: = 0
var wiring = {
	start_pos = Vector2(),
	end_pos = Vector2(),
	is_wiring = false,
	type = ""
}


func load_existing_level(level: int) -> void:
	GameRule.game_level_data = GameRule.string2game(GameRule.levels_data[level].data)
	GameRule.go_back_to_editor()

func _ready() -> void:
	for i in range(11):
		var new_button = Button.new()
		$LevelLoader/List.add_child(new_button)
		new_button.text = "Level %02d" % [i+1]
		new_button.connect("pressed", self, "load_existing_level", [i])
	
	add_child(timer)
	timer.wait_time = 1
	timer.one_shot = false
	timer.start()
	#Get Saved Gamerule Data
	GameRule.is_editing_level = true
	level_data = GameRule.editor_level_data
	
	# INITIALIZE TILE LIST
	#Create Player Tile
	level_data_fill("player_spawn", Vector2.ZERO)
	texref.player = load("res://Assets/Editor/player.png")
	create_selector_button("Player", texref.player)
	tile_list.append({
		name = "player spawn",
		texture = texref.player,
		group = GROUP.PLAYER_SPAWN
	})
	
	#Create Entity Tiles
	level_data_fill("entities")
	texref.entity = {}
	var entity_set:Node = GameRule.ENTITYSET.instance()
	for child_idx in range(entity_set.get_child_count()):
		var child = entity_set.get_child(child_idx)
		create_selector_button("Entity", child.tile_texture)
		tile_list.append({
			name = child.name,
			texture = child.tile_texture,
			group = GROUP.ENTITY,
			id = child_idx
		})
		texref.entity[child_idx] = child.tile_texture
	
	#Create Static Body Tiles
	level_data_fill("static_bodies")
	texref.static = {}
	var tile_set:TileSet = GameRule.TILESET.STATIC
	for id in tile_set.get_tiles_ids():
		var _tex: = AtlasTexture.new()
		_tex.atlas = tile_set.tile_get_texture(id)
		_tex.region = tile_set.tile_get_region(id)
		create_selector_button("Static", _tex)
		tile_list.append({
			name = tile_set.tile_get_name(id),
			texture = _tex,
			group = GROUP.STATIC,
			id = id
		})
		texref.static[id] = _tex
	
	#Create Prop Tiles
	level_data_fill("props")
	texref.prop = {}
	tile_set = GameRule.TILESET.PROP
	for id in tile_set.get_tiles_ids():
		var _tex: = AtlasTexture.new()
		_tex.atlas = tile_set.tile_get_texture(id)
		_tex.region = tile_set.tile_get_region(id)
		create_selector_button("Prop", _tex)
		tile_list.append({
			name = tile_set.tile_get_name(id),
			texture = _tex,
			group = GROUP.PROP,
			id = id
		})
		texref.prop[id] = _tex
	
	#Create Input Tiles
	level_data_fill("inputs")
	texref.input = {}
	var input_set:Node = GameRule.INPUTSET.instance()
	for child_idx in range(input_set.get_child_count()):
		var child = input_set.get_child(child_idx)
		create_selector_button("Input", child.tile_texture)
		tile_list.append({
			name = child.name,
			texture = child.tile_texture,
			group = GROUP.INPUT,
			id = child_idx
		})
		texref.input[child_idx] = child.tile_texture
	
	#Create Input Tiles
	level_data_fill("outputs")
	texref.output = {}
	var output_set:Node = GameRule.OUTPUTSET.instance()
	for child_idx in range(output_set.get_child_count()):
		var child = output_set.get_child(child_idx)
		create_selector_button("Output", child.tile_texture)
		tile_list.append({
			name = child.name,
			texture = child.tile_texture,
			group = GROUP.OUTPUT,
			id = child_idx
		})
		texref.output[child_idx] = child.tile_texture
	
	#Create Logic Tiles
	level_data_fill("logic")
	texref.logic = {}
	var logic_set:Node = GameRule.LOGICSET.instance()
	for child_idx in range(logic_set.get_child_count()):
		var child = logic_set.get_child(child_idx)
		create_selector_button("Logic", child.tile_texture)
		tile_list.append({
			name = child.name,
			texture = child.tile_texture,
			group = GROUP.LOGIC,
			id = child_idx,
			description = "'Buffer' and 'Not' logic gates take one input while the rest take two inputs.\n\nBatch logic gates however can take multiple inputs.\n\nWARNING: LOOPS WILL DEFINITELY BREAK THE GAME"
		})
		texref.logic[child_idx] = child.tile_texture
	
	#Add Wiring
	var tex
	tex = load("res://Assets/Editor/Add Wire.png")
	create_selector_button("Wiring", tex)
	tile_list.append({
		name = "add wire",
		texture = tex,
		group = GROUP.WIRING,
		description = "Click on an input or logic gate to start wiring.\n\nClick on an output or logic gate afterwards to connect.\n\nWhile wiring, right-click anywhere to cancel the wiring process.\n\nRight-click on any input or logic gate to remove any connecting wires."
	})
	
	#WINDOW SIZE CHANGER
	get_tree().get_root().connect("size_changed", self, "_size_changed")
	_size_changed()
	
	#UPDATE VIEWER
	update_viewer()
	

func _process(delta: float) -> void:
	#Move Canvas Offset by Keyboard
	move_canvas_by_keys(delta, 256)
	#Enable Placing And Erasing Tiles
	if mouse_is_focused:
		place_tile(Input.is_action_pressed("mouse_left"))
		place_tile(Input.is_action_just_pressed("mouse_left"), true)
		erase_tile(Input.is_action_pressed("mouse_right"))
		erase_tile(Input.is_action_just_pressed("mouse_right"), true)
	
	update()


func _draw() -> void:
	draw_set_transform(canvas_offset, 0, Vector2.ONE)
	draw_grid()
	#Selected Tile From Mouse
	var _selected_tile:Dictionary = tile_list[cursor_select]
	
	#DRAW PROPS
	if !$ToggleButtons/Props.pressed:
		draw_regular("props", "prop")
	
	#DRAW STATIC BODIES
	if !$ToggleButtons/StaticBodies.pressed:
		draw_regular("static_bodies", "static")
	
	#DRAW INPUTS
	if !$ToggleButtons/Inputs.pressed:
		draw_regular("inputs", "input")
	
	#DRAW OUTPUTS
	if !$ToggleButtons/Outputs.pressed:
		draw_regular("outputs", "output")
	
	#DRAW PLAYER
	if !$ToggleButtons/Player.pressed:
		draw_texture(texref.player, pos2world(level_data.player_spawn))
	
	#DRAW ENTITIES
	if !$ToggleButtons/Entities.pressed:
		for entity_key in level_data.entities.keys():
			var data: Array = level_data.entities[entity_key]
			draw_transformed_tile(texref.entity[data[INDEX.TYPE]], entity_key)
	
	#DRAW LOGIC GATES
	if !$ToggleButtons/LogicGates.pressed:
		for logic_key in level_data.logic.keys():
			var data: Array = level_data.logic[logic_key]
			draw_transformed_tile(texref.logic[data[0]], logic_key)
	
	#DRAW WIRING
	if !$ToggleButtons/Wires.pressed:
		draw_wiring_preview()
	
	#DRAW MOUSE PREVIEW
	if !mouse_is_focused:
		return
	draw_texture(_selected_tile.texture, pos2world(cursor_position), Color(1,1,1,0.5))


func _input(event: InputEvent) -> void:
	#Set Cursor Position
	if event is InputEventMouse:
		cursor_position = world2pos((event.position-canvas_offset-grid_size/2.0))
		cursor_position.x = clamp(cursor_position.x, 0, 31)
		cursor_position.y = clamp(cursor_position.y, 0, 15)
	if event is InputEventMouseButton && event.button_index == BUTTON_MIDDLE:
		mouse_is_midclick = event.pressed
	if event is InputEventMouseMotion && mouse_is_midclick:
		canvas_offset += event.relative
	
	#Load LevelPlayer when `Q` is pressed
#	if event is InputEventKey && event.is_pressed() && event.scancode == KEY_Q:
#		GameRule.play_level_from_editor(level_data)
	
#	#Select Tile on Mouse Scroll
#	if event is InputEventMouseButton:
#		if event.pressed && [BUTTON_WHEEL_UP, BUTTON_WHEEL_DOWN].has(event.button_index):
#			cursor_select += 1 if event.button_index == BUTTON_WHEEL_UP else -1
#		cursor_select = cursor_select % tile_list.size()

################################################################
func draw_grid() -> void:
	draw_rect(Rect2(Vector2(), Vector2(1024, 512)), Color(1, 1, 1, 32/255.0), false, 2)
	for i in range(32):
		var pulse = 0#(32 if i%8 == 0 else 13)/255.0
		if i%8 == 0:
			pulse = 32
		elif i%4 == 0:
			pulse = 18
		else:
			pulse = 13
		pulse /= 255.0
		var color = Color(1, 1, 1, pulse)
		draw_line(
			Vector2(i*32, 0),
			Vector2(i*32, 512),
			color,
			1.5 if i%8 == 0 else 1
		)
		if i > 16:
			continue
		draw_line(
			Vector2(0, i*32),
			Vector2(1024, i*32),
			color,
			1.5 if i%8 == 0 else 1
		)

func draw_wiring_preview() -> void:
	for key_coord in level_data.inputs.keys():
		var start = pos2world(key_coord)+grid_size*0.5
		for end_coord in level_data.inputs[key_coord][4]:
			if key_coord == end_coord:
				var radius = sqrt(pow(grid_size.x*0.5,2)*2)
				draw_arc(start,radius,0,PI*2,16,Color.blue, 1.5, true)
				for i in range(4):
					draw_circle(
						start+Vector2(radius, 0).rotated(fmod(timer.time_left+i*0.25, 1.0)*PI*2),
						1.5,
						Color.cyan
					)
				continue
			var end: Vector2 = pos2world(end_coord)+grid_size*0.5
			end -= start
			end = end.clamped(end.length()-grid_size.x*0.5)
			end += start
			draw_wire(
				start,
				end,
				ColorN("blue", 0.7),
				Color.cyan,
				1.5,
				6
			)
	
	for key_coord in level_data.logic.keys():
		var start = pos2world(key_coord)+grid_size*0.5
		for end_coord in level_data.logic[key_coord][1]:
			if key_coord == end_coord:
				var radius = sqrt(pow(grid_size.x*0.5,2)*2)
				draw_arc(start,radius,0,PI*2,16,Color.blue, 1.5, true)
				for i in range(4):
					draw_circle(
						start+Vector2(radius, 0).rotated(fmod(timer.time_left+i*0.25, 1.0)*PI*2),
						1.5,
						Color.cyan
					)
				continue
			var end: Vector2 = pos2world(end_coord)+grid_size*0.5
			end -= start
			end = end.clamped(end.length()-grid_size.x*0.5)
			end += start
			draw_wire(
				start,
				end,
				ColorN("blue", 0.7),
				Color.cyan,
				1.5,
				6
			)
	
	if !wiring.is_wiring:
		return
	draw_line(
		pos2world(wiring.start_pos)+grid_size*0.5,
		pos2world(cursor_position)+grid_size*0.5,
		ColorN("white", 0.5),
		2
	)


func draw_regular(level_data_key, texref_key):
	for key in level_data[level_data_key].keys():
		var data: Array = level_data[level_data_key][key]
		draw_transformed_tile(
				texref[texref_key][data[INDEX.TYPE]], 
				key, 
				data[INDEX.FLIPX],
				data[INDEX.FLIPY],
				data[INDEX.TRANS])


func draw_transformed_tile(texture: Texture, position: Vector2, hflip: bool = false, vflip: bool = false, transpose: bool = false) -> void:
	var _hflip = !hflip if transpose else hflip
	var _vflip = vflip
	var scale = Vector2(1+int(_hflip)*-2 , 1+int(_vflip)*-2)
	var rotation = int(transpose)*PI*0.5
	draw_set_transform(canvas_offset+pos2world(position)+grid_size*0.5, rotation, scale)
	draw_texture(
		texture,
		Vector2.ZERO-grid_size*0.5
	)
	draw_set_transform(canvas_offset, 0, Vector2.ONE)

func draw_wire(start: Vector2, end: Vector2, color: Color, bead_color: Color, size: float, arrow_size: float) -> void:
	# draw dashed line
	draw_line(
		start,
		end,
		color,
		size,
		true
	)
	for idx in range(4):
		draw_circle(
			end.linear_interpolate(start, fmod(timer.time_left+idx/4.0,1)),
			size,
			bead_color
		)
	var dir = (end - start).normalized()
	# draw triangular arrow end
	var a = end + dir * arrow_size/1.5 
	var b = end + dir.rotated(2*PI/3) * arrow_size
	var c = end + dir.rotated(4*PI/3) * arrow_size
	draw_polygon(PoolVector2Array([a, b, c]), PoolColorArray([color]))

func draw_empty_circle(circle_center: Vector2, circle_radius: float, color: Color, resolution: int):
	var lines = PoolVector2Array()
	for i in range(resolution):
		lines.append(circle_center+Vector2(circle_radius, 0).rotated(float(i)/resolution))

func level_data_fill(key: String, default_value = {}) -> void:
	if !level_data.has(key):
		level_data[key] = default_value

func place_tile(condition: bool, is_just = false) -> void:
	if !condition:
		return
	var _tile : Dictionary = tile_list[cursor_select]
	match _tile.group:
		GROUP.PLAYER_SPAWN:
			level_data.player_spawn = cursor_position
		GROUP.STATIC:
			level_data.static_bodies[cursor_position] = [_tile.id, cursor_fliph, cursor_flipv, cursor_transpose]
		GROUP.PROP:
			level_data.props[cursor_position] = [_tile.id, cursor_fliph, cursor_flipv, cursor_transpose]
		GROUP.INPUT:
			level_data.inputs[cursor_position] = [_tile.id, cursor_fliph, cursor_flipv, cursor_transpose, []]
		GROUP.OUTPUT:
			level_data.outputs[cursor_position] = [_tile.id, cursor_fliph, cursor_flipv, cursor_transpose, []]
		GROUP.ENTITY:
			level_data.entities[cursor_position] = [_tile.id]
		GROUP.LOGIC:
			level_data.logic[cursor_position] = [_tile.id, []]
		GROUP.WIRING:
			var type = check_type_in_pos(cursor_position)
			if wiring.is_wiring && is_just:
				wiring.is_wiring = false
				wiring.end_pos = cursor_position
				var index = 4 if wiring.type == "inputs" else 1
				if !level_data[wiring.type][wiring.start_pos][index].has(wiring.end_pos):
					level_data[wiring.type][wiring.start_pos][index].append(wiring.end_pos)
			elif type != "" && is_just && !wiring.is_wiring:
				wiring.is_wiring = true
				wiring.type = type
				wiring.start_pos = cursor_position
		#print(level_data

func check_type_in_pos(pos) -> String:
	var types = ["inputs", "logic"]
	for type in types:
		if level_data[type].has(pos):
			return type
	return ""

func erase_tile(condition: bool, is_just = false) -> void:
	if !condition:
		return
	var _tile = tile_list[cursor_select]
	match _tile.group:
		GROUP.STATIC:
			level_data.static_bodies.erase(cursor_position)
		GROUP.PROP:
			level_data.props.erase(cursor_position)
		GROUP.INPUT:
			level_data.inputs.erase(cursor_position)
		GROUP.OUTPUT:
			level_data.outputs.erase(cursor_position)
		GROUP.ENTITY:
			level_data.entities.erase(cursor_position)
		GROUP.LOGIC:
			level_data.logic.erase(cursor_position)
		GROUP.WIRING:
			if wiring.is_wiring:
				wiring.is_wiring = false
			else:
				var type: String = check_type_in_pos(cursor_position)
				if type != "":
					var index = 4 if type == "inputs" else 1
					level_data[type][cursor_position][index] = []

func move_canvas_by_keys(delta: float, speed: float) -> void:
	var direction = Vector2(
		Input.get_action_strength("ui_right")-Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down")-Input.get_action_strength("ui_up")
	)
	var speed_up = 1 + Input.get_action_strength("editor_speedup")
	canvas_offset -= direction*delta*speed*speed_up
################################################################

func world2pos(vec2: Vector2) -> Vector2:
	return vec2.snapped(grid_size)/grid_size 

func pos2world(vec2: Vector2) -> Vector2:
	return vec2*grid_size

func update_viewer() -> void:
	$Viewer/TextureRect.texture = tile_list[cursor_select].texture
	$Viewer/TextureRect.rect_rotation = -int(cursor_transpose)*90.0
	$Viewer/TextureRect.flip_h = !cursor_flipv if cursor_transpose else cursor_fliph
	$Viewer/TextureRect.flip_v = cursor_fliph if cursor_transpose else cursor_flipv
	var description = ""
	if tile_list[cursor_select].has("description"):
		description = tile_list[cursor_select].description
	$Viewer/Label.text = tile_list[cursor_select].name+"\n\n"+description
	$Viewer/TransposeButton.pressed = cursor_transpose
	$Viewer/FlipHButton.pressed = cursor_fliph
	$Viewer/FlipVButton.pressed = cursor_flipv

func create_selector_button(tab_name: String, texture: Texture):
	var button = TextureButton.new()
	if !$Selector.has_node(tab_name):
		var new_ScrollContainer = ScrollContainer.new()
		$Selector.add_child(new_ScrollContainer)
		new_ScrollContainer.name = tab_name
		var new_GridContainer = GridContainer.new()
		new_ScrollContainer.add_child(new_GridContainer)
		new_GridContainer.columns = floor(new_ScrollContainer.rect_size.x/32.0)
		new_GridContainer.name = "GridContainer"
		
	$Selector.get_node(tab_name+"/GridContainer").add_child(button)
	button.texture_normal = texture
	button.connect("pressed", self, "_on_Selector_pressed", [tile_list.size()])

###############################################################

func _on_LevelEditor_mouse_entered() -> void:
	mouse_is_focused = true


func _on_LevelEditor_mouse_exited() -> void:
	mouse_is_focused = false

func _on_Selector_pressed(id) -> void:
	cursor_select = id
	update_viewer()

func _size_changed() -> void:
	for cont in $Selector.get_children():
		var grid: GridContainer = cont.get_node("GridContainer")
		grid.columns = floor($Selector.rect_size.x/32.0)-4
	rect_size = get_viewport_rect().size
	var new_off = 1024-rect_size.x
	canvas_offset.x += (canvas_latest_win_off-new_off)/2
	canvas_latest_win_off = new_off

func _on_Test_pressed() -> void:
	GameRule.play_level_from_editor(level_data)
	pass # Replace with function body.

func _on_Clip_pressed() -> void:
	var game_data = GameRule.editor2game(level_data)
	OS.clipboard = GameRule.game2string(game_data)
	$Label/AnimationPlayer.stop()
	$Label/AnimationPlayer.play("New Anim")

func _on_Paste_pressed() -> void:
	var result = GameRule.string2game(OS.clipboard)#deep_copy(GameRule.string2game(OS.clipboard))
	if typeof(result) != TYPE_DICTIONARY:
		return
	print(result)
	print(typeof(result))
	GameRule.game_level_data = result
	GameRule.go_back_to_editor()
	pass # Replace with function body.

func _on_Clear_pressed() -> void:
	GameRule.editor_level_data = {}
	get_tree().reload_current_scene()


func _on_FlipH_pressed() -> void:
	cursor_fliph = !cursor_fliph
	update_viewer()


func _on_FlipV_pressed() -> void:
	cursor_flipv = !cursor_flipv
	update_viewer()


func _on_ResetTransform_pressed() -> void:
	cursor_transpose = false
	cursor_fliph = false
	cursor_flipv = false
	update_viewer()


func _on_Transpose_pressed() -> void:
	cursor_transpose = !cursor_transpose
	update_viewer()


func _on_Back_pressed() -> void:
	if Transition.is_running():
		return
	GameRule.is_editing_level = false
	Transition.close()
	yield(Transition, "is_done_opening")
	get_tree().change_scene("res://Scenes/MainMenu.tscn")
