extends Node2D
## Screen-space rain for the storm. Lives on a CanvasLayer above the level.

const DROPS := 90
const SPEED := Vector2(-60, 340)

## World-space areas with a roof (bunkers, shafts) where the rain is hidden.
@export var indoor_areas: Array[Rect2] = []

var _drops: Array[Vector2] = []


func _ready() -> void:
	for i in DROPS:
		_drops.append(Vector2(randf_range(0, 360), randf_range(0, 180)))


func _process(delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	visible = true
	if player:
		for area in indoor_areas:
			if area.has_point(player.global_position):
				visible = false
	for i in _drops.size():
		var drop := _drops[i] + SPEED * delta * (0.8 + 0.4 * float(i % 3) / 2.0)
		if drop.y > 184.0:
			drop = Vector2(randf_range(0, 380), -6.0)
		_drops[i] = drop
	queue_redraw()


func _draw() -> void:
	for drop in _drops:
		draw_line(drop, drop + Vector2(-2, 6), Color(0.7, 0.78, 0.86, 0.35), 1.0)
