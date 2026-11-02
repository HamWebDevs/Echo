extends SceneTree

var checks := 0
var failures := 0

func _initialize() -> void:
	_test_daily_seed()
	_test_targets()
	_test_scoring_and_walls()
	_test_echoes()
	_test_swept_collision()
	_test_history()
	_test_profile()
	_test_challenges()
	print("CORE TESTS: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error("FAIL: " + message)

func _test_daily_seed() -> void:
	var a := RunConfig.daily("2026-10-30")
	var b := RunConfig.daily("2026-10-30")
	var c := RunConfig.daily("2026-10-31")
	check(a.seed_value == b.seed_value, "same UTC date has the same seed")
	check(a.seed_value != c.seed_value, "next UTC day changes the seed")
	check(a.record_key() == "2026-10-30:v1", "records include date and rules")
	check(a.daily_date == "2026-10-30", "starting date does not follow clock rollover")

func _test_targets() -> void:
	var a := EchoRun.new(RunConfig.endless(12345))
	var b := EchoRun.new(RunConfig.endless(12345))
	var previous := a.spark
	var deterministic := true
	var bounded := true
	for i in range(10000):
		var next := a.next_spark(previous)
		var other := b.next_spark(previous)
		deterministic = deterministic and next == other
		bounded = bounded and next.x >= 60 and next.x <= 660 and next.y >= 60 and next.y <= 660
		bounded = bounded and previous.distance_to(next) >= 180 and previous.distance_to(next) <= 430
		previous = next
	check(deterministic, "10,000 seeded targets match independently of play timing")
	check(bounded, "10,000 targets respect margins and reachable distances")

func _test_scoring_and_walls() -> void:
	var run := EchoRun.new()
	for i in range(47):
		run.step(Vector2.UP)
	check(run.sparks == 1 and run.score == 10, "first spark awards ten points")
	check(run.charge > 7.9, "spark refreshes charge")
	check(run.spark_at(0) == Vector2(360, 360) and run.spark_at(run.tick) == run.spark, "replay restores historical target rather than the final one")
	check(absf(run.charge_at(run.tick) - run.charge) < 0.0001, "replay preserves spark timer")
	var wall := EchoRun.new()
	for i in range(300):
		wall.step(Vector2.RIGHT)
	check(not wall.alive and wall.death_cause == "wall", "wall collision ends run")
	var final_tick := wall.tick
	wall.step(Vector2.LEFT)
	check(wall.tick == final_tick, "dead run cannot advance")
	var empty := EchoRun.new()
	empty.charge = EchoRun.DT / 2
	empty.step(Vector2.RIGHT)
	check(empty.death_cause == "charge", "empty charge ends run")
	var last_chance := EchoRun.new()
	last_chance.charge = EchoRun.DT / 2
	last_chance.spark = last_chance.player + Vector2(0, -20)
	last_chance.step(Vector2.UP)
	check(last_chance.alive and last_chance.sparks == 1, "collection on final tick refills before expiry")

func _test_echoes() -> void:
	var run := EchoRun.new()
	run.tick = 479
	run.player = Vector2(360, 360)
	run.history.fill(Vector2(100, 100))
	run.history[479] = run.player
	run.spark = Vector2(360, 340)
	run.step(Vector2.UP)
	check(run.echo_count() == 1 and run.score == 20, "first echo activates score multiplier at eight seconds")
	check(not run.echo_is_live(1), "spawned echo starts with collision grace")
	check(run.charge_limit() == 7.5, "first echo reduces charge limit")
	check(run.echo_position(1) == Vector2(100, 100), "echo reads delayed history")
	run.tick = 523
	run.player = Vector2(100,100)
	run.history.fill(Vector2(100,100))
	run.spark = Vector2(600,600)
	run.step(Vector2.RIGHT)
	check(run.alive, "echo harmless on last grace tick")
	run.player = Vector2(100,100)
	run.step(Vector2.RIGHT)
	check(not run.alive and run.death_cause == "echo", "echo lethal exactly after grace period")
	check(run.death_echo == 1, "death identifies responsible echo")
	run.tick = 10000
	check(run.echo_count() == 6 and run.charge_limit() == 5.0, "difficulty caps at six echoes and five seconds")

func _test_swept_collision() -> void:
	check(EchoRun.swept_overlap(Vector2(-100, 0), Vector2(100, 0), 25), "fast crossing cannot tunnel through a body")
	check(not EchoRun.swept_overlap(Vector2(-100, 26), Vector2(100, 26), 25), "near miss outside hitbox is safe")
	check(EchoRun.swept_overlap(Vector2(25, 0), Vector2(25, 0), 25), "stationary tangent counts as collision")
	check(not EchoRun.swept_overlap(Vector2(30, 0), Vector2(30, 0), 25), "stationary separated bodies stay safe")

func _test_history() -> void:
	var run := EchoRun.new()
	for i in range(1, 5001):
		run.tick = i
		run.history[i % EchoRun.HISTORY_SIZE] = Vector2(i, i * 2)
	check(run.position_at(4500.5) == Vector2(4500.5, 9001), "wrapped history interpolates correct samples")
	check(run.echo_position(6) == Vector2(2120, 4240), "oldest echo survives buffer wrap")
	check(run.history.size() == EchoRun.HISTORY_SIZE, "history memory remains bounded")

func _test_profile() -> void:
	var path := "user://core-test-profile.json"
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)
	var store := ProfileStore.new(path)
	check(store.save(), "new profile saves")
	store.data.lifetime_sparks = 50
	store.data.best = 240
	check(store.save(), "profile can be atomically replaced")
	var restored := ProfileStore.new(path)
	restored.load_profile()
	check(restored.data.best == 240 and restored.unlocked_count() == 4, "saved progress and unlocks restored")
	restored.data.best = 999
	restored.save()
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken save")
	file.close()
	var recovered := ProfileStore.new(path)
	recovered.load_profile()
	check(recovered.recovered and recovered.data.best == 240, "corrupt primary falls back to valid previous save")
	check(recovered.save(), "recovered state can be saved")
	file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string('{"schema":{}}')
	file.close()
	var malformed := ProfileStore.new(path)
	malformed.load_profile()
	check(malformed.recovered and malformed.data.best == 240, "invalid schema type falls back without a runtime error")
	var safe := recovered._sanitize({"schema": 1, "daily": {"2026-11-01:v1": {"score": 50, "sparks": []}}, "skin": {}})
	check(safe.skin == 0 and safe.daily["2026-11-01:v1"].sparks == 0, "invalid nested scalar types are safely normalized")
	check(not recovered.skin_available(9, false), "premium skin cannot be earned or selected without entitlement")
	check(recovered.skin_available(9, true), "verified entitlement unlocks premium skins")
	var daily := EchoRun.new(RunConfig.daily("2026-10-30"))
	daily.score = 160
	daily.sparks = 8
	recovered.record(daily)
	check(recovered.best_for(daily.config) == 160 and recovered.data.best == 240, "daily and endless records remain separate")
	check(recovered.best_for(RunConfig.daily("2026-10-31")) == 0, "new day starts a separate record")
	check(not recovered.skin_available(-1, true) and not recovered.skin_available(13, true), "invalid pal IDs cannot be selected even with ownership")
	recovered.data.lifetime_sparks = 9
	var reward := EchoRun.new()
	reward.sparks = 1
	check(recovered.record(reward).unlocked_indices == [1], "crossing a threshold names the newly earned pal")
	check(recovered.record(reward).unlocked_indices.is_empty(), "the next run does not announce the same unlock again")
	reward.sparks = 40
	check(recovered.record(reward).unlocked_indices == [2, 3], "one run can report every newly earned pal")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)

