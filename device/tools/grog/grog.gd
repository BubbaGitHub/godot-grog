extends Node

signal grog_update

var tree

enum ParameterType {
	# accepts quoted and raw strings, passes it as String
	StringType,
	# accepts quoted and raw strings, passes full token (keeping that information)
	StringTokenType,
	# parses and passes parameter as float
	FloatType
}

var commands = {
	load_room = {
		has_subject = false,
		required_params = [
			ParameterType.StringType
		]
	},
	load_actor = {
		has_subject = false,
		required_params = [
			ParameterType.StringType
		]
	},
	wait = {
		has_subject = false,
		required_params = [
			ParameterType.FloatType
		]
	},
	say = {
		has_subject = true,
		required_params = [
			ParameterType.StringTokenType
		]
	},
	walk = {
		has_subject = true,
		required_params = []
		# TODO required option 'at'
	}
}

#	@PUBLIC

func _enter_tree():
	tree = get_tree()

func compile(script: Resource) -> Object:
	return get_compiler().compile(script)

func compile_text(code: String) -> Object:
	return get_compiler().compile_text(code)
	
func get_compiler():
	return GrogCompiler.new()
	
#	@GODOT
	
func _process(delta):
	emit_signal("grog_update", delta)
