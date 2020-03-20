"""
	Class: ObjectItem
	Item of an ObjectList.

	Copyright:
	Copyright 2020, jluini
"""
extends "res://source/view.gd"

signal item_toggled

export (NodePath) var label_path

#	@PRIVATE

func target_changing(_old_target, _new_target):
	if _new_target:
		set_label_text(_new_target.get_name())

func set_label_text(new_text):
	var label = get_label()
	if label:
		label.text = new_text

func get_label():
	return get_node(label_path)

func check():
	$check.pressed = true
	

func uncheck():
	$check.pressed = false
	
func _on_check_toggled(toggle_value):
	emit_signal("item_toggled", self, toggle_value)
