class_name Sequence

var _instructions: Array
var _telekinetic: bool

func _init(p_instructions, p_telekinetic = true):
	_instructions = p_instructions
	_telekinetic = p_telekinetic

func get_instructions():
	return _instructions

func is_telekinetic() -> bool:
	return _telekinetic

func in_context(context: Dictionary) -> Array:
	var ret: Array = _instructions.duplicate(true)
	
	for i in range(ret.size()):
		var instruction = ret[i]
		var command = instruction.command
		var requirements = grog.commands[command]
		
		if requirements.has_subject:
			var current_subject = instruction.params[0]
			if context.has(current_subject):
				var new_subject = context[current_subject]
				instruction.params[0] = new_subject
	
	return ret
