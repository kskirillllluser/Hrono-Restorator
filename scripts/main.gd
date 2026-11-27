extends Node

const MINIGAME_SCENE := preload("res://scenes/minigame.tscn")

@onready var clock: ClockArtifact = $World/Clock
@onready var scanner: Scanner = $UILayer/Root/Scanner
@onready var terminal: Terminal = $UILayer/Root/Terminal
@onready var hud: Hud = $UILayer/Root/Hud
@onready var bench: Bench = $UILayer/Root/Bench
@onready var glitch: GlitchOverlay = $UILayer/Root/Glitch
@onready var overlay: Control = $OverlayLayer/Root
@onready var top: Control = $TopLayer/Root
@onready var fade: ColorRect = $TopLayer/Root/Fade
@onready var title_menu: TitleMenu = $OverlayLayer/Root/TitleMenu
@onready var intro: IntroSequence = $OverlayLayer/Root/Intro
@onready var report_screen: ReportScreen = $OverlayLayer/Root/Report
@onready var journal_screen: JournalScreen = $TopLayer/Root/Journal
@onready var pause_menu: PauseMenu = $TopLayer/Root/PauseMenu

var busy := false
var in_order := false
var seen := {}
var selected := ""
var runner: DemoRunner = null

func _ready() -> void:
	_apply_themes()
	_connect_signals()
	_set_ui_visible(false)
	refresh()
	if G.auto:
		DisplayServer.window_set_size(Vector2i(1920, 1080))
	if G.auto or G.demo != "":
		runner = DemoRunner.new()
		runner.main = self
		top.add_child(runner)
	if G.demo != "":
		_setup_demo_window()
		runner.run(G.demo)
		return
	if G.skip_menu:
		G.skip_menu = false
		_fade_in()
		start_order(false)
	else:
		open_title()

func _apply_themes() -> void:
	for root in [ $UILayer/Root, overlay, top ]:
		root.theme = G.theme

func _connect_signals() -> void:
	clock.module_clicked.connect(_on_module_clicked)
	scanner.scanned.connect(_on_scanned)
	scanner.slice_picked.connect(_on_slice)
	terminal.method_confirmed.connect(apply_method)
	hud.order_pressed.connect(show_order)
	hud.journal_pressed.connect(open_journal)
	hud.menu_pressed.connect(open_pause)
	bench.reg_changed.connect(set_reg)
	bench.test_pressed.connect(_on_test_pressed)
	bench.submit_pressed.connect(_on_submit_pressed)
	bench.order_pressed.connect(show_order)
	bench.journal_pressed.connect(open_journal)
	pause_menu.resumed.connect(_close_pause)
	pause_menu.journal_pressed.connect(open_journal)
	pause_menu.restart_pressed.connect(_restart_order)
	pause_menu.menu_pressed.connect(_to_main_menu)

func _setup_demo_window() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, true)
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	DisplayServer.window_set_position(Vector2i(0, 0))
	get_viewport().gui_disable_input = true
	var drv := DemoDriver.new()
	drv.theme = G.theme
	top.add_child(drv)
	G.drv = drv

func _on_module_clicked(id: String) -> void:
	if in_order and not busy:
		select(id)

func _on_test_pressed() -> void:
	if not busy:
		run_test()

func _on_submit_pressed() -> void:
	if not busy:
		submit()

func _fade_in(t := 0.8) -> void:
	fade.color.a = 1
	create_tween().tween_property(fade, "color:a", 0.0, t)

func _fade_out(t := 0.5) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, t)
	await tw.finished

func _set_ui_visible(on: bool) -> void:
	hud.visible = on
	scanner.visible = on
	terminal.visible = on
	bench.set_ui_visible(on)

func _unhandled_input(ev: InputEvent) -> void:
	if G.demo != "":
		return
	if ev is InputEventKey and ev.pressed and ev.keycode == KEY_ESCAPE and in_order:
		if pause_menu.visible:
			_close_pause()
		else:
			open_pause()

func refresh() -> void:
	hud.refresh_resources()
	hud.set_stability(G.stability)
	hud.set_step(_step_text())
	bench.refresh(busy)
	bench.set_hint(hint())
	clock.refresh()

