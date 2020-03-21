"""
	Class: Label
	Node for setting capitalization to label and buttons.
	It can be used in any node with 'text' property.

	Copyright:
	Copyright 2020, jluini
"""
extends Node

"""
	Property: capitalize_first
	If true, the text property will be capitalized (after being translated).
"""
export (bool) var capitalize_first = true

func _ready():
	update()
	
func update():
	if capitalize_first:
		self.text = tr(self.text).capitalize()
