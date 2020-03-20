extends Node2D

export (String) var global_id
export (Color) var color

export (NodePath) var speech_position_path

export (float) var walk_speed = 300 # pixels per second

signal start_walking
signal stop_walking

# TODO build always?
# TODO currently it is not used
var event_queue = EventQueue.new()

var _walking_routine = null

##############################

func _ready():
	add_to_group("item")
	event_queue.start(self)


func _process(delta):
	if _walking_routine:
		_walking_routine = _walking_routine.resume(delta)

func is_ready():
	return event_queue.started and event_queue.is_ready()

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

func do_action(action: Dictionary) -> Dictionary:
	var ret = { block = false }
	
	if action.command == "walk":
		assert(not _walking_routine)
		assert(action.has("path") and action.path.size() >= 2)
		
		_walking_routine = walking_routine(action.path)
		
		# blocks until event_queue.is_blocked is manually set to false
		ret.block = true
	
	return ret

func set_ready():
	pass

##############################

func walking_routine(path: Array):
	while path.size() >= 2:
		var time = 0.0
	
		var origin: Vector2 = path[0]
		var destiny: Vector2 = path[1]
		
		var displacement = destiny - origin
		var distance2 = displacement.length_squared()
		var direction = displacement.normalized()
		
		emit_signal("start_walking", direction)
		
		var finish_step = false
		
		while not finish_step:
			time += yield()
			
			var step_distance = walk_speed * time
			
			var target_point = origin + step_distance * direction
			if pow(step_distance, 2) >= distance2:
				teleport(destiny)
				finish_step = true
			else:
				teleport(target_point)
			
		path.pop_front()
	
	emit_signal("stop_walking")
	
	event_queue.is_blocked = false

##############################

func teleport(target_pos):
	position = target_pos
	on_teleport(target_pos)

# abstract method
func on_teleport(_target_pos):
	pass

func get_speech_position():
	if speech_position_path and has_node(speech_position_path):
		return position + get_node(speech_position_path).position
	else:
		return position
