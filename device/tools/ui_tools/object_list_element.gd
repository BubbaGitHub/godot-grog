"""
	Class: ObjectListElement
	Element of an ObjectList.

	Copyright:
	Copyright 2020, jluini
"""
extends "view.gd"

signal element_toggled

#	@PRIVATE

func target_changing(_old_target, _new_target):
	draw_element(_old_target, _new_target)

# override me
func draw_element(_old_target, _new_target):
	pass

# override me
func check():
	pass
	
# override me
func uncheck():
	pass
	
func _on_check_toggled(toggle_value):
	emit_signal("element_toggled", self, toggle_value)
