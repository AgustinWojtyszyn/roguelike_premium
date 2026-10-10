extends SceneTree
## Visual QA for the real Home and every secondary menu; isolated save path.
## XDG_DATA_HOME=/tmp/premium-menu-qa godot --path . --rendering-driver opengl3 --script tools/premium_all_menus_review.gd
var output := "/tmp/premium-menu-redesign"

func _init() -> void:
	call_deferred("run")

func snap(label_text: String) -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label_text + ".png")) == OK)

func run() -> void:
	create_timer(45).timeout.connect(func(): push_error("Menu review timed out"); quit(1))
	DirAccess.make_dir_recursive_absolute(output)
	var profile = root.get_node("Profile")
	profile.path = "user://menu_review_only.json"
	profile.p = load("res://save/player_profile.gd").new()
	var home = load("res://scenes/home.tscn").instantiate()
	root.add_child(home)
	await create_timer(0.5).timeout
	await snap("home")
	for key in ["chars", "arms", "shop", "pass", "missions", "news", "modes"]:
		home._open(key)
		await create_timer(0.45).timeout
		assert(home.screen != null)
		await snap(key)
		for child in home.screen.get_children():
			if child.get_script() == load("res://ui/scroll_pane.gd"):
				assert(child.size.x > 0 and child.size.y > 0)
				child.scroll_to(child.max_scroll())
				await process_frame
				await snap(key + "-scrolled")
		home.screen.close()
		await create_timer(0.2).timeout
		assert(home.screen == null)
	home._open_settings()
	await create_timer(0.4).timeout
	await snap("settings")
	# Every settings row must be above the action, including the fifth toggle.
	assert(home.settings._row_rect(4).end.y < home.settings.close_btn.position.y)
	home.settings.closed.emit()
	await process_frame
	# Exercise and capture chapter / combatant cycling without starting gameplay.
	home._cycle_chapter(1)
	await create_timer(0.2).timeout
	await snap("home-chapter2")
	var game = load("res://game/game.gd").new()
	game.chapter = root.get_node("Catalog").chapter("ch1")
	var pause = load("res://ui/pause_menu.gd").new()
	pause.game = game
	root.add_child(pause)
	await create_timer(0.3).timeout
	await snap("pause")
	pause._set_confirm(true)
	await process_frame
	await snap("pause-confirm")
	pause.queue_free()
	await process_frame
	game.free()
	print("ALL MENUS REVIEW: OK — home, seven routes, scrolled content, settings layout and chapter navigation. Captures: ", output)
	quit()
