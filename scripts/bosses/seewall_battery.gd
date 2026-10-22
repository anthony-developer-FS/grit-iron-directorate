class_name SeewallBattery
extends Node2D
## Mission 1 boss: the Seewall gun battery, a cliff-top fortress wall commanded by Kommandant Brandt.
## Phase 1: two flak turrets, plus riflemen from the hatch.
## Phase 2: the main cannon fires a ground-level shell (dodge it on the raised planks) between mortar rounds.
## Phase 3: the exposed generator core sprays spiraling bullets while debris falls.
## The origin is the foot of the fortress wall, at ground level.

signal defeated

enum Phase { DORMANT, TURRETS, CANNON, CORE, DESTROYED }

const BulletScene := preload("res://scenes/projectiles/bullet.tscn")
const RiflemanScene := preload("res://scenes/enemies/rifleman.tscn")
const StrikeScene := preload("res://scenes/fx/artillery_strike.tscn")
const ExplosionScene := preload("res://scenes/fx/explosion.tscn")

## Left edge of the arena floor, for aiming mortar rounds and debris.
@export var arena_left := -220.0

var phase := Phase.DORMANT

var _timer := 0.0
var _attack_timer := 0.0
var _spawn_timer := 4.0
var _spiral_angle := 0.0
var _charging := false
var _death_timer := 0.0

@onready var _turret_low: BossPart = $TurretLow
@onready var _turret_high: BossPart = $TurretHigh
@onready var _breech: BossPart = $Breech
@onready var _core: BossPart = $Core


func _ready() -> void:
	_turret_low.destroyed.connect(_on_part_destroyed)
	_turret_high.destroyed.connect(_on_part_destroyed)
	_breech.destroyed.connect(_on_part_destroyed)
	_core.destroyed.connect(_on_part_destroyed)


## Called by the arena trigger when Grit walks in.
func wake() -> void:
	if phase != Phase.DORMANT:
		return
	_set_phase(Phase.TURRETS)


func total_health_fraction() -> float:
	var parts := [_turret_low, _turret_high, _breech, _core]
	var health := 0.0
	var max_health := 0.0
	for part: BossPart in parts:
		health += maxi(part.health, 0)
		max_health += part.max_health
	return health / max_health


func _set_phase(new_phase: Phase) -> void:
	phase = new_phase
	_timer = 0.0
	_attack_timer = 1.0
	match phase:
		Phase.TURRETS:
			_turret_low.vulnerable = true
			_turret_high.vulnerable = true
			Game.show_message("SILENCE THE SEEWALL!", 2.0)
		Phase.CANNON:
			_breech.vulnerable = true
			_attack_timer = 1.5
			Game.show_message("MAIN CANNON! GET HIGH!", 2.0)
		Phase.CORE:
			_core.vulnerable = true
			Game.show_message("THE GENERATOR IS EXPOSED!", 2.0)
		Phase.DESTROYED:
			_death_timer = 2.5
			Game.add_score(10000)
	Game.boss_health_changed.emit(total_health_fraction() if phase != Phase.DESTROYED else 0.0)
	queue_redraw()


func _on_part_destroyed() -> void:
	Game.boss_health_changed.emit(total_health_fraction())
	match phase:
		Phase.TURRETS:
			if _turret_low.is_destroyed() and _turret_high.is_destroyed():
				_set_phase(Phase.CANNON)
		Phase.CANNON:
			_charging = false
			_breech.charge = 0.0
			_set_phase(Phase.CORE)
		Phase.CORE:
			_set_phase(Phase.DESTROYED)


func _physics_process(delta: float) -> void:
	_timer += delta
	match phase:
		Phase.TURRETS:
			_process_turrets(delta)
		Phase.CANNON:
			_process_cannon(delta)
		Phase.CORE:
			_process_core(delta)
		Phase.DESTROYED:
			_process_destruction(delta)


