class_name Goal
extends Area2D
## End of the test range. Locks the camera and shows the results.

@export var camera_path: NodePath

var _reached := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _reached or not body is Player:
		return
	_reached = true
	var camera := get_node_or_null(camera_path) as ForwardCamera
	if camera:
		camera.locked = true
	Game.show_message("TEST RANGE CLEAR!\nSCORE %d   POWs %d" % [Game.score, Game.pows_rescued], 5.0)


func _draw() -> void:
	draw_rect(Rect2(-1, -48, 2, 48), Color("c9c1a6"))
	draw_rect(Rect2(1, -48, 16, 10), Color("6b7a3a"))
