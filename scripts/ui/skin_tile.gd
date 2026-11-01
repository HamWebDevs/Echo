class_name SkinTile
extends Button

var index := 0
var available := false
var equipped := false
var subtitle := ""

func _ready() -> void:
	custom_minimum_size = Vector2(140, 145)
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	add_theme_stylebox_override("normal", EchoStyle.box(Color("dcf2df") if equipped else EchoStyle.PANEL, 16, EchoStyle.MINT if equipped else EchoStyle.BORDER))
	add_theme_stylebox_override("hover", EchoStyle.box(Color("f8e4bb"), 16, EchoStyle.MINT))
	add_theme_stylebox_override("pressed", EchoStyle.box(Color("efd1a0"), 16, EchoStyle.MINT))
	add_theme_stylebox_override("focus", EchoStyle.box(Color(0, 0, 0, 0), 16, EchoStyle.GOLD, 2))

func _draw() -> void:
	var center := Vector2(size.x / 2, 43)
	CartoonArt.buddy(self, center, 24, index, 0, false, 1.0 if available else 0.4)
	var title := ProfileStore.SKIN_NAMES[index] as String
	var title_width := EchoStyle.display.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17).x
	draw_string(EchoStyle.display, Vector2((size.x - title_width) / 2, 95), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 17, EchoStyle.TEXT)
	var sub_width := EchoStyle.body.get_string_size(subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(EchoStyle.body, Vector2((size.x - sub_width) / 2, 118), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, EchoStyle.MINT if equipped else EchoStyle.MUTED)
