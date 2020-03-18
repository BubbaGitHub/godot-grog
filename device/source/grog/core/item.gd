extends Node2D

export (String) var global_id
export (Color) var color

export (NodePath) var speech_position_path

# TODO build always?
var event_queue = EventQueue.new()

##############################

func _ready():
	add_to_group("item")
	event_queue.start(self)

func _process(delta):
	event_queue.process(delta)

##############################

func is_active():
	# TODO
	return true
	
##############################

func walk(path):
	if not event_queue.is_ready():
		print("I'm not ready to walk'")
		return
	
	event_queue.push_action({ command = "walk", path = path })

##############################

func do_action(inst: Dictionary) -> Dictionary:
	var ret = { block = false }
	
	if inst.command == "walk":
		print("Walk to %s" % inst.path)
		
		ret.block = true
		ret.delay = 1.0
	
	return ret

func set_ready():
	print("I'm ready'")

##############################

func get_speech_position():
	if speech_position_path and has_node(speech_position_path):
		return position + get_node(speech_position_path).position
	else:
		return position
