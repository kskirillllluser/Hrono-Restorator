extends Node

func _ready() -> void:
	G.auto = true
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
