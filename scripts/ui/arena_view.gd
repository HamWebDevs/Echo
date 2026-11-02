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
var pop_effects: Array[Dictionary] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not reduced_motion:
		clock += delta
	for p in particles:
		p.life -= delta
	particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0)
	for effect in pop_effects:
		effect.life -= delta
	pop_effects = pop_effects.filter(func(effect: Dictionary) -> bool: return effect.life > 0)
	queue_redraw()

func burst(at: Vector2, points: int = 0) -> void:
	if not reduced_motion:
		particles.append({"at": at, "life": 0.55, "points": points})

func pop_burst(at: Vector2, cleared: Array[Vector2]) -> void:
	pop_effects.append({"at": at, "life": 0.7, "cleared": cleared})

func _draw_garden(bg: Color) -> void:
	# Flat, low-contrast scenery is decoration; the thick outer rim is the wall.
	draw_style_box(EchoStyle.box(bg, 28, CartoonArt.INK, 5), Rect2(0, 0, 720, 720))
	for row in range(6):
		for col in range(6):
			if (row + col) % 2 == 0:
				draw_rect(Rect2(12 + col * 116, 12 + row * 116, 116, 116), Color("c6e1ab", 0.14))
	for i in range(18):
		var at := Vector2(44 + fmod(i * 137.0, 634), 47 + fmod(i * 233.0, 620))
		var sway := sin(clock * 1.5 + i) * 2
		var grass := Color("8baa74", 0.26)
		draw_line(at, at + Vector2(-5 + sway, -7), grass, 2, true)
		draw_line(at, at + Vector2(3 + sway, -9), grass, 2, true)
	for at in [Vector2(30, 100), Vector2(684, 260), Vector2(37, 655), Vector2(665, 44)]:
		for petal in range(5):
			draw_circle(at + Vector2.from_angle(petal * TAU / 5) * 7, 5, Color("eab6b6", 0.42))
		draw_circle(at, 3, Color("d5b36e", 0.65))
	# Candy-coloured fence studs make the dangerous edge unmistakable.
	for i in range(1, 12):
		for edge in [Vector2(i * 60, 6), Vector2(i * 60, 714), Vector2(6, i * 60), Vector2(714, i * 60)]:
			draw_circle(edge, 4, Color("e9af75"))

