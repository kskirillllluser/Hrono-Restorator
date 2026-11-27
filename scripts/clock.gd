extends Node2D
class_name ClockArtifact


signal module_clicked(id: String)
signal module_hovered(id: String)

const S := 4.0
const SPR_POS := {"gear": Vector2(16, 24), "spring": Vector2(56, 24), "block": Vector2(53, 59), "lid": Vector2(108, 54)}
const SPR_SIZE := {"gear": Vector2(32, 32), "spring": Vector2(24, 24), "block": Vector2(22, 14), "lid": Vector2(42, 50)}
const CENTER := {"gear": Vector2(32, 40), "spring": Vector2(68, 36), "block": Vector2(64, 66), "hands": Vector2(50, 50), "lid": Vector2(129, 79)}
const MODULES := ["gear", "spring", "block", "lid"]

@onready var rig: Node2D = $Rig
@onready var overlay: Node2D = $Rig/Overlay
@onready var spr := {"gear": $Rig/Gear, "spring": $Rig/Spring, "block": $Rig/Block, "lid": $Rig/Lid}

var selected := ""
var hovered := ""
var chain: Array = []
var chain_t := 0.0
var running := false
var jitter := false
var minute := 10.0 * 60 + 10
var flash := {}

var _t := 0.0
var anchors := {}

func _ready() -> void:
	overlay.cb = _draw_overlay
	_setup_hit_zones()
	refresh()

func hit(id: String) -> Button:
	return get_node("Hit" + id.capitalize()) as Button

func _setup_hit_zones() -> void:
	for id in MODULES:
		var b := hit(id)
		b.tooltip_text = G.mname(id)
		b.pressed.connect(func(): module_clicked.emit(id))
		b.mouse_entered.connect(func(): hovered = id; module_hovered.emit(id))
		b.mouse_exited.connect(func(): if hovered == id: hovered = "")

func refresh() -> void:
	var gm: Dictionary = G.m
	spr.gear.texture = G.tex({"ret2": "gear_ok", "analog": "gear_analog"}.get(gm.gear.via, "gear_dusty") if gm.gear.fixed else "gear_dusty")
	spr.spring.texture = G.tex({"ret2": "spring_ok", "manual": "spring_manual", "ret1a": "spring_weak"}.get(gm.spring.via, "spring_displaced") if gm.spring.fixed else "spring_displaced")
	spr.block.texture = G.tex("block_ok" if (G.last_test.get("sync", false) and G.regs_ok()) else "block_mis")
	spr.lid.texture = G.tex({"clean": "lid_clean", "replace": "lid_replaced"}.get(gm.lid.via, "lid_scratched"))
	anchors.clear()
	for id in ["gear", "spring"]:
		if gm[id].anchored:
			anchors[id] = true
	overlay.queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	if running:
		minute += delta * 40.0
	if chain_t > 0:
		chain_t -= delta
		if chain_t <= 0:
			chain.clear()
	overlay.queue_redraw()

func _pline(n: Node2D, a: Vector2, b: Vector2, col: Color, dashed := false) -> void:
	var steps := int(maxf(absf(b.x - a.x), absf(b.y - a.y)))
	for i in steps + 1:
		if dashed and (i + int(_t * 12)) % 4 == 0:
			continue
		var p := a.lerp(b, float(i) / maxf(1, steps)).round()
		n.draw_rect(Rect2(p, Vector2(1, 1)), col)

func _draw_overlay(n: Node2D) -> void:
	_draw_hands(n)
	_draw_lamps(n)
	_draw_chain(n)
	_draw_anchors(n)
	_draw_brackets(n)
	_draw_flashes(n)

func _draw_hands(n: Node2D) -> void:
	var c: Vector2 = CENTER.hands
	var mm := minute
	if jitter:
		mm += sin(_t * 28.0) * 9.0
	var ma := mm / 60.0 * TAU - PI / 2
	var ha := mm / 720.0 * TAU - PI / 2
	_pline(n, c, c + Vector2(cos(ha), sin(ha)) * 17, G.MUSTARD)
	_pline(n, c + Vector2(1, 0), c + Vector2(1, 0) + Vector2(cos(ha), sin(ha)) * 16, Color("c98327"))
	_pline(n, c, c + Vector2(cos(ma), sin(ma)) * 27, Color("ffe4a3"))
	n.draw_rect(Rect2(c - Vector2(2, 2), Vector2(4, 4)), Color("ffe4a3"))
	n.draw_rect(Rect2(c - Vector2(1, 1), Vector2(2, 2)), Color("8a5418"))

