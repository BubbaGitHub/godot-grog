
class_name GrogCompiler

# Tokenizer patterns

# any number of tabs followed by any number of spaces and non-whitespaces (anything but tabs)
const line_regex_pattern = "^(\\t)*(\\S|\\ )*$"

# Compiler patterns
const sequence_header_regex_pattern = "^\\:([a-zA-Z0-9\\.\\-\\_\\ \\#]+)$"

const command_regex_pattern = "^([a-zA-Z0-9\\-\\_\\ \\#]*)\\.([a-zA-Z0-9\\-\\_\\ \\#]+)$"

const float_regex_pattern = "^\\ *([0-9]+|[0-9]*\\.[0-9]+)\\ *$"

const TOKEN_RAW = "raw"
const TOKEN_QUOTED = "quoted"

#	@PUBLIC

func compile(script: Resource) -> CompiledGrogScript:
	return compile_text(script.get_code())

func compile_text(code: String) -> CompiledGrogScript:
	var raw_lines: Array = code.split("\n")
	
	var compiled_script = CompiledGrogScript.new()
	
	var tokenized_lines = tokenize_lines(compiled_script, raw_lines)
	
	if not compiled_script.is_valid:
		return compiled_script
	
	identify_lines(compiled_script, tokenized_lines)
	
	if not compiled_script.is_valid:
		return compiled_script
	
	compile_lines(compiled_script, tokenized_lines)
	
	return compiled_script

func compile_lines(compiled_script: CompiledGrogScript, lines: Array) -> void:
	var num_lines = lines.size()
	
	var i = 0
	
	while i < num_lines:
		var current_line = lines[i]
		var line_num = current_line.line_number
		i += 1
		
		# expecting actions like ":pick_up" or ":start"
		
		if not current_line.is_sequence_header:
			# this can only happen at the start of the script
			compiled_script.add_error("Expecting action header (line %s)" % line_num)
			return
		
		# reading sequence header line
		
		var sequence_name: String = current_line.sequence_name
		var params: Array = current_line.params
		
		# TODO telekinetic
		
		if params.size() > 0 and false: # TODO!
			for j in range(params.size()):
				var param = params[j]
				compiled_script.add_error("Sequence '%s': invalid param '%s' (line %s)" % [sequence_name, token_str(param), line_num])
				return
		
		var statements = []
		
		while true:
			var more_statements = i < num_lines and not lines[i].is_sequence_header
			
			if not more_statements:
				break
			
			# reading command line
			
			current_line = lines[i]
			line_num = current_line.line_number
			i += 1
			var subject: String = current_line.subject
			var command: String = current_line.command
			params = current_line.params
			
			if not grog.commands.has(command):
				compiled_script.add_error("Unknown command '%s' (line %s)" % [command, line_num])
				return
			
			var command_requirements = grog.commands[command]
			
			if subject and not command_requirements.has_subject:
				compiled_script.add_error("Command '%s' can't has subject (line %s)" % [command, line_num])
				return
			
			var total = params.size()
			var required = command_requirements.required_params
			var num_required = required.size()
			
			if total < num_required:
				compiled_script.add_error("Command '%s' needs at least %s parameters (line %s)" % [command, num_required, line_num])
				return
			
			var final_params = []
			
			if command_requirements.has_subject:
				final_params.append(subject)
			
			# checks and pushes required parameters and removes them from params list
			for j in range(num_required):
				var param_token = params.pop_front() # removes first param
				
				var param
				
				match required[j]:
					grog.ParameterType.StringType:
						param = param_token.content
					grog.ParameterType.StringTokenType:
						param = param_token
					grog.ParameterType.FloatType:
						var float_str = param_token.content
						if not float_str_is_valid(float_str):
							compiled_script.add_error("Token '%s' is not a valid float parameter (line %s)" % [float_str, line_num])
							return
						param = float(param_token.content)
					_:
						compiled_script.add_error("Grog error: unexpected parameter type %s" % required[j])
						return
				
				final_params.append(param)
			
			var options = {}
			
			var named: Array = command_requirements.named_params
			var num_named = named.size()
			
			for j in range(num_named):
				var named_option: Dictionary = named[j]
				
				var option_name: String = named_option.name
				var option_type = named_option.type
				var is_required: bool = named_option.required
				
				var option_values: Array = extract_option_values(params, option_name)
				
				match option_values.size():
					0:
						if is_required:
							compiled_script.add_error("Command '%s' requires option '%s' (line %s)" % [command, option_name, line_num])
							return

					1:
						var option_raw_value: String = option_values[0]
						var option_value
						match option_type:
							grog.ParameterType.StringType:
								option_value = option_raw_value
							grog.ParameterType.FloatType:
								if not float_str_is_valid(option_raw_value):
									compiled_script.add_error("Option '%s' is not a valid float (line %s)" % [option_raw_value, line_num])
									return
								
								option_value = float(option_raw_value)
								
							grog.ParameterType.BooleanType:
								if option_raw_value.to_lower() == "false":
									option_value = false
								elif option_raw_value.to_lower() == "true":
									option_value = true
								else:
									compiled_script.add_error("Option '%s' is not a valid boolean (line %s)" % [option_raw_value, line_num])
									return
								
							_:
								compiled_script.add_error("Grog error: unexpected option type %s" % option_type)
								return
						
						options[option_name] = option_value
					_:
						compiled_script.add_error("Duplicated option '%s' (line %s)" % [option_name, line_num])
						return
				
			if params.size() > 0:
				for j in range(params.size()):
					var param = params[j]
					compiled_script.add_error("%s: invalid param '%s' (line %s)" % [command, token_str(param), line_num])
					return
			
			# saves array of options parameters
			final_params.append(options)
			
			statements.append({
				command = command,
				params = final_params
			})
		
		compiled_script.add_sequence(sequence_name, statements)
		
	#return compiled_script

