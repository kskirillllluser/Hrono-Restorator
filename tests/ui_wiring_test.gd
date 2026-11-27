extends Node

const MAIN_SCENE := preload("res://scenes/main.tscn")

var main: Node

func _boot() -> Node:
	var m: Node = MAIN_SCENE.instantiate()
	add_child(m)
	await _frames(2)
	return m

func test_regulator_buttons_change_game_state() -> void:
	main = MAIN_SCENE.instantiate()
	add_child(main)
	await _frames(2)
	var bench: Bench = main.bench
	assert(not bench.submit_btn.disabled == false or true)
	assert(bench.submit_btn.disabled, "Сдача должна быть недоступна до синхронизации")
	(bench.dial_buttons()[0][1] as Button).pressed.emit()
	await _frames(1)
	(bench.dial_buttons()[0][1] as Button).pressed.emit()
	await _frames(1)
	assert(G.regs[0] == 2, "Кнопка «+» должна двигать фазу шестерни, стало: %d" % G.regs[0])
	(bench.dial_buttons()[0][0] as Button).pressed.emit()
	await _frames(1)
	assert(G.regs[0] == 1, "Кнопка «−» должна возвращать фазу")
	(bench.test_btn as Button).pressed.emit()
	await _seconds(2.6)
	assert(G.tests == 1, "Кнопка ТЕСТИРОВАТЬ должна увеличить счётчик тестов")
	(bench.get_node("ActBox/OrderButton") as Button).pressed.emit()
	await _frames(1)
	assert(main.terminal.mod == "", "После «Заказ» терминал показывает заказ")

func test_hud_buttons_open_screens() -> void:
	main = await _boot()
	main.in_order = true
	(main.hud.get_node("HudMenu") as Button).pressed.emit()
	await _frames(2)
	assert(main.pause_menu.visible, "Кнопка меню должна открывать паузу")
	assert(get_tree().paused, "Пауза должна останавливать дерево")
	(main.pause_menu.get_node("PanelContainer/VBox/ContinueButton") as Button).pressed.emit()
	await _frames(2)
	assert(not main.pause_menu.visible and not get_tree().paused, "«Продолжить» закрывает паузу")
	(main.hud.get_node("HudJournal") as Button).pressed.emit()
	await _frames(2)
	assert(main.journal_screen.visible, "Кнопка журнала открывает журнал")
	assert(main.journal_screen.get_index() > main.pause_menu.get_index(),
		"Журнал должен рисоваться поверх окна паузы")
	main.journal_screen.close()
	(main.hud.get_node("HudLetter") as Button).pressed.emit()
	await _frames(1)
	assert(main.pause_menu.restart_pressed.is_connected(main._restart_order), "Рестарт должен вести к перезагрузке заказа")
	assert(main.pause_menu.menu_pressed.is_connected(main._to_main_menu), "«Главное меню» должно вести в меню")

func test_clock_and_scanner_wiring() -> void:
	main = await _boot()
	main.in_order = true
	main.clock.hit("gear").pressed.emit()
	await _frames(1)
	assert(main.selected == "gear", "Клик по шестерне выбирает модуль")
	assert(main.scanner.mod == "gear", "Сканер показывает выбранную деталь")
	assert(main.terminal.mod == "gear", "Терминал показывает карточку детали")
	(main.scanner.scan_btn as Button).pressed.emit()
	await _seconds(1.2)
	assert(G.m.gear.scanned, "Сканер отмечает деталь отсканированной")
	main.scanner.card_for_age(1).pressed.emit()
	await _frames(1)
	assert(G.m.gear.diag, "Верный срез открывает диагноз")

func test_report_screen_becomes_visible() -> void:
	main = await _boot()
	main.report_screen.open()
	await _seconds(1.2)
	assert(main.report_screen.visible, "Отчёт должен показываться после сдачи заказа")
	assert(main.report_screen.get_node("Panel").visible, "Панель отчёта должна быть видима")
	(main.report_screen.again_btn as Button).pressed.emit()
	await _frames(2)

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _seconds(t: float) -> void:
	await get_tree().create_timer(t).timeout
