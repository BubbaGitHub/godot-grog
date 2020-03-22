extends Node

signal grog_update

var tree

enum ParameterType {
	# accepts quoted and raw strings, passes it as String
	StringType,
	# accepts quoted and raw strings, passes full token (keeping that information)
	StringTokenType,
	# parses and passes parameter as float
	FloatType,
	# parses and passes parameter as float (either 'true' or 'false')
	BooleanType
}

var commands = {
	load_room = {
		has_subject = false,
		required_params = [
			ParameterType.StringType
		],
		named_params = []
	},
	load_actor = {
		has_subject = false,
		required_params = [
			ParameterType.StringType
		],
		named_params = [
			{ name = "at", required = false, type = ParameterType.StringType }
		]
	},
	wait = {
		has_subject = false,
		required_params = [
			ParameterType.FloatType
		],
		named_params = [
			{ name = "skippable", required = false, type = ParameterType.BooleanType }
		]
	},
	say = {
		has_subject = true,
		required_params = [
			ParameterType.StringTokenType
		],
		named_params = [
			{ name = "duration", required = false, type = ParameterType.FloatType },
			{ name = "skippable", required = false, type = ParameterType.BooleanType }
		]
	},
	walk = {
		has_subject = true,
		required_params = [],
		named_params = [
			{ name = "to", required = true, type = ParameterType.StringType }
		]
	},
	end = {
		has_subject = false,
		required_params = [],
		named_params = []
	}
}

#	@PUBLIC

func _enter_tree():
	tree = get_tree()

func compile(script: Resource) -> CompiledGrogScript:
	return get_compiler().compile(script)

func compile_text(code: String) -> CompiledGrogScript:
	return get_compiler().compile_text(code)
	
func get_compiler():
	return GrogCompiler.new()
	
#	@GODOT
	
func _process(delta):
	emit_signal("grog_update", delta)
