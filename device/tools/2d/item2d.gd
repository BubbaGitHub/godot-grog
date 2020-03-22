tool

extends "res://tools/grog/item.gd"

export (float) var radius = 50 setget set_radius

func on_teleport(target_pos):
	z_index = int(target_pos.y)

func _draw():
	if Engine.editor_hint:
		draw_arc(Vector2(), radius, 0, 2*PI, 50, Color("#aaffffff"), 2.0)

func set_radius(new_radius):
	radius = new_radius
	update()

func get_speech_position():
	return position_of_child_at("speech_position")
