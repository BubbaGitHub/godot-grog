extends Node

# TODO
var game = null

func get_compiler():
	return GrogCompiler.new()

func _process(delta):
	if game:
		game.process(delta)

#	@PUBLIC

func new_game_server(game_data: Resource, initial_script: CompiledGrogScript, display: Node) -> Object:
	game = game_data.game_server_model.new()
	
	game.start_game(game_data, display)
	
	if initial_script:
		run_action(game, initial_script, "start")
	else:
		print("No initial script")
	
	return game

func compile(script: Resource) -> Object:
	return get_compiler().compile(script)
#	@PRIVATE

func run_action(_game: Object, compiled_script: CompiledGrogScript, routine_name: String):
	if not compiled_script:
		push_error("No compiled_script")
		return
	if not routine_name:
		push_error("No routine_name")
		return
	
	if compiled_script.has_routine(routine_name):
		var instructions = compiled_script.get_routine(routine_name)
		
		_game.push_actions(instructions)

	else:
		print("Routine '%s' not found" % routine_name)
