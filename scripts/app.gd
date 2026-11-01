extends Control

var profile := ProfileStore.new()
var services: PlatformServices
var audio: EchoAudio
var state := "home"
var page: MarginContainer
var body: VBoxContainer
var overlay: Control
var toast: Label
var toast_left := 0.0
var run: EchoRun
var arena: ArenaView
var pad: ThumbPad
var score_label: Label
var signal_label: Label
var energy_label: Label
var energy_bar: ProgressBar
var help_label: Label
var game_started := false
var paused := false
var resume_time := 0.0
var countdown_label: Label
var tutorial_stage := 0
var tutorial_destination := "endless"
var result_info: Dictionary = {}
var replay_view: ArenaView
var replay_time := 0.0
var capture_args: Dictionary = {}
var utc_today := ""
var midnight_check := 0.0
var screen_clock := 0.0
var metadata: Dictionary = {"developer": "HamWebDev", "support_email": "", "privacy_url": ""}
var showcase_mode := ""
var showcase_started := false

func _ready() -> void:
	if FileAccess.file_exists("res://config/app_metadata.json"):
		var public_config: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://config/app_metadata.json"))
		if public_config is Dictionary:
			metadata.merge(public_config, true)
	profile.load_profile()
	services = PlatformServices.new()
	add_child(services)
	services.message.connect(_toast)
	services.store_changed.connect(_store_changed)
	services.set_analytics(profile.data.settings.analytics)
	audio = EchoAudio.new()
	add_child(audio)
	audio.apply(profile.data.settings)
	get_tree().auto_accept_quit = false
	resized.connect(_layout)
	utc_today = RunConfig.utc_date()
	show_home()
	for arg in OS.get_cmdline_user_args():
		if not OS.is_debug_build():
			break
		if arg.begins_with("--capture="):
			capture_args.screen = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-path="):
			capture_args.path = arg.trim_prefix("--capture-path=")
		elif arg.begins_with("--showcase="):
			showcase_mode = arg.trim_prefix("--showcase=")
	if not capture_args.is_empty():
		_prepare_capture.call_deferred()
	elif not showcase_mode.is_empty():
		_start_showcase.call_deferred()
	if profile.recovered:
		_toast("Your progress was recovered from a backup.")

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), EchoStyle.BG)
	draw_circle(Vector2(size.x * 0.9, 90), 240, Color(EchoStyle.MINT, 0.016))
	draw_circle(Vector2(0, size.y * 0.8), 200, Color(EchoStyle.PURPLE, 0.013))

func _new_page(next_state: String, spacing: int = 10) -> VBoxContainer:
	_close_modal()
	if is_instance_valid(page):
		# Keep the old controls in-tree until the current touch/mouse dispatch ends.
		page.hide()
		page.queue_free()
	arena = null
	pad = null
	state = next_state
	screen_clock = 0
	page = MarginContainer.new()
	page.add_theme_constant_override("margin_left", 28)
	page.add_theme_constant_override("margin_right", 28)
	page.add_theme_constant_override("margin_top", 24)
	page.add_theme_constant_override("margin_bottom", 20)
	add_child(page)
	body = EchoStyle.vbox(spacing)
	page.add_child(body)
	_layout()
	return body

func _layout() -> void:
	if not is_instance_valid(page):
		return
	var viewport_size := get_viewport_rect().size
	var width := minf(540, viewport_size.x)
	page.position = Vector2((viewport_size.x - width) / 2, 0)
	page.size = Vector2(width, viewport_size.y)
	if OS.has_feature("android"):
		var safe := DisplayServer.get_display_safe_area()
		var screen := DisplayServer.screen_get_size()
		if screen.y > 0:
			page.add_theme_constant_override("margin_top", maxi(24, int(safe.position.y * viewport_size.y / screen.y) + 8))
			page.add_theme_constant_override("margin_bottom", maxi(20, int((screen.y - safe.end.y) * viewport_size.y / screen.y) + 8))
	if state == "game" and is_instance_valid(arena):
		var side := minf(width - 56, viewport_size.y - 430)
		arena.custom_minimum_size = Vector2(side, side)
	queue_redraw()

func _header(title: String, back: Callable = Callable()) -> void:
	var row := EchoStyle.hbox(10)
	row.custom_minimum_size.y = 36
	if back.is_valid():
		var button := EchoStyle.button("‹", back, false, 40)
		button.custom_minimum_size.x = 44
		row.add_child(button)
	var label := EchoStyle.label(title, 14, EchoStyle.MUTED, true)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	body.add_child(row)

