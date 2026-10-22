class_name Rifleman
extends Enemy
## Basic Directorate infantry. Patrols, aims with a visible telegraph, fires slow bullets,
## and panics when Grit gets too close.

enum State { PATROL, AIM, COOLDOWN, PANIC }

const WALK_SPEED := 22.0
const PANIC_SPEED := 60.0
const SIGHT_RANGE := 160.0
const PANIC_RANGE := 26.0
const AIM_TIME := 0.55
const BULLET_SPEED := 110.0
const FRAMES := ["idle", "run0", "run1", "run2", "run3", "run4", "run5", "aim", "shoot",
	"panic0", "panic1", "dead0", "dead1"]

@export var patrol_distance := 24.0

var state := State.PATROL

var _timer := 0.0
var _panic_cooldown := 0.0
var _home_x := 0.0
var _shot_flash := 0.0


func _ready() -> void:
	super._ready()
	_home_x = global_position.x
	_timer = randf_range(0.4, 1.2)


func _think(delta: float, player: Player) -> void:
	_timer -= delta
	_shot_flash = maxf(_shot_flash - delta, 0.0)
	_panic_cooldown = maxf(_panic_cooldown - delta, 0.0)

	match state:
		State.PATROL:
			velocity.x = facing * WALK_SPEED
			if absf(global_position.x - _home_x) > patrol_distance:
				facing = 1 if global_position.x < _home_x else -1
			if player and _can_see(player):
				_face(player)
				velocity.x = 0.0
				if _timer <= 0.0:
					state = State.AIM
					_timer = AIM_TIME
		State.AIM:
			velocity.x = 0.0
			if player:
				_face(player)
			if _timer <= 0.0:
				if player:
					_shoot(player)
				state = State.COOLDOWN
				_timer = randf_range(1.2, 2.2)
		State.COOLDOWN:
			velocity.x = 0.0
			if _timer <= 0.0:
				state = State.PATROL
		State.PANIC:
			velocity.x = facing * PANIC_SPEED
			if _timer <= 0.0:
				state = State.PATROL
				_timer = 0.4

	if player and state != State.PANIC and _panic_cooldown <= 0.0 \
			and absf(player.global_position.x - global_position.x) < PANIC_RANGE:
		# Run away from Grit, genre-style.
		state = State.PANIC
		facing = 1 if global_position.x > player.global_position.x else -1
		_timer = 0.7
		_panic_cooldown = 3.0


func _can_see(player: Player) -> bool:
	var offset := player.global_position - global_position
	return absf(offset.x) < SIGHT_RANGE and absf(offset.y) < 60.0


func _shoot(player: Player) -> void:
	var muzzle := global_position + Vector2(facing * 9, -18)
	var direction := player.global_position + Vector2(0, -18) - muzzle
	# Shots at Grit's level fly flat, so crouching dodges them.
	if absf(direction.y) < 12.0:
		direction.y = 0.0
	direction.x = absf(direction.x) * facing
	_fire_bullet(muzzle, direction, BULLET_SPEED)
	_shot_flash = 0.1


func _draw() -> void:
	if dead:
		_draw_frame(0, _death_frame(FRAMES))
		return
	match state:
		State.PANIC:
			_draw_frame(0, _cycle(FRAMES, "panic", 2, 8.0))
			draw_string(ThemeDB.fallback_font, Vector2(-2, -32), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color("ffe066"))
		State.AIM:
			_draw_frame(0, FRAMES.find("aim"))
			# Blinking red telegraph at the muzzle before the shot.
			if int(_timer * 16.0) % 2 == 0:
				draw_circle(Vector2(facing * 14, -17), 1.5, Color("ff3b3b"))
		_:
			if _shot_flash > 0.0:
				_draw_frame(0, FRAMES.find("shoot"))
			elif absf(velocity.x) > 1.0:
				_draw_frame(0, _cycle(FRAMES, "run", 6, 8.0))
			else:
				_draw_frame(0, FRAMES.find("idle"))
