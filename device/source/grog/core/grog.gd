extends Node

# TODO
var game = null

var tree

func _enter_tree():
	# TODO
	tree = get_tree()

enum GameState { Idle, DoingSomething }

func get_compiler():
	return GrogCompiler.new()

func _process(delta):
	if game and game.has_started():
		game.process(delta)

#	@PUBLIC

func new_game_server(game_data: Resource) -> Object:
	game = game_data.game_server_model.new()
	
	game.init_game(game_data)

	return game

func compile(script: Resource) -> Object:
	return get_compiler().compile(script)
