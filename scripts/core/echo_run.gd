class_name EchoRun
extends RefCounted

const HZ := 60
const DT := 1.0 / HZ
const WORLD := 720.0
const SPEED := 204.0
const PLAYER_RADIUS := 20.0
const ECHO_RADIUS := 21.0
const SPARK_RADIUS := 18.0
const ECHO_INTERVAL := 8 * HZ
const MAX_ECHOES := 6
const GRACE_TICKS := 45
const POP_COST := 3
const POP_RADIUS := 220.0
const POP_RESPAWN := 8 * HZ
const HISTORY_SIZE := (MAX_ECHOES * 8 + 4) * HZ + 1

var config: RunConfig
var tick := 0
var player := Vector2(360, 540)
var heading := Vector2.UP
var spark := Vector2(360, 360)
var charge := 8.0
var pop_charge := 0
var pops := 0
var pop_history: Array[Dictionary] = []
var score := 0
var sparks := 0
var alive := true
var death_cause := ""
var death_echo := 0
var events: Array[Dictionary] = []
var history := PackedVector2Array()
var spark_history := PackedVector2Array()
var charge_history := PackedFloat32Array()
var rng := RandomNumberGenerator.new()
var collected_positions := PackedVector2Array()

func _init(run_config: RunConfig = null) -> void:
	config = run_config if run_config != null else RunConfig.endless(1)
	rng.seed = config.seed_value
	history.resize(HISTORY_SIZE)
	history[0] = player
	spark_history.resize(HISTORY_SIZE)
	charge_history.resize(HISTORY_SIZE)
	_record_visual_state()

func echo_count(at_tick: int = -1) -> int:
	return mini(MAX_ECHOES, maxi(0, (tick if at_tick < 0 else at_tick) / ECHO_INTERVAL))

func charge_limit() -> float:
	return 8.0 - 0.5 * echo_count()

func elapsed() -> float:
	return tick * DT

func position_at(at_tick: float) -> Vector2:
	var bounded := clampf(at_tick, maxi(0, tick - HISTORY_SIZE + 1), tick)
	var a := int(floor(bounded))
	var b := mini(a + 1, tick)
	return history[a % HISTORY_SIZE].lerp(history[b % HISTORY_SIZE], bounded - a)

func echo_position(index: int, at_tick: float = -1) -> Vector2:
	return position_at((float(tick) if at_tick < 0 else at_tick) - index * ECHO_INTERVAL)

func spark_at(at_tick: float) -> Vector2:
	return spark_history[clampi(int(at_tick), maxi(0, tick - HISTORY_SIZE + 1), tick) % HISTORY_SIZE]

func charge_at(at_tick: float) -> float:
	return charge_history[clampi(int(at_tick), maxi(0, tick - HISTORY_SIZE + 1), tick) % HISTORY_SIZE]

func _record_visual_state() -> void:
	spark_history[tick % HISTORY_SIZE] = spark
	charge_history[tick % HISTORY_SIZE] = charge

func echo_is_present(index: int, at_tick: int = -1) -> bool:
	var now := tick if at_tick < 0 else at_tick
	if now < index * ECHO_INTERVAL:
		return false
	for pop in pop_history:
		if pop.index == index and now >= pop.start and now < pop.end:
			return false
	return true

func echo_is_live(index: int, at_tick: int = -1) -> bool:
	var now := tick if at_tick < 0 else at_tick
	if not echo_is_present(index, now) or now < index * ECHO_INTERVAL + GRACE_TICKS:
		return false
	for pop in pop_history:
		if pop.index == index and now >= pop.end and now < pop.end + GRACE_TICKS:
			return false
	return true

func pop_echoes() -> Array[Vector2]:
	var cleared: Array[Vector2] = []
	if not alive or pop_charge < POP_COST:
		return cleared
	for index in range(1, echo_count() + 1):
		if echo_is_present(index) and player.distance_to(echo_position(index)) <= POP_RADIUS:
			cleared.append(echo_position(index))
			pop_history.append({"index": index, "start": tick, "end": tick + POP_RESPAWN})
	if not cleared.is_empty():
		pop_charge = 0
		pops += cleared.size()
	return cleared

func step(steering: Vector2 = Vector2.ZERO) -> void:
	events.clear()
	if not alive:
		return
	if steering.length_squared() > 0.01:
		heading = steering.normalized()
	var previous := player
	player += heading * SPEED * DT
	tick += 1
	history[tick % HISTORY_SIZE] = player
	charge -= DT
	# Keep all intervals needed by the replay ring; bound memory for long runs.
	pop_history = pop_history.filter(func(pop: Dictionary) -> bool: return pop.end + GRACE_TICKS >= tick - HISTORY_SIZE)
	if tick % ECHO_INTERVAL == 0 and tick / ECHO_INTERVAL <= MAX_ECHOES:
		events.append({"type": "echo", "count": echo_count()})
		charge = minf(charge, charge_limit())
	if player.x < PLAYER_RADIUS or player.x > WORLD - PLAYER_RADIUS or player.y < PLAYER_RADIUS or player.y > WORLD - PLAYER_RADIUS:
		_die("wall")
		return
	for index in range(1, echo_count() + 1):
		if not echo_is_live(index):
			continue
		var echo_before := echo_position(index, tick - 1)
		var echo_now := echo_position(index)
		if swept_overlap(previous - echo_before, player - echo_now, PLAYER_RADIUS + ECHO_RADIUS):
			death_echo = index
			_die("echo")
			return
	if swept_overlap(previous - spark, player - spark, PLAYER_RADIUS + SPARK_RADIUS):
		sparks += 1
		pop_charge = mini(POP_COST, pop_charge + 1)
		var points := 10 * (1 + echo_count())
		score += points
		collected_positions.append(spark)
		if collected_positions.size() > 100:
			collected_positions.remove_at(0)
		events.append({"type": "spark", "position": spark, "points": points})
		charge = charge_limit()
		spark = next_spark(spark)
	if charge <= 0.0:
		_die("charge")
	_record_visual_state()

func next_spark(previous_spark: Vector2) -> Vector2:
	# Depends ONLY on the seed and previous target, never on player position/time.
	for attempt in range(256):
		var candidate := Vector2(rng.randf_range(60, 660), rng.randf_range(60, 660))
		var distance := candidate.distance_to(previous_spark)
		if distance >= 180.0 and distance <= 430.0:
			return candidate
	# Deterministic bounded fallback, always within the maximum travel distance.
	return Vector2(540 if previous_spark.x < 360 else 180, previous_spark.y)

func _die(cause: String) -> void:
	alive = false
	death_cause = cause
	_record_visual_state()
	events.append({"type": "death", "cause": cause})

static func swept_overlap(relative_start: Vector2, relative_end: Vector2, radius: float) -> bool:
	var motion := relative_end - relative_start
	var length_sq := motion.length_squared()
	var t := clampf(-relative_start.dot(motion) / length_sq, 0, 1) if length_sq > 0.000001 else 0.0
	return (relative_start + t * motion).length_squared() <= radius * radius

func result() -> Dictionary:
	return {"mode": config.mode, "seed": config.seed_value, "rules_version": RunConfig.RULES_VERSION,
		"daily_date": config.daily_date, "score": score, "sparks": sparks, "duration": elapsed(),
		"death_cause": death_cause, "echoes": echo_count(), "pops": pops}
