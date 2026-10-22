class_name ArenaTrigger
extends Area2D
## Locks the camera when Grit walks in and wakes the arena's boss.
## The camera unlocks again when the boss emits `defeated`.

@export var camera_path: NodePath
@export var boss_path: NodePath
## Camera center while the arena is locked.
@export var lock_x := 0.0
@export var announcement := "WARNING!"
## Crate dropped where the boss died, if any.
@export_enum("none", "hmg", "rocket", "shotgun", "flame", "grenades") var reward := "none"

const PickupScene := preload("res://scenes/pickups/pickup.tscn")

var _triggered := false


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _triggered or not body is Player:
		return
	_triggered = true
	var camera := get_node_or_null(camera_path) as ForwardCamera
	var boss := get_node_or_null(boss_path)
	if camera:
		camera.lock_at(lock_x)
	if boss == null:
		return
	Game.show_message(announcement, 1.5)
	boss.defeated.connect(_on_boss_defeated.bind(boss))
	boss.wake()


func _on_boss_defeated(boss: Node2D) -> void:
	var camera := get_node_or_null(camera_path) as ForwardCamera
	if camera:
		camera.unlock()
	if reward != "none":
		var pickup := PickupScene.instantiate() as Pickup
		pickup.kind = reward
		# Drop it on the ground just ahead of Grit so he doesn't have to backtrack.
		var drop_x := boss.global_position.x - 40.0
		var player := get_tree().get_first_node_in_group("player") as Player
		if player:
			drop_x = maxf(drop_x, player.global_position.x + 24.0)
		pickup.position = Vector2(drop_x, boss.global_position.y)
		get_parent().add_child.call_deferred(pickup)
