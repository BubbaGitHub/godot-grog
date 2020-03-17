extends Resource

class_name RoomResource

#export (String) var room_name = "" setget set_room_name, get_room_name

export (Resource) var room_scene

#func set_room_name(new_room_name):
#	room_name = new_room_name
#
#func get_room_name():
#	return room_name
