class_name Game
extends Node2D
## Raiz de la escena de run: monta el mundo, camara, entrada, HUD y servicios de combate (dano, explosiones,
## ralentizacion). El flujo de etapas vive en RunDirector; la entrada en GameInput.

static var tscale: float = 1.0

const MELEE_SLOTS := 2

var ysort: Node2D
var room: Room
var fx: Fx
var bullets: Bullets
var pickups: Pickups
var player: Player
var sfx: Node
var cam: Camera2D
var hud: Hud
var director: RunDirector
var input: GameInput
var run: RunState
var chapter: ChapterData
var hud_layer: CanvasLayer
var overlay_layer: CanvasLayer

var enemies: Array[Enemy] = []
var allies: Array = []
var melee_users: Array = []
var over := false
var victory := false
var result_ready := false
var input_locked := false
var enemy_time: float = 1.0
var hp_scale: float = 1.0
var _slow_f: float = 1.0
var _slow_t: float = 0.0
var trauma: float = 0.0
var shake_t: float = 0.0
var cam_pos := Vector2.ZERO
var hs_timer: float = 0.0
var clock: float = 0.0
var touch_mode := false
var paused_menu: Node = null

# banco de pruebas (--bot) y capturas
var bot := false
var god := false
var focus := false
var idle := false
var zoom_arg: float = 1.32
var bot_t := 0.0
var shots: Array[float] = []
var shot_dir := "/tmp/shots"
var shot_i := 0
var quit_at := -1.0
var fps_samples: Array[float] = []
var _boot_first_frame := true
var cam_extra := Vector2.ZERO
var _dbg_t := -1.0


func _enter_tree() -> void:
	Boot.log_stage(2, "run scene entered")


func _ready() -> void:
	Boot.log_stage(3, "run ready begin")
	randomize()
	tscale = 1.0
	Engine.time_scale = 1.0
	RenderingServer.set_default_clear_color(Color("04060c"))
	touch_mode = DisplayServer.is_touchscreen_available() or OS.has_feature("android") or OS.has_feature("web_android")
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_read_args()
	if Boot.has_flag("show"):
		_dbg_t = 2.0
	Prof.on = Boot.has_flag("perf")
	if Boot.has_flag("speed"):
		Engine.time_scale = float(Boot.get_arg("speed"))
	sfx = AudioMgr
	var params: Dictionary = Router.params
	var cid: String = str(params.get("character", Boot.get_arg("char", Profile.p.selected_character())))
	var chid: String = str(params.get("chapter", Boot.get_arg("chapter", Profile.p.data.get("selected_chapter", "ch1"))))
	var seed_v: int = int(params.get("seed", int(Boot.get_arg("seed", str(randi())))))
	var cdata := Catalog.character(cid)
	chapter = Catalog.chapter(chid)
	if chapter == null:
		chapter = Catalog.chapter("ch1")
	hp_scale = chapter.difficulty
	run = RunState.create(cdata, chapter, seed_v)
	if Boot.has_flag("weapon"):
		run.weapons[0] = Boot.get_arg("weapon")
	if Boot.has_flag("perks"):
		for pid in Boot.get_arg("perks").split(","):
			if Catalog.perks.has(pid):
				run.add_perk(Catalog.perks[pid], Catalog.perks)
	run.recompute(Catalog.perks)
	ysort = Node2D.new()
	ysort.y_sort_enabled = true
	add_child(ysort)
	Boot.log_stage(4, "world nodes")
	fx = Fx.new()
	add_child(fx)
	bullets = Bullets.new()
	bullets.game = self
	add_child(bullets)
	pickups = Pickups.new()
	pickups.game = self
	add_child(pickups)
	input = GameInput.new()
	input.game = self
	add_child(input)
	player = Player.new()
	ysort.add_child(player)
	var look := _look_for(cdata)
	player.build(self, run, look)
	player.skin_bullet = _skin_bullet(cdata)
	if bot or god:
		god = god
	Boot.log_stage(5, "player ready")
	cam = Camera2D.new()
	cam.zoom = Vector2.ONE * zoom_arg
	add_child(cam)
	cam.make_current()
	hud = Hud.new()
	hud.game = self
	hud_layer = CanvasLayer.new()
	hud_layer.layer = 10
	add_child(hud_layer)
	hud_layer.add_child(hud)
	hud.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay_layer = CanvasLayer.new()
	overlay_layer.layer = 20
	overlay_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(overlay_layer)
	director = RunDirector.new()
	director.game = self
	add_child(director)
	director.begin(int(Boot.get_arg("stage", "0")))
	if Boot.has_flag("hide"):
		var hs := str(Boot.get_arg("hide")).split(",")
		if "hud" in hs:
			hud.visible = false
		if "player" in hs:
			player.visible = false
	cam_pos = player.position
	_snap_camera()
	AudioMgr.play_music(chapter.music)
	AudioMgr.start_hum()
	Boot.log_stage(8, "ready complete nodes=%d memory=%d" % [get_tree().get_node_count(), OS.get_static_memory_usage()])


