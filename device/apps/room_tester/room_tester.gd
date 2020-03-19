extends Node

export (Resource) var game_to_load

onready var _room_list = $ui/room_list
onready var _ui = $ui
onready var _display = $display

var _grog_game = null

func _ready():
	if not game_to_load:
		push_error("No game_to_load")
		return
	
	list_rooms()
	
func list_rooms():
	if not _room_list:
		push_error("No _room_list")
		return
	
	var all_rooms = game_to_load.get_all_rooms()
	
	for room in all_rooms:
		_room_list.add_item(room)
	
	_room_list.select_anyone()
	
func _on_test_room_button_pressed():
	if not _room_list:
		push_error("No _room_list")
		return
		
	var current_room = _room_list.get_current()
	
	if not current_room:
		return
	
	test_room(current_room)

func _on_play_game_button_pressed():
	play_game()
	
func test_room(_room_resource):
	var compiled_script = CompiledGrogScript.new()
	compiled_script.add_routine("start", [ { subject = "", command = "load_room", params = [_room_resource.get_name()] } ])
	
	play_game(GameServer.StartMode.FromCompiledScript, compiled_script)


func play_game(game_mode = GameServer.StartMode.Default, param = null):
	_ui.hide()
	_display.show()
	
	_grog_game = GameServer.new()  
	
	_grog_game.init_game(game_to_load, game_mode, param)
	
	_grog_game.connect("game_server_event", _display, "on_server_event")
	
	_display.init(_grog_game)
	
