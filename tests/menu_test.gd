extends Node
## Headless menu test: drives the title screen and the pause menu with the game's own actions.
## Checks the options change and save the settings, that Start reaches the mission on the
## chosen difficulty, and that the pause menu pauses and resumes.
## Run: godot --headless --fixed-fps 60 res://tests/menu_test.tscn
## Pass a folder after `--` (with a display) to also save a screenshot of each screen.

const TitleScene := preload("res://scenes/ui/title.tscn")

var _out_dir := ""
var _failures: PackedStringArray = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		_out_dir = args[0]
		DirAccess.make_dir_recursive_absolute(_out_dir)
	var saved := [Settings.music_level, Settings.sfx_level, Settings.fullscreen]
	await _run()
	Settings.set_music_level(saved[0])
	Settings.set_sfx_level(saved[1])
	Settings.set_fullscreen(saved[2])
	if _failures.is_empty():
		print("MENU TEST PASSED")
		get_tree().quit(0)
	else:
		for failure in _failures:
			printerr("MENU TEST FAILED: " + failure)
		get_tree().quit(1)


func _run() -> void:
	# The title screen becomes the current scene, so Start replaces it and not this test.
	var title := TitleScene.instantiate()
	get_tree().root.add_child.call_deferred(title)
	await _frames(2)
	get_tree().current_scene = title
	await _frames(8)
	var menu := title.get_node("Menu") as Menu
	await _shot("01_title")

	# Main list: START MISSION, OPTIONS, QUIT. Down once and pick opens the options.
	await _tap("crouch")
	await _tap("shoot")
	_expect(menu.title == "OPTIONS", "options did not open from the title screen")
	await _shot("02_options")
	var music := Settings.music_level
	await _tap("move_left")
	_expect(Settings.music_level == music - 1, "Left did not lower the music volume")
	var config := ConfigFile.new()
	_expect(config.load(Settings.PATH) == OK and config.get_value("audio", "music") == music - 1,
		"music volume was not saved to %s" % Settings.PATH)
	await _tap("move_right")
	# Down to CONTROLS and open the page.
	for i in 3:
		await _tap("crouch")
	await _tap("shoot")
	_expect(not menu.page.is_empty(), "controls page did not open")
	await _shot("03_controls")
	await _tap("grenade")
	_expect(menu.page.is_empty(), "controls page did not close")
	# Grenade backs out to the main list with OPTIONS still selected.
	await _tap("grenade")
	_expect(menu.title == "" and menu.selected == 1, "Grenade did not go back to the main list")

	# Start on Easy: up to START MISSION, pick, then pick EASY.
	await _tap("aim_up")
	await _tap("shoot")
	_expect(menu.title == "CHOOSE DIFFICULTY", "difficulty list did not open")
	if Game.difficulty != Game.Difficulty.EASY:
		await _tap("aim_up")
	await _shot("04_difficulty")
	await _tap("shoot")
	await _frames(30)
	var level := get_tree().current_scene
	_expect(level != null and level.name == "Mission1", "Start did not load the mission")
	_expect(Game.difficulty == Game.Difficulty.EASY, "Easy was picked but the difficulty is not Easy")
	if level == null or level.name != "Mission1":
		return

	await _tap("pause")
	var pause_menu := level.get_node("HUD/PauseMenu") as Menu
	_expect(get_tree().paused and pause_menu.visible, "pause did not open the pause menu")
	await _shot("05_pause")
	await _tap("shoot")
	_expect(not get_tree().paused and not pause_menu.visible, "RESUME did not unpause the game")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _tap(action: StringName) -> void:
	Input.action_press(action)
	await _frames(2)
	Input.action_release(action)
	await _frames(2)


func _frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _shot(shot_name: String) -> void:
	if _out_dir == "":
		return
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [_out_dir, shot_name])
	# Back into a normal frame, or the next tap lands between frames and never counts as "just pressed".
	await get_tree().process_frame
