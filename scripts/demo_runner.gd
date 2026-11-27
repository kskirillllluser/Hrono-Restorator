extends Node
class_name DemoRunner


var main: Node = null


func run(demo: String) -> void:
	match demo:
		"core1":
			await demo_core1()
		"core2":
			await demo_core2()
		"gameloop":
			await demo_gameloop()
		"userflow":
			for k in ["scan", "slices", "diag", "test", "lid", "lid_remind"]:
				main.seen[k] = true
			G.drv.speed(1.5)
			main.open_title()
			return
		"methods":
			await demo_methods()
	main.get_tree().quit()


func run_userflow() -> void:
	G.cap("Ремонт: скан → причина → метод")
	await sel("gear")
	await scan()
	await slice("gear", 1)
	await method("gear", "ret2")
	await sel("spring")
	await scan()
	await slice("spring", 0)
	G.cap("Ручная сборка пружины: в гнездо и повернуть по меткам")
	await method("spring", "manual")
	G.cap("Тест → помеха → новый план")
	await test()
	await idle(0.4)
	await method("spring", "ret1a")
	G.cap("Синхронизация фаз")
	await sel("block")
	await scan()
	await slice("block", 1)
	await regs()
	await test()
	G.cap("Финальный выбор по крышке → сдача")
	await sel("lid")
	await scan()
	await slice("lid", 1)
	await method("lid", "leave")
	await G.drv.click(main.bench.submit_btn)

func demo_core1() -> void:
	demo_setup(true)
	G.drv.speed(1.0)
	G.cap("Core Loop: деталь → срезы прошлого → причина → метод → хроно-возврат")
	await w(1.0)
	await sel("gear")
	await scan()
	G.cap("Ищем срез, где трещина появилась впервые")
	await slice("gear", 0)
	await w(0.8)
	await slice("gear", 1)
	G.cap("Причина найдена — методы открыты; цена видна до подтверждения")
	await method("gear", "ret2")
	G.cap("«Призрак» T−2 материализуется: шестерня целая, −2 заряда")
	await w(2.5)

func demo_core2() -> void:
	demo_setup(true)
	for id in ["gear", "spring"]:
		G.m[id].scanned = true; G.m[id].diag = true; G.m[id].fixed = true; G.m[id].via = "ret2"; G.m[id].age = 2
	G.charge = 0
	G.jolt_done = true
	G.cal_preview = true
	G.add_journal("rule_phase", "Фаза = возраст детали", "Регулятор показывает возраст детали: T−2 → 2, T−1 → 1, T0 → 0. Стрелки всегда 0. Модуль под якорем — 0.")
	main.refresh()
	G.drv.speed(1.0)
	G.cap("Core Loop 2: тест → сбойная цепь → фазы и якорь → повторный тест")
	await w(1.0)
	await test()
	G.cap("Стрелки дрожат: детали из T−2 спорят с настоящим")
	await w(2.0)
	await sel("gear")
	G.cap("Якорь притягивает фазу шестерни к настоящему — её регулятор встаёт сам")
	await method("gear", "anchor")
	G.cap("Регуляторы: пружина из T−2 → 2, стрелки → 0")
	await regs()
	await w(0.6)
	await test()
	G.cap("Синхронизация — часы идут ровно")
	await w(2.5)

func demo_gameloop() -> void:
	demo_setup(true)
	for id in ["gear", "spring", "block", "lid"]:
		G.m[id].scanned = true; G.m[id].diag = true
	main.refresh()
	G.drv.speed(1.5)
	G.cap("Game Loop: заказ «АСТРА-01» — детали продиагностированы, выбираем методы")
	await w(1.0)
	await sel("gear")
	await method("gear", "ret2")
	await sel("spring")
	await method("spring", "ret2")
	G.cap("Тест: ход есть, но фазы спорят")
	await test()
	G.cap("Темпоральная помеха: срез T−2 потерян, пружину выбило — новый план")
	await idle(0.5)
	await method("spring", "manual")
	await sel("gear")
	await method("gear", "anchor")
	G.cap("Синхронизация: пружина T0 → 0, стрелки → 0")
	await regs()
	await test()
	G.cap("Финальный выбор: крышка с подписью")
	await sel("lid")
	await method("lid", "leave")
	G.cap("Сдача заказа: часы идут, письмо заказчицы")
	await G.drv.click(main.bench.submit_btn)
	await w(6.0)

