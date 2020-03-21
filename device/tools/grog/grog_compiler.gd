
class_name GrogCompiler

# Tokenizer patterns
const line_regex_pattern = "^(\\t)*[a-zA-Z0-9\\.\\:\\-\\_\\'\\?\\=\\ \\#\\\"]*$"
const token_char_regex_pattern = "[a-zA-Z0-9\\.\\:\\-\\_]"

# Compiler patterns
const routine_header_regex_pattern = "^\\:([a-zA-Z0-9\\.\\-\\_\\ \\#]+)$"

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
		i += 1
		
		# expecting actions like ":pick_up" or ":start"
		
		if not current_line.is_routine_header:
			# this can only happen at the start of the script
			compiled_script.add_error("Expecting action header (line %s)" % current_line.line_number)
			return
		
		# reading routine header line
		
		var routine_name = current_line.routine_name
		
		var statements = []
		
		while true:
			var more_statements = i < num_lines and not lines[i].is_routine_header
			
			if not more_statements:
				break
			
			# reading command line
			
			current_line = lines[i]
			i += 1
			
			var subject: String = current_line.subject
			var command: String = current_line.command
			var params: Array = current_line.params
			
			if not grog.commands.has(command):
				compiled_script.add_error("Unknown command '%s' (line %s)" % [command, current_line.line_number])
				return
			
			var command_requirements = grog.commands[command]
			
			if subject and not command_requirements.has_subject:
				compiled_script.add_error("Command '%s' can't has subject (line %s)" % [command, current_line.line_number])
				return
			
			var total = params.size()
			var required = command_requirements.required_params
			var num_required = required.size()
			
			if total < num_required:
				compiled_script.add_error("Command '%s' needs at least %s parameters (line %s)" % [command, num_required, current_line.line_number])
				return
			
			var final_params = []
			
			if command_requirements.has_subject:
				final_params.append(subject)
			
			# checks and pushes required parameters and removes them rom params list
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
							compiled_script.add_error("Token '%s' is not a valid float parameter (line %s)" % [float_str, current_line.line_number])
							return
						param = float(param_token.content)
					_:
						compiled_script.add_error("Grog error: unexpected parameter type")
						return 
				
				final_params.append(param)
			
			# saves array of optional parameters
			var optional_params = []
			for j in range(params.size()):
				optional_params.append(params[j])
			final_params.append(optional_params)
			
			statements.append({
				command = command,
				params = final_params
			})
		
		compiled_script.add_routine(routine_name, statements)
		
	#return compiled_script

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
		# it's a routine header
		var result = routine_header_regex().search(first_content)
		if not result:
			compiled_script.add_error("Routine name '%s' is not valid (line %s)" % [first_content, line.line_number])
			return
		
		# TODO check routine headers parameters or additional tokens (if any)
		
		line.is_routine_header = true
		line.routine_name = result.strings[1]
		
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
		
		var params: Array = line.tokens
		params.pop_front()
		
		line.is_routine_header = false
		line.subject = result.strings[1]
		line.command = result.strings[2]
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

enum TokenizerState { WaitingNextToken, WaitingSpace, ReadingToken, ReadingQuotedToken }

func tokenize(compiled_script: CompiledGrogScript, c_line: Dictionary) -> void:
	var raw_line = c_line.raw
	
	if not line_is_valid(raw_line):
		compiled_script.add_error("Line '%s' is not valid" % c_line.line_number)
		compiled_script.add_error("%s" % raw_line)
		
		return
	
	var indent_level = number_of_leading_tabs(raw_line)
	var line_content = raw_line.substr(indent_level)
	
	var tokens = get_tokens(compiled_script, line_content)
	
	if not compiled_script.is_valid:
		# Invalid line
		return
	
	c_line.blank = tokens.size() == 0
	
	if not c_line.blank:
		c_line.indent_level = indent_level
		c_line.tokens = tokens
		
	
func get_tokens(compiled_script: CompiledGrogScript, line: String) -> Array:
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
				elif contains_pattern(c, token_char_regex()):
					state = TokenizerState.ReadingToken
					current_token = { type = TOKEN_RAW, content = c }
				else:
					compiled_script.add_error("Unexpected char '%s' waiting next token" % c)
					return []
					
			TokenizerState.ReadingToken:
				if c == " ":
					tokens.append(current_token)
					current_token = {} # actually unnecessary
					state = TokenizerState.WaitingNextToken
				elif c == "\"":
					compiled_script.add_error("Unexpected quote inside token")
					return []
				elif c == "#":
					compiled_script.add_error("Unexpected '#' inside token")
					return []
				elif c == "=" or contains_pattern(c, token_char_regex()):
					# TODO build string efficiently
					current_token.content += c
				else:
					compiled_script.add_error("Unexpected char '%s' reading token" % c)
					return []
			
			TokenizerState.ReadingQuotedToken:
				if c in " #'?=" or contains_pattern(c, token_char_regex()):
					# TODO build string efficiently
					current_token.content += c
				elif c == "\"":
					tokens.append(current_token)
					current_token = {} # actually unnecessary
					state = TokenizerState.WaitingSpace
				else:
					compiled_script.add_error("Unexpected char '%s' reading quoted token" % c)
					return []
			
			TokenizerState.WaitingSpace:
				if c == " ":
					state = TokenizerState.WaitingNextToken
				elif c == "#":
					break
				else:
					compiled_script.add_error("Unexpected char '%s' after closing quote" % c)
					return []
			_:
				push_error("Unexpected state %s" % state)
				return []
		
	match state:
		TokenizerState.ReadingToken:
			tokens.append(current_token)
			current_token = {} # actually unnecessary
		TokenizerState.ReadingQuotedToken:
			compiled_script.add_error("Unexpected end of line while reading quoted token")
			return []
		
	return tokens

#####################

func line_is_valid(raw_line: String) -> bool:
	var ret = contains_pattern(raw_line, line_regex())
	if not ret:
		return false
	
	return true

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

func token_char_regex():
	return regex(token_char_regex_pattern)
	
func line_regex():
	return regex(line_regex_pattern)

func routine_header_regex():
	return regex(routine_header_regex_pattern)

func command_regex():
	return regex(command_regex_pattern)

func float_regex():
	return regex(float_regex_pattern)

func regex(pattern):
	var ret = RegEx.new()
	ret.compile(pattern)
	return ret
