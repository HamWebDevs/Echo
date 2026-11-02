class_name BuddyPortrait
extends Control

var skin := 0
var reduced_motion := false
var celebrate := false
var surprised := false
var clock := 0.0

func _init() -> void:
	custom_minimum_size = Vector2(100, 140)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	if not reduced_motion:
		clock += delta
		queue_redraw()

func _draw() -> void:
	var radius := minf(size.x * 0.26, size.y * 0.30)
	var centre := size * Vector2(0.5, 0.58)
	var bob := sin(clock * 3.4) * 4.0 if not reduced_motion else 0.0
	draw_circle(centre, radius * 1.55, Color("f7e8c3"))
	if celebrate:
		for i in range(8):
			var angle := i * TAU / 8.0 + (clock * 0.12 if not reduced_motion else 0.0)
			var offset := Vector2.from_angle(angle) * radius * 1.65
			CartoonArt.star(self, centre + offset, 5 + float(i % 2) * 2, angle)
	# Portrait-only squash and bounce: gameplay collision silhouettes never move.
	var squash := sin(clock * 3.4 + 0.5) * 0.035 if not reduced_motion else 0.0
	draw_set_transform(centre + Vector2(0, bob), 0, Vector2(1 + squash, 1 - squash))
	CartoonArt.buddy(self, Vector2.ZERO, radius, skin, clock, false, 1.0, surprised and clock < 1.2)
	draw_set_transform(Vector2.ZERO)
