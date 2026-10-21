class_name Grenade
extends CharacterBody2D
## Thrown in an arc. Bounces once, then explodes on the next touch, on hitting an enemy, or when the fuse runs out.

const GRAVITY := 420.0
const FUSE_TIME := 1.5
const BOUNCE_DAMPING := 0.45

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

var _age := 0.0
var _bounces := 0


func _physics_process(delta: float) -> void:
	_age += delta
	velocity.y += GRAVITY * delta
	rotation += velocity.x * 0.08 * delta
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group("enemies"):
			_explode()
			return
		_bounces += 1
		if _bounces >= 2:
			_explode()
			return
		velocity = velocity.bounce(collision.get_normal()) * BOUNCE_DAMPING
	if _age >= FUSE_TIME:
		_explode()


func _explode() -> void:
	var explosion := ExplosionScene.instantiate() as Explosion
	explosion.position = global_position
	get_parent().add_child(explosion)
	queue_free()


func _draw() -> void:
	draw_rect(Rect2(-2, -3, 4, 6), Color("4a5530"))
	draw_rect(Rect2(-1, -4, 2, 1), Color("9a9a9a"))
