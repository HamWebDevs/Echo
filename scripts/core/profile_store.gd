class_name ProfileStore
extends RefCounted

const THRESHOLDS := [0, 10, 25, 50, 100, 200, 400, 800, 1600]
const SKIN_NAMES := ["Pip", "Skipper", "Petal", "Mochi", "Party Bean", "Peaches", "Sprout", "Sunny", "Cupcake", "Lagoon", "Moonflower", "Butters", "Pickle"]
var path := "user://profile.json"
var data: Dictionary
var recovered := false
var save_failed := false

func _init(save_path: String = "user://profile.json") -> void:
	path = save_path
	data = defaults()

static func defaults() -> Dictionary:
	return {"schema": 1, "best": 0, "longest": 0.0, "runs": 0, "lifetime_sparks": 0,
		"tutorial_complete": false, "skin": 0, "theme": 0, "sound_set": 0, "daily": {},
		"settings": {"sound": true, "music": true, "haptics": true, "reduced_motion": false,
			"high_contrast": false, "analytics": false}}

func load_profile() -> void:
	var loaded := _read(path)
	if loaded.is_empty():
		loaded = _read(path + ".bak")
		recovered = not loaded.is_empty()
	if not loaded.is_empty():
		data = _sanitize(loaded)

func _read(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(file_path)) != OK:
		return {}
	var parsed: Variant = parser.data
	if not parsed is Dictionary:
		return {}
	var schema: Variant = parsed.get("schema")
	if not (schema is int or schema is float) or float(schema) != 1.0:
		return {}
	return parsed

func _safe_integer(value: Variant, maximum: int = 2000000000) -> int:
	if not (value is int or value is float) or not is_finite(float(value)):
		return 0
	return int(clampf(float(value), 0, maximum))

func _sanitize(source: Dictionary) -> Dictionary:
	var clean := defaults()
	for key in ["best", "runs", "lifetime_sparks"]:
		clean[key] = _safe_integer(source.get(key))
	if source.get("longest") is float or source.get("longest") is int:
		clean.longest = clampf(float(source.longest), 0, 10000000) if is_finite(float(source.longest)) else 0.0
	clean.tutorial_complete = source.get("tutorial_complete", false) == true
	for key in ["skin", "theme", "sound_set"]:
		clean[key] = _safe_integer(source.get(key), 12 if key == "skin" else (2 if key == "theme" else 1))
	if source.get("settings") is Dictionary:
		for key in clean.settings:
			if source.settings.get(key) is bool:
				clean.settings[key] = source.settings[key]
	if source.get("daily") is Dictionary:
		for key in source.daily:
			var entry: Variant = source.daily[key]
			if key is String and key.length() <= 24 and entry is Dictionary and (entry.get("score") is float or entry.get("score") is int):
				clean.daily[key] = {"score": _safe_integer(entry.score), "sparks": _safe_integer(entry.get("sparks"))}
	return clean

func save() -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		save_failed = true
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	if _read(temporary).is_empty():
		save_failed = true
		return false
	# Never replace a valid backup with a corrupted primary.
	if not _read(path).is_empty():
		DirAccess.copy_absolute(path, path + ".bak")
	var error := DirAccess.rename_absolute(temporary, path)
	save_failed = error != OK
	return not save_failed

func record(run: EchoRun) -> Dictionary:
	var old_best := best_for(run.config)
	var old_unlocks := unlocked_count()
	data.runs += 1
	data.lifetime_sparks += run.sparks
	data.longest = maxf(data.longest, run.elapsed())
	if run.config.mode == "daily":
		var key := run.config.record_key()
		if run.score > old_best or not data.daily.has(key):
			data.daily[key] = {"score": run.score, "sparks": run.sparks}
		var keys: Array = data.daily.keys()
		keys.sort()
		while keys.size() > 90:
			data.daily.erase(keys.pop_front())
	else:
		data.best = maxi(data.best, run.score)
	save()
	return {"new_best": run.score > old_best, "previous_best": old_best, "unlocked": unlocked_count() > old_unlocks}

func best_for(config: RunConfig) -> int:
	if config.mode == "daily":
		return int(data.daily.get(config.record_key(), {}).get("score", 0))
	return int(data.best)

func unlocked_count() -> int:
	var count := 0
	for threshold in THRESHOLDS:
		if int(data.lifetime_sparks) >= threshold:
			count += 1
	return count

func skin_available(index: int, supporter: bool = false) -> bool:
	return (index < THRESHOLDS.size() and index < unlocked_count()) or (index >= THRESHOLDS.size() and index < SKIN_NAMES.size() and supporter)

func next_unlock() -> int:
	for threshold in THRESHOLDS:
		if int(data.lifetime_sparks) < threshold:
			return threshold
	return -1
