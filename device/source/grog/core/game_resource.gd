extends Resource

class_name GameResource

export (Array, Resource) var scripts setget , get_all_scripts

export (Array, Resource) var rooms setget , get_all_rooms

export (Resource) var game_model

func get_all_rooms():
	return rooms

func get_all_scripts():
	return scripts
