class_name GameServer

# server to client signals
signal game_server_event

var data

# State
var globals = {}
var current_room = null
var current_player = null

var event_queue : EventQueue = EventQueue.new()

enum StartMode {
	Default,
	FromScript,
	FromCompiledScript
}

var _game_start_mode
var _game_start_param

const empty_action = { block = false }

func init_game(game_data: Resource, p_game_start_mode = StartMode.Default, p_game_start_param = null):
	data = game_data
	
	_game_start_mode = p_game_start_mode
	_game_start_param = p_game_start_param

func start_game():
	server_event("game_started")
	event_queue.start(self)
	
	match _game_start_mode:
		StartMode.Default:
			var scripts = data.get_all_scripts()
			
			if not scripts:
				print("Game data has no scripts")
				return
			
			if not scripts[0]:
				print("Game data has no first script")
				return
			
			var script = scripts[0]
			run_script(script, "start")
		
		StartMode.FromCompiledScript:
			run_compiled(_game_start_param, "start")

func set_ready():
	server_event("set_ready")

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

func do_action(action: Dictionary) -> Dictionary:
	if action.subject:
		var item = get_item_named(action.subject)
		if not item:
			print("Unknown subject '%s'" % action.subject)
			return empty_action
		
		if not item.is_active():
			print("Item '%s' is inactive" % action.subject)
			return empty_action
		
		return do_item_action(item, action)
	else:
		return do_global_action(action)

func do_global_action(action: Dictionary) -> Dictionary:
	var params = action.params
	match action.command:
		"load_room":
			if params.size() < 1:
				print("One parameter needed for load_room")
				return empty_action
			
			var room_name = params[0]
			
			var room = load_room(room_name)
			
			if room:
				# TODO check this (clearing player when loading new room)
				current_player = null
			else:
				print("Couldn't load room '%s'" % room_name)
		
		"load_actor":
			if params.size() < 1:
				print("One parameter needed for load_actor")
				return empty_action
			
			var actor_name = params[0]
			
			var actor = load_actor(actor_name)
			
			if not actor:
				print("Couldn't load actor '%s'" % actor_name)
			
		"wait":
			if params.size() < 1:
				print("One parameter needed for wait")
				return empty_action
			
			var time_param = params[0]
			var delay_seconds = float(time_param)
			
			server_event("wait_started", [delay_seconds])
			
			return { block = true, delay = delay_seconds }
			
		"say":
			return say(null, params)
		
		_:
			print("Unknown instruction '%s'" % action.command)

	return empty_action

func do_item_action(item: Node, action: Dictionary) -> Dictionary:
	var params = action.params
	match action.command:
		"say":
			return say(item, params)

	return empty_action

##############################

func say(item, params):
	if params.size() < 1:
		print("One parameter needed for say")
		return empty_action
			
	# TODO
	var delay_seconds = 1.0
	var speech = params[0]
	
	server_event("say", [item, speech, delay_seconds])
	
	return { block = true, delay = delay_seconds }

##############################

func load_room(room_name: String) -> Node:
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
	
	server_event("room_loaded", [room])

	return room

func load_actor(actor_name: String) -> Node:
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
	
	# TODO
	current_player = actor
	
	server_event("actor_loaded", [actor])
	
	return actor

func walk_to(actor, target_position):
	var nav : Navigation2D = current_room.get_navigation()
	
	if not nav:
		return
	
	var relative_target_position = target_position - nav.global_position
	var relative_final_target = nav.get_closest_point(relative_target_position)
	
	var current_position = actor.position
	
	var path = nav.get_simple_path(current_position, relative_final_target)
	
	var debug_node = current_room.get_debug_node()
	if debug_node:
		debug_node.draw_points(path)
	
	actor.walk(path)

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

#### Finding items

func get_item_named(item_name: String) -> Node:
	# TODO make it efficient
	var items = grog.tree.get_nodes_in_group("item")
	
	for i in items:
		if i.global_id == item_name:
			return i
	
	return null

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

#### Misc
func get_default_color():
	return Color.gray
