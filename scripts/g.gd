extends Node

const INK := Color("0e131d")
const INK_SOFT := Color("8d9ab3")
const CREAM := Color("e6edf7")
const PAPER := Color("1a2232")
const MUSTARD := Color("f5b54a")
const TERRA := Color("e2584e")
const TEAL := Color("2a9a9a")
const CYAN := Color("4fd1c5")
const CYAN_L := Color("a8fff2")
const LILAC := Color("aa82fa")
const ROSE := Color("e58296")
const GOOD := Color("4fae7f")
const BAD := Color("e2584e")
const SCREEN := Color("08121a")
const PANEL := Color("1a2232")
const STEEL := Color("63718e")
const BRASS := Color("cf9b45")

var f_ui: FontVariation
var f_ui_b: FontVariation
var f_head: FontVariation
var f_hand: FontVariation
var f_retro: FontVariation
var theme: Theme
var _icons := {}

var auto := false
var shots_dir := ""
var skip_menu := false
var volume := 0.8
var demo := ""
var drv: DemoDriver = null
var start_msec := 0
var notes := 0
var demo_pick := 0

var journal := {}
var cal_preview := false
var cal_overlay := false
var runs := 0
var profiles_seen := {}

const MOD_ORDER := ["gear", "spring", "block", "lid"]
const AGE_NAME := {2: "T−2", 1: "T−1", 0: "T0"}

const MODS := {
	"gear": {"name": "Шестерня", "problem": "трещина — часы стоят", "cause": 1,
		"slices": [
			{"age": 2, "spr": "gear_ok", "text": "Целая, 14 зубцов. День открытия станции."},
			{"age": 1, "spr": "gear_hairline", "text": "Трещинка у зуба. Год стыковки «Зари»."},
			{"age": 0, "spr": "gear_dusty", "text": "Трещина насквозь. Часы встали."}],
		"cause_text": "Трещина появилась в год стыковки «Зари»: перегрузка механизма."},
	"spring": {"name": "Пружина", "problem": "сместилась из гнезда", "cause": 0,
		"slices": [
			{"age": 2, "spr": "spring_ok", "text": "Плотная, точно в гнезде."},
			{"age": 1, "spr": "spring_weak", "text": "Металл устал, но пружина на месте."},
			{"age": 0, "spr": "spring_displaced", "text": "Выбита из гнезда при переноске."}],
		"cause_text": "Пружину выбило совсем недавно — при переноске в мастерскую."},
	"block": {"name": "Блок синхронизации", "problem": "фаза стрелок сбита", "cause": 1,
		"slices": [
			{"age": 2, "spr": "block_ok", "text": "Все три метки фаз совпадают."},
			{"age": 1, "spr": "block_slight", "text": "Метка стрелок сдвинута на 1."},
			{"age": 0, "spr": "block_mis", "text": "Метка стрелок сдвинута на 2."}],
		"cause_text": "Фаза стрелок начала сбиваться в год «Зари» — вместе с трещиной шестерни."},
	"lid": {"name": "Крышка с подписью", "problem": "царапины, подпись уязвима", "cause": 1,
		"slices": [
			{"age": 2, "spr": "lid_clean", "text": "Подпись свежая, металл блестит."},
			{"age": 1, "spr": "lid_light", "text": "Первые царапины на крышке."},
			{"age": 0, "spr": "lid_scratched", "text": "Глубокие царапины у подписи."}],
		"cause_text": "Царапины копились годами — крышку открывали на каждом юбилее."},
}

const ENDINGS := {
	"hist": {"title": "Историческая реставрация", "text": "Вы сохранили почти всё родное. Часы идут так, как шли в день открытия станции."},
	"care": {"title": "Бережная реставрация", "text": "Ни одного лишнего действия: часы идут, а запасы мастерской почти целы."},
	"prac": {"title": "Практичная реставрация", "text": "Надёжный ход и стабильный механизм. Часы прослужат ещё полвека."},
}