func _paragraph(text: String, font_size: int = 16, color: Color = EchoStyle.MUTED) -> Label:
	var label := EchoStyle.label(text, font_size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _panel(parent: Node, color: Color = EchoStyle.PANEL) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", EchoStyle.box(color))
	parent.add_child(panel)
	var content := EchoStyle.vbox(8)
	panel.add_child(content)
	return content

func show_home() -> void:
	_new_page("home", 10)
	var header := EchoStyle.hbox()
	var mark := TextureRect.new()
	mark.texture = load("res://assets/icon.svg")
	mark.custom_minimum_size = Vector2(24, 24)
	mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(mark)
	var brand := EchoStyle.label("PROJECT ECHO", 13, EchoStyle.TEXT, true)
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(brand)
	header.add_child(EchoStyle.label("OFFLINE READY", 10, EchoStyle.MINT))
	body.add_child(header)
	body.add_child(EchoStyle.spacer(9, true))
	body.add_child(EchoStyle.label("OUTRUN YOURSELF", 12, EchoStyle.MINT))
	var title := EchoStyle.label("ECHO", 100, EchoStyle.TEXT, true)
	title.add_theme_constant_override("outline_size", 0)
	body.add_child(title)
	body.add_child(EchoStyle.label("Your past is catching up.", 22, EchoStyle.MUTED, true))
	body.add_child(EchoStyle.spacer(4))
	var demo := ArenaView.new()
	demo.demo = true
	demo.reduced_motion = profile.data.settings.reduced_motion
	demo.custom_minimum_size.y = 213
	body.add_child(demo)
	var stats := _panel(body)
	var row := EchoStyle.hbox()
	var left := EchoStyle.vbox(2)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_child(EchoStyle.label("PERSONAL BEST", 10, EchoStyle.MUTED))
	left.add_child(EchoStyle.label("%04d" % profile.data.best, 29, EchoStyle.TEXT, true))
	row.add_child(left)
	var right := EchoStyle.vbox(2)
	var runs_text := EchoStyle.label("LIFETIME SPARKS", 10, EchoStyle.MUTED)
	runs_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(runs_text)
	var sparks_text := EchoStyle.label(str(profile.data.lifetime_sparks), 29, EchoStyle.GOLD, true)
	sparks_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right.add_child(sparks_text)
	row.add_child(right)
	stats.add_child(row)
	body.add_child(EchoStyle.button("PLAY ENDLESS     →", func() -> void: request_start("endless"), true, 64))
	var daily := EchoStyle.button("THE DAILY SIGNAL     ↗\n%s  ·  A new route every day" % _friendly_date(), func() -> void: request_start("daily"), false, 76)
	daily.add_theme_font_size_override("font_size", 16)
	body.add_child(daily)
	var navigation := EchoStyle.hbox(8)
	for entry in [["COLLECTION", show_collection], ["HOW TO PLAY", show_how_to], ["SETTINGS", show_settings]]:
		var button := EchoStyle.button(entry[0], entry[1], false, 46)
		button.add_theme_font_size_override("font_size", 11)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		navigation.add_child(button)
	body.add_child(navigation)
	body.add_child(EchoStyle.spacer(2, true))
	var footer := EchoStyle.label("ONE THUMB. ONE MORE TRY.", 10, EchoStyle.MUTED)
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(footer)

func _friendly_date() -> String:
	var now := Time.get_datetime_dict_from_system(true)
	var months := ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
	return "%s %02d  /  UTC" % [months[now.month - 1], now.day]

func request_start(mode: String) -> void:
	audio.begin_music()
	audio.play("click")
	if not profile.data.tutorial_complete:
		tutorial_destination = mode
		var content := _modal("YOUR PAST IS THE CHALLENGE", "Learn the loop")
		content.add_child(_paragraph("Steer with one thumb. Collect the gold sparks. Every eight seconds, an echo follows the route you took earlier.", 18))
		content.add_child(EchoStyle.button("SHOW ME HOW", start_tutorial, true))
		content.add_child(EchoStyle.button("Skip · let's play", func() -> void:
			profile.data.tutorial_complete = true
			profile.save()
			_begin_mode(mode)))
	else:
		_begin_mode(mode)

func _begin_mode(mode: String) -> void:
	var config := RunConfig.daily(RunConfig.utc_date()) if mode == "daily" else RunConfig.endless(randi())
	start_run(config)

func start_tutorial() -> void:
	tutorial_stage = 0
	var config := RunConfig.endless(81024)
	config.tutorial = true
	start_run(config)
	services.track("tutorial_start")
	_toast("Drag upward in the control pad to collect your first spark.")

func start_run(config: RunConfig) -> void:
	_new_page("game", 8)
	run = EchoRun.new(config)
	game_started = false
	paused = false
	resume_time = 0
	audio.begin_music()
	audio.play("start")
	var top := EchoStyle.hbox()
	var mode_label := EchoStyle.label("GUIDED RUN" if config.tutorial else ("DAILY SIGNAL  /  " + config.daily_date if config.mode == "daily" else "ENDLESS  /  FIND YOUR FLOW"), 12, EchoStyle.MINT)
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(mode_label)
	top.add_child(EchoStyle.button("II", pause_game, false, 44))
	body.add_child(top)
	var score_row := EchoStyle.hbox()
	score_label = EchoStyle.label("0000", 55, EchoStyle.TEXT, true)
	score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	score_row.add_child(score_label)
	var best_column := EchoStyle.vbox(0)
	best_column.add_child(EchoStyle.label("PERSONAL BEST", 10, EchoStyle.MUTED))
	best_column.add_child(EchoStyle.label(str(profile.best_for(config)), 24, EchoStyle.MUTED, true))
	score_row.add_child(best_column)
	body.add_child(score_row)
	signal_label = EchoStyle.label("DRAG BELOW TO BEGIN", 12, EchoStyle.MUTED)
	body.add_child(signal_label)
	var center := CenterContainer.new()
	arena = ArenaView.new()
	arena.run = run
	arena.reduced_motion = profile.data.settings.reduced_motion
	arena.high_contrast = profile.data.settings.high_contrast
	arena.skin = profile.data.skin if profile.skin_available(profile.data.skin, services.supporter) else 0
	arena.arena_theme = profile.data.theme if services.supporter else 0
	center.add_child(arena)
	body.add_child(center)
	var charge_row := EchoStyle.hbox()
	energy_label = EchoStyle.label("SPARK CHARGE", 10, EchoStyle.GOLD)
	energy_label.custom_minimum_size.x = 122
	charge_row.add_child(energy_label)
	energy_bar = ProgressBar.new()
	energy_bar.min_value = 0
	energy_bar.max_value = 1
	energy_bar.step = 0.001
	energy_bar.value = 1
	energy_bar.show_percentage = false
	energy_bar.custom_minimum_size.y = 5
	energy_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	energy_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var meter_background := EchoStyle.box(EchoStyle.BORDER, 3, EchoStyle.BORDER, 0)
	var meter_fill := EchoStyle.box(EchoStyle.GOLD, 3, EchoStyle.GOLD, 0)
	for style in [meter_background, meter_fill]:
		style.content_margin_top = 0
		style.content_margin_bottom = 0
		style.content_margin_left = 0
		style.content_margin_right = 0
	energy_bar.add_theme_stylebox_override("background", meter_background)
	energy_bar.add_theme_stylebox_override("fill", meter_fill)
	charge_row.add_child(energy_bar)
	body.add_child(charge_row)
	body.add_child(EchoStyle.spacer(1, true))
	pad = ThumbPad.new()
	pad.custom_minimum_size.y = 120
	body.add_child(pad)
	help_label = EchoStyle.label("DRAG TO STEER  ·  RELEASE TO KEEP MOVING", 10, EchoStyle.MUTED)
	help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(help_label)
	_layout()

func _physics_process(_delta: float) -> void:
	if state != "game" or run == null or paused or resume_time > 0 or not run.alive:
		return
	var steering := pad.direction if is_instance_valid(pad) else Vector2.ZERO
	var keyboard := Vector2(float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)), float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
	if keyboard != Vector2.ZERO:
		steering = keyboard
	if not showcase_mode.is_empty():
		steering = DemoPilot.direction(run)
		if showcase_mode == "retry" and run.tick >= 1200:
			steering = Vector2.RIGHT
	if not game_started:
		if steering == Vector2.ZERO:
			return
		game_started = true
		services.track("run_start", {"mode": run.config.mode, "rules_version": RunConfig.RULES_VERSION})
	run.step(steering)
	for event in run.events:
		if event.type == "spark":
			arena.burst(event.position)
			audio.play("spark", run.echo_count())
			if run.config.tutorial and tutorial_stage == 0:
				tutorial_stage = 1
				paused = true
				pad.release()
				var content := _modal("01 / SPARK COLLECTED", "Keep the signal alive")
				content.add_child(_paragraph("Each gold spark refills your timer. Keep moving toward the next one. Your first echo arrives at eight seconds."))
				content.add_child(EchoStyle.button("GOT IT", _resume_game, true))
		elif event.type == "echo":
			audio.play("echo", run.echo_count())
			if run.config.tutorial and tutorial_stage == 1:
				tutorial_stage = 2
				paused = true
				pad.release()
				var content := _modal("02 / MEET YOUR ECHO", "That was you")
				content.add_child(_paragraph("The purple diamond repeats your movement from eight seconds ago. Avoid its body. Faint trails are safe to cross."))
				content.add_child(EchoStyle.button("LET'S DODGE IT", _resume_game, true))
		elif event.type == "death":
			_end_run()
			return
	if run.config.tutorial and tutorial_stage == 2 and run.tick > EchoRun.ECHO_INTERVAL + 120:
		_complete_tutorial()
		return
	_update_hud()