func demo_methods() -> void:
	demo_setup(true)
	G.drv.speed(1.0)
	G.cap("Механика «Выбор метода»: одна деталь — три способа и разная цена")
	await w(1.0)
	await sel("lid")
	await scan()
	await slice("lid", 1)
	G.cap("Хроно-очистка: 1 заряд, подпись цела, подлинность высокая")
	await method("lid", "clean", false)
	await w(1.2)
	await G.drv.click(main.terminal.cancel_btn)
	await w(0.4)
	G.cap("Оставить как есть: бесплатно, царапины — часть истории")
	await method("lid", "leave", false)
	await w(1.2)
	await G.drv.click(main.terminal.cancel_btn)
	await w(0.4)
	G.cap("Замена: 1 материал, подпись будет утеряна — игра предупреждает")
	G.demo_pick = 0
	await method("lid", "replace")
	G.cap("Выбираем бережно: хроно-очистка поверхности")
	await method("lid", "clean")
	await w(2.5)

func demo_setup(skip_notes: bool) -> void:
	G.reset_order()
	G.runs = 1
	if skip_notes:
		for k in ["order", "scan", "slices", "diag", "test", "lid", "lid_remind"]:
			main.seen[k] = true
	main.fade.color.a = 0
	main._set_ui_visible(true)
	main.in_order = true
	Sfx.music("music_lab")
	main.refresh()


func auto_play() -> void:
	if "b" in OS.get_cmdline_user_args():
		await auto_play_b()
		return
	await w(0.5)
	await auto_fix("gear", "ret2")
	await G.shot("after_gear")
	await auto_fix("spring", "ret2")
	await main.run_test()
	await w(0.6)
	await G.shot("after_jolt")
	await auto_fix("spring", "manual")
	await auto_fix("gear", "anchor")
	main.select("block")
	await w(0.3)
	if not G.m.block.scanned:
		await main.scanner.do_scan()
	await main._on_slice("block", G.MODS.block.cause)
	await set_regs()
	await G.shot("regs_set")
	await main.run_test()
	await w(0.5)
	await auto_fix("lid", "leave")
	main.open_journal()
	await w(1.0)
	await main.submit()

func auto_play_b() -> void:
	await w(0.5)
	await auto_fix("gear", "analog")
	await auto_fix("spring", "manual")
	await main.run_test()
	await w(0.6)
	await auto_fix("spring", "ret1a")
	await G.shot("b_after_ret1a")
	await set_regs()
	await main.run_test()
	await G.shot("b_test2")
	await auto_fix("lid", "clean")
	await main.submit()


func auto_fix(id: String, mid: String) -> void:
	await main.select(id)
	await w(0.3)
	if not G.m[id].scanned:
		await main.scanner.do_scan()
		await w(0.4)
	if not G.m[id].diag:
		var wrong: int = (G.MODS[id].cause + 1) % 3
		await main._on_slice(id, wrong)
		await w(0.3)
		await G.shot("scan_wrong_" + id)
		await main._on_slice(id, G.MODS[id].cause)
		await w(0.3)
	await G.shot("card_" + id)
	await main.apply_method(id, mid)
	await w(0.5)

func set_regs() -> void:
	var tg := G.targets()
	for i in 3:
		while G.regs[i] != tg[i] and not G.reg_locked(i):
			main.set_reg(i, 1 if G.regs[i] < tg[i] else -1)
			await w(0.1)


func idle(extra := 0.3) -> void:
	await main.get_tree().process_frame
	while main.busy or G.notes > 0:
		await main.get_tree().process_frame
	await w(extra)

func sel(id: String) -> void:
	await G.drv.click(main.clock.hit(id))
	await idle(0.5)

func scan() -> void:
	await G.drv.click(main.scanner.scan_btn)
	await w(1.2)
	await idle(0.4)

func slice(_id: String, age: int) -> void:
	await G.drv.click(main.scanner.card_for_age(age))
	await idle(0.9)

func method(_id: String, mid: String, confirm := true) -> void:
	await G.drv.click(main.terminal.method_btns[mid])
	await w(1.4)
	if confirm and main.terminal.confirm_btn:
		await G.drv.click(main.terminal.confirm_btn)
	await w(0.3)
	await idle(0.6)

func test() -> void:
	await G.drv.click(main.bench.test_btn)
	await w(0.5)
	await idle(1.2)

func regs() -> void:
	var tg := G.targets()
	for i in 3:
		while G.regs[i] != tg[i] and not G.reg_locked(i):
			await G.drv.click(main.bench.dial_buttons()[i][1 if G.regs[i] < tg[i] else 0], 0.3)
			await w(0.35)

func w(t: float) -> void:
	await main.get_tree().create_timer(t).timeout
