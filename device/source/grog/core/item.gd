extends Node

# TODO build always?
var event_queue = EventQueue.new()

func _ready():
	event_queue.start(self)

func _process(delta):
	event_queue.process(delta)

func walk(path):
	if not event_queue.is_ready():
		print("I'm not ready to walk'")
		return
	
	event_queue.push_action({ command = "walk", path = path })

func do_action(inst: Dictionary) -> Dictionary:
	var ret = { block = false }
	
	if inst.command == "walk":
		print("Walk to %s" % inst.path)
		
		ret.block = true
		ret.delay = 1.0
	
	return ret

func set_ready():
	print("I'm ready'")
