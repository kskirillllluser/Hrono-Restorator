extends Node2D

func _ready() -> void:
	G.reset_order()
	var term: Terminal = load("res://scenes/terminal.tscn").instantiate()
	add_child(term)
	term.show_order()