var charge := 4
var mat := 3
var anchor := 1
var stability := 80.0
var m := {}
var regs := [0, 0, 2]
var tests := 0
var jolt_done := false
var last_test := {}
var submitted := false
var decisions: Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if "--demo" in args:
		demo = args[args.find("--demo") + 1]
	if "--shots" in args:
		auto = true
		var i := args.find("--shots")
		shots_dir = args[i + 1] if i + 1 < args.size() and not args[i + 1].begins_with("--") else OS.get_user_data_dir()
	_build_fonts()
	_build_theme()
	for n in ["charge", "mat", "anchor", "stab", "scan", "ret", "manual", "replace", "test", "journal", "ok", "no", "warn", "clean", "leave", "lost", "menu", "eye", "letter"]:
		icon(n)
	reset_order()

const FONT_PATH := "res://fonts/ScienceGothic-VariableFont_CTRS,slnt,wdth,wght.ttf"

func _build_fonts() -> void:
	var ts := TextServerManager.get_primary_interface()
	var wght := ts.name_to_tag("wght")
	var slnt := ts.name_to_tag("slnt")
	f_ui = _var(FONT_PATH, {wght: 500})
	f_ui_b = _var(FONT_PATH, {wght: 700})
	f_head = _var(FONT_PATH, {wght: 700})
	f_hand = _var(FONT_PATH, {wght: 500, slnt: -10.0})
	var wdth := ts.name_to_tag("wdth")
	f_retro = _var(FONT_PATH, {wght: 800, wdth: 125})

func _var(path: String, variation: Dictionary) -> FontVariation:
	var fv := FontVariation.new()
	var ff: FontFile = load(path)
	ff.hinting = TextServer.HINTING_NONE
	ff.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	fv.base_font = ff
	fv.variation_opentype = variation
	return fv

func _build_theme() -> void:
	theme = Theme.new()
	theme.default_font = f_ui
	theme.default_font_size = 24
	theme.set_color("font_color", "Label", CREAM)
	theme.set_stylebox("panel", "TooltipPanel", UI.sb(INK, 8, 6, 3, CYAN, 16))
	theme.set_color("font_color", "TooltipLabel", CREAM)
	theme.set_font_size("font_size", "TooltipLabel", 22)

func icon(key: String) -> Texture2D:
	if not _icons.has(key):
		_icons[key] = load("res://pix/icons/%s.png" % key)
	return _icons[key]

func tex(key: String) -> Texture2D:
	return load("res://pix/%s.png" % key)

func reset_order() -> void:
	charge = 4
	mat = 3
	anchor = 1
	stability = 80.0
	regs = [0, 0, 2]
	tests = 0
	jolt_done = false
	last_test = {}
	submitted = false
	decisions.clear()
	m.clear()
	for id in MOD_ORDER:
		m[id] = {"fixed": false, "via": "", "age": 0, "diag": false, "anchored": false, "scanned": false, "lost": []}
	start_msec = Time.get_ticks_msec()

func mname(id: String) -> String:
	return MODS[id].name

func targets() -> Array:
	var tg := [0, 0, 0]
	if m.gear.fixed and not m.gear.anchored:
		tg[0] = m.gear.age
	if m.spring.fixed and not m.spring.anchored:
		tg[1] = m.spring.age
	return tg

func reg_locked(i: int) -> bool:
	return (i == 0 and m.gear.anchored) or (i == 1 and m.spring.anchored)

func regs_ok() -> bool:
	var tg := targets()
	for i in 3:
		if not reg_locked(i) and regs[i] != tg[i]:
			return false
	return true

func runs_ok() -> bool:
	return m.gear.fixed and m.spring.fixed

func signature_kept() -> bool:
	return m.lid.via != "replace"