func _look_for(c: CharacterData) -> Dictionary:
	var look: Dictionary = c.look.duplicate()
	var sid: String = Profile.p.skin_of(c.id)
	if Boot.has_flag("skin"):
		sid = Boot.get_arg("skin")
	if sid != "" and Catalog.skins.has(sid):
		look.merge((Catalog.skins[sid] as SkinData).look, true)
	return look


func _skin_bullet(c: CharacterData) -> Color:
	var sid: String = Profile.p.skin_of(c.id)
	if sid != "" and Catalog.skins.has(sid):
		return (Catalog.skins[sid] as SkinData).bullet_color
	return Color(0, 0, 0, 0)


func _read_args() -> void:
	bot = Boot.has_flag("bot")
	god = Boot.has_flag("god")
	focus = Boot.has_flag("focus")
	idle = Boot.has_flag("idle")
	if Boot.has_flag("shots"):
		for s in Boot.get_arg("shots").split(","):
			shots.append(float(s))
	if Boot.has_flag("shotdir"):
		shot_dir = Boot.get_arg("shotdir")
	if Boot.has_flag("quit"):
		quit_at = float(Boot.get_arg("quit"))
	if Boot.has_flag("zoom"):
		zoom_arg = float(Boot.get_arg("zoom"))
	if Boot.has_flag("touch"):
		touch_mode = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


# ---------------------------------------------------------------- entrada (fachada)
func move_input() -> Vector2:
	return input.move_input()


func aim_input(origin: Vector2) -> Vector2:
	return input.aim_input(origin)


func fire_input() -> bool:
	return input.fire_input()


func ability_input() -> bool:
	return input.ability_input()


func nearest_enemy() -> Enemy:
	var best: Enemy = null
	var bd := 1e9
	for e in enemies:
		if not e.targetable():
			continue
		var d := e.position.distance_to(player.position)
		if d < bd:
			bd = d
			best = e
	return best


func bot_goal() -> Vector2:
	if director != null and director.exit_open():
		return room.exit_trigger.get_center()
	if director != null and director.boss_alive():
		return Vector2(0, 160)
	var fr := room.floor_rect
	return fr.get_center() + Vector2(0, fr.size.y * 0.12)


# ---------------------------------------------------------------- bucle
func _process(delta: float) -> void:
	Prof.begin("game_proc")
	__process_impl(delta)
	Prof.end("game_proc")


func __process_impl(delta: float) -> void:
	if _boot_first_frame:
		_boot_first_frame = false
		var vs := get_viewport_rect().size
		Boot.log_stage(9, "run first frame viewport=%s" % vs)
	var rdt := minf(delta, 1.0 / 30.0)
	clock += rdt
	if clock > 1.0:
		fps_samples.append(Engine.get_frames_per_second())
		_perf_acc(rdt)
	if hs_timer > 0.0:
		hs_timer -= rdt
		if hs_timer <= 0.0:
			Game.tscale = 1.0
	if _slow_t > 0.0:
		_slow_t -= rdt
		enemy_time = lerpf(enemy_time, _slow_f, clampf(rdt * 10.0, 0.0, 1.0))
	else:
		enemy_time = lerpf(enemy_time, 1.0, clampf(rdt * 4.0, 0.0, 1.0))
	if not over:
		run.time += rdt
	if Boot.has_flag("debug") and int(clock * 2.0) != int((clock - rdt) * 2.0) and int(clock) % 5 == 0:
		print("[t=%.0f] etapa=%d entered=%s combat=%s cleared=%s enemies=%d pend=%d wave=%d seal=%.2f pos=%s hp=%d kills=%d" % [clock, director.stage, director.entered, director.in_combat, director.cleared, enemies.size(), director.pending.size(), director.wave_i, room.seal_open, str(player.position.round()), player.hp, run.kills])
	if bot:
		bot_t += rdt
	_update_camera(rdt)
	if _dbg_t >= 0.0 and clock >= _dbg_t:
		_dbg_t = -1.0
		var w := str(Boot.get_arg("show", ""))
		match w:
			"pause":
				request_pause()
			"perk":
				offer_perk("chest")
			"win":
				run.won = true
				victory = true
				over = true
				show_result(true)
			"lose":
				over = true
				show_result(false)
	while shots.size() > shot_i and clock >= shots[shot_i]:
		_save_shot(shot_i)
		shot_i += 1
	if quit_at > 0.0 and clock >= quit_at:
		var avg := 0.0
		for f in fps_samples:
			avg += f
		avg /= maxf(1.0, float(fps_samples.size()))
		print("FPS medio: %.1f  kills: %d  hp: %d  etapa: %d  victoria: %s  nodos: %d" % [avg, run.kills, player.hp, director.stage, str(victory), get_tree().get_node_count()])
		if Boot.has_flag("perf"):
			print("PERF  ", perf_report())
			print(Prof.report(int(_pf["n"])))
		get_tree().quit()


