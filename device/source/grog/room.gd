extends Node2D

export (int) var width = 1366
export (int) var height = 768

func start_room():
	var player = $player_position/player
	
	if not player:
		return
	
	var player_anim : AnimationPlayer = player.get_node("animation")
	
	if not player_anim:
		return
	
	var anim_name = "walk_front"
	
	if not player_anim.has_animation(anim_name):
		return
	
	player_anim.play(anim_name)
	
func _ready():
	pass