func extract_option_values(params: Array, option_name: String) -> Array:
	var ret = []
	for i in range(params.size()):
		var index = i - ret.size()
		var param_token: Dictionary = params[index]
		var param_content: String = param_token.content
		var prefix = option_name + "="
		
		if param_token.type == TOKEN_RAW and param_content.begins_with(prefix) and param_content.length() > prefix.length():
			ret.append(param_content.substr(prefix.length()))
			params.remove(index)
			
	return ret

func identify_lines(compiled_script: CompiledGrogScript, lines: Array) -> void:
	for i in range(lines.size()):
		identify_line(compiled_script, lines[i])

func identify_line(compiled_script: CompiledGrogScript, line: Dictionary) -> void:
	if line.indent_level != 0:
		compiled_script.add_error("Indentation levels not implemented (line %s)" % line.line_number)
		return
	
	var first_token: Dictionary = line.tokens[0]
	
	if first_token.type != TOKEN_RAW:
		compiled_script.add_error("Invalid first token %s (line %s)" % [token_str(first_token), line.line_number])
		return
	
	var first_content: String = first_token.content
	
	if first_content.begins_with(":"):
		# it's a sequence header
		var result = sequence_header_regex().search(first_content)
		if not result:
			compiled_script.add_error("Sequence name '%s' is not valid (line %s)" % [first_content, line.line_number])
			return
		
		# TODO check sequence headers parameters or additional tokens (if any)
		
		line.is_sequence_header = true
		line.sequence_name = result.strings[1]
		
	else:
		# it's a command
		var result = command_regex().search(first_content)
		if not result:
			compiled_script.add_error("Command '%s' is not valid (line %s)" % [first_content, line.line_number])
			
			if first_content.find(".") == -1:
				if grog.commands.has(first_content):
					compiled_script.add_error("Did you mean .%s?" % first_content)
				else:
					compiled_script.add_error("Did you forget the leading dot?")
				
			return
			
		# TODO do a basic check over parameters?
		
		line.is_sequence_header = false
		line.subject = result.strings[1]
		line.command = result.strings[2]
	
	var params: Array = line.tokens
	params.pop_front()
	line.params = params
	
func tokenize_lines(compiled_script: CompiledGrogScript, raw_lines: Array) -> Array:
	var ret = []
	
	for i in range(raw_lines.size()):
		var raw_line = raw_lines[i]
		
		var line = { line_number = i + 1, raw = raw_line }
		
		tokenize(compiled_script, line)
		
		if not compiled_script.is_valid:
			return []
			
		if not line.blank:
			ret.append(line)
	
	return ret

