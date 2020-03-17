extends Node

export (NodePath) var room_place_path

export (bool) var update_layout = false

var _room_place: Control
var _current_room: Node2D
var _current_player: Node2D

func _ready():
	_room_place = get_node(room_place_path)
	#ignore-warning:return_value_discarded
	var _ret = get_tree().get_root().connect("size_changed", self, "on_viewport_resized")
	
	# TODO _ret

func load_player(actor_resource):
	
	var player_place = _current_room.get_player_place()
	var actor_scene = actor_resource.actor_scene
	var player : Node2D = actor_scene.instance()
	
	make_empty(player_place)
	
	_current_player = player
	
	player_place.add_child(player)
	
	
func load_room(room_to_load : Resource) -> Node:
	var room_scene = room_to_load.room_scene
	
	var room : Node2D = room_scene.instance()
	
	# makes _room_place empty
	make_empty(_room_place)
	
	_current_room = room
	
	_room_place.add_child(room) # room.ready is called here
	
	update_room_layout()
	
	return room

func update_room_layout():
	var scale = _room_place.rect_size.y / _current_room.height
	
	_current_room.scale = Vector2(scale, scale)
	
	var room_pos = -_current_room.width * scale / 2
	_current_room.position.x = room_pos
	
func on_viewport_resized():
	if not update_layout:
		return
	var new_size = get_tree().get_root().size
	
	update_room_layout()

#####

func make_empty(node):
	while node.get_child_count():
		var first_child = node.get_child(0)
		node.remove_child(first_child)
		first_child.queue_free()