func _process_turrets(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 0.9
		# Turrets take turns firing a three-shot flak fan at Grit.
		var shooter := _turret_low if int(_timer / 0.9) % 2 == 0 else _turret_high
		if shooter.is_destroyed():
			shooter = _turret_high if shooter == _turret_low else _turret_low
		_fire_fan(shooter.global_position + Vector2(-12, -shooter.size.y * 0.6 - 2))
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 5.0
		_spawn_rifleman()


func _process_cannon(delta: float) -> void:
	_attack_timer -= delta
	if not _charging and _attack_timer <= 0.0:
		_charging = true
		_attack_timer = 1.4
	elif _charging:
		_breech.charge = 1.0 - _attack_timer / 1.4
		if _attack_timer <= 0.0:
			_charging = false
			_breech.charge = 0.0
			_attack_timer = 3.0
			var shell := BulletScene.instantiate() as Bullet
			shell.setup(Bullet.Team.ENEMY, global_position + Vector2(-50, -9), Vector2(-150, 0), 1, Bullet.Style.SHELL)
			get_parent().add_child(shell)
			Game.shake(5.0, 0.3)
			for i in 2:
				_call_strike(randf_range(arena_left + 20.0, -60.0), 1.4)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 7.0
		_spawn_rifleman()


func _process_core(delta: float) -> void:
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = 0.12
		_spiral_angle += 0.45
		var origin := _core.global_position + Vector2(_core.size.x / 2.0, -_core.size.y / 2.0)
		for offset in [0.0, PI]:
			var direction := Vector2.from_angle(_spiral_angle + offset)
			var bullet := BulletScene.instantiate() as Bullet
			bullet.setup(Bullet.Team.ENEMY, origin, direction * 70.0, 1, Bullet.Style.FLAK)
			bullet.lifetime = 4.0
			get_parent().add_child(bullet)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = 1.6
		_call_strike(randf_range(arena_left + 20.0, -40.0), 1.0)


func _process_destruction(delta: float) -> void:
	if _death_timer <= 0.0:
		return
	_death_timer -= delta
	if int(_death_timer * 10.0) != int((_death_timer + delta) * 10.0):
		var explosion := ExplosionScene.instantiate() as Explosion
		explosion.position = global_position + Vector2(randf_range(0.0, 90.0), randf_range(-110.0, -10.0))
		explosion.radius = randf_range(16.0, 30.0)
		explosion.hurts_enemies = false
		get_parent().add_child(explosion)
	if _death_timer <= 0.0:
		visible = false
		defeated.emit()
		Game.complete_mission()


func _fire_fan(muzzle: Vector2) -> void:
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null or player.dead:
		return
	var aim := (player.global_position + Vector2(0, -14) - muzzle).angle()
	for spread in [-0.22, 0.0, 0.22]:
		var bullet := BulletScene.instantiate() as Bullet
		bullet.setup(Bullet.Team.ENEMY, muzzle, Vector2.from_angle(aim + spread) * 95.0, 1, Bullet.Style.FLAK)
		bullet.lifetime = 3.5
		get_parent().add_child(bullet)


func _spawn_rifleman() -> void:
	var riflemen := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Rifleman:
			riflemen += 1
	if riflemen >= 2:
		return
	var rifleman := RiflemanScene.instantiate() as Rifleman
	rifleman.position = global_position + Vector2(-24, -1)
	rifleman.patrol_distance = 40.0
	get_parent().add_child(rifleman)


func _call_strike(local_x: float, warning: float) -> void:
	var strike := StrikeScene.instantiate() as ArtilleryStrike
	strike.position = ArtilleryStrike.find_ground(get_world_2d().direct_space_state, global_position + Vector2(local_x, -60.0))
	strike.warning_time = warning
	get_parent().add_child(strike)


func _draw() -> void:
	if phase == Phase.DESTROYED and _death_timer <= 0.0:
		return
	# Fortress wall with rivets, the command tower and the main cannon.
	draw_rect(Rect2(0, -120, 100, 120), Color("4a4e52"))
	for y in range(-112, 0, 16):
		for x in range(6, 100, 16):
			draw_rect(Rect2(x, y, 2, 2), Color("6a6e72"))
	draw_rect(Rect2(0, -124, 100, 4), Color("2e3134"))
	draw_rect(Rect2(50, -170, 36, 46), Color("3e4246"))
	draw_rect(Rect2(56, -162, 24, 8), Color("ffd27a") if phase != Phase.DORMANT else Color("6a5a3a"))
	draw_rect(Rect2(46, -174, 44, 4), Color("2e3134"))
	draw_rect(Rect2(64, -190, 2, 16), Color("2e3134"))
	draw_colored_polygon(PackedVector2Array([Vector2(66, -190), Vector2(80, -186), Vector2(66, -182)]), Color("b32424"))
	if not _breech.is_destroyed():
		draw_rect(Rect2(-48, -14, 46, 10), Color("3a3e44"))
		draw_rect(Rect2(-52, -16, 6, 14), Color("2b2b2b"))
		if _charging:
			draw_circle(Vector2(-52, -9), 3.0 + 5.0 * _breech.charge, Color(1.0, 0.7, 0.2, 0.5 + 0.5 * _breech.charge))
	# Hatch the riflemen come out of.
	draw_rect(Rect2(4, -30, 14, 30), Color("2a2c2e"))
	if phase in [Phase.TURRETS, Phase.CANNON, Phase.CORE]:
		queue_redraw()
