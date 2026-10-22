class_name Pow
extends Area2D
## A tied-up prisoner of war. Touching him frees him; he salutes, drops a reward crate and runs off.

enum State { TIED, SALUTING, LEAVING }

const SALUTE_TIME := 0.6
const RUN_SPEED := 70.0
const PickupScene := preload("res://scenes/pickups/pickup.tscn")

@export_enum("hmg", "grenades") var reward := "hmg"

var state := State.TIED
var _timer := 0.0
var _rescuer: Player


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_timer += delta
	match state:
		State.SALUTING:
			if _timer >= SALUTE_TIME:
				var pickup := PickupScene.instantiate() as Pickup
				pickup.kind = reward
				# Drop the crate just ahead of Grit so he doesn't have to backtrack for it.
				var drop_x := position.x + 14.0
				if is_instance_valid(_rescuer):
					drop_x = _rescuer.global_position.x + 20.0 * _rescuer.facing
				pickup.position = Vector2(drop_x, position.y)
				get_parent().add_child(pickup)
				state = State.LEAVING
				_timer = 0.0
		State.LEAVING:
			position.x -= RUN_SPEED * delta
			if _timer > 3.0:
				queue_free()
	queue_redraw()


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if state != State.TIED or player == null or player.dead:
		return
	state = State.SALUTING
	_timer = 0.0
	_rescuer = player
	Game.rescue_pow()
	Game.show_message("THANK YOU!", 1.0)


func _draw() -> void:
	var skin := Color("e0b48a")
	var beard := Color("7a5230")
	var shirt := Color("c9c1a6")
	match state:
		State.TIED:
			var sway := roundf(sin(_timer * 3.0))
			draw_rect(Rect2(-7, -4, 14, 4), Color("3d3324"))
			draw_rect(Rect2(-5 + sway, -14, 10, 10), shirt)
			draw_rect(Rect2(-4 + sway, -21, 8, 7), skin)
			draw_rect(Rect2(-4 + sway, -16, 8, 3), beard)
			draw_line(Vector2(-6 + sway, -10), Vector2(6 + sway, -8), Color("a07c4a"), 1.0)
			draw_line(Vector2(-6 + sway, -7), Vector2(6 + sway, -5), Color("a07c4a"), 1.0)
		_:
			var bob := roundf(sin(_timer * 20.0)) if state == State.LEAVING else 0.0
			draw_rect(Rect2(-4, -9 + bob, 3, 9), Color("3d3324"))
			draw_rect(Rect2(1, -9 + bob, 3, 9), Color("3d3324"))
			draw_rect(Rect2(-5, -20 + bob, 10, 11), shirt)
			draw_rect(Rect2(-4, -27 + bob, 8, 7), skin)
			draw_rect(Rect2(-4, -22 + bob, 8, 3), beard)
			if state == State.SALUTING:
				draw_line(Vector2(4, -18), Vector2(6, -26), skin, 2.0)
