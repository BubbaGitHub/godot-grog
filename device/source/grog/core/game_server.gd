class_name GameServer

# server to client signals
signal game_server_event

var data

var root_node : Node

# State
var globals = {}
var current_room : Node = null
var current_player : Node = null

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

func start_game(p_root_node: Node):
	root_node = p_root_node
	
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
		
		# TODO push actions instead of raw instructions
		event_queue.push_actions(instructions)
	else:
		print("Routine '%s' not found" % routine_name)

func execute_instruction(instruction: Dictionary) -> Dictionary:
	if instruction.subject:
		var item = get_item_named(instruction.subject)
		if not item:
			print("Unknown subject '%s'" % instruction.subject)
			return empty_action
		
		if not item.is_active():
			print("Item '%s' is inactive" % instruction.subject)
			return empty_action
		
		return execute_item_instruction(item, instruction)
	else:
		return execute_global_instruction(instruction)

func execute_global_instruction(instruction: Dictionary) -> Dictionary:
	var params = instruction.params
	match instruction.command:
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
			if not current_room:
				print("There's no room so can't load actor")
				return empty_action
			
			if params.size() < 1:
				print("One parameter needed for load_actor")
				return empty_action
			
			var actor_name = params[0]
			var starting_position
			
			var at_parameter: Node = get_parameter_as_room_node(params, "at", 1)
			
			if at_parameter:
				starting_position = at_parameter.position
			else:
				starting_position = current_room.get_default_player_position()
			
			var actor = load_actor(actor_name, starting_position)
			
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
			print("Unknown instruction '%s'" % instruction.command)

	return empty_action

func execute_item_instruction(item: Node, instruction: Dictionary) -> Dictionary:
	var params = instruction.params
	match instruction.command:
		"say":
			return say(item, params)
		"walk":
			var to_parameter: Node = get_parameter_as_room_node(params, "to")
	
			if not to_parameter:
				print("parameter 'to' needed for walk")
				return empty_action
			
			var target_position = to_parameter.position
			
			return walk(item, target_position)

	return empty_action

##############################

func get_parameter(params: Array, param_name: String, first_index = 0) -> String:
	for i in range(first_index, params.size()):
		var full_param: String = params[i]
		var prefix = param_name + "="
		if full_param.begins_with(prefix):
			return full_param.substr(prefix.length())
	return ""

func get_parameter_as_room_node(params: Array, param_name: String, first_index = 0) -> Node:
	if not current_room:
		return null
	
	var node_name = get_parameter(params, param_name, first_index)
	
	if not node_name:
		return null
	
	if current_room.has_node(node_name):
		return current_room.get_node(node_name)
	
	print("Room child '%s' not found" % node_name)
	
	return null
##############################

func say(item, params: Array):
	if params.size() < 1:
		print("One parameter needed for say")
		return empty_action
	
	# TODO
	var delay_seconds = 1.0
	var speech = params[0]
	
	server_event("say", [item, speech, delay_seconds])
	
	return { block = true, delay = delay_seconds }

func walk(actor, target_position: Vector2, global = false) -> Dictionary:
	var nav : Navigation2D = current_room.get_navigation()
	
	if not nav:
		return empty_action
	
	if global:
		target_position = target_position - nav.global_position
	
	target_position = nav.get_closest_point(target_position)
	
	var current_position = actor.position
	
	var path = nav.get_simple_path(current_position, target_position)
	
	return { block = true, routine = walk_routine(actor, path) }

func walk_routine(item, path: PoolVector2Array):
	while path.size() >= 2:
		var time = 0.0
	
		var origin: Vector2 = path[0]
		var destiny: Vector2 = path[1]
		
		var displacement = destiny - origin
		var distance2 = displacement.length_squared()
		var direction = displacement.normalized()
		
		item.emit_signal("start_walking", direction)
		
		var finish_step = false
		
		while not finish_step:
			time += yield()
			
			var step_distance = item.walk_speed * time
			
			var target_point = origin + step_distance * direction
			if pow(step_distance, 2) >= distance2:
				item.teleport(destiny)
				finish_step = true
			else:
				item.teleport(target_point)
			
		path.remove(0)
	
	item.emit_signal("stop_walking")
	

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
	
	if current_player:
		current_room.remove_child(current_player)
		current_player.queue_free()
		current_player = null
	
	if current_room:
		root_node.remove_child(current_room)
		current_room.queue_free()
	
	# TODO also free another actors and items
	
	current_room = room
	
	root_node.add_child(room) # room's _ready is called here
	
	server_event("room_loaded", [room]) # TODO parameter is not necessary

	return room

func load_actor(actor_name: String, starting_position: Vector2) -> Node:
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
	
	current_room.add_child(actor)
	
	# TODO
	if not current_player:
		current_player = actor
	
	actor.teleport(starting_position)
	
	server_event("actor_loaded", [actor])
	
	return actor

##############################

func server_event(event_name: String, args: Array = []):
	emit_signal("game_server_event", event_name, args)

#### Client calls

func is_ready():
	return event_queue.is_ready()

func has_started():
	return event_queue.started
	
func go_to(target_position: Vector2):
	if not current_player or not current_player.is_ready():
		return
	
	event_queue.push_action({
		method = "walk",
		params = [current_player, target_position, true]
	})
	

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
