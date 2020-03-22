class_name EventQueue

enum State {
	Idle,
	Busy
}

var started = false
var state = State.Idle

var _target: WeakRef

var _pending_actions = []
var _routine = null
var _stopped: bool

func start(p_target):
	# uses weak reference so the game can be destroyed even if the queue didn't
	_target = weakref(p_target)
	
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
			_get_target().event_queue_stopped()

func coroutine():
	state = State.Idle
	
	while true:
		while not _pending_actions:
			if _stopped:
				return null
			yield()
		
		# starts running actions
		
		while true:
			var next_action = _pending_actions.pop_front()
			
			var command = next_action.command
			var params = next_action.params if next_action.has("params") else []
			
			var action_result = _get_target().callv(command, params)
			
			if not action_result:
				push_error("Command %s: no action returned (%s)" % [command, action_result])
				return null
			elif typeof(action_result) != TYPE_DICTIONARY:
				push_error("Command %s: action should be a dictionary (%s)" % [command, action_result])
				return null
			elif not ((action_result.has("stop") and action_result.stop) or action_result.has("block")):
				push_error("Command %s: invalid action dictionary (%s)" % [command, action_result])
				return null
			
			if action_result.has("stop") and action_result.stop:
				return null # stops coroutine
			
			elif action_result.block:
				if state == State.Idle:
					 # first blocking action in this run
					state = State.Busy
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
				# ends running actions
				if state == State.Busy:
					# there were blocking actions in this run
					# so we get ready now
					state = State.Idle
					_get_target().event_queue_set_ready()
				
				break

func is_ready():
	return started and state == State.Idle

#####################

func push_action(action):
	_pending_actions.push_back(action)
	
func push_actions(action_list):
	for action in action_list:
		push_action(action)

####################

func _get_target():
	return _target.get_ref()
