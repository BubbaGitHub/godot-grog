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
	
	var scripts = game_to_load.get_all_scripts()
	
	if not scripts:
		return
	
	# TODO this should be in another place
	var script = scripts[0]
	_grog_game.run_script(script.get_name(), "start")

func test_room(_room_resource):
	play_game()

	var compiled_script = CompiledGrogScript.new()
	compiled_script.add_routine("start", [ { subject = "", command = "load_room", params = [_room_resource.get_name()] } ])
	
	_grog_game.run_compiled(compiled_script, "start")

func play_game():
	_ui.hide()
	_display.show()
	
	_grog_game = grog.new_game_server(game_to_load)
	_grog_game.connect("grog_server_event", _display, "on_server_event")
	
