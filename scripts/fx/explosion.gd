class_name Explosion
extends Node2D
## Splash damage plus a placeholder fireball. Damages enemies and/or Grit within `radius`.

const DURATION := 0.4

@export var radius := 24.0
@export var damage := 5
@export var hurts_enemies := true
@export var hurts_player := false
@export var shake_strength := 4.0

var _time := 0.0


func _ready() -> void:
	Game.shake(shake_strength, 0.25)
	var targets: Array[Node] = []
	if hurts_enemies:
		targets.append_array(get_tree().get_nodes_in_group("enemies"))
	if hurts_player:
		targets.append_array(get_tree().get_nodes_in_group("player"))
	for target in targets:
		if not target is Node2D or not target.has_method("take_damage"):
			continue
		# Targets have their origin at their feet, so measure to roughly their center.
		var center: Vector2 = target.global_position + Vector2(0, -12)
		if center.distance_to(global_position) <= radius + 6.0:
			target.take_damage(damage)


func _process(delta: float) -> void:
	_time += delta
	if _time >= DURATION:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var t := _time / DURATION
	draw_circle(Vector2.ZERO, radius * (0.4 + 0.6 * t), Color(1.0, 0.45, 0.1, 1.0 - t))
	draw_circle(Vector2.ZERO, radius * 0.55 * (1.0 - t), Color(1.0, 0.95, 0.6, 1.0 - t))
	for i in 6:
		var angle := TAU * i / 6.0 + t
		draw_circle(Vector2.from_angle(angle) * radius * t, 3.0 * (1.0 - t), Color(0.3, 0.3, 0.3, 1.0 - t))
