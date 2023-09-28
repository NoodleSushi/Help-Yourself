extends Node

enum INDEX{
	TYPE,
	FLIPX,
	FLIPY,
	TRANS
}

var TILESET = {
	STATIC = load("res://Objects/StaticTileSet.tres"),
	PROP = load("res://Objects/PropTileSet.tres")
}

var ENTITYSET = load("res://Objects/EntitySet.tscn")
var INPUTSET = load("res://Objects/InputSet.tscn")
var OUTPUTSET = load("res://Objects/OutputSet.tscn")
var LOGICSET = load("res://Objects/LogicSet.tscn")

var WINDOW_DIMENSIONS: Vector2 = Vector2(1024, 600)

var UNIT_SIZE:float = 32
var GRAVITY_SCALE:float = 9.81
var GRAVITY:float = UNIT_SIZE*GRAVITY_SCALE

var game_level_data: = {}
var editor_level_data: = {}

var is_editing_level = false

var level_name = ""
var levels_data = []
var level_num = 0

func _ready() -> void:
	var file = File.new()
	file.open("res://levels.json", file.READ)
	var text = file.get_as_text()
	levels_data = parse_json(text)["data"]
	file.close()
	# print something from the dictionnary for testing.

func editor2game(input, gen = 0):
	var new_gen = gen + 1
	match typeof(input):
		TYPE_DICTIONARY:
			match gen:
				0:
					var out = {}
					for key in input.keys():
						out[key] = editor2game(input[key], new_gen)
					return out
				1:
					var out = []
					for key in input.keys():
						#key is Vector2()
						out.append([key.x, key.y]+editor2game(input[key], new_gen))
					return out
			assert(false)
		TYPE_VECTOR2:
			return [input.x, input.y]
		TYPE_ARRAY:
			var out = []
			for element in input:
				out.append(editor2game(element, new_gen))
			return out
		_:
			return input


func game2editor(input, gen = 0):
	var new_gen = gen+1
	match typeof(input):
		TYPE_DICTIONARY:
			assert(gen == 0)
			var out = {}
			for key in input.keys():
				out[key] = game2editor(input[key], new_gen)
			print("HERE GOIS:")
			print(str(out))
			return out
		TYPE_ARRAY:
			if input.size() == 2 && [TYPE_REAL, TYPE_INT].has(typeof(input[0])) && [TYPE_REAL, TYPE_INT].has(typeof(input[1])):
				return Vector2(int(input[0]), int(input[1]))
			if gen == 1:
				var out = {}
				for element in input:
					out[Vector2(int(element[0]), int(element[1]))] = game2editor(element.slice(2, -1, 1, true), new_gen)
				return out
			var out = []
			for element in input:
				out.append(game2editor(element, new_gen))
			return out
		TYPE_REAL:
			return int(input)
		_:
			return input
	


var str_repl_term = ["[[","],[","]],","]]","false", "true", "\"entities\":", "\"player_spawn\":[", "\"static_bodies\":", "\"props\":", "\"inputs\":", "\"outputs\":", "\"logic\":"]
var repl_char_count = 2
var compress = true

func game2string(game: Dictionary) -> String:
	var out: String = to_json(game)
	if !compress:
		return out
	
	#REPLACE TERMS INTO UPPER CASE ALPHABETS
	assert(str_repl_term.size() <= 26)
	for idx in range(str_repl_term.size()):
		out = out.replace(str_repl_term[idx], char(65+idx))
	
	#FIND REPEATING TERMS
	var duplicate_checker: Dictionary = {}
	var dup_arr: Array = []
	for indexes in range(out.length()+1-repl_char_count):
		var string = out.substr(indexes, repl_char_count)
		if !duplicate_checker.has(string):
			duplicate_checker[string] = 0
		duplicate_checker[string] += 1
	for i in duplicate_checker.keys():
		dup_arr.append([i, duplicate_checker[i]])
	dup_arr.sort_custom(self, "dup_sorter")
	dup_arr.invert()
	#check if lower case letters are found
	for i in "abcdefghijklmnopqrstuvwxyz":
		assert(out.find(i) == -1)
	#CHOOSE REPEATING NON-SIMILAR TERMS
	var repeating_strings = []
	for i in range(dup_arr.size()):
		if repeating_strings.size() >= 26 || dup_arr[i][1] <= repl_char_count:
			break
		var similarity = 0
		var sel_str = dup_arr[i][0]
		for repstr in repeating_strings:
			similarity += sel_str.similarity(repstr)
		if similarity == 0:
			repeating_strings.append(sel_str)
			print(dup_arr[i])
	#REPLACE REPEATING TERMS INTO LOWER-CASE ALPHABETS
	for idx in range(repeating_strings.size()):
		out = out.replace(repeating_strings[idx], char(97+idx))
	out = char(96+repeating_strings.size())+PoolStringArray(repeating_strings).join("")+out
	#aaa -> *a
	var cleared_out_threes = false
	while !cleared_out_threes:
		cleared_out_threes = true
		for idx in range(out.length()+1-3):
			var string = out.substr(idx, 3)
			if string[0] == string[1] && string[1] == string[2]:
				out = out.replace(string, "*"+string[0])
				cleared_out_threes = false
				break
#
	return out

func dup_sorter(a, b):
	return a[1] < b[1]

func string2game(string: String) -> Dictionary:
	var out: = string
	if !compress:
		return parse_json(out)
	assert(str_repl_term.size() <= 26)
	#*a -> aaa
	var find_threes = true
	while find_threes:
		var idx = out.find("*")
		if idx == -1:
			find_threes = false
			break
		var data = out.substr(idx, 2)
		out = out.replace(data, data[1].repeat(3))
	#lower-case to term
	var number_of_repl : int = ord(out[0])-96
	var repl_data : String = out.substr(0, number_of_repl*repl_char_count+1)
	out = out.substr(number_of_repl*repl_char_count+1)
	for i in range(number_of_repl):
		out = out.replace(char(97+i), repl_data.substr(1+i*repl_char_count,2))
	#upper case to term
	for idx in range(str_repl_term.size()):
		out = out.replace(char(65+idx), str_repl_term[idx])
	return parse_json(out)

func play_level_from_editor(level_data: Dictionary):
	editor_level_data = level_data
	game_level_data = editor2game(level_data)
	get_tree().change_scene("res://Scenes/LevelPlayer.tscn")

func go_back_to_editor():
	if !is_editing_level:
		return
	editor_level_data = game2editor(game_level_data)
	get_tree().change_scene("res://Scenes/LevelEditor.tscn")
