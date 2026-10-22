class_name Grenade
extends CharacterBody2D
## Thrown in an arc. Bounces once, then explodes on the next touch, on hitting a target, or when the fuse runs out.
## Grit's grenades hurt enemies; grenadiers' grenades hurt Grit.

const GRAVITY := 420.0
const FUSE_TIME := 1.5
const BOUNCE_DAMPING := 0.45

const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

## Which group the explosion damages: &"enemies" for Grit's grenades, &"player" for enemy grenades.
var target_group := &"enemies"

var _age := 0.0
var _bounces := 0


func _ready() -> void:
	# Hit the world, platforms and whoever the grenade is aimed at.
	collision_mask = 1 | 8 | (4 if target_group == &"enemies" else 2)


func _physics_process(delta: float) -> void:
	_age += delta
	velocity.y += GRAVITY * delta
	rotation += velocity.x * 0.08 * delta
	var collision := move_and_collide(velocity * delta)
	if collision:
		var collider := collision.get_collider()
		if collider is Node and collider.is_in_group(target_group):
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
	if target_group == &"player":
		explosion.hurts_player = true
		explosion.hurts_enemies = false
		explosion.radius = 18.0
	get_parent().add_child(explosion)
	queue_free()


func _draw() -> void:
	if target_group == &"player":
		# Directorate stick grenade.
		draw_rect(Rect2(-1, -1, 6, 2), Color("6a4020"))
		draw_rect(Rect2(-4, -2, 4, 4), Color("4a4e54"))
	else:
		draw_rect(Rect2(-2, -3, 4, 6), Color("4a5530"))
		draw_rect(Rect2(-1, -4, 2, 1), Color("9a9a9a"))
