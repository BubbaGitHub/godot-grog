extends Node

export (Resource) var game_to_load

onready var _room_list = $ui/room_list
onready var _ui = $ui
onready var _display = $display


# Called when the node enters the scene tree for the first time.
func _ready():
	if not game_to_load:
		push_error("No game_to_load")
		return
	
	list_rooms()
	
func list_rooms():
	if not _room_list:
		push_error("No _room_list")
		return
		
	for room in game_to_load.get_all_rooms():
		_room_list.room_added(room)



func _on_test_room_button_pressed():
	if not _room_list:
		push_error("No _room_list")
		return
		
	var current_room = _room_list.get_current()
	
	if not current_room:
		return
	
	load_room(current_room)
	
func load_room(_room):
	
	
	_display.load_room(_room)
	
	_ui.hide()
	_display.show()
