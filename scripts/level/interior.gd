@tool
class_name Interior
extends Node2D
## Dark back wall of an indoor area (bunker interior, elevator shaft), drawn behind the level.
## The origin is the top-left corner.

@export var size := Vector2(200, 100):
	set(value):
		size = value
		queue_redraw()
@export var color := Color("24282c"):
	set(value):
		color = value
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), color)
	# Concrete panel seams.
	for x in range(0, int(size.x), 32):
		draw_line(Vector2(x, 0), Vector2(x, size.y), color.lightened(0.06), 1.0)
	for y in range(0, int(size.y), 24):
		draw_line(Vector2(0, y), Vector2(size.x, y), color.darkened(0.2), 1.0)
