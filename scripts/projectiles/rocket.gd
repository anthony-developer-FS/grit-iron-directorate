class_name Rocket
extends Area2D
## Grit's rocket launcher round. Speeds up, steers gently toward the nearest enemy ahead, and explodes on contact.

const START_SPEED := 120.0
const MAX_SPEED := 300.0
const ACCELERATION := 500.0
const TURN_RATE := 2.5
const SEEK_RANGE := 160.0
const LIFETIME := 2.0

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

var direction := Vector2.RIGHT

var _speed := START_SPEED
var _age := 0.0
var _exploded := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 | 4
	body_entered.connect(func(_body: Node) -> void: _explode())
	Game.shots_fired += 1


func _physics_process(delta: float) -> void:
	_age += delta
	_speed = minf(_speed + ACCELERATION * delta, MAX_SPEED)
	var target := _find_target()
	if target:
		var wanted := (target.global_position + Vector2(0, -12) - global_position).angle()
		direction = Vector2.from_angle(rotate_toward(direction.angle(), wanted, TURN_RATE * delta))
	position += direction * _speed * delta
	rotation = direction.angle()
	if _age > LIFETIME:
		_explode()
	queue_redraw()


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_distance := SEEK_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var offset: Vector2 = enemy.global_position + Vector2(0, -12) - global_position
		# Only seek targets roughly in front, so rockets never loop back.
		if offset.length() < best_distance and offset.normalized().dot(direction) > 0.5:
			best = enemy
			best_distance = offset.length()
	return best


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var explosion := ExplosionScene.instantiate() as Explosion
	explosion.position = global_position
	explosion.radius = 26.0
	explosion.damage = 6
	get_parent().add_child.call_deferred(explosion)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-5, -2, 9, 4), Color("5a6b3a"))
	draw_rect(Rect2(4, -1, 2, 2), Color("b33a3a"))
	draw_circle(Vector2(-7, 0), 2.0 + randf(), Color("ffb040"))