func _draw() -> void:
	if demo:
		_draw_demo()
		return
	if run == null or size.x <= 0:
		return
	var scale_factor := size.x / EchoRun.WORLD
	draw_set_transform(Vector2.ZERO, 0, Vector2.ONE * scale_factor)
	var bg := [Color("f1f4d5"), Color("deefdf"), Color("efe4f5")][clampi(arena_theme, 0, 2)] as Color
	_draw_garden(bg)
	var now := float(run.tick) if replay_tick < 0 else replay_tick
	for index in range(1, run.echo_count(int(now)) + 1):
		if not run.echo_is_present(index, int(now)):
			continue
		var pos := run.echo_position(index, now)
		var live := run.echo_is_live(index, int(now))
		var col := EchoStyle.PURPLE if not high_contrast else Color("62328f")
		if not live:
			col.a = 0.45
		_draw_history(now - index * EchoRun.ECHO_INTERVAL, col, 36)
		# The next half-second is known because echoes replay history.
		var preview := PackedVector2Array()
		for offset in range(0, 31, 5):
			preview.append(run.position_at(now - index * EchoRun.ECHO_INTERVAL + offset))
		if preview.size() > 1:
			draw_polyline(preview, Color(col, 0.28), 2, true)
		_draw_echo(pos, col, EchoRun.ECHO_RADIUS)
		if not live:
			draw_arc(pos, 29, -PI / 2, TAU - PI / 2, 32, Color(col, 0.5), 2, true)
	# Warn before an echo materializes at the run's origin.
	var next_spawn := (run.echo_count(int(now)) + 1) * EchoRun.ECHO_INTERVAL
	if run.echo_count(int(now)) < EchoRun.MAX_ECHOES and next_spawn - now < 60:
		draw_arc(Vector2(360, 540), 30, 0, TAU, 40, Color(EchoStyle.PURPLE, 0.6), 2, true)
		_draw_echo(Vector2(360, 540), Color(EchoStyle.PURPLE, 0.35), EchoRun.ECHO_RADIUS)
	var spark_pulse := 1.0 + (sin(clock * 4) * 0.08 if not reduced_motion else 0.0)
	var target := run.spark if replay_tick < 0 else run.spark_at(now)
	var target_charge := run.charge if replay_tick < 0 else run.charge_at(now)
	var target_limit := 8.0 - run.echo_count(int(now)) * 0.5
	draw_circle(target, 26 * spark_pulse, Color(EchoStyle.GOLD, 0.07))
	draw_circle(target, 18 * spark_pulse, Color(EchoStyle.GOLD, 0.1))
	_draw_spark(target, EchoStyle.GOLD, EchoRun.SPARK_RADIUS)
	draw_arc(target, 24, -PI / 2, -PI / 2 + TAU * clampf(target_charge / target_limit, 0.01, 1), 40, Color(EchoStyle.GOLD, 0.7), 2, true)
	_draw_history(now, EchoStyle.MINT, 55)
	_draw_player(run.position_at(now), EchoStyle.MINT, EchoRun.PLAYER_RADIUS)
	if run.pop_charge == EchoRun.POP_COST and replay_tick < 0:
		var at := run.position_at(now)
		draw_arc(at, 33 + sin(clock * 4) * 2, 0, TAU, 48, Color(EchoStyle.GOLD, 0.65), 3, true)
	for effect in pop_effects:
		if reduced_motion:
			draw_string(EchoStyle.display, effect.at + Vector2(-34, -36), "POP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, CartoonArt.INK)
			continue
		var t: float = 1 - effect.life / 0.7
		var radius := EchoRun.POP_RADIUS * (1.0 if reduced_motion else minf(1, t * 2))
		draw_circle(effect.at, radius, Color("f6c85f", (1 - t) * 0.13))
		draw_arc(effect.at, radius, 0, TAU, 64, Color(EchoStyle.GOLD, 1 - t), 5, true)
		for at in effect.cleared:
			for i in range(7):
				var offset := Vector2.from_angle(i * TAU / 7) * (18 + t * 40)
				draw_circle(at + offset, 10 * (1 - t), Color("cab1e8", 1 - t))
			draw_string(EchoStyle.display, at + Vector2(-34, -30 - t * 24), "POP!", HORIZONTAL_ALIGNMENT_LEFT, -1, 30, Color(CartoonArt.INK, 1 - t))
	for p in particles:
		var progress: float = 1.0 - p.life / 0.55
		if p.points > 0:
			draw_string(EchoStyle.display, p.at + Vector2(-16, -25 - progress * 25), "+%d" % p.points, HORIZONTAL_ALIGNMENT_LEFT, -1, 24, Color(CartoonArt.INK, 1 - progress))
		draw_arc(p.at, 15 + progress * 50, 0, TAU, 32, Color(EchoStyle.GOLD, (1 - progress) * 0.7), 2, true)
		for i in range(8):
			var offset := Vector2.from_angle(i * TAU / 8) * (15 + progress * 40)
			draw_line(p.at + offset, p.at + offset + Vector2.from_angle(i * 1.7) * 7, Color(CartoonArt.COATS[i], 1 - progress), 3, true)
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
	CartoonArt.buddy(self, at, radius, 0, clock + 1.2, true, color.a, false, high_contrast)

func _draw_spark(at: Vector2, _color: Color, radius: float) -> void:
	CartoonArt.star(self, at, radius, sin(clock * 3) * 0.12)

func _draw_player(at: Vector2, _color: Color, radius: float) -> void:
	CartoonArt.buddy(self, at, radius, skin, clock, false, 1.0, run != null and not run.alive, high_contrast)

func _demo_position(angle: float) -> Vector2:
	return size * Vector2(0.5, 0.48) + Vector2(cos(angle) * size.x * 0.32, sin(angle * 2) * size.y * 0.23)

func _draw_demo() -> void:
	draw_style_box(EchoStyle.box(Color("fffaf0"), 22, EchoStyle.BORDER), Rect2(Vector2.ZERO, size))
	for x in range(22, int(size.x), 24):
		for y in range(22, int(size.y) - 20, 24):
			draw_circle(Vector2(x, y), 0.8, Color(0.52, 0.36, 0.24, 0.1))
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
		_draw_echo(_demo_position(time - j * 1.15), EchoStyle.PURPLE, 23)
	var lead := PackedVector2Array()
	for i in range(24):
		lead.append(_demo_position(time - (23 - i) * 0.025))
	draw_polyline(lead, Color(EchoStyle.MINT, 0.6), 3, true)
	_draw_player(_demo_position(time), EchoStyle.MINT, 29)
	_draw_spark(_demo_position(time + 0.6), EchoStyle.GOLD, 16)
	draw_string(EchoStyle.body, Vector2(20, 28), "MEET YOUR LITTLE COPYCATS", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EchoStyle.MUTED)
	draw_circle(Vector2(23, size.y - 21), 3, EchoStyle.MINT)
	draw_string(EchoStyle.body, Vector2(34, size.y - 17), "CATCH STARS. DODGE YOUR PAST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, EchoStyle.MUTED)
