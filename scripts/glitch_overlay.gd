extends Control
class_name GlitchOverlay

const SCAN_RECT := Rect2(40, 160, 544, 400)

var _time := 0.0
var _left := 0.0

func _process(delta: float) -> void:
	_time += delta
	if _left > 0:
		_left -= delta
		queue_redraw()

func flash(duration := 1.6) -> void:
	_left = duration

func _draw() -> void:
	if _left <= 0:
		return
	var seed_v := int(_time * 20)
	for k in 26:
		var h := absi(hash(Vector2i(k, seed_v)))
		var y := float(h % 270) * 4.0
		@warning_ignore("integer_division")
		var w := float(40 + (h / 270) % 400)
		@warning_ignore("integer_division")
		var x := float((h / 7) % 1900)
		draw_rect(Rect2(x, y, w, 4 + (h % 3) * 4), [Color(G.CYAN, 0.45), Color(G.TERRA, 0.4), Color(1, 1, 1, 0.25)][h % 3])
	draw_rect(SCAN_RECT, Color(G.TERRA, 0.12 * _left))