func _update_hud() -> void:
	if not is_instance_valid(score_label):
		return
	score_label.text = "%04d" % run.score
	var count := run.echo_count()
	var time_to_next := 8.0 - fmod(run.elapsed(), 8.0)
	signal_label.text = "%02d / 06 ECHOES   ·   ×%d SCORE" % [count, count + 1]
	if count < 6:
		signal_label.text += "   ·   NEXT IN %.1fs" % time_to_next
	energy_bar.value = maxf(0, run.charge / run.charge_limit())
	energy_label.text = "SPARK  /  %.1fs" % maxf(0, run.charge)
	energy_label.add_theme_color_override("font_color", EchoStyle.RED if run.charge < 2 else EchoStyle.GOLD)

func _process(delta: float) -> void:
	screen_clock += delta
	if toast_left > 0:
		toast_left -= delta
		if toast_left <= 0 and is_instance_valid(toast):
			toast.queue_free()
	if resume_time > 0:
		resume_time -= delta
		if is_instance_valid(countdown_label):
			countdown_label.text = str(maxi(1, int(ceil(resume_time))))
		if resume_time <= 0:
			_close_modal()
			paused = false
	if is_instance_valid(replay_view):
		replay_time += delta
		var start := maxi(0, run.tick - 90)
		replay_view.replay_tick = minf(run.tick, start + fmod(replay_time, 2.2) * 60)
	midnight_check += delta
	if midnight_check >= 30:
		midnight_check = 0
		var date := RunConfig.utc_date()
		if date != utc_today:
			utc_today = date
			if state == "home":
				show_home()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ESCAPE or event.keycode == KEY_P):
		_back()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if state == "game" and run != null and run.alive:
			resume_time = 0
			pause_game()
	elif what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if state == "home":
			profile.save()
			get_tree().quit()
		else:
			_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		profile.save()
		get_tree().quit()

