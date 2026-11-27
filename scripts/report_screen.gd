extends Control
class_name ReportScreen

@onready var panel: Panel = $Panel
@onready var stamp: Label = $Panel/Stamp
@onready var again_btn: Button = $Panel/AgainButton

func _ready() -> void:
	_apply_styles()

func _apply_styles() -> void:
	panel.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 20, 6, G.CYAN, 0))
	UI.style($Panel/Heading, 30, G.CYAN, G.f_retro)
	var bars := [$Panel/RowBar1, $Panel/RowBar2, $Panel/RowBar3, $Panel/RowBar4]
	var colors := [G.GOOD, G.CYAN, G.MUSTARD, G.ROSE]
	for i in 4:
		UI.style(panel.get_node("RowName%d" % (i + 1)), 30, G.CREAM, G.f_ui_b)
		UI.style(panel.get_node("RowSub%d" % (i + 1)), 19, G.INK_SOFT)
		UI.style(panel.get_node("RowValue%d" % (i + 1)), 32, G.CREAM, G.f_ui_b)
		bars[i].get_node("Back").add_theme_stylebox_override("panel", UI.sb(Color(1, 1, 1, 0.1), 11, 0, 0, Color.TRANSPARENT, 0))
		bars[i].get_node("Fill").add_theme_stylebox_override("panel", UI.sb(colors[i], 11, 0, 0, Color.TRANSPARENT, 0))
	UI.style(stamp, 24, G.MUSTARD, G.f_retro)
	stamp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stamp.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stamp.add_theme_stylebox_override("normal", UI.sb(Color(0, 0, 0, 0), 8, 0, 6, G.MUSTARD, 24))
	UI.style($Panel/EndText, 24, G.CREAM, G.f_ui)
	UI.style($Panel/RouteHint, 21, G.MUSTARD, G.f_ui)
	UI.style($Panel/DecisionsTitle, 24, G.CYAN, G.f_ui_b)
	UI.style($Panel/Decisions, 21, G.CREAM, G.f_ui)
	UI.style($Panel/Stats, 20, G.INK_SOFT)
	UI.apply_button_style(again_btn, "primary", 28)
	UI.apply_button_style($Panel/MenuButton, "secondary", 24)

func open() -> String:
	visible = true
	_fill_values()
	var rows := [["Функциональность", 100.0], ["Стабильность", G.stability], ["Подлинность", G.authenticity()], ["Экономность", G.economy()]]
	var bars := [$Panel/RowBar1, $Panel/RowBar2, $Panel/RowBar3, $Panel/RowBar4]
	for i in 4:
		panel.get_node("RowValue%d" % (i + 1)).text = str(int(rows[i][1]))
	G.profiles_seen[G.profile()] = true
	UI.appear(panel, 40, 0.5)
	await get_tree().create_timer(0.5).timeout
	for i in 4:
		UI.set_bar(bars[i], rows[i][1] / 100.0)
		Sfx.play("tick", -6)
		await get_tree().create_timer(0.3).timeout
	await _stamp_anim()
	if G.auto:
		await get_tree().create_timer(0.8).timeout
		await G.shot("report")
		get_tree().quit()
		return ""
	elif G.drv:
		await get_tree().create_timer(3.0).timeout
		await G.drv.click(again_btn)
		get_tree().quit()
		return ""
	var res := [""]
	again_btn.pressed.connect(func(): res[0] = "again")
	$Panel/MenuButton.pressed.connect(func(): res[0] = "menu")
	while res[0] == "":
		await get_tree().process_frame
	return res[0]

func _fill_values() -> void:
	var e: Dictionary = G.ENDINGS[G.profile()]
	stamp.text = e.title
	stamp.modulate.a = 0
	$Panel/EndText.text = e.text
	var other := "Попробуйте практичный маршрут: аналог шестерни и ручная пружина — меньше конфликтов фаз." if G.m.gear.via == "ret2" else "Попробуйте исторический маршрут: верните родную шестерню из T−2 и закрепите её якорем."
	$Panel/RouteHint.text = "Неиспытанный маршрут: " + other
	$Panel/Decisions.text = "• " + "\n• ".join(G.decisions)
	$Panel/Stats.text = "Журнал реставратора: %d/11 · профилей открыто: %d/3 · тестов: %d · время: %d мин" % [G.journal.size(), G.profiles_seen.size(), G.tests, int((Time.get_ticks_msec() - G.start_msec) / 60000.0)]

func _stamp_anim() -> void:
	Sfx.play("stamp")
	stamp.pivot_offset = stamp.size / 2
	stamp.scale = Vector2(1.8, 1.8)
	var tw := stamp.create_tween().set_parallel()
	tw.tween_property(stamp, "scale", Vector2.ONE, 0.2)
	tw.tween_property(stamp, "modulate:a", 1.0, 0.15)
	await tw.finished
