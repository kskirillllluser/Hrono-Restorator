extends Control

func _draw() -> void:
	for y in range(0, int(size.y), 8):
		draw_rect(Rect2(0, y, size.x, 2), Color(0, 0, 0, 0.16))
