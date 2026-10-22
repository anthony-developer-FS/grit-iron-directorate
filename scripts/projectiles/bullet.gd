class_name Bullet
extends Area2D
## A straight-flying projectile. Player and enemy bullets share this scene and differ by team.
## `style` changes the look and behavior for shotgun pellets and flamethrower bursts.

enum Team { PLAYER, ENEMY }
enum Style { BULLET, PELLET, FLAME, FLAK, SHELL }

const PLAYER_MASK := 1 | 4 # world + enemies
const ENEMY_MASK := 1 | 2 # world + player

var team := Team.PLAYER
var style := Style.BULLET
var velocity := Vector2.ZERO
var damage := 1
var lifetime := 1.6
## Piercing projectiles (flames) pass through targets, hitting each one once.
var pierce := false
## Off for shots that shouldn't affect Grit's accuracy (e.g. from rescued POWs).
var counts_for_accuracy := true

var _age := 0.0
var _already_hit: Array[Node] = []


func setup(bullet_team: Team, start_position: Vector2, start_velocity: Vector2, bullet_damage: int, bullet_style := Style.BULLET) -> void:
	team = bullet_team
	style = bullet_style
	position = start_position
	velocity = start_velocity
	damage = bullet_damage
	rotation = velocity.angle()
	collision_layer = 0
	collision_mask = PLAYER_MASK if team == Team.PLAYER else ENEMY_MASK
	match style:
		Style.PELLET:
			lifetime = 0.22
		Style.FLAME:
			lifetime = 0.35
			pierce = true
		Style.SHELL:
			lifetime = 4.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	if team == Team.PLAYER and counts_for_accuracy:
		Game.shots_fired += 1


func _physics_process(delta: float) -> void:
	var from := global_position
	position += velocity * delta
	_sweep(from, global_position)
	_age += delta
	if _age > lifetime:
		queue_free()
	elif style == Style.FLAME:
		queue_redraw()


## Checks the path flown this frame for anything solid. The Area2D's body_entered signal still
## catches moving bodies (troops, vehicles), even point blank, but area overlaps never report
## static bodies (walls, MG nests, boss parts), so those need this ray. It also stops fast shots
## skipping past thin targets between frames.
func _sweep(from: Vector2, to: Vector2) -> void:
	var space := get_world_2d().direct_space_state
	var query := PhysicsRayQueryParameters2D.create(from, to, collision_mask)
	# Piercing shots can pass through several targets in one frame.
	for i in 4:
		query.exclude = _already_hit.map(func(body: Node) -> RID: return body.get_rid())
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return
		global_position = hit["position"] if not pierce else global_position
		_on_body_entered(hit["collider"])
		if is_queued_for_deletion() or not hit["collider"] in _already_hit:
			return


func _on_body_entered(body: Node) -> void:
	if body in _already_hit:
		return
	if body.has_method("blocks_hit") and body.blocks_hit(global_position):
		queue_free()
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
		if team == Team.PLAYER and counts_for_accuracy and body.is_in_group("enemies") and _already_hit.is_empty():
			Game.shots_hit += 1
		_already_hit.append(body)
		if pierce:
			return
	queue_free()


func _draw() -> void:
	match style:
		Style.BULLET:
			if team == Team.PLAYER:
				draw_rect(Rect2(-3, -1, 6, 2), Color("ffe066"))
			else:
				draw_circle(Vector2.ZERO, 2.0, Color("ff7a1a"))
				draw_circle(Vector2.ZERO, 1.0, Color("fff2a8"))
		Style.PELLET:
			draw_rect(Rect2(-1, -1, 3, 2), Color("ffe066"))
		Style.FLAME:
			var t := _age / lifetime
			draw_circle(Vector2.ZERO, 3.0 + 6.0 * t, Color(1.0, 0.45 + 0.3 * (1.0 - t), 0.1, 1.0 - t * 0.7))
			draw_circle(Vector2.ZERO, 2.0 + 2.0 * t, Color(1.0, 0.95, 0.6, 1.0 - t))
		Style.FLAK:
			draw_circle(Vector2.ZERO, 3.0, Color("ff4632"))
			draw_circle(Vector2.ZERO, 1.5, Color("ffe066"))
		Style.SHELL:
			draw_rect(Rect2(-14, -5, 28, 10), Color("3a3e44"))
			draw_rect(Rect2(-14, -5, 28, 2), Color("6a7078"))
			draw_circle(Vector2(-14, 0), 5.0, Color("ff7a1a"))
