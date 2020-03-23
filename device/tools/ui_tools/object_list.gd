"""
	Class: ObjectList
	Lists elements and manages selections.

	Copyright:
	Copyright 2020, jluini
"""
extends Control

signal on_element_selected
signal on_element_deselected


export (Resource) var element_view_model

export (NodePath) var list_path

var _element_views = []
onready var _list = get_node(list_path)

var _current_selected_view = null


#	@PUBLIC

func get_current():
	return _current_selected_view.target if _current_selected_view else null

func add_element(target) -> void:
	if not element_view_model:
		print("No element_model")
		return
	
	if not _list:
		print("No _list")
		return
	
	var element_view = element_view_model.instance()
	
	element_view.set_target(target)
	
	element_view.connect("element_toggled", self, "on_element_toggled")
	
	_list.add_child(element_view)
	_element_views.append(element_view)

# Selects the first element (if any)
func select_first():
	if _element_views.size() == 0:
		return
	
	var some_element_view = _element_views[0]
	some_element_view.check()

# Deselects the selected element (if any)
func deselect():
	if not _current_selected_view:
		return
	
	_current_selected_view.uncheck()
	emit_signal("on_element_deselected", _current_selected_view)
	_current_selected_view = null

#	@PRIVATE

func on_element_toggled(element_view, value):
	if not element_view:
		push_error("No element_view")
		return
	
	if value:
		if _current_selected_view:
			if element_view == _current_selected_view:
				push_warning("Element '%s' already selected" % element_view.target.get_name())
				return
			
			# TODO send deselected signal? currently is single selection
			_current_selected_view.uncheck()
		
		# TODO send target objects instead of views?
		emit_signal("on_element_selected", _current_selected_view, element_view)
		
		_current_selected_view = element_view
	
	else:
		if not _current_selected_view or _current_selected_view != element_view:
			push_error("Unselected a non-selected element")
			return
		
		emit_signal("on_element_deselected", element_view)
		
		_current_selected_view = null
