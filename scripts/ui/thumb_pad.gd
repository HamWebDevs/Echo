class_name ThumbPad
extends Control

var direction := Vector2.ZERO
var held := false
var origin := Vector2.ZERO
var pointer := Vector2.ZERO
var touch_id := -1

func _ready() -> void:
	custom_minimum_size.y = 150
	mouse_filter = Control.MOUSE_FILTER_STOP

func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed and touch_id < 0:
			touch_id = event.index
			held = true
			origin = event.position
			pointer = origin
		elif not event.pressed and event.index == touch_id:
			release()
		accept_event()
	elif event is InputEventScreenDrag and event.index == touch_id:
		pointer = event.position
		var movement := pointer - origin
		direction = movement.normalized() if movement.length() > 7 else Vector2.ZERO
		accept_event()
	queue_redraw()

func release() -> void:
	held = false
	touch_id = -1
	direction = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	draw_style_box(EchoStyle.box(Color("f5e5c5"), 22, EchoStyle.BORDER), Rect2(Vector2.ZERO, size))
	var center := origin if held else size / 2
	var displacement := (pointer - origin).limit_length(38) if held else Vector2.ZERO
	draw_circle(center, 48, Color(EchoStyle.MINT, 0.025))
	draw_arc(center, 44, 0, TAU, 64, Color(EchoStyle.MINT, 0.28 if held else 0.13), 1.5, true)
	for i in range(4):
		var axis := Vector2.from_angle(i * PI / 2)
		draw_line(center + axis * 53, center + axis * 58, Color(EchoStyle.MUTED, 0.35), 1, true)
	draw_circle(center + displacement, 17, Color(EchoStyle.MINT, 0.12 if held else 0.04))
	draw_arc(center + displacement, 17, 0, TAU, 32, Color(EchoStyle.MINT, 0.6 if held else 0.25), 1.5, true)
	CartoonArt.buddy(self, center + displacement, 18, 0, 0, false, 1.0 if held else 0.65)
