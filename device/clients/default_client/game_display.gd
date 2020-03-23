extends Node

signal game_ended

export (Resource) var action_button_model

export (NodePath) var actions_path
export (NodePath) var action_display_path

export (NodePath) var room_area_path
export (NodePath) var room_place_path
export (NodePath) var controls_place_path

export (NodePath) var text_label_path
export (NodePath) var text_label_anchor_path

# debug flags
export (NodePath) var input_enabled_flag_path
export (NodePath) var skippable_flag_path

# Server
var server: GameServer
var data: GameResource

var _skippable: bool
var _input_enabled: bool

# Input
enum InputState { Nothing, DoingLeftClick }
var input_state = InputState.Nothing
var input_position: Vector2

var current_action = null
var default_action: Node

# Node hooks
onready var _actions: Control = get_node(actions_path)
onready var _action_display: Control = get_node(action_display_path)

onready var _room_area: Control = get_node(room_area_path)
onready var _room_place: Control = get_node(room_place_path)
onready var _controls_place: Control = get_node(controls_place_path)

onready var _text_label: RichTextLabel = get_node(text_label_path)
onready var _text_label_anchor: Control = get_node(text_label_anchor_path)

onready var _default_text_position: Vector2 = _text_label_anchor.rect_position

onready var _input_enabled_flag: CheckButton = get_node(input_enabled_flag_path)
onready var _skippable_flag: CheckButton = get_node(skippable_flag_path)

func _ready():
	#warning-ignore:return_value_discarded
	_actions.connect("on_element_selected", self, "_on_action_selected")
	#warning-ignore:return_value_discarded
	_actions.connect("on_element_deselected", self, "_on_action_deselected")

func init(p_game_server: GameServer):
	server = p_game_server
	data = server.data
	
	default_action = _actions.element_view_model.instance()
	default_action.set_target(data.default_action)
		
	_hide_controls()
	
	make_empty(_actions)
	
	for action_name in data.actions:
		_actions.add_element(action_name)
	
	#warning-ignore:return_value_discarded
	server.connect("game_server_event", self, "on_server_event")
	
	if not server.start_game_request(_room_place):
		_end_game()
	
	# else signal game_started was just received (or it will now)

func _input(event):
	if not server:
		return
	
	if event is InputEventMouseButton:
		var mouse_position: Vector2 = event.position
		if not rect_includes_point(_room_area.get_global_rect(), mouse_position):
			return
			
		if event.button_index == BUTTON_LEFT:
			if event.pressed:
				if input_state == InputState.Nothing:
					input_state = InputState.DoingLeftClick
					input_position = mouse_position
			else:
				if input_state == InputState.DoingLeftClick:
					if mouse_position.is_equal_approx(input_position):
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
	_hide_all()
	_set_current_action(default_action)

func on_game_ended():
	_end_game()

func on_input_enabled():
	_set_input_enabled(true)
	_show_controls()
	
func on_input_disabled():
	_set_input_enabled(false)
	_hide_controls()

func on_room_loaded(_room):
	pass

func on_actor_loaded(_actor):
	pass

func on_wait_started(_duration: float, skippable: bool):
	# start waiting '_duration' seconds
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
	_hide_all()
	_actions.deselect()
	default_action.queue_free()
	emit_signal("game_ended")

func _hide_all():
	_set_skippable(false)
	_set_input_enabled(false)
	_text_label.clear()
	_hide_controls()
	_action_display.text = ""

func _left_click(position: Vector2):
	if not server.current_room:
		print("No room")
		return
	
	var clicked_item = _get_item_at(position)
	
	if clicked_item:
		server.interact_request(clicked_item, current_action.target)
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

func _on_action_selected(_old_action, new_action: Node):
	_set_current_action(new_action)
	

func _on_action_deselected(_old_view):
	_set_current_action(default_action)

func _set_current_action(new_action):
	current_action = new_action
	#var translation_key = "ACTION_" + new_action.replace(" ", "_").to_upper()
	#var caption = tr(translation_key).capitalize()
	_action_display.text = new_action.localized_name

# Misc

func make_empty(node: Node):
	while node.get_child_count() > 0:
		var child = node.get_child(0)
		node.remove_child(child)
		child.queue_free()

func rect_includes_point(rect: Rect2, point: Vector2) -> bool:
	var eq_x = point.x >= rect.position.x and point.x <= rect.end.x
	var eq_y = point.y >= rect.position.y and point.y <= rect.end.y
	
	var eq = eq_x and eq_y
	
	return eq
