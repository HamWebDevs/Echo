class_name SkinTile
extends Button

var index := 0
var available := false
var equipped := false
var subtitle := ""

func _ready() -> void:
	custom_minimum_size = Vector2(140, 145)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("normal", EchoStyle.box(Color("13252f") if equipped else EchoStyle.PANEL, 16, EchoStyle.MINT if equipped else EchoStyle.BORDER))
	add_theme_stylebox_override("hover", EchoStyle.box(Color("1a2a3c"), 16, EchoStyle.MINT))
	add_theme_stylebox_override("pressed", EchoStyle.box(Color("223846"), 16, EchoStyle.MINT))
	add_theme_stylebox_override("focus", EchoStyle.box(Color(0, 0, 0, 0), 16, EchoStyle.GOLD, 2))

func _draw() -> void:
	var center := Vector2(size.x / 2, 43)
	var color := EchoStyle.MINT if available else Color("63738e")
	if index >= 9:
		color = EchoStyle.GOLD if available else Color("9f8a6f")
	draw_circle(center, 28, Color(color, 0.06))
	draw_arc(center, 17, 0, TAU, 40, color, 2, true)
	if index % 3 == 0:
		draw_circle(center, 5, color)
	elif index % 3 == 1:
		draw_arc(center, 8, 0, TAU, 24, color, 2, true)
	else:
		draw_polyline(PackedVector2Array([center + Vector2(0,-8), center + Vector2(8,0), center + Vector2(0,8), center + Vector2(-8,0), center + Vector2(0,-8)]), color, 2, true)
	if index > 2:
		var count := mini(5, index / 3 + 1)
		for i in range(count):
			draw_circle(center + Vector2.from_angle(i * TAU / count - PI / 2) * 25, 2.5, color)
	var title := ProfileStore.SKIN_NAMES[index] as String
	var title_width := EchoStyle.display.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(EchoStyle.display, Vector2((size.x - title_width) / 2, 95), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, EchoStyle.TEXT)
	var sub_width := EchoStyle.body.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(EchoStyle.body, Vector2((size.x - sub_width) / 2, 118), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, EchoStyle.MINT if equipped else EchoStyle.MUTED)
