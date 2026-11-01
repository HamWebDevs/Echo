class_name ArenaView
extends Control

var run: EchoRun
var demo := false
var clock := 0.0
var reduced_motion := false
var high_contrast := false
var skin := 0
var arena_theme := 0
var replay_tick := -1.0
var particles: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not reduced_motion:
		clock += delta
	for p in particles:
		p.life -= delta
	particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0)
	queue_redraw()

func burst(at: Vector2) -> void:
	if not reduced_motion:
		particles.append({"at": at, "life": 0.55})

func _draw() -> void:
	if demo:
		_draw_demo()
		return
	if run == null or size.x <= 0:
		return
	var scale_factor := size.x / EchoRun.WORLD
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	var bg := [Color("0c1726"), Color("0b2028"), Color("1a142c")][clampi(arena_theme, 0, 2)] as Color
	draw_style_box(EchoStyle.box(bg, 20, Color("486278") if high_contrast else EchoStyle.BORDER, 2), Rect2(0, 0, 720, 720))
	for line in range(1, 10):
		var col := Color(0.45, 0.65, 0.8, 0.09)
		draw_line(Vector2(line * 72, 14), Vector2(line * 72, 706), col, 1, true)
		draw_line(Vector2(14, line * 72), Vector2(706, line * 72), col, 1, true)
	for corner in [Vector2(20, 20), Vector2(700, 20), Vector2(20, 700), Vector2(700, 700)]:
		var inward := Vector2(1 if corner.x < 360 else -1, 1 if corner.y < 360 else -1)
		draw_line(corner, corner + Vector2(inward.x * 22, 0), EchoStyle.MUTED, 2, true)
		draw_line(corner, corner + Vector2(0, inward.y * 22), EchoStyle.MUTED, 2, true)
	var now := float(run.tick) if replay_tick < 0 else replay_tick
	for index in range(1, run.echo_count(int(now)) + 1):
		var pos := run.echo_position(index, now)
		var live := run.echo_is_live(index, int(now))
		var col := EchoStyle.PURPLE if not high_contrast else Color("ff9de4")
		if not live:
			col.a = 0.45
		_draw_history(now - index * EchoRun.ECHO_INTERVAL, col, 36)
		# The next half-second is known because echoes replay history.
		var preview := PackedVector2Array()
		for offset in range(0, 31, 5):
			preview.append(run.position_at(now - index * EchoRun.ECHO_INTERVAL + offset))
		if preview.size() > 1:
			draw_polyline(preview, Color(col, 0.28), 2, true)
		_draw_echo(pos, col, 17)
		if not live:
			draw_arc(pos, 29, -PI / 2, TAU - PI / 2, 32, Color(col, 0.5), 2, true)
	# Warn before an echo materializes at the run's origin.
	var next_spawn := (run.echo_count(int(now)) + 1) * EchoRun.ECHO_INTERVAL
	if run.echo_count(int(now)) < EchoRun.MAX_ECHOES and next_spawn - now < 60:
		draw_arc(Vector2(360, 540), 30, 0, TAU, 40, Color(EchoStyle.PURPLE, 0.6), 2, true)
		_draw_echo(Vector2(360, 540), Color(EchoStyle.PURPLE, 0.35), 17)
	var spark_pulse := 1.0 + (sin(clock * 4) * 0.08 if not reduced_motion else 0.0)
	var target := run.spark if replay_tick < 0 else run.spark_at(now)
	var target_charge := run.charge if replay_tick < 0 else run.charge_at(now)
	var target_limit := 8.0 - run.echo_count(int(now)) * 0.5
	draw_circle(target, 26 * spark_pulse, Color(EchoStyle.GOLD, 0.07))
	draw_circle(target, 18 * spark_pulse, Color(EchoStyle.GOLD, 0.1))
	_draw_spark(target, EchoStyle.GOLD, 12)
	draw_arc(target, 24, -PI / 2, -PI / 2 + TAU * clampf(target_charge / target_limit, 0.01, 1), 40, Color(EchoStyle.GOLD, 0.7), 2, true)
	_draw_history(now, EchoStyle.MINT, 55)
	_draw_player(run.position_at(now), EchoStyle.MINT, 12)
	for p in particles:
		var progress: float = 1.0 - p.life / 0.55
		draw_arc(p.at, 15 + progress * 50, 0, TAU, 32, Color(EchoStyle.GOLD, (1 - progress) * 0.7), 2, true)
		for i in range(8):
			var offset := Vector2.from_angle(i * TAU / 8) * (15 + progress * 40)
			draw_circle(p.at + offset, 3 * (1 - progress), Color(EchoStyle.GOLD, 1 - progress))
	if not run.alive and replay_tick < 0:
		draw_circle(run.player, 28, Color(EchoStyle.RED, 0.12))
		draw_arc(run.player, 29, 0, TAU, 32, EchoStyle.RED, 2, true)
	draw_set_transform(Vector2.ZERO)

