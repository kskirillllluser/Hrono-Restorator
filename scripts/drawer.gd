extends Node2D

var cb: Callable

func _draw() -> void:
	if cb.is_valid():
		cb.call(self)