func _back() -> void:
	if state == "game":
		if run != null and not run.alive:
			show_home()
			return
		if paused and is_instance_valid(overlay):
			_resume_game()
		else:
			pause_game()
	elif is_instance_valid(overlay):
		_close_modal()
	elif state != "home":
		show_home()

func pause_game() -> void:
	if state != "game" or run == null or not run.alive:
		return
	paused = true
	resume_time = 0
	pad.release()
	var content := _modal("TAKE YOUR TIME", "Signal paused")
	content.add_child(_paragraph("Your run will be right here. Resume when you're ready."))
	content.add_child(EchoStyle.button("RESUME", _resume_game, true))
	content.add_child(EchoStyle.button("Restart run", func() -> void: start_run(run.config)))
	content.add_child(EchoStyle.button("End run · go home", _finish_and_home))

func _finish_and_home() -> void:
	if game_started and run != null and run.alive and not run.config.tutorial and showcase_mode.is_empty():
		run._die("ended")
		profile.record(run)
		services.track("run_end", run.result())
	show_home()

func _resume_game() -> void:
	if not game_started:
		_close_modal()
		paused = false
		return
	var content := _modal("FIND YOUR NEXT MOVE", "Ready?")
	countdown_label = EchoStyle.label("3", 90, EchoStyle.MINT, true)
	countdown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content.add_child(countdown_label)
	resume_time = 3.0

func _complete_tutorial() -> void:
	paused = true
	profile.data.tutorial_complete = true
	profile.save()
	services.track("tutorial_complete")
	var content := _modal("03 / YOU KNOW THE LOOP", "Make your next move")
	content.add_child(_paragraph("More echoes mean more points. Leave yourself space, chase the sparks, and see how far you can go."))
	content.add_child(EchoStyle.button("LET'S PLAY", func() -> void: _begin_mode(tutorial_destination), true))

func _end_run() -> void:
	audio.play("death")
	pad.release()
	if not showcase_mode.is_empty():
		result_info = {}
		show_results()
		await get_tree().create_timer(1.5).timeout
		if state == "results":
			_start_showcase()
		return
	if run.config.tutorial:
		paused = true
		var content := _modal("PRACTICE MAKES PROGRESS", _death_title())
		content.add_child(_paragraph(_death_detail()))
		content.add_child(EchoStyle.button("TRY THE TUTORIAL AGAIN", start_tutorial, true))
		content.add_child(EchoStyle.button("Skip tutorial · play", func() -> void:
			profile.data.tutorial_complete = true
			profile.save()
			_begin_mode(tutorial_destination)))
		return
	result_info = profile.record(run)
	services.track("run_end", run.result())
	show_results()
	if profile.save_failed:
		_toast("Progress could not be saved. Check your device storage.")

