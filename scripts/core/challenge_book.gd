class_name ChallengeBook
extends RefCounted

# Permanent skill milestones: no countdown, spending or loss of earned progress.
const GOALS := [
	{"id": "pocket", "title": "Pocket of sunshine", "detail": "Collect 3 sparks in one run.", "metric": "run_sparks", "target": 3, "pal": 0},
	{"id": "copycat", "title": "Hello, copycat!", "detail": "Meet your first echo.", "metric": "max_echoes", "target": 1, "pal": 2},
	{"id": "fifteen", "title": "Finding your feet", "detail": "Stay in a run for 15 seconds.", "metric": "longest", "target": 15, "pal": 1},
	{"id": "hundred", "title": "Triple digits", "detail": "Score 100 points in one run.", "metric": "best_score", "target": 100, "pal": 7},
	{"id": "collector", "title": "Little treasure hunter", "detail": "Collect 25 lifetime sparks.", "metric": "lifetime_sparks", "target": 25, "pal": 6},
	{"id": "double", "title": "Double trouble", "detail": "Meet two echoes in one run.", "metric": "max_echoes", "target": 2, "pal": 5},
	{"id": "ten", "title": "Star catcher", "detail": "Collect 10 sparks in one run.", "metric": "run_sparks", "target": 10, "pal": 8},
	{"id": "thirty", "title": "A little longer", "detail": "Survive for 30 seconds.", "metric": "longest", "target": 30, "pal": 3},
	{"id": "threehundred", "title": "On a roll", "detail": "Score 300 points in one run.", "metric": "best_score", "target": 300, "pal": 4},
	{"id": "hoard", "title": "A jar of stars", "detail": "Collect 100 lifetime sparks.", "metric": "lifetime_sparks", "target": 100, "pal": 11},
	{"id": "fortyfive", "title": "Fancy footwork", "detail": "Survive for 45 seconds.", "metric": "longest", "target": 45, "pal": 9},
	{"id": "six", "title": "The whole parade", "detail": "Meet all six echoes in one run.", "metric": "max_echoes", "target": 6, "pal": 12}
]

static func progress(data: Dictionary, goal: Dictionary) -> int:
	return mini(int(data.get(goal.metric, 0)), int(goal.target))

static func earned(data: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for goal in GOALS:
		if progress(data, goal) >= goal.target:
			result.append(goal.id)
	return result

static func next_goal(data: Dictionary) -> Dictionary:
	for goal in GOALS:
		if progress(data, goal) < goal.target:
			return goal
	return {}

static func daily_medal(score: int) -> String:
	if score >= 450: return "Gold"
	if score >= 200: return "Silver"
	if score >= 75: return "Bronze"
	return ""

static func daily_target(score: int) -> int:
	for target in [75, 200, 450]:
		if score < target: return target
	return 0
