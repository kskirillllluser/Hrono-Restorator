extends Control
class_name JournalScreen

@onready var panel: Panel = $Panel

func _ready() -> void:
	_apply_styles()
	$Panel/CloseButton.pressed.connect(close)

func _apply_styles() -> void:
	panel.add_theme_stylebox_override("panel", UI.sb(Color("223056"), 8, 18, 6, G.MUSTARD, 0))
	UI.style($Panel/Heading, 26, G.MUSTARD, G.f_retro)
	UI.style($Panel/Sub, 20, G.CREAM)
	UI.style($Panel/RulesCaption, 18, G.CYAN, G.f_retro)
	UI.style($Panel/HistoryCaption, 18, G.CYAN, G.f_retro)
	UI.apply_button_style($Panel/CloseButton, "primary", 24)

func open() -> void:
	visible = true
	$Panel/Heading.text = "ЖУРНАЛ РЕСТАВРАТОРА · %d/11" % G.journal.size()
	$Panel/Sub.text = "Записи сохраняются между заказами. Режимы сканера: «Предпросмотр конфликта» %s · «Наложение срезов» %s" % ["есть" if G.cal_preview else "—", "есть" if G.cal_overlay else "—"]
	_fill_list($Panel/RulesList, "rule")
	_fill_list($Panel/HistoryList, "history")
	UI.appear(panel, 30)
	Sfx.play("page", -4)
	if G.auto:
		await get_tree().create_timer(0.6).timeout
		await G.shot("journal")
		close()

func close() -> void:
	visible = false

func _fill_list(list: VBoxContainer, kind: String) -> void:
	for c in list.get_children():
		c.queue_free()
	for k in G.journal:
		var e: Dictionary = G.journal[k]
		if e.kind != kind:
			continue
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", UI.sb(G.SCREEN, 8, 0, 3, Color(G.CYAN, 0.4), 14))
		var rv := UI.vbox(2)
		row.add_child(rv)
		rv.add_child(UI.label(e.title, 21, G.MUSTARD, G.f_ui_b))
		var tl := UI.label(e.text, 18, G.CREAM, G.f_ui, HORIZONTAL_ALIGNMENT_LEFT, true)
		tl.custom_minimum_size = Vector2(600, 0)
		rv.add_child(tl)
		list.add_child(row)
