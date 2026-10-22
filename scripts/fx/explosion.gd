class_name Explosion
extends Node2D
## Splash damage plus a pixel-art fireball (tools/art/fx.py). Damages enemies and/or Grit within `radius`.

const DURATION := 0.55
const FRAME_COUNT := 7
const Sheet := preload("res://assets/sprites/explosion.png")

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
	var frame := mini(int(_time / DURATION * FRAME_COUNT), FRAME_COUNT - 1)
	# The sprite's fireball has a 22 px radius at full size; scale in half steps to keep it crisp.
	var size := maxf(snappedf(radius / 22.0, 0.5), 0.5)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(size, size))
	draw_texture_rect_region(Sheet, Rect2(-24, -24, 48, 48), Rect2(frame * 48, 0, 48, 48))
	draw_set_transform(Vector2.ZERO)
