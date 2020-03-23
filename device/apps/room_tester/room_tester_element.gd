extends "res://tools/ui_tools/object_list_element.gd"

export (NodePath) var label_path

func draw_element(_old, _new):
	if _new:
		set_label_text(_new.get_name())

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
