@tool
class_name Interior
extends Node2D
## Concrete back wall of an indoor area (bunker interior, elevator shaft), drawn behind the level.
## The origin is the top-left corner.

@export var size := Vector2(200, 100):
	set(value):
		size = value
		queue_redraw()
@export var color := Color("24282c"):
	set(value):
		color = value
		queue_redraw()


const WallTexture := preload("res://assets/sprites/interior_wall.png")


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	# Concrete panels, tinted toward `color` so each room keeps its own shade.
	draw_texture_rect(WallTexture, Rect2(Vector2.ZERO, size), true, color.lightened(0.6))
