class_name EchoAudio
extends Node

var settings: Dictionary = {}
var effects: Dictionary = {}
var music: AudioStreamPlayer
var sound_set := 0

func _ready() -> void:
	for key in ["spark", "echo", "death", "start", "click"]:
		var player := AudioStreamPlayer.new()
		player.stream = load("res://assets/audio/%s.wav" % key)
		player.volume_db = -8
		add_child(player)
		effects[key] = player
	music = AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/ambient.wav")
	music.volume_db = -21
	add_child(music)
	music.finished.connect(func() -> void: music.play() if settings.get("music", true) else music.stop())

func apply(new_settings: Dictionary) -> void:
	settings = new_settings
	if not settings.get("music", true) and music != null:
		music.stop()

func begin_music() -> void:
	if settings.get("music", true) and not music.playing:
		music.play()

func play(key: String, echo_count: int = 0) -> void:
	if settings.get("sound", true) and effects.has(key):
		var player := effects[key] as AudioStreamPlayer
		player.pitch_scale = (1.0 + echo_count * 0.025) * (0.87 if sound_set == 1 else 1.0)
		player.play()
	if settings.get("haptics", true) and OS.has_feature("android"):
		Input.vibrate_handheld(45 if key == "death" else 15)
	if music != null:
		music.volume_db = -23 + mini(echo_count, 6) * 0.6

func _exit_tree() -> void:
	for child in get_children():
		if child is AudioStreamPlayer:
			child.stop()
			child.stream = null
