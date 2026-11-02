extends SceneTree

var checks := 0
var failed := false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failed = true
		push_error(description)

func _run() -> void:
	var app: Node = load("res://scenes/main.tscn").instantiate()
	root.add_child(app)
	await process_frame
	app.profile = ProfileStore.new("user://ui-smoke-profile.json")
	check(app.state == "home", "home loads")
	for screen in ["show_collection", "show_journal", "show_settings", "show_how_to", "show_privacy", "show_licences", "show_supporter", "show_home"]:
		app.call(screen)
		await process_frame
		check(is_instance_valid(app.page), screen + " creates its UI")
	check(not app.services.supporter and app.services.price.is_empty(), "unconfigured store does not fake entitlements or prices")
	await process_frame
	var collection_button: Button
	for control in app.find_children("*", "Button", true, false):
		if control.text == "COLLECTION":
			collection_button = control
	var press := InputEventScreenTouch.new()
	press.index = 0
	# parse_input_event takes physical window pixels. Headless windows are 64x64,
	# so logical UI positions must pass through the viewport's final transform.
	press.position = root.get_final_transform() * collection_button.get_global_rect().get_center()
	press.pressed = true
	Input.parse_input_event(press)
	await process_frame
	var release := InputEventScreenTouch.new()
	release.index = 0
	release.position = press.position
	release.pressed = false
	Input.parse_input_event(release)
	await process_frame
	check(app.state == "collection", "real screen-touch events activate menu buttons")
	app._show_pal(1)
	await process_frame
	check(is_instance_valid(app.overlay) and app.profile.data.skin == 0, "previewing a locked pal does not change the selected pal")
	check(not app._equip_skin(1), "locked pal cannot be equipped from its preview")
	app.profile.data.lifetime_sparks = 10
	check(app._equip_skin(1) and app.profile.data.skin == 1, "earned pal can be equipped after confirmation")
	var restored := ProfileStore.new("user://ui-smoke-profile.json")
	restored.load_profile()
	check(restored.data.skin == 1 and restored.data.lifetime_sparks == 10, "equipping preserves collected sparks and survives a reload")
	app.show_home()
	app.profile.data.skin = 10
	app.profile.data.theme = 2
	app.profile.data.sound_set = 1
	app.services._on_offer("TEST PRICE")
	check(app.profile.data.skin == 10 and app.profile.data.theme == 2 and app.profile.data.sound_set == 1, "price callback cannot revoke an unresolved entitlement")
	app.services._on_entitlement(true)
	check(app.profile.data.skin == 10 and app.services.entitlement_known, "confirmed ownership preserves supporter selections")
	app._show_pal(10)
	app.services._on_entitlement(false)
	check(app.profile.data.skin == 0 and app.profile.data.theme == 0 and app.profile.data.sound_set == 0, "confirmed revocation resets supporter selections")
	check(not app._equip_skin(10), "an open preview cannot equip a pal after ownership is revoked")
	app.services.price = ""
	app.profile.data.tutorial_complete = true
	app.start_run(RunConfig.endless(42))
	await process_frame
	await process_frame
	check(app.help_label.get_global_rect().end.y <= root.get_visible_rect().size.y, "game controls and instructions fit the portrait viewport")
	var touch_at: Vector2 = app.arena.get_global_rect().get_center()
	_touch(touch_at, true, 0)
	check(app.pad.held and app.pad.origin.distance_to(touch_at) < 1, "floating joystick begins where the screen is touched")
	_touch(touch_at + Vector2(50, 20), true, 1)
	check(app.pad.touch_id == 0, "a second finger cannot steal the joystick")
	_drag(touch_at + Vector2(0, -50), 0)
	check(app.pad.direction.y < -0.9, "real screen drag steers the floating joystick")
	_touch(touch_at, false, 1)
	check(app.pad.held, "lifting another finger does not release steering")
	app._physics_process(1.0 / 60)
	var pop_taps := [0]
	app.pop_button.pressed.connect(func() -> void: pop_taps[0] += 1)
	_touch(app.pop_button.get_global_rect().get_center(), true, 1)
	_touch(app.pop_button.get_global_rect().get_center(), false, 1)
	check(pop_taps[0] == 1 and app.pad.held, "a second finger can tap POP while the first keeps steering")
	_touch(app.pop_button.get_global_rect().get_center(), true, 1)
	_drag(touch_at, 1)
	_touch(touch_at, false, 1)
	check(pop_taps[0] == 1 and app.pad.held, "dragging off POP cancels the tap without interrupting steering")
	_touch(app.pop_button.get_global_rect().get_center(), false, 0)
	check(not app.pad.held and app.run.heading == Vector2.UP, "release over a button ends gesture and preserves heading")
	_touch(app.pop_button.get_global_rect().get_center(), true, 0)
	_touch(app.pop_button.get_global_rect().get_center(), false, 0)
	check(not app.pad.held and not app.paused, "POP button does not start an accidental joystick gesture")
	var pause_button: Button
	for control in app.page.find_children("*", "Button", true, false):
		if control.text == "II": pause_button = control
	_touch(pause_button.get_global_rect().get_center(), true, 0)
	_touch(pause_button.get_global_rect().get_center(), false, 0)
	check(app.paused and not app.pad.held, "pause button receives real touch above the joystick layer")
	app._toggle_music()
	check(not app.audio.music.playing and not app.profile.data.settings.music, "music toggle stops playback and saves the setting")
	app._toggle_music()
	check(app.audio.music.playing and app.profile.data.settings.music, "music can be restarted from the game")
	app.profile.data.settings.fixed_joystick = true
	app.start_run(RunConfig.endless(42))
	await process_frame
	await process_frame
	_touch(Vector2(270, 200), true, 0)
	check(not app.pad.held, "fixed mode ignores touches outside its large control")
	_touch(Vector2(270, 200), false, 0)
	_touch(app.pad.fixed_center + Vector2(30, 0), true, 0)
	check(app.pad.held and app.pad.direction.x > 0.9, "large fixed joystick steers relative to its visible center")
	_touch(app.pad.fixed_center, false, 0)
	app.profile.data.settings.fixed_joystick = false
	app.start_run(RunConfig.daily("2026-10-30"))
	await process_frame
	check(not app.game_started and app.run.tick == 0, "run waits for deliberate steering")
	check(app.goal_label.text.contains("75"), "daily medal goal is visible before the first move")
	app.pad.direction = Vector2.UP
	for i in range(48):
		app._physics_process(1.0 / 60)
	check(app.run.sparks == 1, "actual game input collects a spark")
	app.pause_game()
	var tick: int = app.run.tick
	app._physics_process(1.0 / 60)
	check(app.run.tick == tick and app.paused, "pause stops simulation")
	app._resume_game()
	check(app.resume_time == 3, "resume protects player with countdown")
	app._process(3.1)
	check(not app.paused and app.resume_time <= 0, "countdown resumes run")
	app.profile.data.lifetime_sparks = 24
	app.run.death_cause = "wall"
	app.run.alive = false
	app._end_run()
	await process_frame
	check(app.state == "results" and app.profile.data.runs == 1, "death records once and shows results")
	check(app.result_info.unlocked_indices == [2], "results identify the pal earned by this completed run")
	var reward_button: Button
	for control in app.page.find_children("*", "Button", true, false):
		if control.text == "PLAY WITH PETAL":
			reward_button = control
	if is_instance_valid(reward_button):
		reward_button.pressed.emit()
	check(is_instance_valid(reward_button) and app.profile.data.skin == 2, "reward button equips the newly earned pal")
	check(app.state == "game" and app.run.config.daily_date == "2026-10-30", "reward retry preserves the starting daily challenge")
	app.pad.direction = Vector2.UP
	app._physics_process(1.0 / 60)
	app._finish_and_home()
	check(app.state == "home" and app.profile.data.runs == 2, "explicitly ending a run banks earned progress")
	app.queue_free()
	await process_frame
	await create_timer(0.12).timeout
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute("user://ui-smoke-profile.json" + suffix)
	print("UI SMOKE: %d checks, failed=%s" % [checks, failed])
	quit(1 if failed else 0)

func _touch(at: Vector2, down: bool, finger: int) -> void:
	var event := InputEventScreenTouch.new()
	event.position = root.get_final_transform() * at
	event.pressed = down
	event.index = finger
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _drag(at: Vector2, finger: int) -> void:
	var event := InputEventScreenDrag.new()
	event.position = root.get_final_transform() * at
	event.index = finger
	Input.parse_input_event(event)
	Input.flush_buffered_events()
