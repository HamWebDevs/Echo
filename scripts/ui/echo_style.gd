class_name EchoStyle
extends RefCounted

const BG := Color("fff3d9")
const PANEL := Color("fffaf0")
const BORDER := Color("40394f")
const TEXT := Color("343047")
const MUTED := Color("716478")
const MINT := Color("267b62")
const GOLD := Color("a36517")
const PURPLE := Color("8056ad")
const RED := Color("bd4c63")
static var reduced_motion := false
static var body: Font = load("res://assets/fonts/body.tres")
static var display: Font = load("res://assets/fonts/display.tres")

static func box(color: Color = PANEL, radius: int = 18, border: Color = BORDER, width: int = 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	style.border_color = border
	style.shadow_color = Color("40394f")
	style.shadow_size = 0
	style.shadow_offset = Vector2(0, 4)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	return style

static func label(text: String, font_size: int = 18, color: Color = TEXT, heading: bool = false) -> Label:
	var item := Label.new()
	item.text = text
	item.add_theme_font_override("font", display if heading else body)
	item.add_theme_font_size_override("font_size", font_size)
	item.add_theme_color_override("font_color", color)
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return item

static func button(text: String, action: Callable, primary: bool = false, height: float = 58) -> Button:
	var item := Button.new()
	item.text = text
	item.custom_minimum_size.y = height
	item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	item.add_theme_font_override("font", display)
	item.add_theme_font_size_override("font_size", 21 if primary else 17)
	item.add_theme_color_override("font_color", TEXT)
	item.add_theme_color_override("font_hover_color", TEXT)
	item.add_theme_color_override("font_pressed_color", TEXT)
	item.add_theme_color_override("font_disabled_color", MUTED)
	item.add_theme_stylebox_override("normal", box(Color("82d9b0") if primary else PANEL, 16, BORDER))
	item.add_theme_stylebox_override("hover", box(Color("96dfbb") if primary else Color("f8e4bb"), 16, MINT))
	item.add_theme_stylebox_override("pressed", box(Color("71bfa0") if primary else Color("efd1a0"), 16, MINT))
	item.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 16, GOLD, 2))
	item.add_theme_stylebox_override("disabled", box(Color("e7ddcc"), 16, BORDER))
	item.button_down.connect(func() -> void:
		if not reduced_motion:
			item.pivot_offset = item.size / 2
			item.scale = Vector2(0.97, 0.94))
	item.button_up.connect(func() -> void:
		if not reduced_motion:
			item.create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(item, "scale", Vector2.ONE, 0.18))
	item.pressed.connect(action)
	return item

static func vbox(separation: int = 12) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", separation)
	return container

static func hbox(separation: int = 12) -> HBoxContainer:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", separation)
	return container

static func spacer(height: float = 12, expand: bool = false) -> Control:
	var space := Control.new()
	space.custom_minimum_size.y = height
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	return space
