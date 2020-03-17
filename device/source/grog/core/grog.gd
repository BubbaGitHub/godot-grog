extends Node

# TODO
var game = null

func get_compiler():
	return GrogCompiler.new()

func _process(delta):
	if game:
		game.process(delta)

#	@PUBLIC

func new_game_server(game_data: Resource, display: Node) -> Object:
	game = game_data.game_server_model.new()
	
	game.start_game(game_data, display)

	return game

func compile(script: Resource) -> Object:
	return get_compiler().compile(script)
