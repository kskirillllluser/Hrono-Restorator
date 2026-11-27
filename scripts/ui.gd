class_name UI

const PX := 4
static var _sb_cache := {}

static func sb(bg: Color, radius := 18, shadow := 10, border := 0, border_col := Color.TRANSPARENT, pad := 18) -> StyleBox:
	var s: StyleBox
	if bg.a < 0.02 and border == 0:
		s = StyleBoxEmpty.new()
	else:
		var key := "%s|%d|%d|%d|%s" % [bg.to_html(), radius, shadow, border, border_col.to_html()]
		if not _sb_cache.has(key):
			_sb_cache[key] = _make_box(bg, radius, shadow, border, border_col)
		var e: Array = _sb_cache[key]
		var st := StyleBoxTexture.new()
		st.texture = e[0]
		var m: Array = e[1]
		st.texture_margin_left = m[0]
		st.texture_margin_top = m[1]
		st.texture_margin_right = m[2]
		st.texture_margin_bottom = m[3]
		s = st
	s.content_margin_left = pad
	s.content_margin_right = pad
	s.content_margin_top = pad * 0.6
	s.content_margin_bottom = pad * 0.6
	return s

static func _make_box(bg: Color, radius: int, shadow: int, border: int, border_col: Color) -> Array:
	var img: Image
	var margins: Array
	if radius >= 30 and bg.a > 0.02:
		var d := maxi(6, int(round(radius * 2.0 / PX)))
		img = Image.create(d, d, false, Image.FORMAT_RGBA8)
		var oc := border_col if border > 0 else Color(bg.darkened(0.55), 1.0)
		var r := d / 2.0
		for y in d:
			for x in d:
				var dist := Vector2(x + 0.5 - r, y + 0.5 - r).length()
				if dist <= r - 1.0:
					var c := bg
					if y < d * 0.3 and bg.a > 0.9:
						c = bg.lightened(0.12)
					img.set_pixel(x, y, c)
				elif dist <= r:
					img.set_pixel(x, y, oc)
		img.resize(d * PX, d * PX, Image.INTERPOLATE_NEAREST)
		@warning_ignore("integer_division")
		var h := d * PX / 2
		margins = [h - 1, h - 1, h - 1, h - 1]
	else:
		var thick := 2 if border >= 6 else 1
		var sh := 0 if shadow <= 0 else (2 if shadow >= 14 else 1)
		var n := 2 * thick + 4
		var w := n + sh
		img = Image.create(w, w, false, Image.FORMAT_RGBA8)
		var notch := radius >= 4
		if sh > 0:
			for y in range(sh, w):
				for x in range(sh, w):
					var corner := notch and (x == sh or x == w - 1) and (y == sh or y == w - 1)
					if not corner:
						img.set_pixel(x, y, Color(0.13, 0.07, 0.12, 0.30))
		var oc := border_col if border > 0 else Color(bg.darkened(0.55), maxf(bg.a, 0.6))
		for y in n:
			for x in n:
				var corner := notch and (x == 0 or x == n - 1) and (y == 0 or y == n - 1)
				if corner:
					continue
				var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
				var c: Color
				if edge < thick:
					c = oc if not (thick == 2 and edge == 0) else oc.darkened(0.35)
				else:
					c = bg
					if bg.a > 0.9 and y == thick:
						c = bg.lightened(0.16)
					elif bg.a > 0.9 and y == n - 1 - thick:
						c = bg.darkened(0.08)
				img.set_pixel(x, y, c)
		img.resize(w * PX, w * PX, Image.INTERPOLATE_NEAREST)
		var a := (thick + 1) * PX
		margins = [a, a, a + sh * PX, a + sh * PX]
	return [ImageTexture.create_from_image(img), margins]


static func style(l: Label, size: int, color: Color, font: Font = null) -> void:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if font:
		l.add_theme_font_override("font", font)

static func label(text: String, size := 26, color := G.INK, font: Font = null, align := HORIZONTAL_ALIGNMENT_LEFT, wrap_text := false) -> Label:
	var l := Label.new()
	l.text = text
	style(l, size, color, font)
	l.horizontal_alignment = align
	if wrap_text:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l

static func rich(bbcode: String, size := 24, color := G.INK) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.fit_content = true
	r.scroll_active = false
	r.text = bbcode
	r.add_theme_font_override("normal_font", G.f_ui)
	r.add_theme_font_override("bold_font", G.f_ui_b)
	r.add_theme_font_override("italics_font", G.f_hand)
	r.add_theme_font_size_override("normal_font_size", size)
	r.add_theme_font_size_override("bold_font_size", size)
	r.add_theme_font_size_override("italics_font_size", int(size * 1.3))
	r.add_theme_color_override("default_color", color)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func button(text: String, kind := "primary", size := 26, icon_name := "") -> Button:
	var b := Button.new()
	b.text = text
	apply_button_style(b, kind, size, icon_name)
	return b

