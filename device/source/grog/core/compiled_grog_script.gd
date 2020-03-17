
class_name CompiledGrogScript

var _routines = {}
var is_valid
var errors = []

#	@CREATE

func _init():
	is_valid = true

func add_routine(routine_name: String, body: Array):
	if has_routine(routine_name):
		push_error("Already has routine '%s'" % routine_name)
		return
	
	_routines[routine_name] = body

#	@USE

func has_routine(routine_name: String):
	if not is_valid:
		return false
	
	return _routines.has(routine_name)

func get_routine(routine_name: String) -> Array:
	if not is_valid:
		return []
	elif not has_routine(routine_name):
		push_error("Routine '%s' not present" % routine_name)
		return []
	
	return _routines[routine_name]

func add_error(new_error):
	errors.append(new_error)
	is_valid = false

func print_errors():
	for i in range(errors.size()):
		print(errors[i])
		
