extends Control
class_name RegulatorDial

@export var index := 0

func _draw() -> void:
	var c := Vector2(48, 52)
	var locked := G.reg_locked(index)
	draw_rect(Rect2(8, 12, 80, 80), Color("0b141a"))
	var angs := [PI * 1.25, PI * 1.5, PI * 1.75]
	for k in 3:
		var a: float = angs[k]
		var p := (c + Vector2(cos(a), sin(a)) * 34 / 1.0).round()
		draw_rect(Rect2(((p / 4).floor() * 4) - Vector2(4, 4), Vector2(8, 8)), Color("3d4862"))
		var nl := str(k)
		var lp := c + Vector2(cos(a), sin(a)) * 50
		draw_string(G.f_retro, lp + Vector2(-5, 6), nl, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, G.INK_SOFT)
	if G.cal_overlay and not locked:
		var ta: float = angs[G.targets()[index]]
		var tp := c + Vector2(cos(ta), sin(ta)) * 34
		draw_rect(Rect2(((tp / 4).floor() * 4) - Vector2(6, 6), Vector2(12, 12)), Color(G.CYAN, 0.45))
	var v: int = G.regs[index] if not locked else 0
	var a2: float = angs[v]
	var col := G.MUSTARD
	if G.last_test.has("reg_ok"):
		col = G.GOOD if G.last_test.reg_ok[index] else G.TERRA
	if locked:
		col = G.CYAN
	for k in 7:
		var q := c + Vector2(cos(a2), sin(a2)) * (k * 4.0)
		draw_rect(Rect2(((q / 4).floor() * 4) - Vector2(2, 2), Vector2(6, 6)), col)
	draw_rect(Rect2(c - Vector2(6, 6), Vector2(12, 12)), Color("9aa8c2"))
	if locked:
		draw_texture_rect(G.icon("anchor"), Rect2(Vector2(56, 60), Vector2(32, 32)), false)
