extends Node2D
## Placeholder storm-sky backdrop: distant cliffs and ships drawn as flat silhouettes.
## Lives under a Parallax2D so it scrolls slower than the level.

const WIDTH := 320.0


func _draw() -> void:
	# Distant cliffs.
	var cliffs := PackedVector2Array([
		Vector2(0, 130), Vector2(30, 100), Vector2(60, 108), Vector2(95, 82), Vector2(140, 95),
		Vector2(175, 78), Vector2(215, 98), Vector2(250, 88), Vector2(290, 104), Vector2(WIDTH, 130),
	])
	draw_colored_polygon(cliffs, Color("23303d"))
	# Allied ships on the horizon.
	for x in [40.0, 200.0]:
		draw_rect(Rect2(x, 120, 30, 4), Color("1a222b"))
		draw_rect(Rect2(x + 10, 114, 8, 6), Color("1a222b"))
	# Sea.
	draw_rect(Rect2(0, 124, WIDTH, 60), Color("1c2a33"))