func _draw_history(at_tick: float, color: Color, length_ticks: int) -> void:
	var points := PackedVector2Array()
	for offset in range(length_ticks, -1, -3):
		if at_tick - offset >= maxi(0, run.tick - EchoRun.HISTORY_SIZE + 1):
			points.append(run.position_at(at_tick - offset))
	if points.size() > 1:
		draw_polyline(points, Color(color, 0.12), 10, true)
		draw_polyline(points, Color(color, 0.4), 2.5, true)

func _draw_echo(at: Vector2, color: Color, radius: float) -> void:
	var points := PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius, 0), at + Vector2(0, radius), at + Vector2(-radius, 0), at + Vector2(0, -radius)])
	draw_circle(at, radius * 1.6, Color(color, 0.06))
	draw_colored_polygon(points, Color("172039"))
	draw_polyline(points, color, 2.5, true)
	draw_circle(at, 3, color)

func _draw_spark(at: Vector2, color: Color, radius: float) -> void:
	var points := PackedVector2Array()
	for i in range(8):
		points.append(at + Vector2.from_angle(-PI / 2 + i * TAU / 8) * (radius if i % 2 == 0 else radius * 0.38))
	draw_colored_polygon(points, color)

func _draw_player(at: Vector2, color: Color, radius: float) -> void:
	draw_circle(at, radius * 2.1, Color(color, 0.07))
	draw_circle(at, radius * 1.5, Color(color, 0.1))
	draw_circle(at, radius, Color("102c35"))
	draw_arc(at, radius, 0, TAU, 32, color, 3, true)
	if skin % 3 == 0:
		draw_circle(at, 4, color)
	elif skin % 3 == 1:
		draw_arc(at, radius * 0.48, 0, TAU, 16, color, 2, true)
	else:
		_draw_spark(at, color, radius * 0.6)
	if skin > 2:
		for i in range(mini(5, skin / 3 + 1)):
			var angle: float = i * TAU / mini(5, skin / 3 + 1) + (clock * 0.4 if not reduced_motion else 0)
			draw_circle(at + Vector2.from_angle(angle) * (radius + 6), 2, color)

func _demo_position(angle: float) -> Vector2:
	return size * Vector2(0.5, 0.48) + Vector2(cos(angle) * size.x * 0.32, sin(angle * 2) * size.y * 0.29)

func _draw_demo() -> void:
	draw_style_box(EchoStyle.box(Color("0c1726"), 22, EchoStyle.BORDER), Rect2(Vector2.ZERO, size))
	for x in range(22, int(size.x), 24):
		for y in range(22, int(size.y) - 20, 24):
			draw_circle(Vector2(x, y), 0.8, Color(0.43, 0.66, 0.8, 0.15))
	var path := PackedVector2Array()
	for i in range(121):
		path.append(_demo_position(float(i) / 120 * TAU))
	draw_polyline(path, Color(EchoStyle.MINT, 0.06), 16, true)
	draw_polyline(path, Color(EchoStyle.MINT, 0.19), 1.5, true)
	var time := clock * 0.35 + 0.6
	for j in range(1, 4):
		var trail := PackedVector2Array()
		for k in range(18):
			trail.append(_demo_position(time - j * 1.15 - (17 - k) * 0.025))
		draw_polyline(trail, Color(EchoStyle.PURPLE, 0.24), 2, true)
		_draw_echo(_demo_position(time - j * 1.15), EchoStyle.PURPLE, 10)
	var lead := PackedVector2Array()
	for i in range(24):
		lead.append(_demo_position(time - (23 - i) * 0.025))
	draw_polyline(lead, Color(EchoStyle.MINT, 0.6), 3, true)
	_draw_player(_demo_position(time), EchoStyle.MINT, 12)
	_draw_spark(_demo_position(time + 0.6), EchoStyle.GOLD, 9)
	draw_string(EchoStyle.body, Vector2(20, 28), "EVERY MOVE LEAVES AN ECHO", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EchoStyle.MUTED)
	draw_circle(Vector2(23, size.y - 21), 3, EchoStyle.MINT)
	draw_string(EchoStyle.body, Vector2(34, size.y - 17), "YOUR NEXT MOVE CHANGES EVERYTHING", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EchoStyle.MUTED)
