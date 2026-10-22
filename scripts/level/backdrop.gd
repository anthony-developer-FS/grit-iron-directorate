extends Node2D
## Distant cliffs, the sea and the Allied fleet (tools/art/world.py). Lives under a Parallax2D so
## it scrolls slower than the level; the storm sky behind it is fixed to the screen.

const FarLayer := preload("res://assets/sprites/far_layer.png")


func _draw() -> void:
	draw_texture(FarLayer, Vector2.ZERO)
