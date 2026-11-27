extends Control
class_name IntroSequence

@onready var panels: Array = [$Panel1, $Panel2, $Panel3]

var _skip := false

func _ready() -> void:
	for p in panels:
		p.visible = false
	UI.style($SkipHint, 22, Color(G.CREAM, 0.5), G.f_ui)
	for i in panels.size():
		var p: Control = panels[i]
		UI.style(p.get_node("Caption"), 26, G.CREAM, G.f_ui)
		if p.has_node("Bubble"):
			var bl: Label = p.get_node("Bubble")
			UI.style(bl, 22, G.INK, G.f_ui_b)
			bl.add_theme_stylebox_override("normal", UI.sb(G.CREAM, 8, 6, 0, Color.TRANSPARENT, 14))
	$Dim.gui_input.connect(func(ev): if ev is InputEventMouseButton and ev.pressed: _skip = true)

func play() -> void:
	visible = true
	for p in panels:
		p.visible = true
		UI.appear(p, 30, 0.45)
		Sfx.play("page", -6)
		_skip = false
		var t := 0.0
		while t < (2.8 if not G.auto else 0.35) and not _skip:
			await get_tree().process_frame
			t += get_process_delta_time()
	if G.auto:
		await G.shot("intro")
	var t2 := 0.0
	_skip = false
	while t2 < (1.6 if not G.auto else 0.2) and not _skip:
		await get_tree().process_frame
		t2 += get_process_delta_time()
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.5)
	await tw.finished
	visible = false
	modulate.a = 1.0