func _death_title() -> String:
	return {"wall": "Leave yourself room.", "echo": "Your past caught up.", "charge": "Follow the gold.", "ended": "A good place to pause."}.get(run.death_cause, "A new route awaits.")

func _death_detail() -> String:
	if run.death_cause == "ended":
		return "You chose to finish this run. Your collected sparks and completed score have been saved."
	if run.death_cause == "echo":
		return "Echo %d crossed your path, replaying your movement from %d seconds earlier. Give your future self a way out." % [run.death_echo, run.death_echo * 8]
	if run.death_cause == "wall":
		return "You reached the edge of the arena. Turn a little earlier and keep room for your next move."
	return "Your spark timer ran out. Collect each gold spark to refill it."

func show_results() -> void:
	_new_page("results", 14)
	_header("DAILY SIGNAL  /  " + run.config.daily_date if run.config.mode == "daily" else "ENDLESS  /  RUN COMPLETE", show_home)
	body.add_child(EchoStyle.spacer(12, true))
	body.add_child(EchoStyle.label("NEW PERSONAL BEST" if result_info.get("new_best", false) else "EVERY RUN TEACHES YOU SOMETHING", 12, EchoStyle.MINT))
	body.add_child(EchoStyle.label(str(run.score), 106, EchoStyle.TEXT, true))
	var row := EchoStyle.hbox(10)
	for stat in [[str(run.sparks), "SPARKS"], ["%.1fs" % run.elapsed(), "SURVIVED"], [str(run.echo_count()), "ECHOES"]]:
		var column := _panel(row)
		column.get_parent().size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_child(EchoStyle.label(stat[0], 25, EchoStyle.TEXT, true))
		column.add_child(EchoStyle.label(stat[1], 9, EchoStyle.MUTED))
	body.add_child(row)
	var insight := _panel(body)
	insight.add_child(EchoStyle.label(_death_title(), 25, EchoStyle.TEXT, true))
	insight.add_child(_paragraph(_death_detail(), 15))
	insight.add_child(EchoStyle.button("WATCH THE LAST MOMENT  ↗", _show_replay, false, 45))
	var unlock := _panel(body, Color("10242b"))
	var next := profile.next_unlock()
	unlock.add_child(EchoStyle.label("NEW SIGNAL UNLOCKED" if result_info.get("unlocked", false) else "YOUR COLLECTION IS GROWING", 11, EchoStyle.MINT))
	unlock.add_child(_paragraph("All earned signals unlocked. Keep chasing your best." if next < 0 else "%d / %d lifetime sparks to your next signal." % [profile.data.lifetime_sparks, next], 15))
	body.add_child(EchoStyle.spacer(4, true))
	body.add_child(EchoStyle.button("ONE MORE RUN     →", _retry, true, 64))
	var actions := EchoStyle.hbox()
	for entry in [["SHARE SCORE", _share], ["BACK HOME", show_home]]:
		var button := EchoStyle.button(entry[0], entry[1], false, 50)
		button.add_theme_font_size_override("font_size", 13)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		actions.add_child(button)
	body.add_child(actions)

func _retry() -> void:
	services.track("retry", {"mode": run.config.mode})
	# Daily retry remains on the original date, even if the clock crossed midnight.
	start_run(run.config if run.config.mode == "daily" else RunConfig.endless(randi()))

func _show_replay() -> void:
	var content := _modal("YOUR LAST 1.5 SECONDS", _death_title())
	replay_view = ArenaView.new()
	replay_view.run = run
	replay_view.high_contrast = profile.data.settings.high_contrast
	replay_view.reduced_motion = profile.data.settings.reduced_motion
	replay_view.custom_minimum_size = Vector2(350, 350)
	replay_time = 0
	replay_view.replay_tick = maxi(0, run.tick - 90)
	var replay_center := CenterContainer.new()
	replay_center.add_child(replay_view)
	content.add_child(replay_center)
	content.add_child(_paragraph(_death_detail(), 14))
	content.add_child(EchoStyle.button("TRY AGAIN", _retry, true))
	content.add_child(EchoStyle.button("Close replay", _close_modal, false, 42))

func _share() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1080, 1350)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var card := ScoreCard.new()
	card.size = Vector2(1080, 1350)
	card.result = run.result()
	for tick in range(maxi(0, run.tick - 1200), run.tick + 1, 8):
		card.route.append(run.position_at(tick))
	viewport.add_child(card)
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	services.share_image(image)
	services.track("share", {"mode": run.config.mode})
	viewport.queue_free()

