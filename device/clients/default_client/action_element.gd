extends "res://tools/ui_tools/object_list_element.gd"

export (NodePath) var label_path

var localized_name

func draw_element(_old, new_action: String):
	if new_action:
		var translation_key = "ACTION_" + new_action.replace(" ", "_").to_upper()
		localized_name = capitalize_first(tr(translation_key))
		set_label_text(localized_name)

func capitalize_first(text: String) -> String:
	text[0] = text[0].to_upper()
	return text

func check():
	$check.pressed = true
	
func uncheck():
	$check.pressed = false

func set_label_text(new_text):
	var label = get_label()
	if label:
		label.text = new_text

func get_label():
	return get_node(label_path)
