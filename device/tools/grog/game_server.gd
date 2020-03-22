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
	FromRawScript,
	FromScriptResource,
	FromCompiledScript
}

var _game_start_mode
var _game_start_param

const empty_action = { block = false }

func init_game(game_data: Resource, p_game_start_mode = StartMode.Default, p_game_start_param = null) -> bool:
	data = game_data
	
	_game_start_mode = p_game_start_mode
	_game_start_param = p_game_start_param
	
	match p_game_start_mode:
		StartMode.Default:
			return true
		StartMode.FromRawScript:
			var compiled_script = grog.compile_text(_game_start_param)
			
			if compiled_script.is_valid:
				_game_start_param = compiled_script
				return true
			else:
				print("Script is invalid")
				
				compiled_script.print_errors()
				return false
		StartMode.FromScriptResource:
			var compiled_script = grog.compile(_game_start_param)
			if compiled_script.is_valid:
				_game_start_param = compiled_script
				return true
			else:
				print("Script is invalid")
				
				compiled_script.print_errors()
				return false
		StartMode.FromCompiledScript:
			return _game_start_param.is_valid
		
	return false

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
		
		_:
			run_compiled(_game_start_param, "start")

func event_queue_set_ready():
	server_event("set_ready")

func event_queue_stopped():
	_free_all()
	server_event("game_ended")

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
		print("Script is invalid")

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

##############################

#	@COMMANDS

func load_room(room_name: String, _options = {}):
	var room = _load_room(room_name)
	
	if room:
		# TODO check this (clearing player when loading new room)
		current_player = null
	else:
		print("Couldn't load room '%s'" % room_name)
	
	return empty_action

func load_actor(actor_name: String, options = {}):
	if not current_room:
		print("There's no room!")
		return empty_action
	
	var starting_position
	
	var at_node: Node = get_option_as_room_node("at", options)
	
	if at_node:
		starting_position = at_node.position
	else:
		starting_position = current_room.get_default_player_position()

	var actor = _load_actor(actor_name, starting_position)
	
	if not actor:
		print("Couldn't load actor '%s'" % actor_name)
		return
	
	# TODO
	if not current_player:
		current_player = actor
	
	return empty_action

func wait(delay_seconds: float, _options = {}):
	server_event("wait_started", [delay_seconds])
	
	return { block = true, routine = _wait_routine(delay_seconds) }

func say(item_name: String, speech_token: Dictionary, options = {}):
	var speech: String
	if speech_token.type == GrogCompiler.TOKEN_QUOTED:
		speech = speech_token.content
	else:
		speech = tr(speech_token.content)
	
	var item = null
	if item_name:
		item = get_item_named(item_name)
		if not item:
			return empty_action
	
	var duration: float = options.get("duration", 2.0) # TODO harcoded default say duration
	var skippable: bool = options.get("skippable", false) # TODO harcoded default say skippable
	
	# TODO implement skippable
	
	server_event("say", [item, speech, duration])
	
	return { block = true, routine = _wait_routine(duration) }

func walk(item_name: String, options: Dictionary):
	if not item_name:
		print("Walk action needs a subject") # TODO check in compiler?
		return empty_action
	
	var item = get_item_named(item_name)
	if not item:
		return empty_action
	
	var to_node: Node = get_option_as_room_node("to", options)

	if not to_node:
		push_error("parameter 'to' needed for walk")
		return empty_action
	
	var target_position = to_node.position
	
	return _walk_to(item, target_position)
	
func end(_params = []):
	return { stop = true }
	
##############################

func get_option_as_room_node(option_name: String, options: Dictionary) -> Node:
	if not options.has(option_name):
		return null
	
	var node_name: String = options[option_name]
	
	if not current_room.has_node(node_name):
		print("Node '%s' not found" % node_name)
		return null
		
	return current_room.get_node(node_name)

##############################

func _load_room(room_name: String) -> Node:
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
	
	_free_all()
	
	current_room = room
	
	root_node.add_child(room) # room's _ready is called here
	
	server_event("room_loaded", [room]) # TODO parameter is not necessary

	return room

func _load_actor(actor_name: String, starting_position: Vector2) -> Node:
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
	
	actor.teleport(starting_position)
	
	server_event("actor_loaded", [actor])
	
	return actor

func _wait_routine(delay_seconds: float):
	var elapsed = 0.0
	
	while elapsed < delay_seconds:
		elapsed += yield()
	
	server_event("wait_ended")

func _walk_to(actor, target_position: Vector2, global = false) -> Dictionary:
	var nav : Navigation2D = current_room.get_navigation()
	
	if not nav:
		return empty_action
	
	if global:
		target_position = target_position - nav.global_position
	
	target_position = nav.get_closest_point(target_position)
	
	var current_position = actor.position
	
	var path = nav.get_simple_path(current_position, target_position)
	
	return { block = true, routine = _walk_routine(actor, path) }

func _walk_routine(item, path: PoolVector2Array):
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

func _free_all():
	if current_player:
		current_room.remove_child(current_player)
		current_player.queue_free()
		current_player = null
	
	if current_room:
		root_node.remove_child(current_room)
		current_room.queue_free()
		current_room = null
	
	# TODO also free another actors and items
	
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
		command = "_walk_to",
		params = [current_player, target_position, true]
	})
	
func stop():
	event_queue.stop_asap()

#### Finding items

func get_item_named(item_name: String) -> Node:
	var item = find_item_named(item_name)
	if not item:
		print("Unknown item '%s'" % item_name)
		return null
	
	if not item.is_active():
		print("Item '%s' is inactive" % item_name)
		return null
	
	return item
	
func find_item_named(item_name: String) -> Node:
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
