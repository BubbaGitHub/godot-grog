class_name EventQueue

enum State {
	Idle,
	Busy
}

var target

var started = false
var state = State.Idle

var _pending_actions = []
var _routine = null

func start(p_target):
	target = p_target
	
	started = true
	
	_routine = coroutine()
	
	var _ret = grog.connect("grog_update", self, "grog_update")
	
func grog_update(delta):
	if _routine:
		_routine = _routine.resume(delta)

func coroutine():
	state = State.Idle
	
	while true:
		yield()
		
		while not _pending_actions:
			yield()
		
		# there are pending actions
		set_busy()
		
		while true:
			var next_action = _pending_actions.pop_front()
			
			# TODO only allow actions (not raw instructions)
			
			var is_method = next_action.has("method")
			var is_instruction = next_action.has("command")
			
			if is_method and is_instruction:
				push_warning("Parameter 'command' has no effect if 'method' is present")
			
			var action_result
			if next_action.has("method"):
				action_result = target.callv(next_action.method, next_action.params)
			else:
				action_result = target.execute_instruction(next_action)
			
			if action_result.block:
				if action_result.has("routine"):
					if action_result.has("delay"):
						push_warning("Parameter 'delay' has no effect if 'routine' is present")
					
					var subroutine = action_result.routine
					
					while subroutine:
						var delta = yield()
						subroutine = subroutine.resume(delta)
					
				elif action_result.has("delay"):
					var delay = action_result.delay
					
					var elapsed = 0.0
					
					while elapsed < delay:
						elapsed += yield()
				else:
					push_error("Blocking action must have either 'routine' or 'delay parameter'")
			
			if not _pending_actions:
				set_ready()
				break

func set_ready():
	state = State.Idle
	target.set_ready()

func set_busy():
	state = State.Busy
	
func is_ready():
	return started and state == State.Idle

#####################

func push_action(action):
	_pending_actions.push_back(action)
	
func push_actions(action_list):
	for action in action_list:
		push_action(action)
