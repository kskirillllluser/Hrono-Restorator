extends Control
class_name MiniGame

signal finished(ok: bool)

@onready var panel: Panel = $Panel
@onready var hint: Label = $Panel/Hint
@onready var tray: TextureRect = $Panel/Drawer/PartA
@onready var tray2: TextureRect = $Panel/Drawer/PartB
@onready var socket: Control = $Panel/Socket
@onready var rot_l: Button = $Panel/RotateLeft
@onready var rot_r: Button = $Panel/RotateRight
@onready var done_btn: Button = $Panel/FinishButton

var kind := ""
var placed := false
var pos := 3
var bad_hint := ""
var _t := 0.0

func open(p_kind: String) -> bool:
	kind = p_kind
	_setup()
	var r: bool = await finished
	return r

func _setup() -> void:
	_apply_styles()
	_setup_drawer()
	_setup_controls()
	_update()
	UI.appear(panel, 30)
	Sfx.play("whoosh", -6)
	if G.auto:
		_auto()
	elif G.drv:
		_demo()

func _apply_styles() -> void:
	panel.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 18, 6, G.CYAN, 0))
	$Panel/Drawer.add_theme_stylebox_override("panel", UI.sb(Color("86573a"), 8, 8, 4, Color("40281b"), 0))
	$Panel/Heading.text = "РУЧНАЯ СБОРКА ПРУЖИНЫ" if kind == "spring" else "ЗАМЕНА АНАЛОГОМ"
	UI.style($Panel/Heading, 26, G.CYAN, G.f_retro)
	UI.style(hint, 24, G.CREAM, G.f_ui)
	UI.style($Panel/Drawer/DrawerTitle, 22, Color("ffe4a3"), G.f_ui_b)
	UI.style($Panel/Drawer/Cost, 20, Color("ffe4a3"), G.f_ui)
	for b in [rot_l, rot_r]:
		UI.apply_button_style(b, "secondary", 40)
	UI.apply_button_style(done_btn, "primary", 28)
	UI.apply_button_style($Panel/CancelButton, "secondary", 22)

func _setup_drawer() -> void:
	var drawer: Panel = $Panel/Drawer
	tray.texture = G.tex("spring_manual" if kind == "spring" else "gear_analog")
	tray.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tray.mouse_default_cursor_shape = Control.CURSOR_DRAG
	tray.tooltip_text = "Перетащите деталь в гнездо"
	tray.set_drag_forwarding(func(_p): return _drag(tray, 14), Callable(), Callable())
	if kind == "analog":
		tray.size = tray.texture.get_size() * 4
		tray.position = Vector2(30, 90)
		tray2.texture = G.tex("gear_analog12")
		tray2.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tray2.size = tray2.texture.get_size() * 4
		tray2.position = Vector2(162, 90)
		tray2.mouse_default_cursor_shape = Control.CURSOR_DRAG
		tray2.tooltip_text = "Перетащите деталь в гнездо"
		tray2.set_drag_forwarding(func(_p): return _drag(tray2, 10), Callable(), Callable())
		drawer.add_child(tray2)
	else:
		tray.size = tray.texture.get_size() * 6
		tray.position = Vector2((300 - tray.size.x) / 2, 110)
		tray2.visible = false
		$Panel/Drawer/PartLabelB.visible = false

func _setup_controls() -> void:
	socket.set_drag_forwarding(Callable(), func(_p, d): return d is Dictionary and d.has("part"), func(_p, d): _drop(d))
	rot_l.pressed.connect(func(): _rotate(-1))
	rot_r.pressed.connect(func(): _rotate(1))
	done_btn.pressed.connect(func(): _finish(true))
	$Panel/CancelButton.pressed.connect(func(): _finish(false))
	var spring := kind == "spring"
	rot_l.visible = spring
	rot_r.visible = spring
	$Panel/RotateCaption.visible = spring

func _drag(src: TextureRect, teeth: int) -> Variant:
	if placed:
		return null
	var pv := TextureRect.new()
	pv.texture = src.texture
	pv.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pv.size = src.size
	pv.modulate.a = 0.8
	src.set_drag_preview(pv)
	Sfx.play("page", -8)
	return {"part": kind, "teeth": teeth}

