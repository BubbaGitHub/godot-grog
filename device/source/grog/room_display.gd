extends Node

export (NodePath) var room_place_path
export (NodePath) var controls_place_path

export (NodePath) var text_label_path
export (NodePath) var text_label_anchor_path

# Server
var server

# Input
enum InputState { Nothing, DoingLeftClick }
var input_state = InputState.Nothing
var input_position = null

# Node hooks
var _room_place: Control
var _controls_place: Control

var _text_label: RichTextLabel
var _text_label_anchor: Control

var _default_text_position: Vector2

func _ready():
	_room_place = get_node(room_place_path)
	_controls_place = get_node(controls_place_path)
	
	_text_label = get_node(text_label_path)
	_text_label_anchor = get_node(text_label_anchor_path)
	
	_default_text_position = _text_label_anchor.rect_position

func init(game_server):
	server = game_server
	server.start_game()
	
func _input(event):
	if not server or not server.is_ready():
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
					_left_click(input_position)
				
				input_state = InputState.Nothing

func on_server_event(event_name, args):
	var handler_name = "on_" + event_name
	
	if self.has_method(handler_name):
		self.callv(handler_name, args)
	else:
		push_warning("Display has no method '%s'" % handler_name)

#	@SERVER EVENTS

func on_game_started():
	pass

func on_room_loaded(room):
	if not _room_place:
		return
	
	# TODO do this in server
	make_empty(_room_place)
	_room_place.add_child(room) # room.ready is called here
	
func on_actor_loaded(actor):
	var actor_place = server.current_room.get_player_place()
	
	# TODO do this in server
	make_empty(actor_place)
	server.current_room.add_child(actor)
	actor.transform = actor_place.transform

func on_wait_started(_seconds):
	# start waiting '_seconds' seconds
	
	_hide_controls()

func on_say(subject, speech, _seconds):
	# start waiting '_seconds' seconds
	if subject:
		var position = subject.get_speech_position() + _room_place.rect_position
		_say_text(speech, subject.color, position)
	else:
		_say_text(speech, server.get_default_color(), _default_text_position)
	

func on_set_ready():
	# end waiting
	
	_show_controls()
	_text_label.clear()
	
	
#	@PRIVATE

func _left_click(at_position):
	server.left_click(at_position)
	
func _say_text(speech, color, text_position):
	_hide_controls()
	
	_text_label_anchor.rect_position = text_position
	
	_text_label.clear()
	_text_label.push_color(color)
	_text_label.push_align(RichTextLabel.ALIGN_CENTER)
	_text_label.add_text(speech)
	_text_label.pop()
	_text_label.pop()
	
func _show_controls():
	if _controls_place:
		_controls_place.show()

func _hide_controls():
	if _controls_place:
		_controls_place.hide()

##### Misc

func make_empty(node):
	while node.get_child_count():
		var first_child = node.get_child(0)
		node.remove_child(first_child)
		first_child.queue_free()

