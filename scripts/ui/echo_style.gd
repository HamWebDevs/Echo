class_name EchoStyle
extends RefCounted

const BG := Color("080e1b")
const PANEL := Color("101b2b")
const BORDER := Color("233347")
const TEXT := Color("edf5fa")
const MUTED := Color("91a3ba")
const MINT := Color("72f5cf")
const GOLD := Color("ffcf83")
const PURPLE := Color("b49aff")
const RED := Color("ff8398")
static var body: Font = load("res://assets/fonts/body.tres")
static var display: Font = load("res://assets/fonts/display.tres")

static func box(color: Color = PANEL, radius: int = 18, border: Color = BORDER, width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.set_border_width_all(width)
	style.border_color = border
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
	item.add_theme_color_override("font_color", BG if primary else TEXT)
	item.add_theme_color_override("font_hover_color", BG if primary else MINT)
	item.add_theme_color_override("font_pressed_color", BG if primary else MINT)
	item.add_theme_color_override("font_disabled_color", MUTED)
	item.add_theme_stylebox_override("normal", box(MINT if primary else PANEL, 16, MINT if primary else BORDER))
	item.add_theme_stylebox_override("hover", box(Color("a1ffe3") if primary else Color("182c3b"), 16, MINT))
	item.add_theme_stylebox_override("pressed", box(Color("4ec3a4") if primary else Color("213848"), 16, MINT))
	item.add_theme_stylebox_override("focus", box(Color(0, 0, 0, 0), 16, GOLD, 2))
	item.add_theme_stylebox_override("disabled", box(Color("101724"), 16, BORDER))
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
