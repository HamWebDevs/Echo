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
	for screen in ["show_collection", "show_settings", "show_how_to", "show_privacy", "show_licences", "show_supporter", "show_home"]:
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
	app.show_home()
	app.profile.data.skin = 10
	app.profile.data.theme = 2
	app.profile.data.sound_set = 1
	app.services._on_offer("TEST PRICE")
	check(app.profile.data.skin == 10 and app.profile.data.theme == 2 and app.profile.data.sound_set == 1, "price callback cannot revoke an unresolved entitlement")
	app.services._on_entitlement(true)
	check(app.profile.data.skin == 10 and app.services.entitlement_known, "confirmed ownership preserves supporter selections")
	app.services._on_entitlement(false)
	check(app.profile.data.skin == 0 and app.profile.data.theme == 0 and app.profile.data.sound_set == 0, "confirmed revocation resets supporter selections")
	app.services.price = ""
	app.profile.data.tutorial_complete = true
	app.start_run(RunConfig.daily("2026-10-30"))
	await process_frame
	check(not app.game_started and app.run.tick == 0, "run waits for deliberate steering")
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
	app.run.death_cause = "wall"
	app.run.alive = false
	app._end_run()
	await process_frame
	check(app.state == "results" and app.profile.data.runs == 1, "death records once and shows results")
	app._retry()
	check(app.state == "game" and app.run.config.daily_date == "2026-10-30", "daily retry preserves the starting challenge")
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
