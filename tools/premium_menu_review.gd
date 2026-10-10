extends SceneTree
## Focused presentation review, isolated profile; no run is started.
## godot --path . --rendering-driver opengl3 --script tools/premium_menu_review.gd
var received: Array = []

func _init() -> void:
	call_deferred("run")

func touch(button: Control) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = button.get_global_rect().get_center()
	e.pressed = true
	root.push_input(e)
	e.pressed = false
	root.push_input(e)

func shot(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(path) == OK)

func run() -> void:
	create_timer(20.0).timeout.connect(func(): push_error("Menu review timed out"); quit(1))
	var profile = root.get_node("Profile")
	profile.path = "user://menu_review_only.json"
	profile.p = load("res://save/player_profile.gd").new()
	var home = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	await create_timer(0.4).timeout
	await shot("/tmp/premium-home-after.png")
	touch(home.play_btn)
	await process_frame
	var menu = home.screen
	assert(menu.get_script() == load("res://ui/mode_select_screen.gd"))
	menu.chosen.disconnect(home._start_run)
	menu.chosen.connect(func(mode, rule): received.append([mode, rule]))
	assert(menu.cards.size() == 7)
	assert(not menu.cards["bossrush"].enabled)
	for button in menu.canvas.get_children():
		assert(Rect2(Vector2.ZERO, root.size).encloses(button.get_global_rect()))
		assert(not button.focus_next.is_empty())
	touch(menu.cards["bossrush"])
	assert(menu.selected_mode == "campaign")
	# Selection must not start a run; only the explicit confirmation emits chosen.
	touch(menu.cards["survival"])
	assert(menu.selected_mode == "survival" and received.is_empty())
	for id in menu.difficulties:
		touch(menu.difficulties[id])
		assert(profile.p.data["selected_difficulty"] == id)
		assert(menu.difficulties[id].selected)
	touch(menu.difficulties["normal"])
	await shot("/tmp/premium-modes-after.png")
	# Keyboard selection and gamepad confirmation travel through the viewport.
	menu.cards["campaign"].grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_ENTER
	key.physical_keycode = KEY_ENTER
	key.pressed = true
	root.push_input(key)
	key.pressed = false
	root.push_input(key)
	assert(menu.selected_mode == "campaign")
	menu.launch.grab_focus()
	var pad := InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	root.push_input(pad)
	pad.pressed = false
	root.push_input(pad)
	assert(received == [["campaign", ""]])
	for mode in ["campaign", "survival", "bossrush", "challenge", "horde", "timeattack", "expedition"]:
		if mode in ["challenge", "bossrush"]:
			continue
		touch(menu.cards[mode])
		touch(menu.launch)
		assert(received.back() == [mode, ""])
	touch(menu.cards["challenge"])
	touch(menu.launch)
	await process_frame
	assert(menu.state == "rules")
	touch(menu.cards["glass"])
	await shot("/tmp/premium-rules-after.png")
	touch(menu.launch)
	assert(received.back() == ["challenge", "glass"])
	touch(menu.back_btn)
	await process_frame
	assert(menu.state == "modes")
	# Unlocked Boss Rush still emits the existing launch payload.
	profile.p.unlock_chapter("ch4")
	menu._rebuild()
	await process_frame
	touch(menu.cards["bossrush"])
	touch(menu.launch)
	assert(received.back() == ["bossrush", ""])
	menu.cards["campaign"].grab_focus()
	pad.button_index = JOY_BUTTON_DPAD_RIGHT
	pad.pressed = true
	root.push_input(pad)
	assert(menu.cards["survival"].has_focus())
	# Wide mobile aspect: safe layout remains inside the viewport.
	root.size = Vector2i(1560, 720)
	await process_frame
	await process_frame
	for button in menu.canvas.get_children():
		assert(Rect2(Vector2.ZERO, root.size).encloses(button.get_global_rect()))
	await shot("/tmp/premium-modes-wide.png")
	pad.button_index = JOY_BUTTON_B
	pad.pressed = true
	root.push_input(pad)
	await create_timer(0.3).timeout
	assert(home.screen == null and home.play_btn.has_focus())
	print("MENU REVIEW: OK — touch, keyboard, gamepad, difficulty, locks, six mode payloads, challenge, back, 16:9 / wide layout")
	quit()