func _draw_lamps(n: Node2D) -> void:
	var lt: Dictionary = G.last_test
	for i in 3:
		var col := Color("3d4862")
		if lt.has("reg_ok"):
			col = G.GOOD if lt.reg_ok[i] else G.BAD
		n.draw_rect(Rect2(SPR_POS.block + Vector2(4 + i * 6, 1), Vector2(3, 1)), col)

func _draw_chain(n: Node2D) -> void:
	var pts := {"gear": CENTER.gear, "spring": CENTER.spring, "block": CENTER.block, "hands": CENTER.hands}
	for seg in chain:
		_pline(n, pts[seg[0]], pts[seg[1]], seg[2], true)
		n.draw_rect(Rect2(pts[seg[1]] - Vector2(2, 2), Vector2(5, 5)), seg[2])

func _draw_anchors(n: Node2D) -> void:
	for id in anchors:
		var p: Vector2 = SPR_POS[id] + Vector2(SPR_SIZE[id].x - 8, -4)
		n.draw_texture(G.icon("anchor"), p)

func _draw_brackets(n: Node2D) -> void:
	for id in [selected, hovered]:
		if id == "" or not SPR_POS.has(id):
			continue
		var r := Rect2(SPR_POS[id] - Vector2(3, 3), SPR_SIZE[id] + Vector2(6, 6))
		var col := G.CYAN if id == selected else Color(G.CYAN_L, 0.6)
		var L := 4.0
		var blink: bool = id != selected or int(_t * 3) % 2 == 0
		if not blink:
			col = G.CYAN_L
		for corner in [r.position, Vector2(r.end.x - 1, r.position.y), Vector2(r.position.x, r.end.y - 1), r.end - Vector2.ONE]:
			var sx := 1.0 if corner.x < r.get_center().x else -1.0
			var sy := 1.0 if corner.y < r.get_center().y else -1.0
			n.draw_rect(Rect2(Vector2(minf(corner.x, corner.x + sx * L), corner.y), Vector2(L, 1)), col)
			n.draw_rect(Rect2(Vector2(corner.x, minf(corner.y, corner.y + sy * L)), Vector2(1, L)), col)

func _draw_flashes(n: Node2D) -> void:
	for id in flash.keys():
		var k: float = flash[id]
		if k > 0:
			var r2 := Rect2(SPR_POS[id], SPR_SIZE[id])
			n.draw_rect(r2, Color(G.CYAN_L, 0.35 * k))

func play_chrono(id: String, ghost_tex: String) -> void:
	Sfx.play("chrono", -2)
	var g := Sprite2D.new()
	g.texture = G.tex(ghost_tex)
	g.centered = false
	g.position = SPR_POS[id] + Vector2(-10, -14)
	g.modulate = Color(0.7, 1.4, 1.4, 0.0)
	rig.add_child(g)
	var tw := create_tween()
	tw.tween_property(g, "modulate:a", 0.85, 0.35)
	tw.tween_property(g, "position", SPR_POS[id], 0.55).set_trans(Tween.TRANS_SINE)
	for k in 4:
		tw.tween_property(g, "modulate:a", 0.2, 0.05)
		tw.tween_property(g, "modulate:a", 0.9, 0.05)
	await tw.finished
	flash[id] = 1.0
	refresh()
	g.queue_free()
	var t2 := create_tween()
	t2.tween_method(func(x): flash[id] = x, 1.0, 0.0, 0.5)
	await t2.finished
	flash.erase(id)

func set_chain(segs: Array, dur := 5.0) -> void:
	chain = segs
	chain_t = dur

func shake(power := 6.0) -> void:
	var tw := create_tween()
	for k in 8:
		tw.tween_property(self, "position", position + Vector2(randf_range(-power, power), randf_range(-power / 2, power / 2)).round(), 0.04)
	tw.tween_property(self, "position", position, 0.05)

func global_center(id: String) -> Vector2:
	return to_global(CENTER[id] * S)
