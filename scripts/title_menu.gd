extends Control
class_name TitleMenu

@onready var start_btn: Button = $Buttons/StartButton

var _pick := ""

func _ready() -> void:
	_apply_styles()
	$Buttons/StartButton.pressed.connect(func(): _pick = "start")
	$Buttons/HelpButton.pressed.connect(func(): _pick = "help")
	$Buttons/CreditsButton.pressed.connect(func(): _pick = "credits")
	$Buttons/QuitButton.pressed.connect(func(): _pick = "quit")

func _apply_styles() -> void:
	UI.style($TitleA, 92, G.CYAN, G.f_retro)
	$TitleA.add_theme_color_override("font_shadow_color", Color("1b6068"))
	$TitleA.add_theme_constant_override("shadow_offset_x", 8)
	$TitleA.add_theme_constant_override("shadow_offset_y", 8)
	UI.style($TitleB, 92, G.MUSTARD, G.f_retro)
	$TitleB.add_theme_color_override("font_shadow_color", Color("8a5418"))
	$TitleB.add_theme_constant_override("shadow_offset_x", 8)
	$TitleB.add_theme_constant_override("shadow_offset_y", 8)
	UI.style($Tagline, 30, Color(G.CREAM, 0.9), G.f_ui)
	UI.style($JournalNote, 22, G.CYAN, G.f_ui)
	UI.apply_button_style($Buttons/StartButton, "primary", 30)
	UI.apply_button_style($Buttons/HelpButton, "secondary", 30)
	UI.apply_button_style($Buttons/CreditsButton, "secondary", 30)
	UI.apply_button_style($Buttons/QuitButton, "chalk", 30)

func open() -> void:
	visible = true
	var note: Label = $JournalNote
	note.visible = G.journal.size() > 0
	if note.visible:
		note.text = "Журнал реставратора: %d/11 записей сохранено" % G.journal.size()
	UI.appear($TitleA, 30, 0.6)
	UI.appear($TitleB, 30, 0.8)
	if G.auto:
		await get_tree().create_timer(1.4).timeout
		await G.shot("title")
		_pick = "start"
	elif G.drv:
		await get_tree().create_timer(2.0).timeout
		await G.drv.click(start_btn)
		_pick = "start"
	while true:
		while _pick == "":
			await get_tree().process_frame
		match _pick:
			"start":
				break
			"help":
				await _info("Как играть", "[b]Цель:[/b] починить часы «АСТРА-01» так, чтобы они шли, а подпись основателя на крышке сохранилась.\n\n[b]1. Выберите деталь[/b] на верстаке — откроется её карточка.\n[b]2. Сканируйте[/b] (бесплатно) и найдите срез прошлого, где появилась поломка.\n[b]3. Выберите метод:[/b] хроно-возврат (заряд), ручной ремонт или замена (материал). Цена видна до подтверждения.\n[b]4. Тестируйте:[/b] тест бесплатен и показывает сбойную цепь. Настройте фазы регуляторами или якорем.\n[b]5. Сдайте заказ[/b] — оценка по ходу, стабильности, подлинности и экономности.\n\nТаймера нет, тупиков нет: заказ можно начать заново в меню. Всё управление — мышью.")
			"credits":
				await _info("Авторы", "Игра создана командой для II этапа НТО (Godot 4.7.2).\n\n[b]Шрифт:[/b] Science Gothic — SIL Open Font License 1.1.\n\nВсе персонажи и события вымышлены. 12+.")
			"quit":
				get_tree().quit()
				return
		_pick = ""
	visible = false

func _info(t: String, bb: String) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)
	root.add_child(UI.dimmer(0.6))
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 18, 6, G.CYAN, 34))
	p.custom_minimum_size = Vector2(1140, 0)
	root.add_child(p)
	var v := UI.vbox(16)
	p.add_child(v)
	v.add_child(UI.label(t, 30, G.CYAN, G.f_retro))
	var r := UI.rich(bb, 25, G.CREAM)
	r.custom_minimum_size = Vector2(1060, 0)
	v.add_child(r)
	var b := UI.button("Понятно", "primary", 26)
	b.size_flags_horizontal = Control.SIZE_SHRINK_END
	v.add_child(b)
	await get_tree().process_frame
	p.position = (Vector2(960, 540) - p.size / 2).round()
	UI.appear(p, 30)
	await b.pressed
	root.queue_free()
