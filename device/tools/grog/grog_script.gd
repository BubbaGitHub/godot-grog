extends Resource

class_name GrogScript

export (String, MULTILINE) var code_or_filename

func get_code():
	return code_or_filename
