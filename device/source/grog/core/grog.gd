extends Node

signal grog_update

var tree


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
