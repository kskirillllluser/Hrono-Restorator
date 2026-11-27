extends Control
class_name ScanNoise

var cards: Array = []
var sweep := -1.0

var _t := 0.0

func _process(delta: float) -> void:
	_t += delta
	if sweep >= 0:
		sweep += delta * 1.3
		if sweep > 1.0:
			sweep = -1.0
	queue_redraw()

func _draw() -> void:
	for y in range(0, 400, 8):
		draw_rect(Rect2(0, y, 544, 2), Color(0, 0, 0, 0.18))
	if sweep >= 0:
		var x := sweep * 560.0 - 16
		draw_rect(Rect2(floorf(x / 4) * 4, 0, 16, 400), Color(G.CYAN_L, 0.35))
		draw_rect(Rect2(floorf(x / 4) * 4 - 24, 0, 24, 400), Color(G.CYAN, 0.12))
	for c in cards:
		if is_instance_valid(c) and c.has_meta("lost"):
			_draw_static(c)

func _draw_static(card: Control) -> void:
	var r := Rect2(card.position + Vector2(10, 36), Vector2(148, 220))
	var seed_v := int(_t * 14)
	for k in 90:
		var h := absi(hash(Vector2i(k, seed_v)))
		@warning_ignore("integer_division")
		var p := r.position + Vector2(float(h % 37) * 4.0, float((h / 37) % 55) * 4.0)
		if r.has_point(p):
			draw_rect(Rect2(p, Vector2(4, 4)), [G.STEEL, G.CREAM, Color("3d4862"), G.TERRA][h % 4] * Color(1, 1, 1, 0.7))
