extends Node2D

# TODO extract this from scene?
# TODO make room Control instead of Node2D?
export (int) var width = 1366
export (int) var height = 768

export (NodePath) var player_place_path

func start_room():
	pass
	
func get_player_place():
	return get_node(player_place_path)

func _ready():
	pass
