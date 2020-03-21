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
		
		if not _routine:
			target.event_queue_stopped()

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
			
			var action_result = target.callv(next_action.command, next_action.params)
			
			if action_result.has("stop") and action_result.stop:
				return null # stops coroutine
			
			elif action_result.block:
				if action_result.has("routine"):
					var subroutine = action_result.routine
					
					while subroutine:
						var delta = yield()
						subroutine = subroutine.resume(delta)
				else:
					print("'block' is true but no 'routine'")
			
			if not _pending_actions:
				set_ready()
				break

func set_ready():
	state = State.Idle
	target.event_queue_set_ready()

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
