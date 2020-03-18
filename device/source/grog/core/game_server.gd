
# server to client signals
signal game_server_event

var data

# State
var globals = {}
var current_room = null
var current_player = null

var event_queue : EventQueue = EventQueue.new()

func init_game(game_data: Resource):
	data = game_data

func start_default():
	start_game()
	
	var scripts = data.get_all_scripts()
	
	if not scripts:
		print("Game data has no scripts")
		return
	
	if not scripts:
		print("Game data has no scripts")
		return
	
	if not scripts:
		print("Game data has no scripts")
		return
	
	var script = scripts[0]
	run_script(script, "start")

func start_from_compiled_script(compiled_script: CompiledGrogScript):
	start_game()
	run_compiled(compiled_script, "start")

func start_game():
	server_event("start_game", [self])
	event_queue.start(self)

func process(delta):
	event_queue.process(delta)

func set_ready():
	server_event("ready")

##############################

func run_script_named(script_name: String, routine_name: String):
	var script_resource = get_script_resource(script_name)
	
	if not script_resource:
		print("No script '%s'" % script_name)
		return
	
	run_script(script_resource, routine_name)

func run_script(script_resource: Resource, routine_name: String):
	var compiled_script = grog.compile(script_resource)
	if not compiled_script.is_valid:
		print("Script '%s' is invalid")
		
		compiled_script.print_errors()
		return
	
	run_compiled(compiled_script, routine_name)

func run_compiled(compiled_script: CompiledGrogScript, routine_name: String):
	if compiled_script.has_routine(routine_name):
		var instructions = compiled_script.get_routine(routine_name)

		event_queue.push_actions(instructions)
	else:
		print("Routine '%s' not found" % routine_name)

func run_instruction(inst: Dictionary) -> Dictionary:
	var ret = { block = false }
	
	if inst.subject:
		print("Unknown subject '%s'" % inst.subject)
		return ret
	
	match inst.command:
		"load_room":
			if inst.params.size() < 1:
				print("One parameter needed for load_room")
				return ret
			
			var room_name = inst.params[0]
			var actor_name = ""
			if inst.params.size() >= 2:
				var actor_param = inst.params[1]
				if actor_param.begins_with("player="):
					actor_name = actor_param.substr(len("player="))

			var room = load_room(room_name, actor_name)
			
			if not room:
				print("Couldn't load room '%s'" % room_name)
				return ret
		"show_controls":
			server_event("show_controls")
		"hide_controls":
			server_event("hide_controls")
		"wait":
			if inst.params.size() < 1:
				print("One parameter needed for wait")
				return ret
			
			var time_param = inst.params[0]
			var delay_seconds = float(time_param)
			
			server_event("start_waiting", [delay_seconds])
			
			ret.block = true
			ret.delay = delay_seconds
			
		"say":
			if inst.params.size() < 1:
				print("One parameter needed for say")
				return ret
			
			# TODO make this configurable and skipping
			var delay_seconds = 1.0
			
			var speech = inst.params[0]
			server_event("say", [speech, delay_seconds])
			
			ret.block = true
			ret.delay = delay_seconds

		_:
			print("Unknown instruction '%s'" % inst.command)

	return ret

##############################

func load_room(room_name: String, actor_name: String) -> Node:
	var room_resource = get_room(room_name)
	if not room_resource:
		print("No room '%s'" % room_name)
		return null
	
	if not room_resource.room_scene:
		print("No room_scene in room '%s'" % room_name)
		return null
	
	var room = room_resource.room_scene.instance()
	
	if not room:
		push_error("Couldn't load room '%s'"  % room_name)
		return null
	
	current_room = room
	
	server_event("load_room", [room])
	
	if actor_name:
		var actor_resource = get_actor(actor_name)
		if not actor_resource:
			print("No actor '%s'" % actor_name)
			return null
		
		if not actor_resource.actor_scene:
			print("No actor_scene in actor '%s'" % actor_name)
			return null
		
		var actor = actor_resource.actor_scene.instance()
		
		if not actor:
			push_error("Couldn't load actor '%s'"  % actor_name)
			return null
		
		current_player = actor
		
		server_event("load_actor", [actor])
	
	return room

func walk_to(actor, target_position):
	var nav : Navigation2D = current_room.get_navigation()
	
	if not nav:
		return
	
	var relative_target_position = target_position - nav.global_position
	var relative_final_target = nav.get_closest_point(relative_target_position)
	
	actor.position = relative_final_target

##############################

func server_event(event_name: String, args: Array = []):
	emit_signal("game_server_event", event_name, args)

#### Client calls

func is_ready():
	return event_queue.is_ready()

func has_started():
	return event_queue.started
	
func left_click(target_position: Vector2):
	if not event_queue.is_ready():
		print("Rejecting click")
		return
	
	if not current_player:
		return
	
	walk_to(current_player, target_position)

#### Finding resources

func get_room(room_name):
	return get_resource_in(data.get_all_rooms(), room_name)

func get_actor(actor_name):
	return get_resource_in(data.get_all_actors(), actor_name)

func get_script_resource(script_name):
	return get_resource_in(data.get_all_scripts(), script_name)

func get_resource_in(list, elem_name):
	for i in range(list.size()):
		var elem = list[i]
		
		if elem.get_name() == elem_name:
			return elem
	return null