func _step_text() -> String:
	var fixed := 0
	for id in G.MOD_ORDER:
		var st: Dictionary = G.m[id]
		if st.fixed or (id == "lid" and st.via != "") or (id == "block" and G.last_test.get("sync", false)):
			fixed += 1
	return "Модулей готово: %d из 4 · тестов: %d · журнал: %d/11" % [fixed, G.tests, G.journal.size()]

func hint() -> String:
	if not G.m.gear.scanned and selected == "":
		return "Начнём с главного: кликните по треснувшей шестерне на верстаке."
	if selected != "" and not G.m[selected].scanned:
		return "Нажмите «Сканировать» на хроносканере слева. Диагностика бесплатна."
	if selected != "" and not G.m[selected].diag:
		return "Сравните срезы прошлого: где впервые появилась поломка? Кликните по этому срезу."
	if not G.runs_ok():
		var left := []
		for id in ["gear", "spring"]:
			if not G.m[id].fixed:
				left.append(G.mname(id).to_lower())
		var s := "Чтобы часы пошли, почините: " + ", ".join(left) + "."
		if G.jolt_done and not G.m.spring.fixed:
			s = "Помеха выбила пружину, срез T−2 потерян. Два пути: ручная сборка (1 материал) или возврат к T−1 под якорем."
		return s
	if G.tests == 0:
		return "Детали на месте. Нажмите «ТЕСТИРОВАТЬ» — тест бесплатен и ничего не ломает."
	if not G.last_test.get("sync", false) or not G.regs_ok():
		if G.journal.has("rule_phase"):
			return "Фаза = возраст детали: T−2 → 2, T−1 → 1, T0 → 0. Стрелки — 0. Якорь ставит модуль в 0. Настройте и протестируйте."
		return "Протестируйте механизм ещё раз."
	if G.m.lid.via == "":
		return "Часы идут! Осталось решить судьбу крышки с подписью — кликните по ней."
	return "Всё готово. Можно сдавать заказ — или проверить ещё раз."

func open_title() -> void:
	in_order = false
	Sfx.music("music_lab")
	_fade_in(1.0)
	await title_menu.open()
	await _fade_out(0.4)
	_fade_in(0.5)
	start_order(true)

func start_order(with_intro: bool) -> void:
	G.reset_order()
	G.runs += 1
	selected = ""
	scanner.show_idle()
	terminal.show_order()
	if with_intro and G.runs == 1:
		await intro.play()
	_set_ui_visible(true)
	in_order = true
	Sfx.music("music_lab")
	refresh()
	if not seen.has("order"):
		seen["order"] = true
		await Popups.note(overlay, "Пожалуйста, заставьте часы снова идти к юбилею станции. И не потеряйте подпись деда на внутренней крышке — это главное.", {"who": "Вера Орлова", "pos": Vector2(960, 470), "button": "Принять заказ"})
		await Popups.note(overlay, "Я ТИК, помощник мастерской. Правила просты: сначала понимаем причину, потом чиним. Таймера нет. Кликните по треснувшей шестерне.", {"pos": Vector2(1000, 300), "arrow": clock.global_center("gear")})
	if G.auto:
		await runner.auto_play()
	elif G.demo == "userflow":
		await runner.run_userflow()

func select(id: String) -> void:
	selected = id
	clock.selected = id
	Sfx.play("click", -6)
	scanner.show_module(id)
	terminal.show_module(id)
	refresh()
	if id == "lid" and not seen.has("lid"):
		seen["lid"] = true
		await Popups.note(overlay, "Крышка — финальный выбор. Подпись основателя — требование заказа. Подлинность и экономия здесь спорят: решайте сами.", {"pos": Vector2(960, 300)})
	if not G.m[id].scanned and not seen.has("scan"):
		seen["scan"] = true
		await Popups.note(overlay, "Это карточка детали (справа) и хроносканер (слева). Нажмите «Сканировать» — прочитаем срезы прошлого.", {"pos": Vector2(960, 700), "arrow": Vector2(312, 400)})

func show_order() -> void:
	if not in_order:
		return
	selected = ""
	clock.selected = ""
	scanner.show_idle()
	terminal.show_order()
	refresh()

