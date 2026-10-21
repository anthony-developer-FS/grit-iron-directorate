extends CanvasLayer
## Arcade-style HUD: lives, score, weapon and ammo, grenades, plus centered messages,
## the pause screen and the game over / continue screen.

@onready var _lives_label: Label = $Lives
@onready var _score_label: Label = $Score
@onready var _arms_label: Label = $Arms
@onready var _bombs_label: Label = $Bombs
@onready var _center_label: Label = $Center

var _message_time := 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.score_changed.connect(_on_score_changed)
	Game.lives_changed.connect(_on_lives_changed)
	Game.grenades_changed.connect(_on_grenades_changed)
	Game.weapon_changed.connect(_on_weapon_changed)
	Game.message_requested.connect(_on_message_requested)
	Game.game_over.connect(_on_game_over)
	_on_score_changed(Game.score)
	_on_lives_changed(Game.lives)
	_on_grenades_changed(Game.grenades)
	_center_label.text = ""
	Game.show_message("MISSION START!", 1.5)


func _process(delta: float) -> void:
	if Game.is_game_over:
		if Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("jump"):
			_center_label.text = ""
			Game.continue_game()
		return

	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		_center_label.text = "PAUSED" if get_tree().paused else ""
		_message_time = 0.0
		return

	if _message_time > 0.0 and not get_tree().paused:
		_message_time -= delta
		if _message_time <= 0.0:
			_center_label.text = ""


func _on_score_changed(score: int) -> void:
	_score_label.text = "%07d" % score


func _on_lives_changed(lives: int) -> void:
	_lives_label.text = "GRIT x%d" % maxi(lives, 0)


func _on_grenades_changed(grenades: int) -> void:
	_bombs_label.text = "BOMBS %d" % grenades


func _on_weapon_changed(label: String, ammo: int) -> void:
	_arms_label.text = "%s %s" % [label, "--" if ammo < 0 else str(ammo)]


func _on_message_requested(text: String, duration: float) -> void:
	_center_label.text = text
	_message_time = duration


func _on_game_over() -> void:
	_message_time = 0.0
	_center_label.text = "GAME OVER\nPRESS SHOOT TO CONTINUE"
