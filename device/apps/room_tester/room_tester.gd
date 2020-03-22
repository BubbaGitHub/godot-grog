extends Node

export (Resource) var game_to_load

export (NodePath) var ui_path
export (NodePath) var display_path

export (NodePath) var room_list_path
export (NodePath) var actor_list_path
export (NodePath) var script_list_path

export (NodePath) var raw_script_edit_path

var _grog_game: GameServer = null

onready var _ui = get_node(ui_path)
onready var _display = get_node(display_path)

onready var _room_list = get_node(room_list_path)
onready var _actor_list = get_node(actor_list_path)
onready var _script_list = get_node(script_list_path)

onready var _raw_script_edit = get_node(raw_script_edit_path)

var _default_script

func _ready():
	if not game_to_load:
		push_error("No game_to_load")
		return
	
	_default_script = _raw_script_edit.text
	
	list_elements("rooms", game_to_load.get_all_rooms(), _room_list)
	list_elements("actors", game_to_load.get_all_actors(), _actor_list)
	list_elements("scripts", game_to_load.get_all_scripts(), _script_list, false)
	
	_script_list.connect("on_element_selected", self, "_on_script_selected")
	_script_list.connect("on_element_deselected", self, "_on_script_deselected")
	
	_display.connect("game_ended", self, "_on_game_ended")
	
func list_elements(name: String, elements: Array, list: Node, select_first = true):
	if not elements:
		push_error("No list node for %s" % name)
		return
	
	for element in elements:
		list.add_element(element)
	
	if select_first:
		list.select_first()

func _on_script_selected(_old_script, _new_script):
	_raw_script_edit.text = _new_script.target.get_code()

func _on_script_deselected(_old_script):
	_raw_script_edit.text = _default_script
	
func _on_test_room_button_pressed():
	var current_room = _room_list.get_current()
	
	if not current_room:
		return
	
	var current_player = _actor_list.get_current()
	
	test_room(current_room, current_player)

func _on_play_game_button_pressed():
	play_game()
	
func _on_test_script_button_pressed():
	var script_text = _raw_script_edit.text
	
	play_game(GameServer.StartMode.FromRawScript, script_text)
	
func _on_quit_button_pressed():
	get_tree().quit()
	
func test_room(_room_resource, _actor_resource):
	var compiled_script = CompiledGrogScript.new()
	var start_routine = [{ command = "load_room", params = [_room_resource.get_name()] }]
	
	if _actor_resource:
		start_routine.append({ command = "load_actor", params = [_actor_resource.get_name()] })
	
	compiled_script.add_routine("start", start_routine)
	
	play_game(GameServer.StartMode.FromCompiledScript, compiled_script)


func play_game(game_mode = GameServer.StartMode.Default, param = null):
	_grog_game = GameServer.new()  
	
	var is_valid = _grog_game.init_game(game_to_load, game_mode, param)
	
	if is_valid:
		_ui.hide()
		_display.show()
		
		_display.init(_grog_game)
	
func _on_game_ended():
	_grog_game = null
	_display.hide()
	_ui.show()
