
var data
var display

var globals

var pending_actions : Array

enum GameState { Idle, DoingSomething}
var state = GameState.Idle
var total_time

var become_idle_when = null

func start_game(game_data: Resource, p_display: Node):
	data = game_data
	display = p_display
	
	globals = {}
	
	pending_actions = []
	state = GameState.Idle
	total_time = 0

func process(delta):
	total_time += delta
	
	if state == GameState.Idle and pending_actions:
		var next = pending_actions.pop_front()
		
		run_instruction(next)
		
	elif state == GameState.DoingSomething:
		if become_idle_when != null:
			var now_seconds = OS.get_time().second
			if become_idle_when <= now_seconds:
				
				state = GameState.Idle
				become_idle_when = null
		
		
func run_instruction(inst: Dictionary):
	if inst.subject:
		print("Unknown subject '%s'" % inst.subject)
		return
	
	match inst.command:
		"load_room":
			if inst.params.size() < 1:
				print("One parameter needed for load_room")
				return
			
			var room_name = inst.params[0]
			var actor_name = null
			if inst.params.size() >= 2:
				var actor_param = inst.params[1]
				if actor_param.begins_with("player="):
					actor_name = actor_param.substr(len("player="))

			var room = load_room(room_name, actor_name)
			
			if not room:
				print("Couldn't load room '%s'" % room_name)
				return
		"show_controls":
			display.show_controls()
		"hide_controls":
			display.hide_controls()
		"wait":
			if inst.params.size() < 1:
				print("One parameter needed for wait")
				return
			
			var time_param = inst.params[0]
			var delay_seconds = float(time_param)
			state = GameState.DoingSomething
			become_idle_when = OS.get_time().second + delay_seconds
			
		_:
			print("Unknown instruction '%s'" % inst.command)
		

func push_actions(action_list):
	for a in action_list:
		pending_actions.push_back(a)

func load_room(room_name: String, actor_name):
	var room_resource = get_room(room_name)
	if not room_resource:
		print("No room '%s'" % room_name)
		return null
	
	var actor_resource = null
	
	if actor_name:
		actor_resource = get_actor(actor_name)
		if not actor_resource:
			print("No actor '%s'" % actor_name)
			#return null
			
	var room = display.load_room(room_resource)
	
	if actor_resource:
		display.load_player(actor_resource)
	
	# room is ready here
	# TODO schedule it...
	# state = GameState.Idle
	
	return room


func get_room(room_name):
	return get_resource_in(data.get_all_rooms(), room_name)

func get_actor(actor_name):
	return get_resource_in(data.get_all_actors(), actor_name)

func get_resource_in(list, elem_name):
	for i in range(list.size()):
		var elem = list[i]
		
		if elem.get_name() == elem_name:
			return elem
	return null
