extends Node2D

# TODO extract this from scene?
# TODO make room Control instead of Node2D?
export (int) var width = 1366
export (int) var height = 768

export (NodePath) var player_place_path
export (NodePath) var navigation_path
export (NodePath) var debug_node_path

func start_room():
	pass
	
func get_player_place():
	return get_node_if_present(player_place_path)

func get_navigation():
	return get_node_if_present(navigation_path)

func get_debug_node():
	return get_node_if_present(debug_node_path)
	
func get_node_if_present(node_path):
	if not node_path:
		return null
	
	if not has_node(node_path):
		print("No has node with path '%s'" % node_path)
		return null
	
	return get_node(node_path)