func _on_scanned(_id: String) -> void:
	G.add_journal("rule_slices", "Срезы времени", "У детали 2–3 сохранённых состояния: T−2, T−1, T0. Чтение срезов бесплатно.")
	refresh()
	if not seen.has("slices"):
		seen["slices"] = true
		await Popups.note(overlay, "Срезы — прошлое детали: T−2 давно, T−1 позже, T0 сейчас. Найдите срез, где поломка появилась впервые, и кликните по нему.", {"pos": Vector2(960, 760)})

func _on_slice(id: String, age: int) -> void:
	var st: Dictionary = G.m[id]
	if st.diag:
		return
	if age == G.MODS[id].cause:
		await _on_cause_found(id, st)
	else:
		Sfx.play("bad", -8)
		var cause: int = G.MODS[id].cause
		var msg := "На этом срезе поломки ещё нет — смотрите позже." if age > cause else "Здесь поломка уже есть. Найдите самый ранний срез, где она появилась."
		scanner.say(msg, G.TERRA)

func _on_cause_found(id: String, st: Dictionary) -> void:
	st.diag = true
	Sfx.play("good", -6)
	G.add_journal("hist_" + id, G.mname(id), G.MODS[id].cause_text, "history")
	if id == "lid":
		G.add_journal("hist_founder", "Подпись основателя", "Лев Орлов подписал крышку в день открытия «Астры». Подпись — требование заказа.", "history")
	toast("Причина найдена · запись в журнале")
	scanner.show_module(id)
	terminal.show_module(id)
	refresh()
	if not seen.has("diag"):
		seen["diag"] = true
		await Popups.note(overlay, "Причина найдена — методы ремонта открыты. Цена и последствия видны заранее. Выберите метод в карточке и подтвердите.", {"pos": Vector2(960, 700), "arrow": Vector2(1600, 300)})

func apply_method(id: String, mid: String) -> void:
	if busy:
		return
	var md := _find_method(id, mid)
	if md.is_empty():
		return
	if mid == "tune":
		_flash_regs()
		if G.journal.has("rule_phase"):
			toast("Фаза = возраст детали: T−2 → 2, T−1 → 1, T0 → 0")
		else:
			toast("Настройте регуляторы внизу и протестируйте")
		return
	if not G.can_pay(md.cost):
		toast("Не хватает ресурсов")
		return
	busy = true
	refresh()
	var st: Dictionary = G.m[id]
	var ok := await _apply_repair(id, mid, md, st)
	if ok and id in ["gear", "spring"] and mid != "anchor":
		G.add_journal("rule_local", "Возврат локален", "Перематывается только выбранная деталь; соседние остаются в настоящем — фазы могут разойтись.")
	busy = false
	G.last_test = {} if ok and id != "lid" else G.last_test
	refresh()
	terminal.show_module(id)
	scanner.show_module(id)
	if ok and not G.cal_preview and id in ["gear", "spring"]:
		G.cal_preview = true
		await Popups.note(overlay, "Первый ремонт засчитан — сканер откалиброван! Новый режим «Предпросмотр конфликта»: в карточке метода теперь видно, какую фазу потребует деталь.", {"pos": Vector2(960, 560)})
	if ok and G.runs_ok() and G.tests == 0 and not seen.has("test"):
		seen["test"] = true
		await Popups.note(overlay, "Шестерня и пружина на месте. Нажмите «ТЕСТИРОВАТЬ» — тест бесплатен и покажет, что не так.", {"pos": Vector2(1000, 560), "arrow": Vector2(1450, 894)})

func _find_method(id: String, mid: String) -> Dictionary:
	for x in G.methods(id):
		if x.id == mid:
			return x
	return {}

