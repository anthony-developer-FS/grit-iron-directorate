class_name ArtilleryStrike
extends Node2D
## A shell called in on a spot: a red flare marks the impact point, then the shell drops and explodes.
## Used by mortar crews, the artillery barrage and the boss. Place it on the ground where the shell lands.

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")
const FALL_TIME := 0.3

@export var warning_time := 1.6
@export var radius := 22.0

var _time := 0.0
var _exploded := false


## Returns the ground point straight below `from`, or `from` itself if nothing is there.
static func find_ground(space: PhysicsDirectSpaceState2D, from: Vector2) -> Vector2:
	var query := PhysicsRayQueryParameters2D.create(from + Vector2(0, -8), from + Vector2(0, 240), 1 | 8)
	var hit := space.intersect_ray(query)
	return hit["position"] if hit else from


func _ready() -> void:
	Sfx.play("flare", 0.0)


func _process(delta: float) -> void:
	var whistle_at := maxf(warning_time + FALL_TIME - 0.9, 0.0)
	if _time < whistle_at and _time + delta >= whistle_at:
		Sfx.play("shell_whistle", 0.1)
	_time += delta
	if not _exploded and _time >= warning_time + FALL_TIME:
		_exploded = true
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = position + Vector2(0, -6)
		explosion.radius = radius
		# Shells hurt Grit and any Directorate troops caught underneath.
		explosion.hurts_player = true
		explosion.shake_strength = 5.0
		get_parent().add_child(explosion)
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	if _time < warning_time:
		# Flare: blinking faster as impact nears.
		var blink := int(_time * (6.0 + 10.0 * _time / warning_time)) % 2 == 0
		draw_rect(Rect2(-1, -6, 2, 6), Color("8a8a8a"))
		draw_circle(Vector2(0, -7), 2.5, Color("ff3b3b") if blink else Color("ff9a3b"))
		draw_arc(Vector2(0, -2), radius * (1.0 - _time / warning_time * 0.5), PI, TAU, 16, Color(1, 0.2, 0.2, 0.5), 1.0)
	else:
		var fall := (_time - warning_time) / FALL_TIME
		var y := lerpf(-200.0, -6.0, fall)
		draw_rect(Rect2(-2, y - 8, 4, 8), Color("2b2b2b"))
		draw_line(Vector2(0, y - 30), Vector2(0, y - 8), Color(1, 1, 1, 0.3), 1.0)