var _pf := {"n": 0, "proc": 0.0, "draw": 0.0, "prim": 0.0, "obj": 0.0, "bul": 0.0, "fx": 0.0}


func _perf_acc(_dt: float) -> void:
	_pf["n"] += 1
	_pf["proc"] += Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	_pf["draw"] += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	_pf["prim"] += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	_pf["obj"] += Performance.get_monitor(Performance.OBJECT_NODE_COUNT)
	_pf["bul"] += float(bullets.list.size())
	_pf["fx"] += float(fx.ps.size())


func perf_report() -> String:
	var n := maxf(1.0, float(_pf["n"]))
	return "script/proceso: %.2f ms  draw calls: %.0f  primitivas: %.0f  nodos: %.0f  proyectiles: %.0f  particulas: %.0f" % [_pf["proc"] / n, _pf["draw"] / n, _pf["prim"] / n, _pf["obj"] / n, _pf["bul"] / n, _pf["fx"] / n]


func _save_shot(i: int) -> void:
	DirAccess.make_dir_recursive_absolute(shot_dir)
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/shot_%02d.png" % [shot_dir, i])


func hitstop(sec: float) -> void:
	Game.tscale = 0.04
	hs_timer = maxf(hs_timer, sec)


func shake(amount: float) -> void:
	trauma = minf(1.0, trauma + amount)


func hud_flash() -> void:
	hud.damage_flash = 1.0


func slow_enemies(f: float, dur: float) -> void:
	_slow_f = f
	_slow_t = maxf(_slow_t, dur)


# ---------------------------------------------------------------- camara
func _snap_camera() -> void:
	cam_pos = _cam_target()
	cam.position = cam_pos


func _cam_target() -> Vector2:
	var tgt := player.position + Vector2(0, -26)
	if focus:
		var n := nearest_enemy()
		if n != null:
			tgt = n.position + Vector2(0, -20)
	elif not touch_mode or input.touch_aim_id != -1:
		tgt += player.aim * 46.0
	tgt += cam_extra
	var vs := get_viewport_rect().size / cam.zoom
	var half := vs * 0.5
	var b := room.bounds.grow(40.0)
	var minx := b.position.x + half.x
	var maxx := b.end.x - half.x
	var miny := b.position.y - 90.0 + half.y
	var maxy := b.end.y + 30.0 - half.y
	tgt.x = clampf(tgt.x, minx, maxx) if minx < maxx else (minx + maxx) * 0.5
	tgt.y = clampf(tgt.y, miny, maxy) if miny < maxy else (miny + maxy) * 0.5
	return tgt


func _update_camera(dt: float) -> void:
	cam_pos = cam_pos.lerp(_cam_target(), 1.0 - exp(-dt * 7.0))
	trauma = maxf(0.0, trauma - dt * 2.2)
	shake_t += dt * 60.0
	var s := trauma * trauma
	var off := Vector2(sin(shake_t * 1.7) + sin(shake_t * 2.9) * 0.5, cos(shake_t * 2.3) + sin(shake_t * 3.7) * 0.5) * 7.0 * s
	cam.position = (cam_pos + off).round()


# ---------------------------------------------------------------- combate: servicios
func hit_enemy(en: Enemy, b: Bullets.B, ip: Vector2) -> void:
	en.hurt(b.dmg, b.vel.normalized(), b.knock, ip, b.style, b.crit, b.cat)


