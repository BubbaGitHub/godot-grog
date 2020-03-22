extends Node2D

export (String) var global_id
export (Color) var color

export (NodePath) var speech_position_path

export (float) var walk_speed = 300 # pixels per second

#warning-ignore:unused_signal
signal start_walking
#warning-ignore:unused_signal
signal stop_walking

##############################

func _ready():
	add_to_group("item")

func is_ready():
	# TODO implement or remove
	return true

##############################

func is_active():
	# TODO
	return true
	
##############################

func teleport(target_pos):
	position = target_pos
	on_teleport(target_pos)

# abstract method
func on_teleport(_target_pos):
	pass

func get_speech_position():
	if speech_position_path and has_node(speech_position_path):
		return position + get_node(speech_position_path).position
	else:
		return position
