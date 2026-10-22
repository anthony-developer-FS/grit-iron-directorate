class_name Pow
extends CharacterBody2D
## A tied-up Allied prisoner. Touching him frees him: he salutes and drops a reward, then grabs a
## rifle and fights beside Grit for up to 10 seconds before heading off. He can't be hurt.

enum State { TIED, SALUTING, FIGHTING, LEAVING }

const SALUTE_TIME := 0.6
const FIGHT_TIME := 10.0
const GRAVITY := 560.0
const RUN_SPEED := 70.0
const FIRE_INTERVAL := 0.45
const FIRE_RANGE := 170.0
const BULLET_SPEED := 260.0
## How far behind Grit he keeps while fighting.
const FOLLOW_DISTANCE := 26.0

const PickupScene := preload("res://scenes/pickups/pickup.tscn")
const BulletScene := preload("res://scenes/projectiles/bullet.tscn")

@export_enum("hmg", "rocket", "shotgun", "flame", "grenades", "ammo") var reward := "hmg"

var state := State.TIED
var facing := 1

var _timer := 0.0
var _fire_cooldown := 0.5
var _muzzle_flash := 0.0
var _rescuer: Player


func _ready() -> void:
	add_to_group("pows")
	$Touch.body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	_timer += delta
	_muzzle_flash = maxf(_muzzle_flash - delta, 0.0)
	velocity.y = minf(velocity.y + GRAVITY * delta, 320.0)
	velocity.x = 0.0
	match state:
		State.SALUTING:
			if _timer >= SALUTE_TIME:
				_drop_reward()
				_set_state(State.FIGHTING)
		State.FIGHTING:
			_fight(delta)
			if _timer >= FIGHT_TIME or not is_instance_valid(_rescuer) or _rescuer.dead:
				_set_state(State.LEAVING)
		State.LEAVING:
			facing = -1
			velocity.x = -RUN_SPEED
			if _timer > 4.0 or get_global_transform_with_canvas().origin.x < -32.0:
				queue_free()
	move_and_slide()
	queue_redraw()


func is_fighting() -> bool:
	return state == State.FIGHTING


func _set_state(new_state: State) -> void:
	state = new_state
	_timer = 0.0


func _on_body_entered(body: Node) -> void:
	var player := body as Player
	if state != State.TIED or player == null or player.dead:
		return
	_rescuer = player
	_set_state(State.SALUTING)
	Game.rescue_pow()
	Game.show_message("THANK YOU! I'LL COVER YOU!", 1.2)


func _drop_reward() -> void:
	var pickup := PickupScene.instantiate() as Pickup
	pickup.kind = reward
	# Drop the reward just ahead of Grit so he doesn't have to backtrack for it.
	var drop_x := position.x + 14.0
	if is_instance_valid(_rescuer):
		drop_x = _rescuer.global_position.x + 20.0 * _rescuer.facing
	pickup.position = Vector2(drop_x, position.y)
	get_parent().add_child(pickup)


func _fight(delta: float) -> void:
	# Keep up with Grit, a step behind him.
	var spot := _rescuer.global_position.x - FOLLOW_DISTANCE * _rescuer.facing
	if absf(spot - global_position.x) > 6.0:
		velocity.x = signf(spot - global_position.x) * RUN_SPEED
		facing = int(signf(velocity.x))
	if _rescuer.is_on_floor() and global_position.distance_to(_rescuer.global_position) > 90.0:
		# Left behind by a wall, a ledge or the elevator: catch up.
		global_position = _rescuer.global_position + Vector2(-FOLLOW_DISTANCE * _rescuer.facing, 0)

	var target := _find_target()
	if target == null:
		return
	var aim_point: Vector2 = target.global_position + Vector2(0, -12)
	facing = 1 if aim_point.x > global_position.x else -1
	_fire_cooldown -= delta
	if _fire_cooldown > 0.0:
		return
	_fire_cooldown = FIRE_INTERVAL
	var muzzle := global_position + Vector2(facing * 10, -17)
	var bullet := BulletScene.instantiate() as Bullet
	bullet.setup(Bullet.Team.PLAYER, muzzle, (aim_point - muzzle).normalized() * BULLET_SPEED, 1)
	# His shots don't count toward Grit's accuracy.
	bullet.counts_for_accuracy = false
	get_parent().add_child(bullet)
	_muzzle_flash = 0.05


func _find_target() -> Node2D:
	var best: Node2D = null
	var best_distance := FIRE_RANGE
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if absf(offset.y) > 70.0:
			continue
		if offset.length() < best_distance and Rect2(Vector2.ZERO, get_viewport_rect().size).has_point(enemy.get_global_transform_with_canvas().origin):
			best = enemy
			best_distance = offset.length()
	return best


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
			var moving := absf(velocity.x) > 1.0
			var bob := roundf(sin(_timer * 20.0)) if moving else 0.0
			draw_rect(Rect2(-4, -9 + bob, 3, 9), Color("3d3324"))
			draw_rect(Rect2(1, -9 + bob, 3, 9), Color("3d3324"))
			draw_rect(Rect2(-5, -20 + bob, 10, 11), shirt)
			draw_rect(Rect2(-4, -27 + bob, 8, 7), skin)
			draw_rect(Rect2(-4, -22 + bob, 8, 3), beard)
			draw_rect(Rect2(-5, -28 + bob, 10, 2), Color("5a6b3a"))
			if state == State.SALUTING:
				draw_line(Vector2(4, -18), Vector2(6, -26), skin, 2.0)
			elif state == State.FIGHTING:
				draw_line(Vector2(facing * 2, -16 + bob), Vector2(facing * 11, -17 + bob), Color("3b2a1a"), 2.0)
				if _muzzle_flash > 0.0:
					draw_circle(Vector2(facing * 12, -17 + bob), 2.5, Color("fff2a8"))
