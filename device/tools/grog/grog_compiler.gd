
class_name GrogCompiler

# Tokenizer patterns
const line_regex_pattern = "^(\\t)*[a-zA-Z0-9\\.\\:\\-\\_\\'\\?\\=\\ \\#\\\"]*$"
const token_char_regex_pattern = "[a-zA-Z0-9\\.\\:\\-\\_]"

# Compiler patterns
const token_regex_pattern = "^\\:?([a-zA-Z0-9\\.\\-\\_\\'\\?\\=\\ \\#]+)$"

const command_regex_pattern = "^([a-zA-Z0-9\\-\\_\\ \\#]*).([a-zA-Z0-9\\-\\_\\ \\#]+)$"

#	@PUBLIC

func compile(script: Resource) -> CompiledGrogScript:
	var code = script.get_code()
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

func compile_lines(compiled_script: CompiledGrogScript, lines: Array):
	var num_lines = lines.size()
	
	var i = 0
	
	while i < num_lines:
		var current_line = lines[i]
		i += 1
		
		# expecting actions like ":pick_up" or ":start"
		
		if not current_line.is_action_header:
			# this can only happen at the start of the script
			compiled_script.add_error("Expecting action header (line %s)" % current_line.line_number)
			return compiled_script
		
		var action_name = current_line.action_name
		
		var statements = []
		
		while true:
			var more_statements = i < num_lines and not lines[i].is_action_header
			
			if not more_statements:
				break
			
			var statement_line = lines[i]
			i += 1
			
			var subject = statement_line.subject
			var command = statement_line.command
			var params = statement_line.tokens.slice(1, statement_line.tokens.size() - 1)
			
			if not grog.commands.has(command):
				compiled_script.add_error("Unknown command '%s' (line %s)" % [command, current_line.line_number])
				return compiled_script
			
			var command_requirements = grog.commands[command]
			
			if subject and not command_requirements.has_subject:
				compiled_script.add_error("Command '%s' can't has subject (line %s)" % [command, current_line.line_number])
				return compiled_script
			
			var total = params.size()
			var required = command_requirements.required_params
			
			if total < required:
				compiled_script.add_error("Command '%s' needs at least %s parameters (line %s)" % [command, required, current_line.line_number])
				return compiled_script
			
			var final_params = []
			
			if command_requirements.has_subject:
				final_params.append(subject)
			
			# saves required parameters
			for _j in range(0, required):
				final_params.append(params.pop_front())
			
			# saves array of optional parameters
			final_params.append(params)
			
			statements.append({
				command = command,
				params = final_params
			})
		
		compiled_script.add_routine(action_name, statements)
		
	#return compiled_script

func identify_lines(compiled_script: CompiledGrogScript, lines: Array) -> void:
	for i in range(lines.size()):
		var line = lines[i]
		
		if line.indent_level != 0:
			compiled_script.add_error("Indentation levels not implemented (line %s)" % line.line_number)
			line.valid = false
		
		for j in range(line.tokens.size()):
			var token = line.tokens[j]
			
			if not token_is_valid(token):
				compiled_script.add_error("Invalid token '%s' (line %s token %s)" % [token, line.line_number, j])
				line.valid = false
			
			else:
				if j == 0:
					var is_action = token[0] == ":"
					
					if is_action:
						line.is_action_header = true
						line.action_name = token.substr(1)
					else:
						line.is_action_header = false
						
						var result = command_regex().search(token)
						
						if not result:
							compiled_script.add_error("Invalid command '%s' (line %s token %s)" % [token, line.line_number, j])
							line.valid = false
						
						line.subject = result.strings[1]
						line.command = result.strings[2]
				
	
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

func tokenize(compiled_script: CompiledGrogScript, c_line: Dictionary) -> void: #Dictionary:
	var raw_line = c_line.raw
	
	if not line_is_valid(raw_line):
		compiled_script.add_error("Line '%s' is not valid" % c_line.line_number)
		compiled_script.add_error("'%s'" % raw_line)
		c_line.valid = false
		return
	
	var indent_level = number_of_leading_tabs(raw_line)
	var line = raw_line.substr(indent_level)
	
	var tokens = get_tokens(compiled_script, line)
	
	if not compiled_script.is_valid:
		# Invalid line
		c_line.valid = false
		return
	
	c_line.valid = true
	c_line.blank = tokens.size() == 0
	
	if not c_line.blank:
		c_line.indent_level = indent_level
		c_line.tokens = tokens
		

	
func get_tokens(compiled_script: CompiledGrogScript, line: String) -> Array: # or null (TODO should be a class)
	var tokens = []
	
	var current_token = ""
	var state = TokenizerState.WaitingNextToken
	
	for i in range(line.length()):
		var c = line[i]
		
		match state:
			TokenizerState.WaitingNextToken:
				if c == " ":
					pass
				elif c == "\"":
					state = TokenizerState.ReadingQuotedToken
					current_token = ""
				elif c == "#":
					break
				elif contains_pattern(c, token_char_regex()):
					state = TokenizerState.ReadingToken
					current_token = c
				else:
					compiled_script.add_error("Unexpected char '%s' waiting next token" % c)
					return []
					
			TokenizerState.ReadingToken:
				if c == " ":
					tokens.append(current_token)
					current_token = ""
					state = TokenizerState.WaitingNextToken
				elif c == "\"":
					compiled_script.add_error("Unexpected quote inside token")
					return []
				elif c == "#":
					compiled_script.add_error("Unexpected '#' inside token")
					return []
				elif c == "=" or contains_pattern(c, token_char_regex()):
					# TODO build string efficiently
					current_token = current_token + c
				else:
					compiled_script.add_error("Unexpected char '%s' reading token" % c)
					return []
			
			TokenizerState.ReadingQuotedToken:
				if c in " #'?=" or contains_pattern(c, token_char_regex()):
					# TODO build string efficiently
					current_token = current_token + c
				elif c == "\"":
					tokens.append(current_token)
					current_token = ""
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

func token_is_valid(token: String) -> bool:
	return contains_pattern(token, token_regex())

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

func token_regex():
	return regex(token_regex_pattern)

func command_regex():
	return regex(command_regex_pattern)

func regex(pattern):
	var ret = RegEx.new()
	ret.compile(pattern)
	return ret