func _apply_repair(id: String, mid: String, md: Dictionary, st: Dictionary) -> bool:
	var ok := true
	match [id, mid]:
		["gear", "ret2"]:
			G.pay(md.cost)
			refresh()
			await clock.play_chrono("gear", "gear_ghost")
			st.fixed = true; st.via = "ret2"; st.age = 2
			G.decisions.append("Шестерня: родная, возвращена из T−2")
		["gear", "analog"]:
			ok = await _mini("analog")
			if ok:
				G.pay(md.cost)
				st.fixed = true; st.via = "analog"; st.age = 0
				Sfx.play("lock", -4)
				G.decisions.append("Шестерня: стальной аналог")
		["spring", "ret2"]:
			G.pay(md.cost)
			refresh()
			await clock.play_chrono("spring", "spring_ghost")
			st.fixed = true; st.via = "ret2"; st.age = 2
			G.decisions.append("Пружина: возвращена из T−2")
		["spring", "manual"]:
			ok = await _mini("spring")
			if ok:
				G.pay(md.cost)
				st.fixed = true; st.via = "manual"; st.age = 0
				G.decisions.append("Пружина: собрана вручную по меткам")
		["spring", "ret1a"]:
			G.pay(md.cost)
			refresh()
			await clock.play_chrono("spring", "spring_ghost")
			st.fixed = true; st.via = "ret1a"; st.age = 1; st.anchored = true
			Sfx.play("lock", -2)
			_add_anchor_journal()
			G.decisions.append("Пружина: возврат к T−1 под якорем")
		[_, "anchor"]:
			G.pay(md.cost)
			st.anchored = true
			Sfx.play("lock", -2)
			_add_anchor_journal()
			G.decisions.append("%s: закреплена якорем" % G.mname(id))
		["lid", "clean"]:
			G.pay(md.cost)
			refresh()
			await clock.play_chrono("lid", "lid_clean")
			st.via = "clean"
			G.decisions.append("Крышка: хроно-очистка, подпись цела")
		["lid", "leave"]:
			st.via = "leave"
			Sfx.play("good", -6)
			G.decisions.append("Крышка: оставлена как есть, подпись цела")
		["lid", "replace"]:
			ok = await _replace_lid(md)
	if id == "lid" and mid == "replace" and ok:
		pass
	return ok

func _add_anchor_journal() -> void:
	G.add_journal("rule_anchor", "Якорь", "Якорь притягивает фазу модуля к настоящему (регулятор = 0) и защищает от импульса помехи.")

func _replace_lid(md: Dictionary) -> bool:
	var pick := await Popups.choose(overlay, "Подпись будет утеряна", "Новая крышка блестит, но подписи основателя на ней не будет. Заказчица просила её сохранить. Заменить всё равно?", [
		{"title": "Не заменять", "sub": "Вернуться к выбору", "icon": "leave"},
		{"title": "Заменить крышку", "sub": "−1 материал · подпись утеряна · −подлинность", "icon": "replace"}], G.demo_pick)
	if pick == 1:
		G.pay(md.cost)
		G.m.lid.via = "replace"
		Sfx.play("lock", -4)
		G.decisions.append("Крышка: заменена, подпись утеряна")
		return true
	return false

func _mini(kind: String) -> bool:
	var mg: MiniGame = MINIGAME_SCENE.instantiate()
	mg.theme = G.theme
	overlay.add_child(mg)
	var r: bool = await mg.open(kind)
	return r

func _flash_regs() -> void:
	bench.flash_regs()

func set_reg(i: int, d: int) -> void:
	if busy or G.reg_locked(i):
		return
	G.regs[i] = clampi(G.regs[i] + d, 0, 2)
	Sfx.play("tick", -4)
	if G.last_test.has("reg_ok"):
		G.last_test.erase("reg_ok")
		G.last_test["sync"] = false
	refresh()

func run_test() -> void:
	busy = true
	refresh()
	G.tests += 1
	var run := G.runs_ok()
	var reg_ok := _reg_results()
	var sync: bool = run and reg_ok[0] and reg_ok[1] and reg_ok[2]
	var sig := G.signature_kept()
	Sfx.play("clock_tick", -2)
	if run and sync:
		clock.running = true
	elif run:
		clock.jitter = true
	await get_tree().create_timer(2.2).timeout
	_show_chain(run, reg_ok)
	terminal.show_test({"rows": _test_rows(run, sync, reg_ok, sig)})
	_apply_test_result(run, sync)
	clock.running = sync
	clock.jitter = false
	busy = false
	refresh()
	if G.auto:
		await G.shot("test_%d" % G.tests)
	await _test_notes(run, sync)
	if G.tests == 1 and not G.jolt_done:
		await get_tree().create_timer(0.6).timeout
		await jolt()
	if sync and G.m.lid.via == "" and not seen.has("lid_remind"):
		seen["lid_remind"] = true
		toast("Часы идут! Осталась крышка с подписью")

