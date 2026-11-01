class_name DemoPilot
extends RefCounted
## Used only by explicit debug capture/showcase arguments. Never used in normal play.

static func direction(run: EchoRun) -> Vector2:
	var toward := (run.spark - run.player).normalized()
	var best := toward
	var best_score := -INF
	for candidate in range(17):
		var heading := toward if candidate == 0 else Vector2.from_angle((candidate - 1) * TAU / 16)
		var score := heading.dot(toward) * 40.0 + heading.dot(run.heading) * 2.0
		for seconds in [0.12, 0.3, 0.55, 0.85]:
			var future: Vector2 = run.player + heading * EchoRun.SPEED * seconds
			var edge := minf(minf(future.x, 720 - future.x), minf(future.y, 720 - future.y))
			if edge < 28:
				score -= (28 - edge) * 10
			var future_tick: int = run.tick + int(seconds * 60)
			for index in range(1, run.echo_count(future_tick) + 1):
				if not run.echo_is_live(index, future_tick):
					continue
				var distance := future.distance_to(run.echo_position(index, future_tick))
				if distance < 60:
					score -= (60 - distance) * 5
		if score > best_score:
			best_score = score
			best = heading
	return best
