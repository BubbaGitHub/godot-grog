"""
	Class: ObjectList
	Lists items and selection.

	Copyright:
	Copyright 2020, jluini
"""
extends Control

export (Resource) var item_model

export (NodePath) var list_path

var _items = []
onready var _list = get_node(list_path)

var _current_selected = null


#	@PUBLIC

func get_current():
	return _current_selected.target

func add_item(target: Resource) -> void:
	if not item_model:
		print("No item_model")
		return
	
	if not _list:
		print("No _list")
		return
	
	var item = item_model.instance()
	
	item.set_target(target)
	
	item.connect("item_toggled", self, "on_item_toggled")
	
	_list.add_child(item)
	_items.append(item)

func select_anyone():
	if _items.size() == 0:
		return
	
	var some_item = _items[0]
	some_item.check()

#	@PRIVATE

func on_item_toggled(item_view, value):
	if not item_view:
		push_error("No item_view")
		return
	
	if value:
		if _current_selected:
			if item_view == _current_selected:
				push_warning("Item '%s' already selected" % item_view.target.get_name())
				return
			
			_current_selected.uncheck()
		
		# emit on_item_selected (_current_selected, item_view)
		
		_current_selected = item_view
	
	else:
		if not _current_selected or _current_selected != item_view:
			push_error("Unselected a non-selected item")
			return
		
		# emit on_item_deselected (item_view)
		
		_current_selected = null
