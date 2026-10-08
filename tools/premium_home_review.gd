extends SceneTree
## Reproducible home screenshot + real touch routing smoke check.
## godot --path . --rendering-driver opengl3 --script tools/premium_home_review.gd -- --out=/tmp/home.png --verify
var home
func _init() -> void:
	call_deferred("run")
func touch(button) -> void:
	var event := InputEventScreenTouch.new()
	event.index = 0
	event.position = button.size * 0.5
	event.pressed = true
	button._gui_input(event)
	event.pressed = false
	button._gui_input(event)
func run() -> void:
	home = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	await create_timer(1.5).timeout
	if "--verify" in OS.get_cmdline_user_args():
		assert(home.find_children("*", "CharacterRig").is_empty(), "Home must not instantiate a combat hero")
		assert(home.find_children("*", "Node3D").is_empty(), "Home runtime stays 2D")
		for button in home.nav:
			assert(Rect2(Vector2.ZERO, home.size).encloses(button.get_rect()), "Navigation outside viewport")
			touch(button)
			assert(home.screen != null, "Navigation touch did not open a screen")
			home.screen.close()
			await create_timer(0.4).timeout
			assert(home.screen == null, "Screen did not close")
		touch(home.hero_hit)
		assert(home.screen.get_script() == load("res://ui/collection_screen.gd"), "Loadout card must open character selection")
		home.screen.close()
		await create_timer(0.4).timeout
		touch(home.play_btn)
		assert(home.screen.get_script() == load("res://ui/mode_select_screen.gd"), "Play must preserve mode selection")
		home.screen.close()
		await create_timer(0.4).timeout
		touch(home.gear_btn)
		assert(home.settings != null, "Settings touch failed")
		home.settings.queue_free()
		home.settings = null
		print("HOME TOUCH SMOKE: OK (6 navigation routes, loadout, play, settings; sprite-free 2D home)")
	await create_timer(0.4).timeout
	var draws := 0.0
	var memory := 0.0
	for i in 60:
		await process_frame
		draws += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		memory = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)
	print("HOME PERF: draw calls mean=%.1f texture memory=%.2f MiB" % [draws / 60, memory / 1048576.0])
	await RenderingServer.frame_post_draw
	var path := "/tmp/home.png"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			path = arg.substr(6)
	assert(root.get_texture().get_image().save_png(path) == OK)
	print("HOME SNAPSHOT: ", path)
	quit()
