class_name SupplyDrops
extends Node
## Parachutes a random special weapon in just ahead of Grit every minute or so, more often during
## arena fights, so he always has something heavier than the pistol coming. When he is low on
## grenades a bomb crate comes down alongside it.

const PickupScene := preload("res://scenes/pickups/pickup.tscn")
const WEAPONS := ["hmg", "rocket", "shotgun", "flame"]
const MIN_INTERVAL := 60.0
const MAX_INTERVAL := 90.0
## While the camera is locked for an arena fight (half-track, Seewall battery).
const ARENA_INTERVAL := 40.0
const LOW_GRENADES := 4
## How far ahead of Grit the crate lands.
const DROP_AHEAD := 60.0

var player: Player
var camera: ForwardCamera

var _timer := 0.0


func _ready() -> void:
	_timer = randf_range(MIN_INTERVAL, MAX_INTERVAL)


func _physics_process(delta: float) -> void:
	if player == null or player.dead or player.parachuting or not Game.mission_running:
		return
	_timer -= delta
	if camera.locked:
		_timer = minf(_timer, ARENA_INTERVAL)
	if _timer > 0.0:
		return
	_timer = ARENA_INTERVAL if camera.locked else randf_range(MIN_INTERVAL, MAX_INTERVAL)
	drop()


func drop() -> void:
	var choices := WEAPONS.filter(func(weapon: String) -> bool: return weapon != player.weapon)
	var x := player.global_position.x + DROP_AHEAD
	if camera.locked:
		# Keep it on screen in an arena; the view can't scroll to reach it.
		var half_width := camera.get_viewport_rect().size.x / 2.0
		x = clampf(x, camera.global_position.x - half_width + 24.0, camera.global_position.x + half_width - 40.0)
	_spawn(choices.pick_random(), x)
	if Game.grenades <= LOW_GRENADES:
		_spawn("grenades", x + 28.0)
	Game.show_message("SUPPLY DROP!", 1.2)
	Sfx.play("supply_drop", 0.0)


func _spawn(kind: String, x: float) -> void:
	var space := player.get_world_2d().direct_space_state
	# Land on whatever floor Grit is on, or fall back to his height over a pit.
	var from := Vector2(x, player.global_position.y - 40.0)
	var ground := ArtilleryStrike.find_ground(space, from)
	if ground == from:
		ground = Vector2(x, player.global_position.y)
	var pickup := PickupScene.instantiate() as Pickup
	pickup.kind = kind
	pickup.parachute = true
	pickup.position = ground
	get_parent().add_child(pickup)
