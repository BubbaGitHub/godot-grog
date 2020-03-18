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
					left_click(input_position)
				
				input_state = InputState.Nothing

func on_server_event(event_name, args):
	if self.has_method(event_name):
		self.callv(event_name, args)
	else:
		push_warning("Unknown event '%s'" % event_name)

func start_game(p_server):
	server = p_server

func load_room(room):
	if not _room_place:
		return
	make_empty(_room_place)
	
	_room_place.add_child(room) # room.ready is called here
	
func load_actor(actor):
	var actor_place = server.current_room.get_player_place()
	
	make_empty(actor_place)
	
	server.current_room.add_child(actor)
	actor.transform = actor_place.transform

func start_waiting(_seconds):
	# start waiting '_seconds' seconds
	
	_hide_controls()

func say(subject, speech, _seconds):
	# start waiting '_seconds' seconds
	if subject:
		var position = subject.get_speech_position() + _room_place.rect_position
		say_text(speech, subject.color, position)
	else:
		say_text(speech, server.get_default_color(), _default_text_position)
	

func say_text(speech, color, text_position):
	_hide_controls()
	
	_text_label_anchor.rect_position = text_position
	
	_text_label.clear()
	_text_label.push_color(color)
	_text_label.push_align(RichTextLabel.ALIGN_CENTER)
	_text_label.add_text(speech)
	_text_label.pop()
	_text_label.pop()
	
func ready():
	# end waiting
	
	_show_controls()
	_text_label.clear()
	
	
#	@PRIVATE

func left_click(at_position):
	server.left_click(at_position)
	

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

