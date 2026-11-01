class_name ScoreCard
extends Control

var result: Dictionary
var route := PackedVector2Array()

func _draw() -> void:
	draw_rect(Rect2(0, 0, 1080, 1350), EchoStyle.BG)
	draw_circle(Vector2(960, 200), 400, Color(EchoStyle.MINT, 0.025))
	draw_string(EchoStyle.display, Vector2(80, 140), "ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 84, EchoStyle.MINT)
	draw_string(EchoStyle.body, Vector2(80, 208), "YOUR PAST IS CATCHING UP.", HORIZONTAL_ALIGNMENT_LEFT, -1, 24, EchoStyle.MUTED)
	draw_line(Vector2(80, 256), Vector2(1000, 256), EchoStyle.BORDER, 2)
	var mode := "DAILY SIGNAL  /  " + str(result.get("daily_date", "")) if result.get("mode") == "daily" else "ENDLESS  /  PERSONAL RUN"
	draw_string(EchoStyle.body, Vector2(80, 330), mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 26, EchoStyle.GOLD)
	draw_string(EchoStyle.display, Vector2(70, 565), str(result.get("score", 0)), HORIZONTAL_ALIGNMENT_LEFT, -1, 216, EchoStyle.TEXT)
	draw_string(EchoStyle.body, Vector2(80, 630), "%d SPARKS     /     %.1f SECONDS     /     %d ECHOES" % [result.get("sparks",0), result.get("duration",0), result.get("echoes",0)], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, EchoStyle.MUTED)
	draw_style_box(EchoStyle.box(Color("0e1b2b"), 32), Rect2(80, 700, 920, 440))
	if route.size() > 1:
		var points := PackedVector2Array()
		for point in route:
			points.append(Vector2(150, 750) + point / 720 * Vector2(780, 340))
		draw_polyline(points, Color(EchoStyle.MINT, 0.1), 18, true)
		draw_polyline(points, EchoStyle.MINT, 4, true)
		draw_circle(points[-1], 10, EchoStyle.GOLD)
	draw_string(EchoStyle.display, Vector2(80, 1230), "Can you outrun yourself?", HORIZONTAL_ALIGNMENT_LEFT, -1, 42, EchoStyle.TEXT)
	draw_string(EchoStyle.body, Vector2(80, 1285), "PROJECT ECHO   /   RULES v%d   /   PERSONAL SCORE" % RunConfig.RULES_VERSION, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, EchoStyle.MUTED)
