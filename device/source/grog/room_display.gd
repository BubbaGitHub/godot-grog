extends Node

export (NodePath) var room_place_path
export (NodePath) var text_place_path
export (NodePath) var controls_place_path

export (bool) var update_layout = false

# State
var _server
var _current_room: Node2D
var _state = grog.GameState.DoingSomething

# Input
enum InputState { Nothing, DoingLeftClick }
var input_state = InputState.Nothing
var input_position = null

# Node hooks
var _room_place: Control
var _text_place: RichTextLabel
var _controls_place: Control

func _ready():
	_room_place = get_node(room_place_path)
	_text_place = get_node(text_place_path)
	_controls_place = get_node(controls_place_path)
	
	var ret = get_tree().get_root().connect("size_changed", self, "on_viewport_resized")
	if ret:
		push_error("Couldn't connect 'size_changed' in root")

func _input(event):
	if _state != grog.GameState.Idle:
		return
	
	if event is InputEventMouseButton: 
		if event.pressed:
			if input_state == InputState.Nothing:
				input_state = InputState.DoingLeftClick
				input_position = event.position
		else:
			if input_state == InputState.DoingLeftClick:
				# TODO give it some threshold!
				# currently only exact clicks work
				
				if event.position == input_position:
					left_click(input_position)
				
				input_state = InputState.Nothing

func on_server_event(event_name, args):
	if self.has_method(event_name):
		self.callv(event_name, args)
	else:
		push_warning("Unknown event '%s'" % event_name)

func start_game(p_server):
	_server = p_server

func load_room(room):
	make_empty(_room_place)
	
	_current_room = room
	
	_room_place.add_child(room) # room.ready is called here
	
	update_room_layout()
	
func load_actor(actor):
	var actor_place = _current_room.get_player_place()
	
	make_empty(actor_place)
	
	actor_place.add_child(actor) 

func start_waiting(_seconds):
	# start waiting '_seconds' seconds
	_state = grog.GameState.DoingSomething
	
	_hide_controls()

func say(speech, _seconds):
	# start waiting '_seconds' seconds
	_state = grog.GameState.DoingSomething
	
	_hide_controls()
	_text_place.clear()
	_text_place.push_color(Color.red)
	_text_place.push_align(RichTextLabel.ALIGN_CENTER)
	_text_place.add_text(speech)
	_text_place.pop()
	_text_place.pop()
	
func ready():
	# end waiting
	_state = grog.GameState.Idle
	
	_show_controls()

#	@PRIVATE

func left_click(at_position):
	print("Click %s" % at_position)
	
	

func _show_controls():
	if _controls_place:
		_controls_place.show()

func _hide_controls():
	if _controls_place:
		_controls_place.hide()

func update_room_layout():
	var scale = _room_place.rect_size.y / _current_room.height
	
	_current_room.scale = Vector2(scale, scale)
	
	var room_pos = -_current_room.width * scale / 2
	_current_room.position.x = room_pos
	
func on_viewport_resized():
	if not update_layout:
		return
	
	update_room_layout()

##### Misc

func make_empty(node):
	while node.get_child_count():
		var first_child = node.get_child(0)
		node.remove_child(first_child)
		first_child.queue_free()

