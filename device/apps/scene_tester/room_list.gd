extends Control

export (Resource) var room_item_model

export (NodePath) var room_list_path

var _rooms = []
onready var _room_list = get_node(room_list_path)

var _current_selected = null


#	@PUBLIC

func get_current():
	return _current_selected.target

func room_added(room: Resource) -> void:
	if not room_item_model:
		print("No room_item_model")
		return
	
	if not _room_list:
		print("No _room_list")
		return
	
	var room_item = room_item_model.instance()
	
	room_item.set_target(room)
	
	room_item.connect("room_item_toggled", self, "on_room_toggled")
	
	_room_list.add_child(room_item)
	_rooms.append(room_item)

func select_anyone():
	if _rooms.size() == 0:
		return
	
	var some_item = _rooms[0]
	some_item.check()

#	@PRIVATE

func on_room_toggled(room_view, value):
	if not room_view:
		push_error("No room_view")
		return
	
	if value:
		if _current_selected:
			if room_view == _current_selected:
				push_warning("Room '%s' already selected" % room_view.target.room_name)
				return
			
			_current_selected.uncheck()
		
		# emit on_room_selected (_current_selected, room_view)
		
		_current_selected = room_view
	
	else:
		if not _current_selected or _current_selected != room_view:
			push_error("Unselected a non-selected room")
			return
		
		# emit on_room_deselected (room_view)
		
		_current_selected = null

	

