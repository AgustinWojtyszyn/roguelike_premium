class_name ResultScreen
extends Control
## Pantalla de resultado de la run (victoria / derrota). Presentacion premium: titulo con degradado, personaje,
## estadisticas y recompensas con conteo animado, progreso de nivel/pase y capitulo desbloqueado.

var game: Game
var won := false
var summary: Dictionary = {}
var rewards: Dictionary = {}
var lv_before: Dictionary = {}
var lv_after: Dictionary = {}
var pass_before: Dictionary = {}
var pass_after: Dictionary = {}
var unlocked_chapter := ""
var _t: float = 0.0
var rig: CharacterRig
var home_btn: GButton
var again_btn: GButton
var _tick_t: float = 0.0
var _levelup_played := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var p := Profile.p
	var run := game.run
	var next_ch := ""
	var idx := Catalog.chapter_order.find(game.chapter.id)
	if won and idx >= 0 and idx + 1 < Catalog.chapter_order.size():
		next_ch = Catalog.chapter_order[idx + 1]
	var was_unlocked: bool = p.chapter_state(next_ch).get("unlocked", false) if next_ch != "" else true
	lv_before = p.account_level()
	pass_before = PassSystem.level_info(p, Catalog.season)
	summary = run.summary(game.director.stages_cleared())
	rewards = RunRewards.apply(p, summary, game.chapter, Catalog.missions, next_ch)
	lv_after = p.account_level()
	pass_after = PassSystem.level_info(p, Catalog.season)
	if next_ch != "" and not was_unlocked:
		unlocked_chapter = next_ch
	Profile.save_now()
	rig = CharacterRig.new()
	add_child(rig)
	var look := game._look_for(run.character)
	rig.build(look, Catalog.weapon(run.weapons[0]))
	rig.auto = true
	rig.scale = Vector2.ONE * 3.0
	rig.z_index = 1
	home_btn = GButton.make("VOLVER AL INICIO", GButton.Style.SECONDARY, "")
	home_btn.font_size = 24
	home_btn.pressed.connect(func(): game.quit_to_home(false))
	again_btn = GButton.make("OTRA VEZ", GButton.Style.PRIMARY, "play")
	again_btn.font_size = 28
	again_btn.pressed.connect(_again)
	again_btn.pulse = true
	add_child(home_btn)
	add_child(again_btn)
	home_btn.modulate.a = 0.0
	again_btn.modulate.a = 0.0
	resized.connect(_layout)
	_layout()
	AudioMgr.stop_hum()
	if game.bot:
		print("RESULTADO: victoria=%s kills=%d salas=%d monedas=%d xp=%d etapa=%d" % [won, summary["kills"], summary["rooms"], int(rewards["coins"]) + int(rewards["bonus_coins"]), int(rewards["xp"]), game.director.stage + 1])
		get_tree().create_timer(0.3, true, false, true).timeout.connect(func(): get_tree().quit())
	AudioMgr.ui("victory" if won else "defeat", -2.0)
	if won:
		AudioMgr.play_music("menu")
	else:
		AudioMgr.play_music("menu")


func _again() -> void:
	AudioMgr.stop_hum()
	Router.goto("run", {"character": game.run.character.id, "chapter": game.chapter.id, "seed": randi()}, game.chapter.accent.darkened(0.7))


func _layout() -> void:
	home_btn.size = Vector2(300, 68)
	again_btn.size = Vector2(300, 80)
	home_btn.position = Vector2(size.x * 0.5 - 320.0, size.y - 110.0)
	again_btn.position = Vector2(size.x * 0.5 + 20.0, size.y - 118.0)
	rig.position = Vector2(size.x * 0.22, size.y * 0.66)


func _process(delta: float) -> void:
	_t += delta
	var a := clampf((_t - 1.6) * 2.0, 0.0, 1.0)
	home_btn.modulate.a = a
	again_btn.modulate.a = a
	home_btn.mouse_filter = Control.MOUSE_FILTER_STOP if a > 0.5 else Control.MOUSE_FILTER_IGNORE
	again_btn.mouse_filter = home_btn.mouse_filter
	# tic del conteo de monedas
	if _t > 0.9 and _t < 2.2:
		_tick_t -= delta
		if _tick_t <= 0.0:
			_tick_t = 0.07
			AudioMgr.ui("tick", -10.0, 0.9 + (_t - 0.9) * 0.6)
	if _t > 2.0 and not _levelup_played and (int(lv_after["level"]) > int(lv_before["level"]) or int(pass_after["level"]) > int(pass_before["level"])):
		_levelup_played = true
		AudioMgr.ui("levelup", -2.0)
	queue_redraw()


