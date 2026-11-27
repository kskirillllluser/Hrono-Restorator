extends Node2D

func _ready() -> void:
	G.reset_order()
	var hud: Hud = load("res://scenes/hud.tscn").instantiate()
	add_child(hud)
	hud.refresh_resources()
	hud.set_stability(G.stability)
	hud.set_step("Модулей готово: 0 из 4 · тестов: 0 · журнал: 0/11")
