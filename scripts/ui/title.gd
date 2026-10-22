extends Node2D
## Title screen: start Mission 1 on Easy or Hard, change the options, or quit.

const MISSION_SCENE := "res://scenes/levels/mission1.tscn"
const SkyTexture := preload("res://assets/sprites/sky.png")
const FarLayer := preload("res://assets/sprites/far_layer.png")
const Logo := preload("res://assets/sprites/logo.png")
## How fast the far cliffs and fleet drift behind the logo, in pixels per second.
const DRIFT := 6.0

var _time := 0.0

@onready var _menu: Menu = $Menu


func _ready() -> void:
	get_tree().paused = false
	Music.play("mission")
	_menu.center_y = 128.0
	_open_main()


func _open_main(select := 0) -> void:
	var items: Array[Dictionary] = [
		{"label": "START MISSION", "pick": _open_difficulty},
		{"label": "OPTIONS", "pick": func() -> void: Options.open(_menu, _open_main.bind(1))},
		{"label": "QUIT", "pick": func() -> void: get_tree().quit()},
	]
	_menu.show_items("", items, select)


func _open_difficulty() -> void:
	var items: Array[Dictionary] = [
		{"label": "EASY", "hint": "3 HITS PER LIFE", "pick": _start.bind(Game.Difficulty.EASY)},
		{"label": "HARD", "hint": "ONE HIT AND YOU'RE DOWN: ARCADE RULES", "pick": _start.bind(Game.Difficulty.HARD)},
		{"label": "BACK", "pick": _open_main},
	]
	_menu.show_items("CHOOSE DIFFICULTY", items, 0 if Game.difficulty == Game.Difficulty.EASY else 1, _open_main)


func _start(difficulty: Game.Difficulty) -> void:
	Game.difficulty = difficulty
	Game.start_mission()
	get_tree().change_scene_to_file(MISSION_SCENE)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_texture(SkyTexture, Vector2.ZERO)
	var drift := fmod(_time * DRIFT, 320.0)
	draw_texture(FarLayer, Vector2(-drift, -20))
	draw_texture(FarLayer, Vector2(320 - drift, -20))
	draw_rect(Rect2(0, 0, 320, 180), Color(0.03, 0.04, 0.07, 0.45))
	draw_texture(Logo, Vector2(roundf((320 - Logo.get_width()) / 2.0), 18))
	draw_string(font, Vector2(0, 66), "KESSELSTADT RUN", HORIZONTAL_ALIGNMENT_CENTER, 320, 16, Color("ff6a4a"))
	if _menu.title == "":
		draw_string(font, Vector2(0, 78), "MISSION 1: OPERATION BREAKWATER", HORIZONTAL_ALIGNMENT_CENTER, 320, 8, Color("c8d0dc"))
	draw_string(font, Vector2(0, 174), "SHOOT: SELECT    GRENADE: BACK", HORIZONTAL_ALIGNMENT_CENTER, 320, 8, Color("7a8494"))
