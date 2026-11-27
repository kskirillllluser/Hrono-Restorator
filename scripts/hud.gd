extends Panel
class_name Hud

signal order_pressed
signal journal_pressed
signal menu_pressed

@onready var step_label: Label = $Step
@onready var resources: HBoxContainer = $Resources
@onready var stab_bar: Control = $StabilityBar
@onready var stab_value: Label = $StabilityValue

func _ready() -> void:
	_apply_styles()
	_connect_buttons()

func _apply_styles() -> void:
	add_theme_stylebox_override("panel", UI.sb(Color("141b28"), 8, 10, 4, Color("3d4862"), 0))
	UI.style($Title, 22, G.MUSTARD, G.f_retro)
	UI.style(step_label, 21, G.CREAM, G.f_ui)
	UI.style($StabilityCaption, 18, G.INK_SOFT, G.f_ui)
	UI.style(stab_value, 24, G.CREAM, G.f_ui_b)
	stab_bar.get_node("Back").add_theme_stylebox_override("panel", UI.sb(Color(1, 1, 1, 0.1), 8, 0, 0, Color.TRANSPARENT, 0))
	stab_bar.get_node("Fill").add_theme_stylebox_override("panel", UI.sb(G.CYAN, 8, 0, 0, Color.TRANSPARENT, 0))
	var icons := ["letter", "journal", "menu"]
	for i in 3:
		var b: Button = get_node("Hud" + icons[i].capitalize())
		UI.apply_button_style(b, "chalk", 22, icons[i])
		b.add_theme_constant_override("icon_max_width", 44)

func _connect_buttons() -> void:
	$HudLetter.pressed.connect(func(): order_pressed.emit())
	$HudJournal.pressed.connect(func(): journal_pressed.emit())
	$HudMenu.pressed.connect(func(): menu_pressed.emit())

func set_step(text: String) -> void:
	step_label.text = text

func set_stability(value: float) -> void:
	UI.set_bar(stab_bar, value / 100.0)
	stab_value.text = str(int(value))

func refresh_resources() -> void:
	for c in resources.get_children():
		c.queue_free()
	for k in [["charge", G.charge, 4, "Хроно-заряд: возврат детали в прошлое"], ["mat", G.mat, 3, "Материалы: ручной ремонт и замена"], ["anchor", G.anchor, 1, "Якорь: фиксирует модуль"]]:
		var hb := UI.hbox(2)
		hb.tooltip_text = k[3]
		hb.mouse_filter = Control.MOUSE_FILTER_PASS
		for n in k[2]:
			var ic := UI.icon_rect(k[0], 44)
			ic.modulate = Color.WHITE if n < k[1] else Color(1, 1, 1, 0.18)
			hb.add_child(ic)
		resources.add_child(hb)
		var sp := Control.new()
		sp.custom_minimum_size = Vector2(22, 0)
		resources.add_child(sp)
