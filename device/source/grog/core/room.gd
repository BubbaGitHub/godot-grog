extends Node2D

export (NodePath) var player_place_path
export (NodePath) var navigation_path

func start_room():
	pass
	
func get_player_default_position():
	var player_spot = get_node_if_present(player_place_path)
	if player_spot:
		return player_spot.position

func get_navigation():
	return get_node_if_present(navigation_path)

func get_node_if_present(node_path):
	if not node_path:
		return null
	
	if not has_node(node_path):
		print("No has node with path '%s'" % node_path)
		return null
	
	return get_node(node_path)

