class_name Bullet
extends Area2D
## A straight-flying bullet. Player and enemy bullets share this scene and differ by team.

enum Team { PLAYER, ENEMY }

const LIFETIME := 1.6
const PLAYER_MASK := 1 | 4 # world + enemies
const ENEMY_MASK := 1 | 2 # world + player

var team := Team.PLAYER
var velocity := Vector2.ZERO
var damage := 1

var _age := 0.0


func setup(bullet_team: Team, start_position: Vector2, start_velocity: Vector2, bullet_damage: int) -> void:
	team = bullet_team
	position = start_position
	velocity = start_velocity
	damage = bullet_damage
	rotation = velocity.angle()
	collision_layer = 0
	collision_mask = PLAYER_MASK if team == Team.PLAYER else ENEMY_MASK


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	position += velocity * delta
	_age += delta
	if _age > LIFETIME:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()


func _draw() -> void:
	if team == Team.PLAYER:
		draw_rect(Rect2(-3, -1, 6, 2), Color("ffe066"))
	else:
		draw_circle(Vector2.ZERO, 2.0, Color("ff7a1a"))
		draw_circle(Vector2.ZERO, 1.0, Color("fff2a8"))