func _reg_results() -> Array:
	var tg := G.targets()
	var reg_ok := []
	for i in 3:
		reg_ok.append(G.reg_locked(i) or G.regs[i] == tg[i])
	return reg_ok

func _show_chain(run: bool, reg_ok: Array) -> void:
	var segs := []
	segs.append(["gear", "spring", G.GOOD if run else G.BAD])
	segs.append(["spring", "block", G.GOOD if (run and reg_ok[0] and reg_ok[1]) else G.BAD])
	segs.append(["block", "hands", G.GOOD if (run and reg_ok[2]) else G.BAD])
	clock.set_chain(segs, 6.0)

func _test_rows(run: bool, sync: bool, reg_ok: Array, sig: bool) -> Array:
	var rows := []
	rows.append(["Ход", run, _why_run(run)])
	rows.append(["Синхронизация", sync, _why_sync(run, sync, reg_ok)])
	rows.append(["Сохранность заказа", sig and G.m.lid.via != "", _why_sig(sig)])
	return rows

func _why_run(run: bool) -> String:
	if run:
		return "Шестерня и пружина передают усилие."
	var miss := []
	if not G.m.gear.fixed:
		miss.append("шестерня с трещиной")
	if not G.m.spring.fixed:
		miss.append("пружина не в гнезде")
	return "Цепь «пружина → шестерня» разорвана: " + ", ".join(miss) + "."

func _why_sync(run: bool, sync: bool, reg_ok: Array) -> String:
	if run and not sync:
		var bad := []
		var nm := ["шестерни", "пружины", "стрелок"]
		for i in 3:
			if not reg_ok[i]:
				var src := ""
				if i == 0 and G.m.gear.fixed:
					src = " (деталь из %s)" % G.AGE_NAME[G.m.gear.age]
				if i == 1 and G.m.spring.fixed:
					src = " (деталь из %s)" % G.AGE_NAME[G.m.spring.age]
				bad.append("фаза " + nm[i] + src)
		return "Стрелки дрожат: не совпадает " + ", ".join(bad) + "."
	elif not run:
		return "Нельзя проверить без хода."
	return "Все три фазы совпадают — стрелки идут ровно."

func _why_sig(sig: bool) -> String:
	if not sig:
		return "Крышка заменена — подписи нет."
	elif G.m.lid.via == "":
		return "Подпись цела, но судьба крышки ещё не решена."
	return "Подпись основателя на месте."

func _apply_test_result(run: bool, sync: bool) -> void:
	if run and not sync:
		G.stability = maxf(30, G.stability - 8)
	if sync and not G.last_test.get("ever_sync", false):
		G.stability = minf(100, G.stability + 15)
	G.last_test = {"run": run, "sync": sync, "reg_ok": _reg_results(), "ever_sync": sync or G.last_test.get("ever_sync", false)}
	if sync:
		Sfx.play("good", -4)
	else:
		Sfx.play("bad", -6)

func _test_notes(run: bool, sync: bool) -> void:
	if run and not sync and not G.journal.has("rule_phase"):
		G.add_journal("rule_phase", "Фаза = возраст детали", "Регулятор показывает возраст детали: T−2 → 2, T−1 → 1, T0 → 0. Стрелки всегда 0. Модуль под якорем — 0.")
		await Popups.note(overlay, "Детали целы, но спорят: шестерня и пружина «живут» в разном времени. Правило: регулятор = возраст детали (T−2 → 2, T−1 → 1, T0 → 0), стрелки — всегда 0. Якорь ставит модуль в 0.", {"pos": Vector2(960, 430)})
	if sync and not G.cal_overlay:
		G.cal_overlay = true
		G.add_journal("rule_overlay", "Наложение срезов", "Сканер откалиброван второй раз: на регуляторах видна нужная фаза (бирюзовая метка).")
		await Popups.note(overlay, "Синхронизация! Сканер откалиброван ещё раз: режим «Наложение срезов» подсвечивает нужную фазу на регуляторах. Записано в журнал.", {"pos": Vector2(960, 430)})