static func apply_button_style(b: Button, kind := "primary", size := 26, icon_name := "") -> void:
	b.add_theme_font_override("font", G.f_ui_b)
	b.add_theme_font_size_override("font_size", size)
	var bg: Color
	var fg := G.INK
	match kind:
		"primary": bg = G.MUSTARD
		"secondary": bg = G.CREAM
		"danger": bg = G.TERRA
		"teal":
			bg = G.TEAL
			fg = G.CREAM
		"dark":
			bg = G.INK
			fg = G.CREAM
		"chalk":
			bg = Color(1, 1, 1, 0.08)
			fg = G.CREAM
		_: bg = Color(0, 0, 0, 0)
	var shadow := 6 if kind != "chalk" and kind != "ghost" else 0
	var n := sb(bg, 16, shadow, 0, Color.TRANSPARENT, 22)
	var h := sb(bg.lightened(0.12), 16, shadow + 3, 0, Color.TRANSPARENT, 22)
	var p := sb(bg.darkened(0.1), 16, 2, 0, Color.TRANSPARENT, 22)
	var d := sb(Color(bg, 0.45), 16, 0, 0, Color.TRANSPARENT, 22)
	if kind == "chalk":
		n = sb(Color("2d3a54"), 8, 0, 0, Color.TRANSPARENT, 22)
		h = sb(Color("3b4a68"), 8, 0, 0, Color.TRANSPARENT, 22)
		p = sb(Color("222c40"), 8, 0, 0, Color.TRANSPARENT, 22)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", p)
	b.add_theme_stylebox_override("disabled", d)
	b.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for st in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(st, fg)
	b.add_theme_color_override("font_disabled_color", Color(fg, 0.5))
	if icon_name != "":
		b.icon = G.icon(icon_name)
		b.expand_icon = true
		b.add_theme_constant_override("icon_max_width", int(size * 1.4))
		b.add_theme_constant_override("h_separation", 10)
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.pressed.connect(func(): Sfx.play("click", -4))
	b.mouse_entered.connect(func(): if not b.disabled: hover_pop(b))

static func hover_pop(c: Control) -> void:
	c.pivot_offset = c.size / 2
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2(1.04, 1.04), 0.08)
	tw.tween_property(c, "scale", Vector2.ONE, 0.12)

static func panel(bg := G.CREAM, radius := 24, shadow := 16) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", sb(bg, radius, shadow, 0, Color.TRANSPARENT, 28))
	return p

static func icon_rect(name: String, sz := 40) -> TextureRect:
	var t := TextureRect.new()
	t.texture = G.icon(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(sz, sz)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t

static func hbox(sep := 12) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	return h

static func vbox(sep := 12) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	return v

static func margin(c: Control, l := 24, t := 24, r := 24, b := 24) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", t)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	m.add_child(c)
	return m

static func dimmer(alpha := 0.55) -> ColorRect:
	var d := ColorRect.new()
	d.color = Color(G.INK, alpha)
	d.set_anchors_preset(Control.PRESET_FULL_RECT)
	d.mouse_filter = Control.MOUSE_FILTER_STOP
	return d

static func appear(c: CanvasItem, from_y := 40.0, t := 0.35) -> void:
	c.modulate.a = 0
	var tw := c.create_tween().set_parallel()
	tw.tween_property(c, "modulate:a", 1.0, t)
	if c is Control:
		var ctl := c as Control
		var target := ctl.position
		ctl.position = target + Vector2(0, from_y)
		tw.tween_property(ctl, "position", target, t).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

static func bar(value: float, w := 300, h := 18, col := G.TEAL, bg := Color(0, 0, 0, 0.12)) -> Control:
	var root := Control.new()
	root.custom_minimum_size = Vector2(w, h)
	var back := Panel.new()
	@warning_ignore("integer_division")
	var radius := h / 2
	back.add_theme_stylebox_override("panel", sb(bg, radius, 0, 0, Color.TRANSPARENT, 0))
	back.size = Vector2(w, h)
	root.add_child(back)
	var fill := Panel.new()
	fill.name = "Fill"
	fill.add_theme_stylebox_override("panel", sb(col, radius, 0, 0, Color.TRANSPARENT, 0))
	fill.size = Vector2(maxf(h, w * clampf(value, 0, 1)), h)
	root.add_child(fill)
	return root

static func set_bar(b: Control, value: float, animate := true) -> void:
	var fill: Panel = b.get_node("Fill")
	var w := b.custom_minimum_size.x
	var h := b.custom_minimum_size.y
	var target := Vector2(maxf(h, w * clampf(value, 0, 1)), h)
	if animate:
		fill.create_tween().tween_property(fill, "size", target, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		fill.size = target