func _drop(d: Dictionary) -> void:
	if d.get("teeth", 14) != 14:
		bad_hint = "Не подходит: у родной шестерни 14 зубцов — посмотрите срез T−2 на сканере. Механизм не провернётся."
		Sfx.play("bad", -4)
		_update()
		return
	_place()

func _place() -> void:
	placed = true
	bad_hint = ""
	tray.visible = false
	tray2.visible = false
	Sfx.play("lock", -6)
	_update()

func _rotate(d: int) -> void:
	if not placed:
		return
	pos = posmod(pos + d, 8)
	Sfx.play("tick", -4)
	if pos == 0:
		Sfx.play("good", -8)
	_update()

func _update() -> void:
	if bad_hint != "":
		hint.text = bad_hint
		hint.add_theme_color_override("font_color", G.TERRA)
		bad_hint = ""
	elif not placed:
		hint.add_theme_color_override("font_color", G.CREAM)
		hint.text = "Перетащите %s из шкафа в гнездо механизма." % ("новую пружину" if kind == "spring" else "подходящую шестерню-аналог (сверьтесь со срезом)")
	elif kind == "spring" and pos != 0:
		hint.add_theme_color_override("font_color", G.CREAM)
		hint.text = "Пружина в гнезде. Поворачивайте кольцо, пока бирюзовая метка не совпадёт с янтарной меткой гнезда."
	else:
		hint.add_theme_color_override("font_color", G.CREAM)
		hint.text = "Метки совпали — деталь встанет точно. Нажмите «Закрепить»." if kind == "spring" else "Аналог на месте. Нажмите «Закрепить»."
	done_btn.disabled = not placed or (kind == "spring" and pos != 0)
	rot_l.disabled = not placed
	rot_r.disabled = not placed
	socket.queue_redraw()

func _process(delta: float) -> void:
	_t += delta
	socket.queue_redraw()

func _finish(ok: bool) -> void:
	finished.emit(ok)
	queue_free()

func _px(p: Vector2, col: Color, sz := 8.0) -> void:
	socket.draw_rect(Rect2((p / 4).floor() * 4 - Vector2(sz / 2, sz / 2), Vector2(sz, sz)), col)

func _draw_socket() -> void:
	var c := Vector2(200, 200)
	socket.draw_rect(Rect2(0, 0, 400, 400), Color("0c141c"))
	for y in range(0, 400, 8):
		socket.draw_rect(Rect2(0, y, 400, 2), Color(0, 0, 0, 0.2))
	for k in 72:
		var a := k / 72.0 * TAU
		_px(c + Vector2(cos(a), sin(a)) * 150, Color("5e3f1a") if k % 2 else Color("96682b"))
	for k in 4:
		_px(c + Vector2(0, -170 + k * 8), G.MUSTARD)
	if not placed:
		if int(_t * 2) % 2 == 0:
			for k in 36:
				var a2 := k / 36.0 * TAU
				_px(c + Vector2(cos(a2), sin(a2)) * 110, Color(G.CYAN, 0.6), 4)
		return
	var tex := G.tex("spring_manual" if kind == "spring" else "gear_analog")
	var sz := tex.get_size() * 10
	socket.draw_texture_rect(tex, Rect2(c - sz / 2, sz), false)
	if kind == "spring":
		_draw_spring_marks(c)

func _draw_spring_marks(c: Vector2) -> void:
	var a3 := pos * PI / 4 - PI / 2
	var mark := c + Vector2(cos(a3), sin(a3)) * 138
	var col := G.CYAN_L if pos == 0 else G.CYAN
	for k in 3:
		_px(c + Vector2(cos(a3), sin(a3)) * (126 + k * 8), col, 10)
	_px(mark, col, 14)

func _auto() -> void:
	await get_tree().create_timer(0.4).timeout
	_place()
	while pos != 0:
		await get_tree().create_timer(0.15).timeout
		_rotate(-1 if pos <= 4 else 1)
	await get_tree().create_timer(0.3).timeout
	await G.shot("minigame_" + kind)
	_finish(true)

func _demo() -> void:
	await get_tree().create_timer(1.2).timeout
	await G.drv.drag(tray, socket, "", func(): _place())
	await get_tree().create_timer(0.6).timeout
	while pos != 0:
		await G.drv.click(rot_l if pos <= 4 else rot_r, 0.3)
		await get_tree().create_timer(0.35).timeout
	await get_tree().create_timer(0.6).timeout
	await G.drv.click(done_btn)
