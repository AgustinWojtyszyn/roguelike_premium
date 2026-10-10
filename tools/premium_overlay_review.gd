extends SceneTree
## Draw the real overlay scripts against fixtures, bypassing reward/save/gameplay callbacks.
var output := "/tmp/premium-menu-redesign"

func _init() -> void:
	call_deferred("run")

func fixture(path: String):
	var script := GDScript.new()
	script.source_code = 'extends "%s"\nfunc _ready():\n\tset_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)\nfunc _process(_dt):\n\tqueue_redraw()\n' % path
	assert(script.reload() == OK)
	return script.new()

func snap(node, label_text: String) -> void:
	root.add_child(node)
	await process_frame
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(output.path_join(label_text + ".png")) == OK)
	node.queue_free()
	await process_frame

func run() -> void:
	create_timer(20).timeout.connect(func(): push_error("Overlay review timed out"); quit(1))
	DirAccess.make_dir_recursive_absolute(output)
	var catalog = root.get_node("Catalog")
	var game = load("res://game/game.gd").new()
	game.chapter = catalog.chapter("ch1")
	game.run = load("res://game/run_state.gd").new()
	game.run.character = catalog.character("vesper")
	game.run.chapter = game.chapter
	game.director = load("res://game/run_director.gd").new()
	game.director.stage = 2
	for i in 5:
		game.director.plan.append({})
	var buttons = load("res://ui/home_button.gd")
	var perks = fixture("res://ui/perk_picker.gd")
	perks.game = game
	perks._anim = 1.0
	for key in catalog.perks.keys().slice(0, 3):
		perks.offers.append(catalog.perks[key])
	perks.skip_btn = buttons.menu("SALTAR +20")
	perks.cancel_btn = buttons.menu("ATRÁS")
	perks.cancel_btn.hide()
	perks.add_child(perks.skip_btn)
	perks.add_child(perks.cancel_btn)
	perks.size = root.size
	perks._layout()
	await snap(perks, "perks-fixture")
	var route = fixture("res://ui/route_picker.gd")
	route.game = game
	route._anim = 1.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	route.options = load("res://game/mode_rules.gd").expedition_options(game.chapter, 1, "W", "combat", rng, [])
	await snap(route, "routes-fixture")
	var result = fixture("res://ui/result_screen.gd")
	result.game = game
	result._t = 3.0
	result.summary = {"kills": 48, "rooms": 8, "chests": 3, "time": 245.0, "bosses": 0}
	result.rewards = {"coins": 128, "bonus_coins": 0, "xp": 80}
	result.lv_before = {"level": 2, "into": 40, "need": 150}
	result.lv_after = {"level": 2, "into": 120, "need": 150}
	result.pass_before = {"level": 3, "into": 10, "need": 100}
	result.pass_after = {"level": 3, "into": 90, "need": 100, "max": false}
	result.rig = load("res://characters/character_rig.gd").new()
	result.rig.build(game.run.character.look, catalog.weapon(game.run.character.start_weapon))
	result.rig.scale = Vector2.ONE * 3
	result.add_child(result.rig)
	result.home_btn = buttons.menu("VOLVER AL INICIO")
	result.again_btn = buttons.menu("OTRA VEZ", 0)
	result.add_child(result.home_btn)
	result.add_child(result.again_btn)
	result.size = root.size
	result._layout()
	await snap(result, "result-fixture")
	game.director.free()
	game.free()
	print("OVERLAY REVIEW: OK — real perk/route/result drawing, fixture data; no rewards applied")
	quit()
