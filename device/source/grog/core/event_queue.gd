
class_name EventQueue

var target

var started = false
var state = grog.GameState.Idle
var total_time = 0.0

var pending_actions = []
var become_idle_when = null
var routine = null

func start(p_target):
	target = p_target
	started = true
	total_time = 0.0
	
	routine = coroutine()
	
func process(delta):
	total_time += delta

	if routine:
		routine = routine.resume()

func coroutine():
	state = grog.GameState.Idle
	
	while true:
		yield()
		
		while not pending_actions:
			yield()
		
		# there are pending actions
		set_busy()
		
		while true:
			var next_action = pending_actions.pop_front()
			
			var event_result = target.run_instruction(next_action)
			
			if event_result.block:
				var current = get_current_time()
				become_idle_when = within_seconds(current, event_result.delay)
				
				# Start blocking action
				while true:
					yield()
					var current_time = get_current_time()
					if become_idle_when <= current_time:
						break
				# End of blocking action
				
			if not pending_actions:
				set_ready()
				break

func set_ready():
	state = grog.GameState.Idle
	target.set_ready()

func set_busy():
	state = grog.GameState.DoingSomething
	
func is_ready():
	return started and state == grog.GameState.Idle

#####################

func push_actions(action_list):
	for a in action_list:
		pending_actions.push_back(a)

#####################

#func wait(delay_seconds):
#	state = grog.GameState.DoingSomething
#	var current = get_current_time()
#	become_idle_when = within_seconds(current, delay_seconds)

####### Time

func get_current_time():
	return OS.get_ticks_msec()

func within_seconds(current_time, seconds):
	return current_time + 1000 * seconds