func methods(id: String) -> Array:
	var r: Array = []
	var st: Dictionary = m[id]
	match id:
		"gear":
			if not st.fixed:
				r.append({"id": "ret2", "title": "Хроно-возврат к T−2", "icon": "ret", "cost": {"charge": 2}, "text": "Вернёт родную целую шестерню. Подлинность сохранится.", "phase": 2})
				r.append({"id": "analog", "title": "Замена аналогом", "icon": "replace", "cost": {"mat": 1}, "text": "Стальная шестерня из шкафа. Стабильно, но подлинность ниже.", "phase": 0})
			elif st.via == "ret2" and not st.anchored:
				r.append({"id": "anchor", "title": "Закрепить якорем", "icon": "anchor", "cost": {"anchor": 1}, "text": "Притянет фазу шестерни к настоящему: её регулятор встанет сам.", "phase": 0})
		"spring":
			if not st.fixed:
				if not 2 in st.lost:
					r.append({"id": "ret2", "title": "Хроно-возврат к T−2", "icon": "ret", "cost": {"charge": 2}, "text": "Плотная пружина из прошлого, точно в гнезде.", "phase": 2})
				r.append({"id": "manual", "title": "Ручная сборка по меткам", "icon": "manual", "cost": {"mat": 1}, "text": "Вставить и повернуть кольцо, пока метки не совпадут.", "phase": 0})
				if jolt_done:
					r.append({"id": "ret1a", "title": "Возврат к T−1 + якорь", "icon": "anchor", "cost": {"charge": 1, "anchor": 1}, "text": "Уставшая пружина держится только под якорем; её регулятор встанет сам.", "phase": 0})
			elif st.via == "ret2" and not st.anchored:
				r.append({"id": "anchor", "title": "Закрепить якорем", "icon": "anchor", "cost": {"anchor": 1}, "text": "Защитит пружину и притянет её фазу к настоящему.", "phase": 0})
		"block":
			r.append({"id": "tune", "title": "Настроить фазы регуляторами", "icon": "stab", "cost": {}, "text": "Бесплатно. Три регулятора внизу: фаза шестерни, пружины и стрелок.", "phase": -1})
		"lid":
			if st.via == "":
				r.append({"id": "clean", "title": "Хроно-очистка поверхности", "icon": "clean", "cost": {"charge": 1}, "text": "Вернёт блеск T−2 только верхнему слою. Подпись цела.", "phase": -1})
				r.append({"id": "leave", "title": "Оставить как есть", "icon": "leave", "cost": {}, "text": "Царапины — тоже история вещи. Подпись цела.", "phase": -1})
				r.append({"id": "replace", "title": "Заменить крышку", "icon": "replace", "cost": {"mat": 1}, "text": "Новая блестящая крышка. Подпись основателя будет утеряна!", "phase": -1, "warn": true})
	return r

func can_pay(cost: Dictionary) -> bool:
	return charge >= cost.get("charge", 0) and mat >= cost.get("mat", 0) and anchor >= cost.get("anchor", 0)

func pay(cost: Dictionary) -> void:
	charge -= cost.get("charge", 0)
	mat -= cost.get("mat", 0)
	anchor -= cost.get("anchor", 0)

func stuck() -> bool:
	if not m.gear.fixed and charge < 2 and mat < 1:
		return true
	if not m.spring.fixed:
		var ok: bool = mat >= 1 or (not 2 in m.spring.lost and charge >= 2) or (jolt_done and charge >= 1 and anchor >= 1)
		if not ok:
			return true
	return false

func add_journal(id: String, title: String, text: String, kind := "rule") -> bool:
	if journal.has(id):
		return false
	journal[id] = {"title": title, "text": text, "kind": kind}
	return true

func authenticity() -> float:
	var a := 0.0
	if m.gear.via == "ret2":
		a += 40
	if m.spring.via in ["ret2", "manual", "ret1a"]:
		a += 20
	match m.lid.via:
		"clean": a += 40
		"leave": a += 35
		"": a += 35
	return a

func economy() -> float:
	return clampf(charge / 4.0 * 50.0 + mat / 3.0 * 35.0 + anchor * 15.0, 0, 100)

func profile() -> String:
	if authenticity() >= 90:
		return "hist"
	if economy() >= 45:
		return "care"
	return "prac"

func vera_letter() -> String:
	match m.lid.via:
		"clean":
			return "Мой дед Лев Орлов подписал эту крышку в день открытия «Астры». Спасибо, что подпись снова блестит. Дедушка бы улыбнулся. — В. О."
		"replace":
			return "Часы идут — спасибо. Жаль, подписи деда больше нет… Но тиканье в зале будет напоминать о нём. — В. О."
		_:
			return "Вы оставили царапины — и правильно: каждая из них с какого-то нашего юбилея. Часы снова идут. Спасибо! — В. О."

func cap(text: String) -> void:
	if drv:
		drv.say(text)

func shot(fname: String) -> void:
	if not auto:
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(shots_dir.path_join(fname + ".png"))
	print("shot ", fname)