func jolt() -> void:
	busy = true
	refresh()
	G.jolt_done = true
	Sfx.play("glitch", 0)
	glitch.flash(1.6)
	clock.shake(10)
	await get_tree().create_timer(0.5).timeout
	var sp: Dictionary = G.m.spring
	if not 2 in sp.lost:
		sp.lost.append(2)
	var saved: bool = sp.anchored
	if not saved:
		if sp.fixed:
			G.decisions.append("Помеха выбила пружину")
		sp.fixed = false
		sp.via = ""
		sp.age = 0
		G.last_test = {}
	G.stability = maxf(30, G.stability - 5)
	G.add_journal("rule_jolt", "Темпоральная помеха", "Помеха может стереть ранний срез и выбить незакреплённую деталь. Якорь защищает модуль.")
	clock.running = false
	busy = false
	if selected == "spring":
		scanner.show_module("spring")
	refresh()
	if G.auto:
		await G.shot("jolt")
	var txt := "Темпоральная помеха! Сканер потерял срез T−2 пружины, а импульс выбил её из гнезда. Старый план не сработает. Варианты: ручная сборка (1 материал) или возврат к T−1 — уставшая пружина держится только под якорем (1 заряд + якорь)."
	if saved:
		txt = "Темпоральная помеха! Сканер потерял срез T−2 пружины, но якорь удержал её на месте. Отличный расчёт!"
	await Popups.note(overlay, txt, {"pos": Vector2(960, 460), "button": "Новый план"})
	select("spring")


func submit() -> void:
	if not (G.last_test.get("sync", false) and G.regs_ok() and G.runs_ok()):
		toast("Сначала успешный тест: ход и синхронизация")
		return
	if G.m.lid.via == "":
		toast("Сначала решите судьбу крышки с подписью")
		select("lid")
		return
	busy = true
	in_order = false
	refresh()
	for id in ["gear", "spring"]:
		if G.m[id].via == "ret2" and not G.m[id].anchored:
			G.stability = maxf(30, G.stability - 8)
	clock.running = true
	clock.selected = ""
	Sfx.play("clock_tick", -2)
	Sfx.play("fanfare", -6)
	if G.drv:
		G.cap("Сдача заказа: часы идут, письмо заказчицы, отчёт")
	await get_tree().create_timer(1.6).timeout
	await Popups.note(overlay, G.vera_letter(), {"who": "Вера Орлова", "pos": Vector2(960, 470), "button": "К отчёту"})
	var res: String = await report_screen.open()
	if res == "":
		return
	await _fade_out(0.5)
	G.skip_menu = res == "again"
	get_tree().reload_current_scene()


func open_journal() -> void:
	if journal_screen.visible:
		return
	journal_screen.open()

func open_pause() -> void:
	if pause_menu.visible or not in_order:
		return
	get_tree().paused = true
	pause_menu.open()

func _close_pause() -> void:
	get_tree().paused = false
	pause_menu.close()

func _restart_order() -> void:
	get_tree().paused = false
	G.skip_menu = true
	get_tree().reload_current_scene()

func _to_main_menu() -> void:
	get_tree().paused = false
	G.skip_menu = false
	get_tree().reload_current_scene()

func toast(text: String) -> void:
	for c in top.get_children():
		if c is PanelContainer and c.has_meta("toast"):
			c.queue_free()
	var p := PanelContainer.new()
	p.set_meta("toast", true)
	p.add_theme_stylebox_override("panel", UI.sb(G.INK, 8, 12, 4, G.CYAN, 20))
	var hb := UI.hbox(12)
	p.add_child(hb)
	hb.add_child(UI.icon_rect("journal", 36))
	hb.add_child(UI.label(text, 24, G.CREAM, G.f_ui_b))
	top.add_child(p)
	await get_tree().process_frame
	if not is_instance_valid(p):
		return
	p.position = Vector2(960 - p.size.x / 2, 112)
	p.modulate.a = 0
	var tw := p.create_tween()
	tw.tween_property(p, "modulate:a", 1.0, 0.2)
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.4)
	tw.tween_callback(p.queue_free)
