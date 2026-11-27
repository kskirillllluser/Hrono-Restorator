extends Control
class_name Terminal

signal method_confirmed(id: String, mid: String)

@onready var body: Control = $Body

var mod := ""
var pick := ""
var method_btns := {}
var confirm_btn: Button
var cancel_btn: Button
var next_y := 0

func _ready() -> void:
	show_order()

func _clear() -> void:
	for c in body.get_children():
		c.queue_free()
	method_btns.clear()
	confirm_btn = null
	cancel_btn = null

func _head(t: String, col := G.MUSTARD) -> void:
	var h := UI.label(t, 18, col, G.f_retro)
	h.position = Vector2(14, 10)
	h.size = Vector2(520, 24)
	body.add_child(h)

func _lbl(t: String, sz: int, col: Color, pos: Vector2, w := 520) -> Label:
	var l := UI.label(t, sz, col, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.position = pos
	l.size = Vector2(w, 30)
	return l

func show_order() -> void:
	mod = ""
	pick = ""
	_clear()
	_head("ТЕРМИНАЛ · ЗАКАЗ «АСТРА-01»")
	var pic := TextureRect.new()
	pic.texture = G.tex("portrait_vera")
	pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pic.size = Vector2(96, 96)
	pic.position = Vector2(14, 44)
	body.add_child(pic)
	var q := UI.label("«Пусть часы снова идут к юбилею станции. И, пожалуйста, не потеряйте подпись деда на крышке». — Вера Орлова, комендант", 16, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	q.position = Vector2(124, 42)
	q.size = Vector2(406, 104)
	body.add_child(q)
	_build_checklist()
	body.add_child(_lbl("Клик по детали на верстаке — её карточка.", 18, Color(G.CYAN, 0.8), Vector2(14, 362)))

func _build_checklist() -> void:
	var y := 160
	var rows := [
		["Часы идут (ход)", G.last_test.get("run", false)],
		["Фазы синхронизированы", G.last_test.get("sync", false)],
		["Подпись на крышке сохранена", G.signature_kept() and G.m.lid.via != ""],
	]
	body.add_child(_lbl("Требования заказа:", 20, G.INK_SOFT, Vector2(14, y)))
	y += 30
	for r in rows:
		var h := UI.hbox(10)
		h.position = Vector2(14, y)
		h.add_child(UI.icon_rect("ok" if r[1] else "no", 28))
		h.add_child(UI.label(r[0], 22, G.CREAM if r[1] else Color(G.CREAM, 0.75), G.f_ui_b))
		body.add_child(h)
		y += 38
	var mods := []
	for id in G.MOD_ORDER:
		var st: Dictionary = G.m[id]
		var done: bool = st.fixed or (id == "lid" and st.via != "") or (id == "block" and G.last_test.get("sync", false))
		mods.append(("• " if done else "· ") + G.mname(id))
	var ml := UI.label("   ".join(mods), 15, G.INK_SOFT, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	ml.position = Vector2(14, y + 8)
	ml.size = Vector2(520, 60)
	body.add_child(ml)

func show_module(id: String) -> void:
	mod = id
	pick = ""
	_clear()
	var st: Dictionary = G.m[id]
	_head("КАРТОЧКА · " + G.mname(id).to_upper(), G.CYAN)
	body.add_child(_lbl(_state_line(id, st), 20, G.CREAM, Vector2(14, 40)))
	var ms := G.methods(id)
	if not st.diag:
		var w := UI.label("Сначала найдите причину поломки на хроносканере (слева). Это бесплатно.", 22, G.CYAN_L, G.f_ui_b, HORIZONTAL_ALIGNMENT_LEFT, true)
		w.position = Vector2(14, 90)
		w.size = Vector2(520, 70)
		body.add_child(w)
	var y := 86 if st.diag else 160
	if ms.is_empty():
		body.add_child(_lbl("Деталь готова. Проверьте механизм кнопкой «ТЕСТИРОВАТЬ».", 22, G.GOOD, Vector2(14, y + 4)))
	for md in ms:
		var b := _method_button(id, md, st.diag)
		b.position = Vector2(12, y)
		body.add_child(b)
		method_btns[md.id] = b
		y += 62
	next_y = y
	if G.stuck():
		body.add_child(_lbl("Ресурсов не хватает. Перезапуск заказа (меню → «Начать заказ заново») бесплатен.", 18, G.TERRA, Vector2(14, 360)))

func _state_line(id: String, st: Dictionary) -> String:
	var state: String = "исправна" if st.fixed else G.MODS[id].problem
	if id == "block":
		state = "фазы согласованы" if G.last_test.get("sync", false) else "фаза стрелок сбита — нужна настройка"
	if id == "lid":
		state = {"clean": "очищена, подпись цела", "leave": "оставлена как есть, подпись цела", "replace": "заменена, подписи нет"}.get(st.via, G.MODS[id].problem)
	var info: String = "Сейчас: " + state
	if id in ["gear", "spring"] and st.fixed:
		info += "   ·   возраст: " + G.AGE_NAME[st.age] + ("   ·   якорь" if st.anchored else "")
	return info

func _method_button(id: String, md: Dictionary, enabled: bool) -> Button:
	var b := Button.new()
	b.toggle_mode = true
	b.size = Vector2(520, 56)
	var afford := G.can_pay(md.cost)
	b.disabled = not enabled or not afford
	var col := G.TERRA if md.get("warn", false) else G.CYAN
	b.add_theme_stylebox_override("normal", UI.sb(Color("0c1d24"), 8, 0, 3, Color(col, 0.55), 10))
	b.add_theme_stylebox_override("hover", UI.sb(Color("12303a"), 8, 0, 3, col, 10))
	b.add_theme_stylebox_override("pressed", UI.sb(Color("153c46"), 8, 0, 6, G.MUSTARD, 10))
	b.add_theme_stylebox_override("hover_pressed", UI.sb(Color("153c46"), 8, 0, 6, G.MUSTARD, 10))
	b.add_theme_stylebox_override("disabled", UI.sb(Color("0a1418"), 8, 0, 3, Color(G.STEEL, 0.4), 10))
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var t := UI.label(md.title, 22, G.CREAM if not b.disabled else Color(G.CREAM, 0.45), G.f_ui_b)
	t.position = Vector2(60, 3)
	b.add_child(t)
	b.add_child(_method_icon(md, b.disabled))
	b.add_child(_method_costs(md, afford))
	b.tooltip_text = md.text
	b.pressed.connect(func(): _pick(id, md))
	return b

func _method_icon(md: Dictionary, disabled: bool) -> TextureRect:
	var ic := UI.icon_rect(md.icon, 40)
	ic.position = Vector2(10, 8)
	ic.modulate.a = 1.0 if not disabled else 0.4
	return ic

func _method_costs(md: Dictionary, afford: bool) -> HBoxContainer:
	var costs := UI.hbox(4)
	costs.position = Vector2(60, 30)
	if md.cost.is_empty():
		costs.add_child(UI.label("бесплатно", 18, G.GOOD))
	for k in ["charge", "mat", "anchor"]:
		var n: int = md.cost.get(k, 0)
		if n > 0:
			costs.add_child(UI.icon_rect(k, 20))
			costs.add_child(UI.label("×%d   " % n, 18, G.MUSTARD if afford else G.TERRA, G.f_ui_b))
	if not afford:
		costs.add_child(UI.label("не хватает ресурсов", 18, G.TERRA))
	return costs

func _pick(id: String, md: Dictionary) -> void:
	pick = md.id
	for k in method_btns:
		method_btns[k].set_pressed_no_signal(k == pick)
	if md.id == "tune":
		method_confirmed.emit(id, md.id)
		return
	for c in body.get_children():
		if c.has_meta("detail"):
			c.queue_free()
	var p := Panel.new()
	p.set_meta("detail", true)
	p.add_theme_stylebox_override("panel", UI.sb(Color("101a24"), 8, 10, 4, G.MUSTARD, 0))
	p.position = Vector2(12, mini(next_y + 2, 272))
	p.size = Vector2(520, 124)
	body.add_child(p)
	var txt: String = _method_text(id, md)
	var l := UI.label(txt, 17, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.position = Vector2(14, 10)
	l.size = Vector2(492, 64)
	p.add_child(l)
	confirm_btn = UI.button("Подтвердить", "primary", 22)
	confirm_btn.position = Vector2(14, 72)
	confirm_btn.custom_minimum_size = Vector2(240, 44)
	confirm_btn.pressed.connect(func(): method_confirmed.emit(id, pick))
	p.add_child(confirm_btn)
	cancel_btn = UI.button("Отменить выбор", "secondary", 20)
	cancel_btn.position = Vector2(270, 72)
	cancel_btn.custom_minimum_size = Vector2(236, 44)
	cancel_btn.pressed.connect(func(): show_module(id))
	p.add_child(cancel_btn)

func _method_text(id: String, md: Dictionary) -> String:
	var txt: String = md.text
	if G.cal_preview and md.get("phase", -1) >= 0 and id in ["gear", "spring"]:
		var ri := 0 if id == "gear" else 1
		txt += "\nПредпросмотр конфликта: регулятор «%s» должен будет стоять на %d." % [["Шестерня", "Пружина"][ri], md.phase]
	return txt

func show_test(res: Dictionary) -> void:
	mod = ""
	_clear()
	_head("ОТЧЁТ ТЕСТА №%d" % G.tests, G.CYAN)
	var y := 46
	for row in res.rows:
		var h := UI.hbox(10)
		h.position = Vector2(14, y)
		h.add_child(UI.icon_rect("ok" if row[1] else "no", 30))
		h.add_child(UI.label(row[0], 23, G.CREAM, G.f_ui_b))
		body.add_child(h)
		var why := UI.label(row[2], 16, G.INK_SOFT if row[1] else G.CYAN_L, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
		why.position = Vector2(54, y + 32)
		why.size = Vector2(476, 66)
		body.add_child(why)
		y += 106
	var sl := UI.label("Стабильность: %d" % int(G.stability), 20, G.MUSTARD, G.f_ui_b)
	sl.position = Vector2(14, 366)
	body.add_child(sl)
