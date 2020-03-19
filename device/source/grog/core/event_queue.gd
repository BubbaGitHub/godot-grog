
class_name EventQueue

enum State {
	Idle,
	Busy
}

var target

var started = false
var state = State.Idle
var total_time = 0.0

var _pending_actions = []
var _routine = null

var is_blocked = false
var _timer_on = false
var _become_idle_when = null

func start(p_target):
	target = p_target
	
	started = true
	total_time = 0.0
	
	_routine = coroutine()
	
	var _ret = grog.connect("grog_update", self, "grog_update")
	
func grog_update(delta):
	total_time += delta

	if _routine:
		_routine = _routine.resume()

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
			
			var action_result = target.do_action(next_action)
			
			if action_result.block:
				is_blocked = true
				
				if action_result.has("delay"):
					var current = get_current_time()
					_timer_on = true
					_become_idle_when = within_seconds(current, action_result.delay)
				
				# else it is blocked until is_blocked is set to false manually
				
				# Start blocking action
				while is_blocked:
					yield()
					
					if _timer_on:
						var current_time = get_current_time()
						if _become_idle_when <= current_time:
							is_blocked = false
				# End of blocking action
				
				_timer_on = false
			
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

####### Time

func get_current_time():
	return OS.get_ticks_msec()

func within_seconds(current_time, seconds):
	return current_time + 1000 * seconds
