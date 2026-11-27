extends Control
class_name Bench

signal reg_changed(index: int, delta: int)
signal test_pressed
signal submit_pressed
signal order_pressed
signal journal_pressed

@onready var tik_sprite: TextureRect = $TikBox/TikSprite
@onready var tik_text: Label = $TikBox/TikBubble/TikText
@onready var reg_box: Panel = $RegBox
@onready var test_btn: Button = $ActBox/TestButton
@onready var submit_btn: Button = $ActBox/SubmitButton

var _dials: Array = []
var _dial_btns: Array = []
var _t := 0.0

func _ready() -> void:
	_dials = [$RegBox/DialGear, $RegBox/DialSpring, $RegBox/DialHands]
	_dial_btns = [[$RegBox/MinusGear, $RegBox/PlusGear], [$RegBox/MinusSpring, $RegBox/PlusSpring], [$RegBox/MinusHands, $RegBox/PlusHands]]
	_apply_styles()
	_connect_buttons()

func _apply_styles() -> void:
	$TikBox/TikBubble.add_theme_stylebox_override("panel", UI.sb(G.PANEL, 8, 10, 4, G.CYAN, 0))
	UI.style($TikBox/TikBubble/TikWho, 16, G.CYAN, G.f_retro)
	UI.style(tik_text, 23, G.CREAM, G.f_ui)
	reg_box.add_theme_stylebox_override("panel", UI.sb(Color("141b28"), 8, 10, 4, Color("3d4862"), 0))
	UI.style($RegBox/RegTitle, 14, G.CYAN, G.f_retro)
	var names := ["LabelGear", "LabelSpring", "LabelHands"]
	for i in 3:
		UI.style(reg_box.get_node(names[i]), 20, G.CREAM, G.f_ui_b)
	UI.apply_button_style(test_btn, "primary", 34, "test")
	test_btn.add_theme_font_override("font", G.f_retro)
	test_btn.add_theme_font_size_override("font_size", 22)
	UI.apply_button_style(submit_btn, "teal", 30, "letter")
	submit_btn.add_theme_font_override("font", G.f_retro)
	submit_btn.add_theme_font_size_override("font_size", 18)
	UI.apply_button_style($ActBox/OrderButton, "secondary", 22, "letter")
	UI.apply_button_style($ActBox/JournalButton, "secondary", 22, "journal")
	for pair in _dial_btns:
		for b in pair:
			UI.apply_button_style(b, "secondary", 26)

func _connect_buttons() -> void:
	for i in 3:
		var minus: Button = _dial_btns[i][0]
		var plus: Button = _dial_btns[i][1]
		minus.pressed.connect(func(): reg_changed.emit(i, -1))
		plus.pressed.connect(func(): reg_changed.emit(i, 1))
	test_btn.pressed.connect(func(): test_pressed.emit())
	submit_btn.pressed.connect(func(): submit_pressed.emit())
	$ActBox/OrderButton.pressed.connect(func(): order_pressed.emit())
	$ActBox/JournalButton.pressed.connect(func(): journal_pressed.emit())

func _process(delta: float) -> void:
	_t += delta
	tik_sprite.texture = G.tex("tik_blink" if fmod(_t, 4.0) < 0.12 else "tik")
	tik_sprite.position.y = 902 + (4 if fmod(_t, 2.0) < 1.0 else 0)

func dial_buttons() -> Array:
	return _dial_btns

func set_hint(text: String) -> void:
	tik_text.text = text

func set_ui_visible(on: bool) -> void:
	$TikBox.visible = on
	reg_box.visible = on
	$ActBox.visible = on

func refresh(busy: bool) -> void:
	for i in 3:
		(_dials[i] as RegulatorDial).queue_redraw()
		for b in _dial_btns[i]:
			b.disabled = G.reg_locked(i) or busy
	var can_submit: bool = G.last_test.get("sync", false) and G.regs_ok() and G.runs_ok()
	submit_btn.disabled = not can_submit or busy
	test_btn.disabled = busy

func flash_regs() -> void:
	var tw := create_tween()
	for k in 3:
		tw.tween_property(reg_box, "modulate", Color(1.6, 1.6, 1.6), 0.12)
		tw.tween_property(reg_box, "modulate", Color.WHITE, 0.12)
