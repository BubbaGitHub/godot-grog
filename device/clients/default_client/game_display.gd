extends Node

signal game_ended

export (NodePath) var room_place_path
export (NodePath) var controls_place_path

export (NodePath) var text_label_path
export (NodePath) var text_label_anchor_path

# debug flags
export (NodePath) var input_enabled_flag_path
export (NodePath) var skippable_flag_path

# Server
var server: GameServer

var _skippable: bool
var _input_enabled: bool

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

var _input_enabled_flag: CheckButton
var _skippable_flag: CheckButton

func _ready():
	_room_place = get_node(room_place_path)
	_controls_place = get_node(controls_place_path)
	
	_text_label = get_node(text_label_path)
	_text_label_anchor = get_node(text_label_anchor_path)
	
	_default_text_position = _text_label_anchor.rect_position
	
	_input_enabled_flag = get_node(input_enabled_flag_path)
	_skippable_flag = get_node(skippable_flag_path)

func init(game_server):
	server = game_server
	
	#warning-ignore:return_value_discarded
	server.connect("game_server_event", self, "on_server_event")
	
	if not server.start_game_request(_room_place):
		_end_game()
	
	# else signal game_started was just received (or it will now)

func _input(event):
	if not server:
		return
	
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT:
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
		elif event.button_index == BUTTON_RIGHT:
			if event.pressed:
				server.skip_request()

func on_server_event(event_name, args):
	var handler_name = "on_" + event_name
	
	if self.has_method(handler_name):
		self.callv(handler_name, args)
	else:
		push_warning("Display has no method '%s'" % handler_name)

#	@SERVER EVENTS

func on_game_started():
	_set_skippable(false)
	_set_input_enabled(false)

func on_game_ended():
	_end_game()

func on_input_enabled():
	_set_input_enabled(true)
	
func on_input_disabled():
	_set_input_enabled(false)

func on_room_loaded(_room):
	pass

func on_actor_loaded(_actor):
	pass

func on_wait_started(_duration: float, skippable: bool):
	# start waiting '_duration' seconds
	
	_hide_controls()
	_set_skippable(skippable)

func on_wait_ended():
	_text_label.clear() # do always?
	if _skippable:
		_set_skippable(false)

func on_say(subject: Node, speech: String, _duration: float, skippable: bool):
	# start waiting '_duration' seconds
	
	if subject:
		var position = subject.get_speech_position() + _room_place.rect_position
		_say_text(speech, subject.color, position)
	else:
		_say_text(speech, server.options.default_color, _default_text_position)
	
	_set_skippable(skippable)

#	@PRIVATE

func _end_game():
	server = null
	_text_label.clear()
	_hide_controls()
	
	emit_signal("game_ended")

func _left_click(position: Vector2):
	if not server.current_room:
		print("No room")
		return
	
	var clicked_item = _get_item_at(position)
	
	if clicked_item:
		server.interact_request(clicked_item, "look")
	else:
		server.go_to_request(position)

func _get_item_at(position: Vector2):
	for item in server.current_room.get_items():
		
		var disp: Vector2 = item.global_position - position
		var distance = disp.length()
		
		if distance <= item.radius:
			return item
	
	return null

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

func _on_quit_button_pressed():
	if server:
		server.stop_request()

#	@DEBUG FLAGS

func _set_skippable(new_value: bool):
	_skippable = new_value
	_skippable_flag.pressed = new_value

func _set_input_enabled(new_value: bool):
	_input_enabled = new_value
	_input_enabled_flag.pressed = new_value
