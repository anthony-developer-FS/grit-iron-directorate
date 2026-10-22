class_name Checkpoint
extends Area2D
## Saves Grit's progress. "Restart from checkpoint" on the pause or game over screen returns here.

var _reached := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	Game.reach_checkpoint(global_position)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-1, -40, 2, 40), Color("c9c1a6"))
	var flag := Color("ffe066") if _reached else Color("5a5e62")
	draw_colored_polygon(PackedVector2Array([Vector2(1, -40), Vector2(15, -35), Vector2(1, -30)]), flag)
