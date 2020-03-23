
class_name CompiledGrogScript

var is_valid
var errors = []

var _sequences = {}

#	@CREATE

func _init():
	is_valid = true

func add_sequence(sequence_name: String, body: Array):
	if has_sequence(sequence_name):
		push_error("Already has sequence '%s'" % sequence_name)
		return
	
	_sequences[sequence_name] = body

#	@USE

func has_sequence(sequence_name: String):
	if not is_valid:
		return false
	
	return _sequences.has(sequence_name)

func get_sequence(sequence_name: String) -> Array:
	if not is_valid:
		return []
	elif not has_sequence(sequence_name):
		push_error("Sequence '%s' not present" % sequence_name)
		return []
	
	return _sequences[sequence_name]

func add_error(new_error):
	errors.append(new_error)
	is_valid = false

func print_errors():
	for i in range(errors.size()):
		print(errors[i])
		
