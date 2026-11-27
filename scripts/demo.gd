extends Control
class_name DemoDriver

var cursor: TextureRect
var ring: TextureRect
var caption: Label
var speed_l: Label
var _speed := 1.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	caption = UI.label("", 26, G.CREAM, G.f_ui_b, HORIZONTAL_ALIGNMENT_CENTER)
	caption.add_theme_stylebox_override("normal", UI.sb(G.INK, 8, 10, 4, G.MUSTARD, 22))
	caption.position = Vector2(360, 1000)
	caption.size = Vector2(1200, 56)
	caption.visible = false
	add_child(caption)
	speed_l = UI.label("", 30, G.INK, G.f_retro, HORIZONTAL_ALIGNMENT_CENTER)
	speed_l.add_theme_stylebox_override("normal", UI.sb(G.MUSTARD, 8, 8, 0, Color.TRANSPARENT, 16))
	speed_l.position = Vector2(1700, 140)
	speed_l.size = Vector2(180, 56)
	speed_l.visible = false
	add_child(speed_l)
	ring = TextureRect.new()
	ring.texture = preload("res://pix/click_ring.png")
	ring.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ring.size = Vector2(64, 64)
	ring.visible = false
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ring)
	cursor = TextureRect.new()
	cursor.texture = preload("res://pix/cursor.png")
	cursor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	cursor.size = Vector2(36, 54)
	cursor.position = Vector2(960, 700)
	cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cursor)

func say(text: String) -> void:
	caption.text = text
	caption.visible = text != ""
	if text != "":
		caption.size = Vector2(1200, 56)
		caption.position.x = 960 - caption.size.x / 2

func speed(k: float) -> void:
	_speed = k
	Engine.time_scale = k
	speed_l.text = "×%d" % int(k) if k >= 2 else ""
	speed_l.visible = k >= 2

func wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout

func move_to(p: Vector2, dur := 0.45) -> void:
	var tw := create_tween()
	tw.tween_property(cursor, "position", p - Vector2(4, 2), dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

func _tap() -> void:
	ring.position = cursor.position + Vector2(4, 2) - ring.size / 2
	ring.visible = true
	ring.scale = Vector2(0.4, 0.4)
	ring.pivot_offset = ring.size / 2
	ring.modulate.a = 1
	var tw := create_tween().set_parallel()
	tw.tween_property(ring, "scale", Vector2(1.3, 1.3), 0.25)
	tw.tween_property(ring, "modulate:a", 0.0, 0.3)
	var t2 := create_tween()
	t2.tween_property(cursor, "scale", Vector2(0.85, 0.85), 0.06)
	t2.tween_property(cursor, "scale", Vector2.ONE, 0.08)
	Sfx.play("click", -4)
	await get_tree().create_timer(0.12).timeout

func center_of(c: Control) -> Vector2:
	return c.get_global_rect().get_center()

func click(c: Control, dur := 0.45) -> void:
	if not is_instance_valid(c):
		return
	await move_to(center_of(c), dur)
	await _tap()
	if is_instance_valid(c) and c is BaseButton:
		var b := c as BaseButton
		if b.toggle_mode:
			b.button_pressed = not b.button_pressed
		b.pressed.emit()


func click_point(p: Vector2, dur := 0.45) -> void:
	await move_to(p, dur)
	await _tap()

func drag(from: Control, to: Control, label_text: String, apply: Callable) -> void:
	await move_to(center_of(from), 0.4)
	await _tap()
	var ghost := UI.label(label_text, 24, G.INK, G.f_ui_b)
	ghost.add_theme_stylebox_override("normal", UI.sb(G.MUSTARD, 8, 10, 0, Color.TRANSPARENT, 16))
	add_child(ghost)
	move_child(ghost, cursor.get_index())
	ghost.position = cursor.position + Vector2(20, 20)
	var tw := create_tween().set_parallel()
	var target := center_of(to)
	tw.tween_property(cursor, "position", target, 0.55).set_trans(Tween.TRANS_SINE)
	tw.tween_property(ghost, "position", target + Vector2(20, 20), 0.55).set_trans(Tween.TRANS_SINE)
	await tw.finished
	ghost.queue_free()
	Sfx.play("pen", -6)
	apply.call()
	await get_tree().create_timer(0.15).timeout
