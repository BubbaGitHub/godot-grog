extends Node

# Each direction ends in one angle.
# The angles must be positive and increasing.
# 0.0 is facing right, 90.0 front, etc...
export (Array, Dictionary) var config = [
	{
		value = 45.0,
		idle = "idle_right",
		walk = "walk_left.flip_h"
	},
	{
		value = 135.0,
		idle = "idle_front",
		walk = "walk_front"
	},
	{
		value = 225.0,
		idle = "idle_left",
		walk = "walk_left"
	},
	{
		value = 315.0,
		idle = "idle_up",
		walk = "walk_up"
	},
]

export (NodePath) var animation_path
export (NodePath) var sprite_path

# Expected to be AnimationPlayer. We use play(String).
onready var _animation = get_node(animation_path)

# Expected to be Sprite or AnimatedSprite. We use flip_h and flip_v properties.
onready var _sprite = get_node(sprite_path)

var last_direction = null

func _on_start_walking(direction: Vector2):
	var deg_angle = get_degrees(direction)
	
	var index = get_range_index(deg_angle, config)
	var key = config[index].walk
	
	play_animation(key)
	
	last_direction = direction

func _on_stop_walking():
	var key: String = config.back().idle
	
	if last_direction:
		var deg_angle = get_degrees(last_direction)
		
		var index = get_range_index(deg_angle, config)
		key = config[index].idle
	
	play_animation(key)
	
func play_animation(key):
	var keys: Array = key.split(".", false)
	var animation_name = keys.pop_front()

	_sprite.flip_h = keys.has("flip_h")
	_sprite.flip_v = keys.has("flip_v")

	_animation.play(animation_name)
	
# Misc

# Returns angle in degrees between 0 and 360
func get_degrees(direction: Vector2) -> float:
	var radians_angle = direction.angle()
	
	var deg_angle = radians_angle * 180.0 / PI
	
	if deg_angle < 0:
		deg_angle += 360.0
	
	return deg_angle

# Return the index of the first element greater than the reference value, or 0
func get_range_index(value, cut_values: Array) -> int:
	for i in range(cut_values.size()):
		if value < cut_values[i].value:
			return i
	
	return 0