func _draw() -> void:
	var vs := size
	var k := clampf(_t * 3.0, 0.0, 1.0)
	var top := Color("1a0f2e") if won else Color("0b1226")
	var bot := Color("05060f")
	UiKit.gradient_rect(self, Rect2(Vector2.ZERO, vs), Color(top, 0.94 * k), Color(bot, 0.97 * k))
	var accent := Color("ffd24a") if won else Color("6a9cff")
	# rayos / halo
	if won:
		for i in 14:
			var a := _t * 0.25 + TAU * float(i) / 14.0
			var c := Vector2(vs.x * 0.5, 130.0)
			draw_colored_polygon(PackedVector2Array([c, c + Vector2.from_angle(a - 0.07) * 900.0, c + Vector2.from_angle(a + 0.07) * 900.0]), Color(1.0, 0.8, 0.3, 0.05 * k))
	Gfx.draw_glow(self, Vector2(vs.x * 0.5, 120.0), 340.0, Color(accent, 0.18 * k))
	# titulo
	var tk := Gfx.ease_out(clampf(_t * 2.4, 0.0, 1.0))
	var title := "¡VICTORIA!" if won else "RUN TERMINADA"
	var ts := int(78.0 * (0.7 + 0.3 * tk))
	UiKit.text(self, Vector2(0, 112.0), title, ts, Color(accent.lightened(0.35), tk), 1, vs.x, 14.0)
	var sub := "%s completado" % game.chapter.display_name if won else "Llegaste a la etapa %d de %d" % [game.director.stage + 1, game.director.plan.size()]
	UiKit.text(self, Vector2(0, 152.0), sub, 24, Color(UiKit.TEXT, tk), 1, vs.x, 6.0)
	# personaje
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Gfx.draw_glow(self, Vector2(vs.x * 0.22, vs.y * 0.66), 190.0, Color(accent, 0.12 * k))
	# panel de datos
	var pw := minf(560.0, vs.x * 0.5)
	var pr := Rect2(vs.x * 0.44, 190.0, pw, vs.y - 330.0)
	UiKit.panel(self, pr, Color("0d1424", 0.9), Color(accent, 0.6), 16.0, k)
	var rows := [
		["skull", "BAJAS", str(summary["kills"])],
		["door", "SALAS", str(summary["rooms"])],
		["chest", "COFRES", str(summary["chests"])],
		["clock", "TIEMPO", _fmt_time(float(summary["time"]))],
	]
	for i in rows.size():
		var rk := clampf((_t - 0.35 - float(i) * 0.12) * 5.0, 0.0, 1.0)
		var rowc := Vector2(pr.position.x + 40.0 + float(i % 2) * (pr.size.x * 0.5), pr.position.y + 42.0 + float(i / 2) * 44.0)
		UiIcons.draw(self, rows[i][0], rowc, 11.0, Color(accent, rk))
		UiKit.text(self, rowc + Vector2(26.0, 6.0), "%s  %s" % [rows[i][1], rows[i][2]], 20, Color(UiKit.TEXT, rk), 0, -1.0, 3.0)
	# recompensas
	var ry := pr.position.y + 150.0
	var ck := clampf((_t - 0.9) / 1.2, 0.0, 1.0)
	var coin_total := int(rewards.get("coins", 0)) + int(rewards.get("bonus_coins", 0))
	UiIcons.draw(self, "coin", Vector2(pr.position.x + 46.0, ry), 18.0, Color("ffd24a"))
	UiKit.text(self, Vector2(pr.position.x + 78.0, ry + 11.0), "+%s" % UiKit.format_int(int(round(coin_total * ck))), 36, Color("fff0b0"), 0, -1.0, 6.0)
	if int(rewards.get("bonus_coins", 0)) > 0:
		UiKit.text(self, Vector2(pr.position.x + 78.0, ry + 34.0), "incluye bono de capítulo +%d" % int(rewards["bonus_coins"]), 14, UiKit.DIM, 0, -1.0, 2.0, false)
	# XP + nivel de cuenta
	var xy := ry + 72.0
	var xp_got := int(rewards.get("xp", 0))
	UiKit.text(self, Vector2(pr.position.x + 28.0, xy), "NIVEL %d" % int(lv_after["level"]), 22, UiKit.TEXT, 0, -1.0, 4.0)
	UiKit.text(self, Vector2(pr.end.x - 200.0, xy), "+%d XP" % int(round(xp_got * ck)), 22, Color("8fe8ff"), 2, 172.0, 4.0)
	var br := Rect2(pr.position.x + 28.0, xy + 14.0, pr.size.x - 56.0, 18.0)
	var f0 := float(lv_before["into"]) / float(lv_before["need"])
	var f1 := float(lv_after["into"]) / float(lv_after["need"])
	var lvu: bool = int(lv_after["level"]) > int(lv_before["level"])
	var fill := lerpf(f0, 1.0 if lvu else f1, ck) if (not lvu or ck < 0.5) else lerpf(0.0, f1, (ck - 0.5) * 2.0)
	UiKit.bar(self, br, fill, Color("3fb8ff"))
	if lvu and ck > 0.9:
		UiKit.text(self, Vector2(br.position.x, br.end.y + 24.0), "¡SUBISTE DE NIVEL!", 20, UiKit.GOLD, 1, br.size.x, 4.0)
	# pase
	var py := xy + (74.0 if lvu else 56.0)
	var pl_b := int(pass_before["level"])
	var pl_a := int(pass_after["level"])
	UiKit.text(self, Vector2(pr.position.x + 28.0, py), "PASE  %d" % pl_a, 18, Color(Catalog.season.theme_color, 1.0), 0, -1.0, 3.0)
	var pbr := Rect2(pr.position.x + 120.0, py - 14.0, pr.size.x - 150.0, 12.0)
	var pf: float = 1.0 if bool(pass_after.get("max", false)) else float(pass_after["into"]) / float(pass_after["need"])
	UiKit.bar(self, pbr, pf * ck, Catalog.season.theme_color)
	if pl_a > pl_b and ck > 0.9:
		UiKit.text(self, Vector2(pbr.position.x, pbr.end.y + 20.0), "+%d niveles de pase · ¡reclama tus premios!" % (pl_a - pl_b), 15, UiKit.OK, 0, -1.0, 3.0)
	if unlocked_chapter != "":
		var uc: ChapterData = Catalog.chapter(unlocked_chapter)
		var bounce := 1.0 + 0.04 * sin(_t * 5.0)
		UiKit.text(self, Vector2(0, vs.y - 160.0), "¡NUEVO CAPÍTULO DESBLOQUEADO!  %s" % uc.display_name, int(24.0 * bounce), UiKit.GOLD, 1, vs.x, 6.0)


func _fmt_time(sec: float) -> String:
	var m := int(sec) / 60
	return "%d:%02d" % [m, int(sec) % 60]
