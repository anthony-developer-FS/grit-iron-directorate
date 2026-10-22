extends CanvasLayer
## Arcade-style HUD: lives, health (Easy mode), score, weapon and ammo, grenades, boss health,
## centered messages, the pause menu, the game over screen and the mission results.

const TITLE_SCENE := "res://scenes/ui/title.tscn"
## Center messages use the big 2x font when every line fits on screen at that size.
const BIG_TEXT := 16
const SMALL_TEXT := 8

@onready var _lives_label: Label = $Lives
@onready var _score_label: Label = $Score
@onready var _arms_label: Label = $Arms
@onready var _bombs_label: Label = $Bombs
@onready var _center_label: Label = $Center
@onready var _boss_bar: Control = $BossBar
@onready var _boss_fill: ColorRect = $BossBar/Fill
@onready var _results_panel: Control = $Results
@onready var _results_label: Label = $Results/Text
@onready var _pause_menu: Menu = $PauseMenu

var _message_time := 0.0
var _weapon_label := "PISTOL"
var _weapon_ammo := -1
var _weapon_seconds := 0
var _health := 1
var _pow_total := 0
var _showing_results := false
var _results_ready := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Game.score_changed.connect(_on_score_changed)
	Game.lives_changed.connect(func(_lives: int) -> void: _refresh_lives())
	Game.player_health_changed.connect(func(health: int) -> void:
		_health = health
		_refresh_lives())
	Game.grenades_changed.connect(_on_grenades_changed)
	Game.weapon_changed.connect(_on_weapon_changed)
	Game.weapon_timer_changed.connect(func(seconds: int) -> void:
		_weapon_seconds = seconds
		_refresh_arms())
	Game.message_requested.connect(_on_message_requested)
	Game.boss_health_changed.connect(_on_boss_health_changed)
	Game.game_over.connect(_on_game_over)
	Game.mission_completed.connect(_on_mission_completed)
	_health = Game.hits_per_life()
	_pow_total = get_tree().get_nodes_in_group("pows").size()
	_on_score_changed(Game.score)
	_refresh_lives()
	_on_grenades_changed(Game.grenades)
	_boss_bar.visible = false
	_results_panel.visible = false
	_center_label.text = ""
	_pause_menu.center_y = 96.0
	_pause_menu.backdrop = Color(0.02, 0.03, 0.05, 0.6)
	if Game.checkpoint_position == Vector2.INF:
		Game.show_message("OPERATION BREAKWATER\nMISSION START!", 2.0)


func _process(delta: float) -> void:
	if _showing_results:
		if _results_ready and (Input.is_action_just_pressed("menu_accept") or Input.is_action_just_pressed("shoot")):
			_go_to_title()
		return

	if Game.is_game_over:
		return

	if get_tree().paused:
		# P or Start closes the pause menu from any screen; Escape is the menu's own Back.
		if Input.is_action_just_pressed("pause") and not Input.is_action_just_pressed("menu_back"):
			_resume()
		return

	if Input.is_action_just_pressed("pause"):
		Sfx.play("pause", 0.0)
		get_tree().paused = true
		_center_label.visible = false
		_open_pause_menu()
		return

	if _message_time > 0.0:
		_message_time -= delta
		if _message_time <= 0.0:
			_center_label.text = ""


func _open_pause_menu(select := 0) -> void:
	var items: Array[Dictionary] = [
		{"label": "RESUME", "pick": _resume},
		{"label": "OPTIONS", "pick": func() -> void: Options.open(_pause_menu, _open_pause_menu.bind(1))},
		{"label": "RESTART FROM CHECKPOINT", "pick": Game.restart_from_checkpoint},
		{"label": "QUIT TO TITLE", "pick": _go_to_title},
	]
	_pause_menu.show_items("PAUSED", items, select, _resume)


func _resume() -> void:
	Sfx.play("pause", 0.0)
	_pause_menu.visible = false
	_center_label.visible = true
	get_tree().paused = false


func _go_to_title() -> void:
	get_tree().paused = false
	Game.mission_running = false
	get_tree().change_scene_to_file(TITLE_SCENE)


func _refresh_lives() -> void:
	var text := "GRIT x%d" % maxi(Game.lives, 0)
	if Game.difficulty == Game.Difficulty.EASY:
		text += "  HP " + "#".repeat(maxi(_health, 0))
	_lives_label.text = text


func _on_score_changed(score: int) -> void:
	_score_label.text = "%07d" % score


func _on_grenades_changed(grenades: int) -> void:
	_bombs_label.text = "BOMBS %d" % grenades


func _on_weapon_changed(label: String, ammo: int) -> void:
	_weapon_label = label
	_weapon_ammo = ammo
	_refresh_arms()


func _refresh_arms() -> void:
	var text := "%s %s" % [_weapon_label, "--" if _weapon_ammo < 0 else str(_weapon_ammo)]
	if _weapon_ammo >= 0 and _weapon_seconds > 0:
		text += "  %ds" % _weapon_seconds
	_arms_label.text = text
	# Warn in red for the last 5 seconds.
	_arms_label.modulate = Color("ff6a4a") if _weapon_ammo >= 0 and _weapon_seconds <= 5 else Color.WHITE


func _on_message_requested(text: String, duration: float) -> void:
	if _showing_results:
		return
	_set_center(text)
	_message_time = duration


func _set_center(text: String) -> void:
	var font := _center_label.label_settings.font if _center_label.label_settings.font else ThemeDB.fallback_font
	var widest := 0.0
	for line in text.split("\n"):
		widest = maxf(widest, font.get_string_size(line, HORIZONTAL_ALIGNMENT_LEFT, -1, BIG_TEXT).x)
	_center_label.label_settings.font_size = BIG_TEXT if widest <= _center_label.size.x - 8.0 else SMALL_TEXT
	_center_label.text = text


func _on_boss_health_changed(fraction: float) -> void:
	_boss_bar.visible = fraction > 0.0
	_boss_fill.size.x = 120.0 * fraction


func _on_game_over() -> void:
	_message_time = 0.0
	_center_label.text = ""
	var items: Array[Dictionary] = [
		{"label": "CONTINUE HERE", "hint": "SCORE RESETS TO 0", "pick": func() -> void:
			_pause_menu.visible = false
			Game.continue_game()},
		{"label": "RESTART FROM CHECKPOINT", "pick": Game.restart_from_checkpoint},
		{"label": "QUIT TO TITLE", "pick": _go_to_title},
	]
	_pause_menu.show_items("GAME OVER", items)


func _on_mission_completed() -> void:
	_showing_results = true
	_boss_bar.visible = false
	_set_center("MISSION COMPLETE!")
	await get_tree().create_timer(2.0).timeout
	get_tree().paused = true
	var bonus := Game.speed_bonus()
	var minutes := int(Game.mission_time) / 60
	var seconds := int(Game.mission_time) % 60
	Game.add_score(bonus)
	_center_label.text = ""
	_results_label.text = "\n".join([
		"OPERATION BREAKWATER: COMPLETE",
		"POWS RESCUED   %d / %d" % [Game.pows_rescued, _pow_total],
		"ACCURACY       %d%%" % roundi(Game.accuracy() * 100.0),
		"TIME           %d:%02d" % [minutes, seconds],
		"SPEED BONUS    %d" % bonus,
		"",
		"TOTAL SCORE    %d" % Game.score,
		"REYES: \"Coast is clear, Sergeant.",
		"Kesselstadt is a long walk.\"",
		"PRESS ENTER",
	])
	_results_panel.visible = true
	await get_tree().create_timer(1.0).timeout
	_results_ready = true
