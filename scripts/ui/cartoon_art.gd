class_name CartoonArt
extends RefCounted

const INK := Color("343047")
const COATS := [Color("68c8a5"), Color("f5b95e"), Color("ee8f9e"), Color("97bcec"), Color("ba9fdb"), Color("ed9e68"), Color("97c976"), Color("f0cc70"), Color("e99bc5"), Color("82ccc9"), Color("ada3bd"), Color("f1ac61"), Color("b0c779")]

static func buddy(canvas: CanvasItem, at: Vector2, radius: float, skin: int, clock: float = 0, ghost: bool = false, alpha: float = 1.0, surprised: bool = false) -> void:
	var ink := Color(INK, alpha)
	var coat := Color(Color("bb9cde") if ghost else COATS[clampi(skin, 0, 12)], alpha)
	# The circular body stays on its collision centre. Only the face and accessories animate.
	canvas.draw_circle(at + Vector2(0, radius * 0.23), radius * 1.05, Color(INK, 0.12 * alpha))
	canvas.draw_circle(at, radius, coat)
	canvas.draw_arc(at, radius, 0, TAU, 32, ink, maxf(1.5, radius * 0.09), true)
	canvas.draw_arc(at + Vector2(-radius * 0.15, -radius * 0.12), radius * 0.67, 3.5, 4.7, 12, Color(Color.WHITE, alpha * 0.42), radius * 0.12, true)
	var look := sin(clock * 1.6) * radius * 0.06
	var blink := fmod(clock + skin * 0.31, 4.2) > 4.04 and clock > 0
	for side in [-1, 1]:
		var eye := at + Vector2(side * radius * 0.34 + look, -radius * 0.15)
		if blink:
			canvas.draw_line(eye + Vector2(-radius * 0.13, 0), eye + Vector2(radius * 0.13, 0), ink, maxf(1.4, radius * 0.09), true)
		else:
			canvas.draw_circle(eye, radius * 0.22, Color(Color.WHITE, alpha))
			canvas.draw_circle(eye + Vector2(radius * 0.035, radius * 0.035), radius * 0.11, ink)
		canvas.draw_circle(at + Vector2(side * radius * 0.57, radius * 0.22), radius * 0.14, Color(Color("ef7e91"), alpha * 0.7))
	if surprised:
		canvas.draw_circle(at + Vector2(0, radius * 0.42), radius * 0.16, ink)
	else:
		canvas.draw_arc(at + Vector2(0, radius * 0.22), radius * 0.26, 0.15, PI - 0.15, 12, ink, maxf(1.2, radius * 0.07), true)
	if ghost:
		# Triangular ears distinguish hazards from round buddies without relying on colour.
		for side in [-1, 1]:
			var points := PackedVector2Array([at + Vector2(side * radius * 0.85, -radius * 0.4), at + Vector2(side * radius * 0.78, -radius * 1.15), at + Vector2(side * radius * 0.25, -radius * 0.7)])
			canvas.draw_colored_polygon(points, coat)
			canvas.draw_polyline(points, ink, maxf(1.5, radius * 0.07), true)
	elif skin > 0:
		var top := at + Vector2(0, -radius * 0.82)
		match skin % 4:
			0: # party hat
				canvas.draw_colored_polygon(PackedVector2Array([top + Vector2(-radius * 0.44, 0), top + Vector2(0, -radius * 0.65), top + Vector2(radius * 0.44, 0)]), Color("e57f83"))
			1: # jaunty cap
				canvas.draw_line(top + Vector2(-radius * 0.5, 0), top + Vector2(radius * 0.6, 0), ink, radius * 0.17, true)
				canvas.draw_circle(top + Vector2(-radius * 0.1, -radius * 0.14), radius * 0.3, Color("6583ba"))
			2: # flower
				for petal in range(5):
					canvas.draw_circle(top + Vector2.from_angle(petal * TAU / 5) * radius * 0.22, radius * 0.18, Color("fff5de"))
				canvas.draw_circle(top, radius * 0.15, Color("df9d37"))
			3: # headband
				canvas.draw_arc(at, radius * 0.92, PI + 0.35, TAU - 0.35, 20, Color("fff5de"), radius * 0.18, true)

static func star(canvas: CanvasItem, at: Vector2, radius: float, angle: float = 0) -> void:
	var points := PackedVector2Array()
	for i in range(10):
		points.append(at + Vector2.from_angle(-PI / 2 + i * TAU / 10 + angle) * (radius if i % 2 == 0 else radius * 0.53))
	canvas.draw_colored_polygon(points, Color("f4c44f"))
	points.append(points[0])
	canvas.draw_polyline(points, INK, maxf(1.2, radius * 0.09), true)
	for side in [-1, 1]:
		canvas.draw_circle(at + Vector2(side * radius * 0.2, 0), radius * 0.07, INK)
