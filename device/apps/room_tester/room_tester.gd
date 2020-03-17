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
	var scripts = game_to_load.get_all_scripts()
	
	if not scripts:
		return
	
	var script = scripts[0]
	
	var compiled_script = grog.compile(script)
	if not compiled_script.is_valid:
		print("Script is invalid")
		
		compiled_script.print_errors()
	else:
		play_game(compiled_script)
	
func test_room(_room_resource):
	var compiled_script = CompiledGrogScript.new()
	
	compiled_script.add_routine("start", [ { subject = "", command = "load_room", params = [_room_resource.get_name()] } ])
	
	play_game(compiled_script)

func play_game(compiled_script):
	_ui.hide()
	_display.show()
	
	_grog_game = grog.new_game_server(game_to_load, compiled_script, _display)
	
	
	
