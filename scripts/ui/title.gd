extends Node2D
## Title screen: pick Easy or Hard and start Mission 1.

const MISSION_SCENE := "res://scenes/levels/mission1.tscn"
const OPTIONS := [
	["EASY", "3 HITS PER LIFE"],
	["HARD", "ONE HIT AND YOU'RE DOWN (ARCADE RULES)"],
]

var _selected := 1
var _time := 0.0


func _ready() -> void:
	get_tree().paused = false
	_selected = 0 if Game.difficulty == Game.Difficulty.EASY else 1


func _process(delta: float) -> void:
	_time += delta
	if Input.is_action_just_pressed("aim_up") or Input.is_action_just_pressed("move_left"):
		_selected = 0
	elif Input.is_action_just_pressed("crouch") or Input.is_action_just_pressed("move_right"):
		_selected = 1
	elif Input.is_action_just_pressed("shoot") or Input.is_action_just_pressed("jump"):
		Game.difficulty = Game.Difficulty.EASY if _selected == 0 else Game.Difficulty.HARD
		Game.start_mission()
		get_tree().change_scene_to_file(MISSION_SCENE)
		return
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	draw_rect(Rect2(0, 0, 320, 180), Color("161d27"))
	draw_colored_polygon(PackedVector2Array([Vector2(0, 150), Vector2(60, 118), Vector2(120, 132), Vector2(190, 104), Vector2(260, 126), Vector2(320, 112), Vector2(320, 180), Vector2(0, 180)]), Color("232e3a"))
	draw_rect(Rect2(0, 160, 320, 20), Color("2c2620"))
	draw_string(font, Vector2(0, 46), "VANGUARD OPS", HORIZONTAL_ALIGNMENT_CENTER, 320, 28, Color("ffe066"))
	draw_string(font, Vector2(0, 64), "KESSELSTADT RUN", HORIZONTAL_ALIGNMENT_CENTER, 320, 12, Color("ff6a4a"))
	for i in OPTIONS.size():
		var y := 96.0 + i * 22.0
		var chosen := i == _selected
		var color := Color("ffffff") if chosen else Color("7a8494")
		var label: String = OPTIONS[i][0]
		if chosen and int(_time * 3.0) % 2 == 0:
			label = "> " + label + " <"
		draw_string(font, Vector2(0, y), label, HORIZONTAL_ALIGNMENT_CENTER, 320, 12, color)
		draw_string(font, Vector2(0, y + 9), OPTIONS[i][1], HORIZONTAL_ALIGNMENT_CENTER, 320, 7, color.darkened(0.2))
	if int(_time * 2.0) % 2 == 0:
		draw_string(font, Vector2(0, 150), "PRESS SHOOT TO START", HORIZONTAL_ALIGNMENT_CENTER, 320, 8, Color("ffffff"))
	draw_string(font, Vector2(0, 172), "MOVE: ARROWS   JUMP: Z   SHOOT: X   GRENADE: C", HORIZONTAL_ALIGNMENT_CENTER, 320, 7, Color("9aa4b4"))
