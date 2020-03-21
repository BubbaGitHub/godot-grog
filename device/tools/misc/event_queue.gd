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
var _stopped

func start(p_target):
	target = p_target
	
	started = true
	_stopped = false
	
	_routine = coroutine()
	
	var _ret = grog.connect("grog_update", self, "grog_update")

func stop_asap():
	_stopped = true

func grog_update(delta):
	if _routine:
		_routine = _routine.resume(delta)
		
		if not _routine:
			target.event_queue_stopped()

func coroutine():
	state = State.Idle
	
	while true:
		while not _pending_actions:
			if _stopped:
				return null
			yield()
		
		# there are pending actions
		set_busy()
		
		while true:
			var next_action = _pending_actions.pop_front()
			
			var params = next_action.params if next_action.has("params") else []
			var action_result = target.callv(next_action.command, params)
			
			if action_result.has("stop") and action_result.stop:
				return null # stops coroutine
			
			elif action_result.block:
				if action_result.has("routine"):
					var subroutine = action_result.routine
					
					while subroutine:
						if _stopped:
							return null
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
