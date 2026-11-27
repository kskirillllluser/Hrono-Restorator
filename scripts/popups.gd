class_name Popups

static func _tik_box(text: String, width: int, who := "ТИК") -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 14, 6, G.CYAN, 26))
	p.custom_minimum_size = Vector2(width, 0)
	var h := UI.hbox(20)
	p.add_child(h)
	var face := TextureRect.new()
	face.texture = G.tex("tik") if who == "ТИК" else G.tex("portrait_vera")
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.custom_minimum_size = Vector2(104, 104)
	face.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(face)
	var v := UI.vbox(10)
	h.add_child(v)
	v.add_child(UI.label(who, 22, G.CYAN, G.f_retro))
	var l := UI.label(text, 28, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	l.custom_minimum_size = Vector2(width - 190, 0)
	v.add_child(l)
	return p

static func note(parent: Control, text: String, opts := {}) -> void:
	G.notes += 1
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	if opts.get("modal", true):
		root.add_child(UI.dimmer(0.35))
	var w: int = opts.get("width", 760)
	var p := _tik_box(text, w, opts.get("who", "ТИК"))
	var v: VBoxContainer = p.get_child(0).get_child(1)
	var b := UI.button(opts.get("button", "Понятно"), "primary", 24)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(b)
	root.add_child(p)
	await parent.get_tree().process_frame
	var center: Vector2 = opts.get("pos", Vector2(960, 540))
	p.position = (center - p.size / 2).round()
	if opts.has("arrow"):
		var arr := Node2D.new()
		arr.set_script(preload("res://scripts/drawer.gd"))
		var a1: Vector2 = opts.arrow
		var dir0 := (a1 - center).normalized()
		var k := minf((p.size.x / 2 + 8) / maxf(absf(dir0.x), 0.001), (p.size.y / 2 + 8) / maxf(absf(dir0.y), 0.001))
		var a0: Vector2 = center + dir0 * k
		var tt := [0.0]
		arr.cb = func(n):
			var steps := int(a0.distance_to(a1) / 16)
			for i in steps:
				var q := (a0.lerp(a1, float(i) / maxf(1, steps)) / 4.0).floor() * 4.0
				if (i + int(tt[0] * 8)) % 3 != 0:
					n.draw_rect(Rect2(q - Vector2(4, 4), Vector2(8, 8)), G.CYAN)
			var tip := (a1 / 4.0).floor() * 4.0
			n.draw_rect(Rect2(tip - Vector2(10, 10), Vector2(20, 20)), G.CYAN_L)
			n.draw_rect(Rect2(tip - Vector2(4, 4), Vector2(8, 8)), G.INK)
		var tm := Timer.new()
		tm.wait_time = 0.12
		tm.autostart = true
		tm.timeout.connect(func(): tt[0] += 0.12; arr.queue_redraw())
		arr.add_child(tm)
		root.add_child(arr)
	UI.appear(p, 24)
	Sfx.play("pop", -6, 0.9)
	if G.auto:
		await parent.get_tree().create_timer(0.6).timeout
		await G.shot("note_%d" % (Time.get_ticks_msec() % 100000))
	elif G.drv:
		await parent.get_tree().create_timer(clampf(text.length() * 0.03, 1.4, 3.6)).timeout
		await G.drv.click(b)
	else:
		await b.pressed
	if is_instance_valid(root):
		root.queue_free()
	G.notes -= 1

static func choose(parent: Control, title: String, text: String, options: Array, auto_pick := 0) -> int:
	G.notes += 1
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(root)
	root.add_child(UI.dimmer(0.55))
	var p := UI.panel(G.PANEL, 8, 20)
	p.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 20, 6, G.MUSTARD, 30))
	p.custom_minimum_size = Vector2(1080, 0)
	root.add_child(p)
	var v := UI.vbox(14)
	p.add_child(v)
	var head := UI.hbox(16)
	head.add_child(UI.icon_rect("warn", 56))
	head.add_child(UI.label(title, 34, G.MUSTARD, G.f_retro))
	v.add_child(head)
	var tl := UI.label(text, 26, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
	tl.custom_minimum_size = Vector2(1020, 0)
	v.add_child(tl)
	var result := [-1]
	var buttons: Array[Button] = []
	for i in options.size():
		var o: Dictionary = options[i]
		var b := Button.new()
		b.custom_minimum_size = Vector2(1020, 96)
		b.add_theme_stylebox_override("normal", UI.sb(G.SCREEN, 8, 4, 3, G.STEEL, 20))
		b.add_theme_stylebox_override("hover", UI.sb(Color("10222a"), 8, 8, 3, G.CYAN, 20))
		b.add_theme_stylebox_override("pressed", UI.sb(Color("10222a"), 8, 2, 3, G.CYAN, 20))
		b.add_theme_stylebox_override("disabled", UI.sb(Color(G.SCREEN, 0.5), 8, 0, 0, Color.TRANSPARENT, 20))
		b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		b.disabled = o.get("disabled", false)
		var hb := UI.hbox(18)
		hb.set_anchors_preset(Control.PRESET_FULL_RECT)
		hb.offset_left = 20
		hb.offset_right = -20
		hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
		hb.add_child(UI.icon_rect(o.get("icon", "ok"), 56))
		var tv := UI.vbox(2)
		tv.alignment = BoxContainer.ALIGNMENT_CENTER
		tv.add_child(UI.label(o.title, 27, G.CREAM if not b.disabled else Color(G.CREAM, 0.4), G.f_ui_b))
		if o.has("sub"):
			tv.add_child(UI.label(o.sub, 22, Color(G.INK_SOFT, 1.0 if not b.disabled else 0.4)))
		hb.add_child(tv)
		b.add_child(hb)
		v.add_child(b)
		buttons.append(b)
		b.pressed.connect(func(): result[0] = i; Sfx.play("click"))
	await parent.get_tree().process_frame
	p.position = (Vector2(960, 540) - p.size / 2).round()
	UI.appear(p, 30)
	Sfx.play("whoosh", -6)
	if G.auto:
		await parent.get_tree().create_timer(0.7).timeout
		await G.shot("choice_%d" % (Time.get_ticks_msec() % 100000))
		result[0] = auto_pick
	elif G.drv:
		await parent.get_tree().create_timer(2.6).timeout
		await G.drv.click(buttons[auto_pick])
	else:
		while result[0] < 0:
			await parent.get_tree().process_frame
	root.queue_free()
	G.notes -= 1
	return result[0]
