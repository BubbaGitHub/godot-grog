extends "res://source/grog/core/item.gd"

func on_teleport(target_pos):
	z_index = int(target_pos.y)
