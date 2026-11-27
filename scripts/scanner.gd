extends Control
class_name Scanner

signal scanned(id: String)
signal slice_picked(id: String, age: int)

@onready var head: Label = $Head
@onready var body: Control = $Body
@onready var noise: ScanNoise = $Noise

var mod := ""
var cards: Array[Button] = []
var scan_btn: Button
var status: Label

func _ready() -> void:
	noise.cards = cards
	UI.style(head, 18, G.CYAN, G.f_retro)
	show_idle()

func _clear() -> void:
	for c in body.get_children():
		c.queue_free()
	cards.clear()
	scan_btn = null
	status = null

func card_for_age(age: int) -> Button:
	for i in 3:
		if G.MODS[mod].slices[i].age == age:
			return cards[i]
	return null

func do_scan() -> void:
	if mod == "":
		return
	Sfx.play("scan", -4)
	noise.sweep = 0.0
	if scan_btn:
		scan_btn.disabled = true
	await get_tree().create_timer(0.8).timeout
	G.m[mod].scanned = true
	scanned.emit(mod)
	show_module(mod)

func say(text: String, col := G.CYAN_L) -> void:
	if status:
		status.text = text
		status.add_theme_color_override("font_color", col)

func show_idle() -> void:
	mod = ""
	_clear()
	head.text = "ХРОНОСКАНЕР"
	var t := UI.label("Выберите деталь\nна верстаке", 30, Color(G.CYAN, 0.8), G.f_ui_b, HORIZONTAL_ALIGNMENT_CENTER)
	t.position = Vector2(0, 150)
	t.size = Vector2(544, 90)
	body.add_child(t)
	var s := UI.label("скан и диагностика — бесплатно", 20, Color(G.INK_SOFT, 0.9), G.f_ui, HORIZONTAL_ALIGNMENT_CENTER)
	s.position = Vector2(0, 250)
	s.size = Vector2(544, 30)
	body.add_child(s)

func show_module(id: String) -> void:
	mod = id
	_clear()
	head.text = "ХРОНОСКАНЕР · " + G.mname(id).to_upper()
	var st: Dictionary = G.m[id]
	if not st.scanned:
		_build_scan_prompt()
	else:
		_build_slice_cards(id, st)

func _build_scan_prompt() -> void:
	var t := UI.label("Сигнал детали принят.\nСрезы прошлого ещё не прочитаны.", 24, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_CENTER)
	t.position = Vector2(0, 110)
	t.size = Vector2(544, 80)
	body.add_child(t)
	scan_btn = UI.button("Сканировать  ·  бесплатно", "teal", 26, "scan")
	scan_btn.position = Vector2(112, 230)
	scan_btn.custom_minimum_size = Vector2(320, 68)
	scan_btn.pressed.connect(func(): do_scan())
	body.add_child(scan_btn)

func _build_slice_cards(id: String, st: Dictionary) -> void:
	var slices: Array = G.MODS[id].slices
	for i in 3:
		var b := _make_slice_card(id, st, slices[i])
		body.add_child(b)
		cards.append(b)
	_build_status(id, st)

func _make_slice_card(id: String, st: Dictionary, sl: Dictionary) -> Button:
	var b := Button.new()
	b.position = Vector2(12 + (cards.size()) * 176, 44)
	b.size = Vector2(168, 270)
	var lost: bool = sl.age in st.lost
	var is_cause: bool = st.diag and sl.age == G.MODS[id].cause
	var border := G.MUSTARD if is_cause else G.CYAN if not lost else G.STEEL
	b.add_theme_stylebox_override("normal", UI.sb(Color("0c1d24"), 8, 0, 3 if not is_cause else 6, Color(border, 0.8), 8))
	b.add_theme_stylebox_override("hover", UI.sb(Color("12303a"), 8, 0, 6, G.CYAN_L, 8))
	b.add_theme_stylebox_override("pressed", UI.sb(Color("12303a"), 8, 0, 6, G.MUSTARD, 8))
	b.add_theme_stylebox_override("disabled", UI.sb(Color("0c1d24"), 8, 0, 3 if not is_cause else 6, Color(border, 0.8), 8))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.disabled = st.diag or lost
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var age_l := UI.label(G.AGE_NAME[sl.age], 18, border if not lost else G.STEEL, G.f_retro, HORIZONTAL_ALIGNMENT_CENTER)
	age_l.position = Vector2(0, 8)
	age_l.size = Vector2(168, 24)
	b.add_child(age_l)
	if lost:
		_add_lost_label(b)
		b.set_meta("lost", true)
	else:
		_add_slice_preview(b, sl)
	var age: int = sl.age
	b.pressed.connect(func(): slice_picked.emit(id, age))
	return b

func _add_lost_label(b: Button) -> void:
	var ll := UI.label("СРЕЗ\nПОТЕРЯН", 16, G.TERRA, G.f_retro, HORIZONTAL_ALIGNMENT_CENTER)
	ll.position = Vector2(0, 100)
	ll.size = Vector2(168, 60)
	b.add_child(ll)

func _add_slice_preview(b: Button, sl: Dictionary) -> void:
	var img := TextureRect.new()
	img.texture = G.tex(sl.spr)
	var tsz: Vector2 = img.texture.get_size()
	var k := floorf(minf(118.0 / tsz.x, 118.0 / tsz.y))
	img.size = tsz * k
	img.position = Vector2((168 - img.size.x) / 2, 38 + (118 - img.size.y) / 2).round()
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(img)
	var cap := UI.label(sl.text, 15, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_CENTER, true)
	cap.position = Vector2(6, 160)
	cap.size = Vector2(156, 104)
	b.add_child(cap)

func _build_status(id: String, st: Dictionary) -> void:
	status = UI.label("", 20, G.CREAM, G.f_ui_b, HORIZONTAL_ALIGNMENT_CENTER, true)
	status.position = Vector2(10, 322)
	status.size = Vector2(524, 70)
	body.add_child(status)
	if st.diag:
		status.text = "Причина: " + G.MODS[id].cause_text
		status.add_theme_color_override("font_color", G.MUSTARD)
	else:
		status.text = "Найдите срез, где появилась поломка «%s», и кликните по нему." % G.MODS[id].problem
		status.add_theme_color_override("font_color", G.CYAN_L)
