extends Control
var is_level = false

func set_level_selector_focus(focus: bool):
	is_level = focus
	var lvl_select = Control.FOCUS_ALL if focus else Control.FOCUS_NONE
	for i in $"Level Selector".get_children():
		if i == $"Level Selector/BackMain":
			continue
		i.set_focus_mode(lvl_select)
	
	var menu_select = Control.FOCUS_ALL if !focus else Control.FOCUS_NONE
	$Main/PlayButton.set_focus_mode(menu_select)
	$Main/LevelEditorButton.set_focus_mode(menu_select)
	$Main/CreditsButton.set_focus_mode(menu_select)
	
	if focus:
		$"Level Selector".get_child(1).grab_focus()
	else:
		$Main/PlayButton.grab_focus()

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cancel") && is_level:
		_on_BackMainButton_pressed()

func _ready() -> void:
	var button_ref = load("res://Scenes/LevelButton.tscn")
	#for i in range(GameRule.levels_data.size()):
	for i in range(11):
		var new_button: TextureButton = button_ref.instance()
		$"Level Selector".add_child(new_button)
		var pos = Vector2((1+i%4)/5.0,(1+int(i/4.0))/4.0)
		new_button.anchor_right = pos.x
		new_button.anchor_left = pos.x
		new_button.anchor_top = pos.y
		new_button.anchor_bottom = pos.y
		new_button.get_node("Label").text = str(i+1)
		new_button.connect("pressed", self, "goto_level", [i])
	set_level_selector_focus(false)

func goto_level(level: int) -> void:
	if Transition.is_running():
		return
	GameRule.is_editing_level = false
	GameRule.game_level_data = GameRule.string2game(GameRule.levels_data[level].data)
	GameRule.level_name = GameRule.levels_data[level].name
	GameRule.level_num = level
	Transition.close()
	yield(Transition, "is_done_opening")
	get_tree().change_scene("res://Scenes/LevelPlayer.tscn")

func _on_CreditsButton_pressed() -> void:
	$Main/Credits.visible = !$Main/Credits.visible
	var vis = Control.FOCUS_ALL if !$Main/Credits.visible else Control.FOCUS_NONE
	$Main/PlayButton.set_focus_mode(vis)
	$Main/LevelEditorButton.set_focus_mode(vis)


func _on_LevelEditorButton_pressed() -> void:
	if Transition.is_running():
		return
	Transition.close()
	yield(Transition, "is_done_opening")
	get_tree().change_scene("res://Scenes/LevelEditor.tscn")


func _on_PlayButton_pressed() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play("goto play")
	set_level_selector_focus(true)
	


func _on_BackMainButton_pressed() -> void:
	$AnimationPlayer.stop()
	$AnimationPlayer.play("goto main")
	set_level_selector_focus(false)
