extends Node

var compiler

# Called when the node enters the scene tree for the first time.
func _ready():
	compiler = GrogCompiler.new()
	test_tokenize()
	
func check_action(action_string):
	var regex = RegEx.new()
	regex.compile("^\\:?([a-zA-Z0-9\\.\\-\\_\\ \\#]+)$")
	
	var result = regex.search(action_string)
	var r = ""

	if result == null:
		r = "NOT"
	else:
		r = "YEP"
	
	print("%s -> %s" % [action_string, r])
	
func test_tokenize():
	
	test_compile("empty line",
		"",
		true,
		null
	)
	test_compile("just tabs",
		"\t\t",
		true,
		null
	)
	test_compile("tabs mixed with spaces",
		"\t \t",
		false
	)
	test_compile("unclosed quote",
		"tok\"en1",
		false
	)
	test_compile("unclosed quote in comments is valid",
		"token1 \"token 2\" # \" unclosed quote",
		true,
		{ indent_level = 0, tokens = ["token1", "token 2"] }
	)
	test_compile("misplaced quote",
		"token1   \"token 2\"token3  ",
		false
	)
	test_compile("valid line",
		"token1   \"token 2\" token3 ",
		true,
		{ indent_level = 0, tokens = ["token1", "token 2", "token3"] }
	)
	test_compile("indented line",
		"\t\ttoken1   \"token 2\" token3 ",
		true,
		{ indent_level = 2, tokens = ["token1", "token 2", "token3"] }
	)
	test_compile("tokens with dots",
		"\t\t\ttoke.n1   \"..token 2..\" token3.  ",
		true,
		{ indent_level = 3, tokens = ["toke.n1", "..token 2..", "token3."] }
	)
	test_compile("just comment",
		"# this is a comment",
		true,
		null
	)
	test_compile("tabs spaces and comment",
		"\t\t  # this is a comment",
		true,
		null
	)
	test_compile("token and comment",
		"token  # this is a comment",
		true,
		{ indent_level = 0, tokens = ["token"]}
	)
	test_compile("comment after quote",
		"\"token\"# this is a comment",
		true,
		{ indent_level = 0, tokens = ["token"]}
	)
	test_compile("hash inside quote",
		"\"#tok#en#\"   # token with a hash symbol",
		true,
		{ indent_level = 0, tokens = ["#tok#en#"]}
	)
	
	get_tree().quit()

	
func test_compile(test_name, raw_line, expected_valid, expected_result = null):
	print()
	print("Testing '%s':" % test_name)
	
	var ret = true
	
	var compiled_script = CompiledGrogScript.new()
	var c_line = { line_number = 1, raw = raw_line }
	
	grog_server.get_compiler().tokenize(compiled_script, c_line)
	
	var actual_valid = c_line.valid
	
	var valid_equals = test_equal(expected_valid, actual_valid, "Validness")
	
	ret = valid_equals
	
	if expected_valid and actual_valid:
		var actual_blank = c_line.blank
		var expected_blank = expected_result == null
		
		var blankness_equals = test_equal(expected_blank, actual_blank, "Blankness")
		
		ret = ret and blankness_equals
		
		if actual_blank and c_line.has("tokens") and c_line.tokens.size():
			push_error("Result is blank but has tokens!")
			return false
		
		if not expected_blank and not actual_blank:
			var actual_indent_level = c_line.indent_level
			var expected_indent_level = expected_result.indent_level
			
			var indent_equals = test_equal(expected_indent_level, actual_indent_level, "Indent level")
			
			ret = ret and indent_equals
			
			var token_number_equals = test_equal(expected_result.tokens.size(), c_line.tokens.size(), "Token number")
			
			ret = ret and token_number_equals
			
			if token_number_equals:
				for i in range(expected_result.tokens.size()):
					var expected = expected_result.tokens[i]
					var actual = c_line.tokens[i]
					
					ret = ret and test_equal(expected, actual, "Token %s" % i)
	
	if ret:
		print("OK")
	
	return ret

func test_equal(expected, actual, concept):
	if expected != actual:
		print ("%s mismatch (%s != %s)" % [concept, actual, expected])
		return false
	return true
	
