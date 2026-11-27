extends Node

func _ready() -> void:
	G.reset_order()
	G.m.gear.fixed = true; G.m.gear.via = "ret2"; G.m.gear.age = 2
	G.m.spring.fixed = true; G.m.spring.via = "manual"
	G.m.lid.via = "leave"
	G.last_test = {"run": true, "sync": true, "reg_ok": [true, true, true], "ever_sync": true}
	G.decisions = ["Шестерня: родная, возвращена из T−2", "Пружина: собрана вручную по меткам", "Крышка: оставлена как есть, подпись цела"]
	var main: Node = load("res://scenes/main.tscn").instantiate()
	add_child(main)
	main.report_screen.open()
