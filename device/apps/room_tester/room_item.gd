"""
	Class: RoomItem
	Node for showing SceneResource's.

	Copyright:
	Copyright 2020, jluini
"""
extends "res://source/ui_tools/object_item.gd"

func get_label():
	return $room_name/Label

#signal room_item_toggled
#
##	@PRIVATE
#
#func target_changing(_old_target, _new_target):
#	if _new_target:
#		$room_name/Label.text = _new_target.room_name
#
#
#func check():
#	$check.pressed = true
#
#
#func uncheck():
#	$check.pressed = false
#
#func _on_check_toggled(toggle_value):
#	emit_signal("room_item_toggled", self, toggle_value)