func tokenize(compiled_script: CompiledGrogScript, c_line: Dictionary) -> void:
	var raw_line = c_line.raw
	
	if not contains_pattern(raw_line, line_regex()):
		compiled_script.add_error("Line '%s' is not valid" % c_line.line_number)
		compiled_script.add_error("%s" % raw_line)
		
		return
	
	var indent_level = number_of_leading_tabs(raw_line)
	var line_content = raw_line.substr(indent_level)
	
	var tokens = get_tokens(compiled_script, line_content, c_line.line_number)
	
	if not compiled_script.is_valid:
		# Invalid line
		return
	
	c_line.blank = tokens.size() == 0
	
	if not c_line.blank:
		c_line.indent_level = indent_level
		c_line.tokens = tokens
		

enum TokenizerState {
	WaitingNextToken,
	WaitingSpace,
	ReadingToken,
	ReadingQuotedToken,
	ReadingEscapeSequence
}

# TODO build strings efficiently
func get_tokens(compiled_script: CompiledGrogScript, line: String, line_number: int) -> Array:
	var tokens = []
	
	var current_token: Dictionary
	var state = TokenizerState.WaitingNextToken
	
	for i in range(line.length()):
		var c = line[i]
		
		match state:
			TokenizerState.WaitingNextToken:
				if c == " ":
					pass
				elif c == "\"":
					state = TokenizerState.ReadingQuotedToken
					current_token = { type = TOKEN_QUOTED, content = "" }
				elif c == "#":
					break
				else:
					state = TokenizerState.ReadingToken
					current_token = { type = TOKEN_RAW, content = c }
					
			TokenizerState.ReadingToken:
				if c == " ":
					tokens.append(current_token)
					current_token = {} # actually unnecessary
					state = TokenizerState.WaitingNextToken
				elif c == "\"":
					compiled_script.add_error("Unexpected quote inside token (line %s)" % line_number)
					return []
				elif c == "#":
					compiled_script.add_error("Unexpected '#' inside token (line %s)" % line_number)
					return []
				else:
					current_token.content += c
			
			TokenizerState.ReadingQuotedToken:
				if c == "\"":
					tokens.append(current_token)
					current_token = {} # actually unnecessary
					state = TokenizerState.WaitingSpace
				elif c == "\\":
					state = TokenizerState.ReadingEscapeSequence
				else:
					current_token.content += c
			
			TokenizerState.ReadingEscapeSequence:
				if not c in ["\\", "\""]:
					compiled_script.add_error("Invalid escape sequence (line %s)" % line_number)
					return []
				
				current_token.content += c # escaped character in quote
				state = TokenizerState.ReadingQuotedToken
				
			TokenizerState.WaitingSpace:
				if c == " ":
					state = TokenizerState.WaitingNextToken
				elif c == "#":
					break
				else:
					compiled_script.add_error("Unexpected char '%s' after closing quote (line %s)" % [c, line_number])
					return []
			_:
				push_error("Unexpected state %s" % state)
				return []
		
	match state:
		TokenizerState.ReadingToken:
			tokens.append(current_token)
			current_token = {} # actually unnecessary
		TokenizerState.ReadingQuotedToken, TokenizerState.ReadingEscapeSequence:
			compiled_script.add_error("Unexpected end of line while reading quoted token (line %s)" % line_number)
			return []
		
	return tokens

#####################

func float_str_is_valid(float_str: String) -> bool:
	return contains_pattern(float_str, float_regex())

func token_str(token: Dictionary) -> String:
	match token.type:
		TOKEN_RAW:
			return token.content
		TOKEN_QUOTED:
			return "\"\"\"%s\"\"\"" % token.content
		_:
			push_error("Unexpected type %s" % token.type)
			return token.content

func number_of_leading_tabs(raw_line: String) -> int:
	var ret = 0
	
	for i in range(raw_line.length()):
		var c = raw_line[i]
		
		if c == "\t":
			ret += 1
		else:
			break
		
	return ret

#####################

func contains_pattern(a_string: String, pattern: RegEx) -> bool:
	var result = pattern.search(a_string)
	
	return result != null

func line_regex():
	return regex(line_regex_pattern)

func sequence_header_regex():
	return regex(sequence_header_regex_pattern)

func command_regex():
	return regex(command_regex_pattern)

func float_regex():
	return regex(float_regex_pattern)

func regex(pattern):
	var ret = RegEx.new()
	ret.compile(pattern)
	return ret
