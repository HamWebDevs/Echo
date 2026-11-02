class_name ThumbPad
extends Control

# Input lives over the whole game. Buttons keep first refusal through GUI dispatch.
var direction := Vector2.ZERO
var held := false
var origin := Vector2.ZERO
var pointer := Vector2.ZERO
var touch_id := -1
var fixed := false
var active := true
var fixed_center := Vector2.ZERO
const RADIUS := 72.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		if held: release()
		return
	# Finish the captured gesture even if the finger is lifted over a HUD button.
	if event is InputEventScreenTouch and not event.pressed and event.index == touch_id:
		release()
	elif event is InputEventScreenDrag and event.index == touch_id:
		pointer = get_global_transform_with_canvas().affine_inverse() * event.position
		_update_direction()
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if not active or not is_visible_in_tree():
		return
	if event is InputEventScreenTouch and event.pressed and touch_id < 0:
		var local: Vector2 = get_global_transform_with_canvas().affine_inverse() * event.position
		if fixed and local.distance_to(fixed_center) > RADIUS + 28:
			return
		touch_id = event.index
		held = true
		origin = fixed_center if fixed else local
		pointer = local
		_update_direction()
		get_viewport().set_input_as_handled()

func _update_direction() -> void:
	var movement := pointer - origin
	direction = movement.normalized() if movement.length() > 9 else Vector2.ZERO
	queue_redraw()

func release() -> void:
	held = false
	touch_id = -1
	direction = Vector2.ZERO
	queue_redraw()

func _draw() -> void:
	if not held and not fixed:
		return
	var center := origin if held else fixed_center
	var displacement := (pointer - origin).limit_length(RADIUS * 0.7) if held else Vector2.ZERO
	draw_circle(center, RADIUS, Color("fff6df", 0.65 if held else 0.45))
	draw_arc(center, RADIUS, 0, TAU, 64, Color(CartoonArt.INK, 0.6), 3, true)
	draw_arc(center, RADIUS - 6, 0, TAU, 64, Color(EchoStyle.MINT, 0.4), 2, true)
	for i in range(4):
		var axis := Vector2.from_angle(i * PI / 2)
		draw_line(center + axis * 53, center + axis * 62, Color(CartoonArt.INK, 0.4), 3, true)
	draw_circle(center + displacement + Vector2(0, 4), 29, Color(CartoonArt.INK, 0.18))
	CartoonArt.buddy(self, center + displacement, 27, 0, 0, false, 0.9 if held else 0.65)
