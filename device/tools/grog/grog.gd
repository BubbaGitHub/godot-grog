extends Node

signal grog_update

var tree

var commands = {
	load_room = {
		has_subject = false,
		required_params = 1
	},
	load_actor = {
		has_subject = false,
		required_params = 1
	},
	wait = {
		has_subject = false,
		required_params = 1
	},
	say = {
		has_subject = true,
		required_params = 1
	},
	walk = {
		has_subject = true,
		required_params = 0
		# TODO required option 'at'
	}
}

#	@PUBLIC

func _enter_tree():
	tree = get_tree()

func compile(script: Resource) -> Object:
	return get_compiler().compile(script)

func get_compiler():
	return GrogCompiler.new()
	
#	@GODOT
	
func _process(delta):
	emit_signal("grog_update", delta)