func hit_enemy_direct(en: Enemy, dmg: float, dir: Vector2, knock: float, p: Vector2, cat: String = "", crit: bool = false) -> void:
	if not en.targetable():
		return
	en.hurt(dmg, dir, knock, p, 0, crit, cat)


## Explosion con dano en area. team 0 = del jugador (dana enemigos y props); team 1 = enemiga (dana al jugador).
func explode(pos: Vector2, radius: float, dmg: float, team: int, cat: String, col: Color) -> void:
	fx.ring(pos, 8.0, radius * 1.1, col, 0.3, 5.0)
	fx.ring(pos, 4.0, radius * 0.8, Color(1, 1, 1, 0.8), 0.18, 3.0)
	fx.flash(pos, radius * 1.4, Color(col, 0.8), 0.18)
	fx.burst(pos, int(clampf(radius * 0.3, 8.0, 26.0)), 360.0, col, 0.45)
	fx.puff(pos, Vector2.ZERO, radius * 0.5, Color(0.45, 0.4, 0.5, 0.5), 0.7, 2.4)
	fx.add_decal(pos + Vector2(0, 6), 0, radius * 0.7, Color.BLACK)
	shake(clampf(radius / 160.0, 0.1, 0.5))
	sfx.play("boom", -4.0 if radius > 60.0 else -9.0, 1.0 + randf() * 0.15, 0.05, 0.04)
	if team == 0:
		for e in enemies.duplicate():
			var d: float = e.hit_center().distance_to(pos) - e.hit_r * 0.5
			if d < radius:
				var fall := 1.0 - clampf(d / radius, 0.0, 1.0) * 0.5
				var dir: Vector2 = (e.hit_center() - pos).normalized() if e.hit_center() != pos else Vector2.RIGHT
				hit_enemy_direct(e, dmg * fall, dir, 240.0, e.hit_center(), cat)
		for p in room.props.duplicate():
			if p.destructible and p.position.distance_to(pos) < radius + 20.0:
				p.hit(dmg, p.position)
	else:
		if player.hit_center().distance_to(pos) < radius + Player.HIT_R and player.can_be_hit():
			player.take_damage(maxi(1, int(round(dmg))), (player.position - pos).normalized(), 260.0)


func spawn_ally_turret(pos: Vector2) -> void:
	var t := AllyTurret.new()
	t.game = self
	t.position = Gfx.push_out(pos, 14.0, room.rects)
	ysort.add_child(t)
	allies.append(t)


func claim_melee(e: Enemy) -> bool:
	if melee_users.size() >= MELEE_SLOTS:
		return false
	melee_users.append(e)
	return true


func release_melee(e: Enemy) -> void:
	melee_users.erase(e)


func on_enemy_dying(e: Enemy) -> void:
	enemies.erase(e)
	melee_users.erase(e)


func on_enemy_dead(e: Enemy) -> void:
	run.note_kill(e.last_cat)
	PerkEffects.on_enemy_killed(self, e)
	if player.passive_is("warm_mag"):
		player.add_energy(3.0)
	if player.passive_is("hunt") and run.kills % 5 == 0:
		player.add_shield(1)
	director.on_enemy_dead(e)


func on_prop_broken(p: Prop) -> void:
	if player.passive_is("scrapper"):
		pickups.drop_coins(p.position + Vector2(0, -10), 2)
		pickups.drop_energy(p.position + Vector2(0, -10), 8.0)
	elif randf() < 0.35:
		pickups.drop_coins(p.position + Vector2(0, -10), 1)


func on_player_died() -> void:
	over = true
	run.won = false
	director.on_player_died()


# ---------------------------------------------------------------- menus
func request_pause() -> void:
	if over or paused_menu != null or input_locked:
		return
	paused_menu = PauseMenu.new()
	paused_menu.game = self
	overlay_layer.add_child(paused_menu)
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	input.reset()


func resume_from_pause() -> void:
	get_tree().paused = false
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	paused_menu = null
	input.reset()


func offer_perk(source: String) -> void:
	var picker := PerkPicker.new()
	picker.game = self
	picker.source = source
	overlay_layer.add_child(picker)


func show_result(won: bool) -> void:
	result_ready = true
	var r := ResultScreen.new()
	r.game = self
	r.won = won
	overlay_layer.add_child(r)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func quit_to_home(abandon: bool = true) -> void:
	if abandon and not result_ready:
		var summary := run.summary(director.stages_cleared())
		RunRewards.apply(Profile.p, summary, chapter, Catalog.missions, "")
		Profile.save_now()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	AudioMgr.stop_hum()
	Router.goto("home")
