extends Node2D
## Root of a mission level. Starts the mission (when run straight from the editor),
## puts Grit at the last checkpoint if restarting, snaps the camera to him, and starts the
## timed supply drops.

@onready var _player: Player = $Player
@onready var _camera: ForwardCamera = $Camera


func _ready() -> void:
	if not Game.mission_running:
		Game.start_mission()
	if Game.checkpoint_position != Vector2.INF:
		_player.place_at(Game.checkpoint_position)
	_camera.snap_to_target()
	Music.play("mission")
	var drops := SupplyDrops.new()
	drops.player = _player
	drops.camera = _camera
	add_child(drops)
	if not _player.parachuting:
		return
	# Parachute drop: keep the camera at beach level while Grit drifts down into view.
	_camera.hold_height(_camera.max_y)
