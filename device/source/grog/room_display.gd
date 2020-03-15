extends Node

export (NodePath) var room_place_path

var _room_place: Control
var _current_room: Node2D

func _ready():
	_room_place = get_node(room_place_path)
	

func load_room(room_to_load : Resource) -> Node:
	var room_scene = room_to_load.room_scene
	
	var room : Node2D = room_scene.instance()
	
	# makes _room_place empty
	while _room_place.get_child_count():
		var first_child = _room_place.get_child(0)
		_room_place.remove_child(first_child)
		first_child.queue_free()
	
	_current_room = room
	
	_room_place.add_child(room)
	
	var scale = _room_place.rect_size.y / room.height
	
	room.scale = Vector2(scale, scale)
	
	var room_pos = -room.width * scale / 2
	room.position.x = room_pos
	
	return room
	