func show_collection() -> void:
	_new_page("collection", 14)
	_header("YOUR COLLECTION", show_home)
	body.add_child(EchoStyle.label("Find your signal.", 38, EchoStyle.TEXT, true))
	body.add_child(_paragraph("Different looks. Same perfect hitbox. Earn signals simply by collecting sparks.", 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var content := EchoStyle.vbox(16)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(EchoStyle.label("EARNED SIGNALS  /  %d OF 9" % profile.unlocked_count(), 11, EchoStyle.MINT))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)
	for i in range(9):
		_add_skin(grid, i)
	content.add_child(EchoStyle.label("SUPPORTER SIGNALS", 11, EchoStyle.GOLD))
	var premium := GridContainer.new()
	premium.columns = 3
	premium.add_theme_constant_override("h_separation", 10)
	premium.add_theme_constant_override("v_separation", 10)
	content.add_child(premium)
	for i in range(9, 13):
		_add_skin(premium, i)
	body.add_child(EchoStyle.button("SUPPORT THE SIGNAL  ↗" if not services.supporter else "YOUR SUPPORTER EXTRAS  ↗", show_supporter, false, 56))

func _add_skin(parent: Node, index: int) -> void:
	var tile := SkinTile.new()
	tile.index = index
	tile.available = profile.skin_available(index, services.supporter)
	tile.equipped = profile.data.skin == index and tile.available
	tile.subtitle = "EQUIPPED" if tile.equipped else ("TAP TO EQUIP" if tile.available else ("SUPPORTER" if index >= 9 else "%d SPARKS" % ProfileStore.THRESHOLDS[index]))
	tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tile.pressed.connect(func() -> void:
		if tile.available:
			profile.data.skin = index
			profile.save()
			audio.play("click")
			show_collection()
		elif index >= 9:
			show_supporter()
		else:
			_toast("Collect %d more sparks to unlock %s." % [ProfileStore.THRESHOLDS[index] - profile.data.lifetime_sparks, ProfileStore.SKIN_NAMES[index]]))
	parent.add_child(tile)

func show_supporter() -> void:
	_new_page("supporter", 16)
	_header("THE SUPPORTER PACK", show_collection)
	body.add_child(EchoStyle.spacer(10, true))
	body.add_child(EchoStyle.label("Keep the\nsignal alive.", 49, EchoStyle.TEXT, true))
	body.add_child(_paragraph("A little more self-expression. A lot of support for an independent game.", 18))
	var demo := ArenaView.new()
	demo.demo = true
	demo.skin = 10
	demo.custom_minimum_size.y = 180
	body.add_child(demo)
	var features := _panel(body)
	features.add_child(EchoStyle.label("YOURS, PERMANENTLY", 11, EchoStyle.GOLD))
	for feature in ["Four exclusive signals", "Two additional arena themes", "An alternative sound palette"]:
		features.add_child(EchoStyle.label("+  " + feature, 17, EchoStyle.TEXT, true))
	features.add_child(_paragraph("A single purchase. Every score is earned through skill.", 14))
	if services.supporter:
		body.add_child(EchoStyle.label("THANK YOU FOR SUPPORTING ECHO", 13, EchoStyle.MINT))
		body.add_child(EchoStyle.button("Arena theme: " + ["Midnight", "Deep sea", "Ultraviolet"][profile.data.theme], func() -> void:
			profile.data.theme = (profile.data.theme + 1) % 3
			profile.save()
			show_supporter()))
		body.add_child(EchoStyle.button("Sound palette: " + ("Original" if profile.data.sound_set == 0 else "Low orbit"), func() -> void:
			profile.data.sound_set = 1 - profile.data.sound_set
			audio.sound_set = profile.data.sound_set
			profile.save()
			show_supporter()))
	else:
		var offer_text := "PURCHASES UNAVAILABLE"
		if not services.price.is_empty():
			offer_text = "UNLOCK FOREVER  ·  " + services.price if services.entitlement_known else "CHECKING PURCHASES…"
		var buy := EchoStyle.button("PROCESSING…" if services.busy else offer_text, services.purchase, true, 64)
		buy.disabled = services.price.is_empty() or services.busy or not services.entitlement_known
		body.add_child(buy)
		if services.price.is_empty():
			body.add_child(_paragraph("Purchases aren't available in this build. The full game and earned signals are free to play.", 14))
	body.add_child(EchoStyle.button("Restore purchases", services.restore, false, 48))
	body.add_child(EchoStyle.spacer(2, true))

func _store_changed() -> void:
	# Price availability does not establish ownership. Revoke only on a confirmed
	# inactive entitlement, never while the asynchronous customer lookup is pending.
	if services.entitlement_known and not services.supporter:
		var changed := false
		if int(profile.data.skin) >= 9:
			profile.data.skin = 0
			changed = true
		if int(profile.data.theme) != 0 or int(profile.data.sound_set) != 0:
			profile.data.theme = 0
			profile.data.sound_set = 0
			changed = true
		if changed:
			profile.save()
	if is_instance_valid(audio):
		audio.sound_set = profile.data.sound_set if services.supporter else 0
	if is_instance_valid(arena):
		arena.skin = profile.data.skin if profile.skin_available(profile.data.skin, services.supporter) else 0
		arena.arena_theme = profile.data.theme if services.supporter else 0
	if state == "supporter":
		show_supporter()
	elif state == "collection":
		show_collection()

func show_settings() -> void:
	_new_page("settings", 12)
	_header("SETTINGS", show_home)
	body.add_child(EchoStyle.label("Your kind of flow.", 36, EchoStyle.TEXT, true))
	body.add_child(_paragraph("Make the experience comfortable for you.", 15))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	var content := EchoStyle.vbox(10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	for item in [["sound", "Sound effects", "Hear collections, echoes, and collisions."], ["music", "Music", "A quiet electronic soundtrack."], ["haptics", "Vibration", "Subtle feedback on supported phones."], ["reduced_motion", "Reduced motion", "Remove decorative animation and particles."], ["high_contrast", "High contrast", "Stronger borders and brighter echo shapes."], ["analytics", "Usage analytics", "Optional app activity data to improve the game."]]:
		_setting_row(content, item[0], item[1], item[2])
	content.add_child(EchoStyle.button("Replay the interactive tutorial", func() -> void:
		tutorial_destination = "endless"
		start_tutorial()))
	content.add_child(EchoStyle.button("Privacy & credits", show_privacy))
	if not str(metadata.get("support_email", "")).is_empty():
		content.add_child(EchoStyle.button("Contact " + str(metadata.developer), func() -> void: OS.shell_open("mailto:" + str(metadata.support_email))))
	content.add_child(EchoStyle.button("Restore purchases", services.restore))
	content.add_child(EchoStyle.label("PROJECT ECHO  /  0.1.0  /  RULES v1", 10, EchoStyle.MUTED))

func _setting_row(parent: Node, key: String, title: String, description: String) -> void:
	var panel := _panel(parent)
	var row := EchoStyle.hbox(14)
	var text := EchoStyle.vbox(4)
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.add_child(EchoStyle.label(title, 17, EchoStyle.TEXT, true))
	text.add_child(_paragraph(description, 12))
	row.add_child(text)
	var toggle := EchoStyle.button("ON" if profile.data.settings[key] else "OFF", func() -> void:
		profile.data.settings[key] = not profile.data.settings[key]
		profile.save()
		audio.apply(profile.data.settings)
		services.set_analytics(profile.data.settings.analytics)
		if profile.data.settings.music:
			audio.begin_music()
		show_settings(), profile.data.settings[key], 44)
	toggle.custom_minimum_size.x = 67
	toggle.add_theme_font_size_override("font_size", 13)
	row.add_child(toggle)
	panel.add_child(row)

func show_how_to() -> void:
	_new_page("how_to", 16)
	_header("HOW TO PLAY", show_home)
	body.add_child(EchoStyle.label("Simple moves.\nLasting echoes.", 43, EchoStyle.TEXT, true))
	for item in [["01", "Follow the gold", "Drag in the lower control pad to steer. Releasing your thumb keeps you moving. Collect sparks before the timer empties."], ["02", "Remember your route", "Every eight seconds, a purple echo repeats your earlier movement. Its body is dangerous. Its fading trail is safe."], ["03", "Leave yourself an escape", "Avoid walls and echoes. Each extra echo increases the points per spark. The same daily route is available to everyone, with unlimited tries."]]:
		var panel := _panel(body)
		panel.add_child(EchoStyle.label(item[0] + "  /  " + item[1], 21, EchoStyle.MINT, true))
		panel.add_child(_paragraph(item[2], 15))
	body.add_child(EchoStyle.spacer(2, true))
	body.add_child(EchoStyle.button("TRY THE GUIDED RUN", func() -> void:
		tutorial_destination = "endless"
		start_tutorial(), true, 62))
	body.add_child(_paragraph("On a computer, use WASD or the arrow keys. Press Esc to pause.", 13))

func show_privacy() -> void:
	_new_page("privacy", 14)
	_header("PRIVACY & CREDITS", show_settings)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(scroll)
	var content := EchoStyle.vbox(15)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	content.add_child(EchoStyle.label("Designed for your downtime.", 25, EchoStyle.TEXT, true))
	content.add_child(EchoStyle.label("Made by " + str(metadata.developer), 16, EchoStyle.MINT, true))
	for paragraph in ["The core game works offline. Scores, settings, and earned cosmetics are stored on your device. There is no player account, chat, advertising, or public leaderboard.", "Optional analytics is off by default. When enabled in a connected release, Firebase receives events such as tutorial completion, runs, retries, and sharing. We do not send your movement history or request your name, contacts, microphone, or location.", "In releases with purchases enabled, Google Play and RevenueCat process purchases and anonymous entitlement records so that you can restore the Supporter Pack. Payment details are handled by the store.", "Turning analytics off stops future usage events. Uninstalling removes local progress; purchased cosmetics can be restored using the same Google Play account. Android may report technical diagnostics through its own platform settings.", "Project ECHO uses Godot Engine (MIT), Inter and Space Grotesk (SIL Open Font License). The geometric artwork and synthesized audio were created for this project. Full notices are bundled with the source."]:
		content.add_child(_paragraph(paragraph, 16))
	content.add_child(EchoStyle.label("DEVELOPMENT BUILD · 0.1.0", 11, EchoStyle.MINT))
	content.add_child(EchoStyle.button("Open-source licences", show_licences))
	if str(metadata.get("privacy_url", "")).begins_with("https://"):
		content.add_child(EchoStyle.button("Privacy policy online", func() -> void: OS.shell_open(str(metadata.privacy_url))))

func show_licences() -> void:
	_new_page("licences", 14)
	_header("OPEN-SOURCE LICENCES", show_privacy)
	var text := RichTextLabel.new()
	text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text.selection_enabled = true
	text.add_theme_font_override("normal_font", EchoStyle.body)
	text.add_theme_font_size_override("normal_font_size", 13)
	text.add_theme_color_override("default_color", EchoStyle.MUTED)
	for path in ["res://assets/licenses/godot-license.txt", "res://assets/licenses/godot-copyright.txt", "res://assets/fonts/Inter-OFL.txt", "res://assets/fonts/SpaceGrotesk-OFL.txt", "res://assets/licenses/revenuecat-license.txt", "res://assets/licenses/apache-2.0.txt"]:
		if FileAccess.file_exists(path):
			text.text += path.get_file() + "\n\n" + FileAccess.get_file_as_string(path) + "\n\n"
	body.add_child(text)

func _modal(eyebrow: String, title: String) -> VBoxContainer:
	_close_modal()
	overlay = Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 20
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color(0.015, 0.025, 0.05, 0.93)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = minf(430, get_viewport_rect().size.x - 40)
	panel.add_theme_stylebox_override("panel", EchoStyle.box(Color("122132"), 24))
	center.add_child(panel)
	var content := EchoStyle.vbox(18)
	panel.add_child(content)
	content.add_child(EchoStyle.label(eyebrow, 10, EchoStyle.MINT))
	var heading := EchoStyle.label(title, 32, EchoStyle.TEXT, true)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(heading)
	return content

func _close_modal() -> void:
	replay_view = null
	if is_instance_valid(overlay):
		overlay.hide()
		overlay.queue_free()
		overlay = null

func _toast(text: String) -> void:
	if is_instance_valid(toast):
		toast.queue_free()
	toast = EchoStyle.label(text, 14, EchoStyle.TEXT)
	toast.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast.add_theme_stylebox_override("normal", EchoStyle.box(Color("233648"), 12, Color("527084")))
	toast.z_index = 50
	toast.position = Vector2((get_viewport_rect().size.x - 450) / 2, 16)
	toast.size = Vector2(450, 60)
	add_child(toast)
	toast_left = 4.0

func _prepare_capture() -> void:
	match capture_args.get("screen", "home"):
		"collection": show_collection()
		"settings": show_settings()
		"how_to": show_how_to()
		"supporter": show_supporter()
		"game", "daily", "results":
			start_run(RunConfig.daily(RunConfig.utc_date()) if capture_args.screen == "daily" else RunConfig.endless(423))
			# Drive real simulation toward targets for a reproducible visual fixture.
			for i in range(1200):
				if not run.alive: break
				run.step(DemoPilot.direction(run))
			paused = true
			_update_hud()
			if capture_args.screen == "results":
				while run.alive and run.tick < 7200:
					run.step(run.spark - run.player)
				if run.alive:
					run._die("ended")
				result_info = {"new_best": false}
				show_results()
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.5).timeout
	if OS.has_feature("web"):
		print("CAPTURE_OK ", state)
		return
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(capture_args.get("path", "user://capture.png"))
	print("CAPTURE_OK ", state)
	get_tree().quit()

func _start_showcase() -> void:
	var config := RunConfig.daily(RunConfig.utc_date()) if showcase_mode == "daily" else RunConfig.endless(423)
	start_run(config)
	for i in range(0 if showcase_started else 720):
		if not run.alive: break
		run.step(DemoPilot.direction(run))
	if not run.alive:
		start_run(config)
	game_started = true
	showcase_started = true
	_update_hud()
	print("SHOWCASE_READY")