func _test_challenges() -> void:
	var path := "user://journal-test-profile.json"
	var store := ProfileStore.new(path)
	check(ChallengeBook.earned(store.data).is_empty(), "fresh players start with an empty journal")
	var sample := EchoRun.new(RunConfig.daily("2026-11-02"))
	sample.score = 210
	sample.sparks = 10
	sample.tick = 20 * 60
	var reward := store.record(sample)
	check(reward.new_stickers.has("pocket") and reward.new_stickers.has("double") and reward.new_stickers.has("hundred"), "one run can complete several skill goals")
	check(store.data.best == 0 and store.data.best_score == 210, "daily score contributes to goals without replacing endless best")
	var earned := ChallengeBook.earned(store.data)
	check(store.record(EchoRun.new()).new_stickers.is_empty() and ChallengeBook.earned(store.data) == earned, "a weaker run preserves stickers and does not award them twice")
	var restored := ProfileStore.new(path)
	restored.load_profile()
	check(ChallengeBook.earned(restored.data) == earned, "stickers survive a save and reload")
	var tutorial := EchoRun.new()
	tutorial.config.tutorial = true
	tutorial.sparks = 999
	tutorial.score = 9999
	var before: Dictionary = store.data.duplicate(true)
	store.record(tutorial)
	check(store.data == before, "tutorial practice cannot grant stickers or regular progress")
	for i in range(7):
		var extra := EchoRun.new()
		extra.score = i
		store.record(extra)
	check(store.data.recent_runs.size() == 5 and store.data.recent_runs[0].score == 2 and store.data.recent_runs[-1].score == 6, "recent runs retain only the latest five in order")
	var migrated := store._sanitize({"schema": 1, "best": 300, "longest": 33, "daily": {"old:v1": {"score": 450, "sparks": 12}}})
	check(migrated.best_score == 450 and migrated.run_sparks == 12 and migrated.max_echoes == 4, "old saves recover supported milestone facts")
	var malformed := store._sanitize({"schema": 1, "recent_runs": [{"score": []}, "bad"], "run_sparks": {}, "max_echoes": -7})
	check(malformed.recent_runs.size() == 1 and malformed.recent_runs[0].score == 0 and malformed.max_echoes == 0, "malformed journal fields are safely normalized")
	check(ChallengeBook.daily_medal(74) == "" and ChallengeBook.daily_medal(75) == "Bronze", "bronze medal begins at exactly 75")
	check(ChallengeBook.daily_medal(199) == "Bronze" and ChallengeBook.daily_medal(200) == "Silver", "silver medal begins at exactly 200")
	check(ChallengeBook.daily_medal(449) == "Silver" and ChallengeBook.daily_medal(450) == "Gold" and ChallengeBook.daily_target(450) == 0, "gold medal is the final daily target")
	check(store.best_for(RunConfig.daily("2026-11-03")) == 0 and not ChallengeBook.earned(store.data).is_empty(), "a new daily route leaves permanent stickers intact")
	for suffix in ["", ".bak", ".tmp"]:
		DirAccess.remove_absolute(path + suffix)
