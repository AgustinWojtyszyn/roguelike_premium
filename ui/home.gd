class_name Home
extends Control
## Menu principal: heroe animado al centro, fondo dinamico por capitulo, JUGAR grande, monedas / nivel y navegacion
## clara (tienda, personajes, armas, pase, misiones, novedades). Pensado para movil horizontal.

var t: float = 0.0
var rig: CharacterRig
var hero_hit: GButton
var play_btn: GButton
var chap_prev: GButton
var chap_next: GButton
var char_prev: GButton
var char_next: GButton
var gear_btn: GButton
var nav: Array[NavButton] = []
var mission_chip: GButton
var pass_chip: GButton
var gift_chip: GButton
var screen: MenuScreen = null
var settings: SettingsPanel = null
var hero_scale := 3.2
var hero_pos := Vector2.ZERO
var chapter_id := "ch1"
var _launching := false
var _launch_t: float = 0.0
var _kick_t: float = 0.0
var _news_new := true
var _lv_anim: float = 0.0
var safe := Vector4.ZERO


func _ready() -> void:
	Boot.log_stage(2, "home entered")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var p := Profile.p
	MissionSystem.refresh(p, Catalog.missions, MissionSystem.today_key(), Catalog.season.id)
	chapter_id = str(p.data.get("selected_chapter", "ch1"))
	if Catalog.chapter(chapter_id) == null:
		chapter_id = "ch1"
	rig = CharacterRig.new()
	add_child(rig)
	rig.z_index = 0
	_make_buttons()
	_refresh_hero()
	resized.connect(_layout)
	_layout()
	_refresh_badges()
	AudioMgr.play_music("menu")
	AudioMgr.stop_hum()
	if Boot.has_flag("shots"):
		_shots_mode()
	if Boot.has_flag("autoplay"):
		get_tree().create_timer(1.0).timeout.connect(_on_play)
	Boot.log_stage(8, "home ready")


func _make_buttons() -> void:
	play_btn = GButton.make("JUGAR", GButton.Style.PRIMARY, "")
	play_btn.font_size = 52
	play_btn.pulse = true
	play_btn.pressed.connect(_on_play)
	add_child(play_btn)
	chap_prev = GButton.make("", GButton.Style.ICON, "chev_l")
	chap_next = GButton.make("", GButton.Style.ICON, "chev_r")
	chap_prev.pressed.connect(func(): _cycle_chapter(-1))
	chap_next.pressed.connect(func(): _cycle_chapter(1))
	char_prev = GButton.make("", GButton.Style.ICON, "chev_l")
	char_next = GButton.make("", GButton.Style.ICON, "chev_r")
	char_prev.pressed.connect(func(): _cycle_char(-1))
	char_next.pressed.connect(func(): _cycle_char(1))
	for b in [chap_prev, chap_next, char_prev, char_next]:
		add_child(b)
	gear_btn = GButton.make("", GButton.Style.ICON, "gear")
	gear_btn.pressed.connect(_open_settings)
	add_child(gear_btn)
	hero_hit = GButton.make("", GButton.Style.GHOST, "")
	hero_hit.modulate.a = 0.0
	hero_hit.click_sound = "tick"
	hero_hit.pressed.connect(_hero_emote)
	add_child(hero_hit)
	var defs := [
		["TIENDA", "cart", Color("ffb23d"), "shop"], ["PERSONAJES", "person", Color("27e0cc"), "chars"], ["ARMAS", "sword", Color("ff6a8a"), "arms"],
		["PASE", "star", Color("c47bff"), "pass"], ["MISIONES", "target", Color("5fffc8"), "missions"], ["NOVEDADES", "news", Color("6cc4ff"), "news"],
	]
	for d in defs:
		var b := NavButton.create(d[0], d[1], d[2])
		var key: String = d[3]
		b.pressed.connect(func(): _open(key))
		add_child(b)
		nav.append(b)
	mission_chip = GButton.make("", GButton.Style.GHOST, "")
	mission_chip.pressed.connect(func(): _open("missions"))
	mission_chip.extra = _draw_mission_chip
	add_child(mission_chip)
	pass_chip = GButton.make("", GButton.Style.GHOST, "")
	pass_chip.pressed.connect(func(): _open("pass"))
	pass_chip.extra = _draw_pass_chip
	add_child(pass_chip)
	gift_chip = GButton.make("", GButton.Style.GHOST, "")
	gift_chip.pressed.connect(func(): _open("shop"))
	gift_chip.extra = _draw_gift_chip
	add_child(gift_chip)


func _layout() -> void:
	safe = SafeArea.margins(self)
	var vs := size
	var sc := clampf(vs.y / 720.0, 0.7, 1.4)
	hero_scale = 4.0 * sc
	hero_pos = Vector2(vs.x * 0.5, vs.y * 0.62)
	rig.position = hero_pos
	rig.scale = Vector2.ONE * hero_scale
	hero_hit.size = Vector2(300, 400) * sc
	hero_hit.position = hero_pos - Vector2(150, 330) * sc
	char_prev.size = Vector2(60, 90)
	char_next.size = Vector2(60, 90)
	char_prev.position = hero_pos + Vector2(-280.0 * sc - 30.0, -190.0 * sc)
	char_next.position = hero_pos + Vector2(280.0 * sc - 30.0, -190.0 * sc)
	gear_btn.size = Vector2(66, 62)
	gear_btn.position = Vector2(vs.x - 88.0 - safe.z, 14.0 + safe.y)
	# navegacion inferior
	var nav_w := vs.x - 420.0 - 40.0 - safe.x - safe.z
	var gap := 8.0
	var bw := minf(150.0, (nav_w - gap * 5.0) / 6.0)
	for i in nav.size():
		nav[i].size = Vector2(bw, 96)
		nav[i].position = Vector2(20.0 + safe.x + float(i) * (bw + gap), vs.y - 112.0 - safe.w)
	play_btn.size = Vector2(350, 112)
	play_btn.position = Vector2(vs.x - 372.0 - safe.z, vs.y - 136.0 - safe.w)
	chap_prev.size = Vector2(54, 54)
	chap_next.size = Vector2(54, 54)
	chap_prev.position = Vector2(vs.x - 372.0 - safe.z, vs.y - 208.0 - safe.w)
	chap_next.position = Vector2(vs.x - 76.0 - safe.z, vs.y - 208.0 - safe.w)
	mission_chip.size = Vector2(218, 70)
	mission_chip.position = Vector2(20.0 + safe.x, 106.0 + safe.y)
	pass_chip.size = Vector2(218, 70)
	pass_chip.position = Vector2(20.0 + safe.x, 186.0 + safe.y)
	gift_chip.size = Vector2(218, 70)
	gift_chip.position = Vector2(vs.x - 238.0 - safe.z, 106.0 + safe.y)


func _refresh_hero() -> void:
	var p := Profile.p
	var c := Catalog.character(p.selected_character())
	var look: Dictionary = c.look.duplicate()
	var sid := p.skin_of(c.id)
	if sid != "" and Catalog.skins.has(sid):
		look.merge((Catalog.skins[sid] as SkinData).look, true)
	for ch in rig.get_children():
		ch.queue_free()
	rig.scarf_pts.clear()
	rig.build(look, Catalog.weapon(c.start_weapon), false)
	rig.auto = true
	rig.kick = 0.0


func _refresh_badges() -> void:
	var p := Profile.p
	var claim_m := MissionSystem.claimable_count(p, Catalog.missions)
	var claim_p := PassSystem.claimable_count(p, Catalog.season)
	nav[4].badge = claim_m
	nav[3].badge = claim_p
	nav[0].badge_text = "!" if ShopSystem.gift_available(p, MissionSystem.today_key()) else ""
	nav[5].badge_text = "!" if _news_new else ""
	gift_chip.visible = ShopSystem.gift_available(p, MissionSystem.today_key())
	_update_play_state()


func _update_play_state() -> void:
	var chs := Profile.p.chapter_state(chapter_id)
	var unlocked: bool = chs.get("unlocked", false)
	play_btn.enabled = unlocked
	play_btn.label = "JUGAR" if unlocked else "BLOQUEADO"
	play_btn.icon = "" if unlocked else "lock"
	play_btn.font_size = 52 if unlocked else 34


func _cycle_chapter(d: int) -> void:
	var order: Array[String] = Catalog.chapter_order
	var i := order.find(chapter_id)
	i = posmod(i + d, order.size())
	chapter_id = order[i]
	Profile.p.data["selected_chapter"] = chapter_id
	Profile.p.touch()
	_update_play_state()


func _cycle_char(d: int) -> void:
	var p := Profile.p
	var order: Array = []
	for id in Catalog.char_order:
		if p.is_unlocked(id):
			order.append(id)
	if order.size() < 2:
		return
	var i := order.find(p.selected_character())
	i = posmod(i + d, order.size())
	p.select_character(order[i])
	_refresh_hero()
	_pop_hero()


func _pop_hero() -> void:
	rig.scale = Vector2.ONE * hero_scale * 0.88
	var tw := create_tween()
	tw.tween_property(rig, "scale", Vector2.ONE * hero_scale, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	AudioMgr.ui("swap", -4.0)
	var c := Catalog.character(Profile.p.selected_character())
	_kick_t = 0.5


func _hero_emote() -> void:
	rig.kick = 1.0
	rig.heat = 1.0
	rig.swing = 1.0
	_kick_t = 0.5
	AudioMgr.ui("smg", -8.0, 1.0)


func _open(key: String) -> void:
	if screen != null or _launching:
		return
	match key:
		"chars":
			screen = CollectionScreen.new()
		"arms":
			screen = ArmoryScreen.new()
		"pass":
			screen = PassScreen.new()
		"missions":
			screen = MissionsScreen.new()
		"shop":
			screen = ShopScreen.new()
		"news":
			_news_new = false
			screen = NewsScreen.new()
	screen.closed.connect(_on_screen_closed)
	add_child(screen)
	rig.visible = false


func _on_screen_closed() -> void:
	screen = null
	rig.visible = true
	_refresh_hero()
	_refresh_badges()


func _open_settings() -> void:
	if settings != null or screen != null:
		return
	settings = SettingsPanel.new()
	settings.closed.connect(func(): settings.queue_free(); settings = null)
	add_child(settings)


func _on_play() -> void:
	if _launching or screen != null:
		return
	_launching = true
	_launch_t = 0.0
	var p := Profile.p
	rig.kick = 1.0
	rig.heat = 1.0
	AudioMgr.ui("ui_confirm", 0.0)
	AudioMgr.ui("smg", -4.0)
	var ch := Catalog.chapter(chapter_id)
	get_tree().create_timer(0.35).timeout.connect(func():
		Router.goto("run", {"character": p.selected_character(), "chapter": chapter_id, "seed": randi()}, ch.accent.darkened(0.75)))


func _shots_mode() -> void:
	var which := Boot.get_arg("screen", "")
	if which != "":
		get_tree().create_timer(0.6).timeout.connect(func(): _open(which))


func _process(delta: float) -> void:
	t += delta
	_kick_t = maxf(0.0, _kick_t - delta)
	if _launching:
		_launch_t += delta
	var p := Profile.p
	_lv_anim = lerpf(_lv_anim, float(p.account_level()["into"]) / float(p.account_level()["need"]), clampf(delta * 5.0, 0.0, 1.0))
	if Engine.get_frames_drawn() % 3 == 0:
		queue_redraw()


func _draw() -> void:
	var vs := size
	var ch := Catalog.chapter(chapter_id)
	HomeBackdrop.paint(self, vs, t, ch.theme, ch.accent, hero_pos)
	var p := Profile.p
	var c := Catalog.character(p.selected_character())
	# pedestal
	var pc := hero_pos + Vector2(0, 4)
	var rar := Rarity.color_anim(c.rarity, t)
	for k in 3:
		var rr := (150.0 + float(k) * 48.0) * hero_scale / 3.2
		draw_arc(pc, rr, 0, TAU, 48, Color(rar, 0.30 - float(k) * 0.08), 3.0, true)
	var ex := 140.0 * hero_scale / 3.2
	var ey := 36.0 * hero_scale / 3.2
	draw_set_transform(pc, 0.0, Vector2(1.0, ey / ex))
	draw_circle(Vector2.ZERO, ex, Color(0.02, 0.04, 0.08, 0.7))
	draw_arc(Vector2.ZERO, ex, 0, TAU, 40, Color(rar, 0.9), 4.0 / (ey / ex) * 0.7, true)
	draw_circle(Vector2.ZERO, ex * 0.75, Color(rar.darkened(0.6), 0.5))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	Gfx.draw_glow(self, pc, ex * 1.2, Color(rar, 0.25))
	# placa de nombre
	var nw := 360.0
	var nr := Rect2(hero_pos.x - nw * 0.5, hero_pos.y + 54.0 * hero_scale / 3.2, nw, 70.0)
	UiKit.panel(self, nr, Color("0b1224", 0.82), Color(rar, 0.9), 14.0)
	UiKit.text(self, Vector2(nr.position.x, nr.position.y + 36.0), c.display_name, 38, UiKit.TEXT, 1, nw, 7.0)
	UiKit.text(self, Vector2(nr.position.x, nr.position.y + 58.0), "%s · %s" % [c.title, Rarity.label(c.rarity)], 15, rar.lightened(0.2), 1, nw, 3.0, false)
	_draw_profile(vs)
	_draw_chapter_selector(vs)
	if _launching:
		var a := clampf(_launch_t * 3.0, 0.0, 0.5)
		draw_rect(Rect2(Vector2.ZERO, vs), Color(1, 1, 1, a * 0.2))


func _draw_profile(vs: Vector2) -> void:
	var p := Profile.p
	var lv := p.account_level()
	var r := Rect2(20.0 + safe.x, 16.0 + safe.y, 330, 76)
	UiKit.panel(self, r, Color("0b1224", 0.85), Color(UiKit.EDGE, 0.6), 14.0)
	var cc := Vector2(r.position.x + 40.0, r.get_center().y)
	draw_circle(cc, 30.0, Color("162244"))
	draw_arc(cc, 30.0, 0, TAU, 28, Color(UiKit.EDGE, 0.9), 3.0, true)
	draw_arc(cc, 24.0, -PI * 0.5, -PI * 0.5 + TAU * _lv_anim, 28, Color("5fffc8"), 4.0, true)
	UiKit.text(self, Vector2(cc.x - 20.0, cc.y + 9.0), str(int(lv["level"])), 26, UiKit.TEXT, 1, 40.0, 4.0)
	UiKit.text(self, Vector2(r.position.x + 84.0, r.position.y + 32.0), "NIVEL %d" % int(lv["level"]), 24, UiKit.TEXT, 0, -1.0, 5.0)
	var br := Rect2(r.position.x + 84.0, r.position.y + 44.0, 226.0, 14.0)
	UiKit.bar(self, br, _lv_anim, Color("3fb8ff"))
	UiKit.text(self, Vector2(br.position.x, br.end.y + 12.0), "XP %d / %d" % [int(lv["into"]), int(lv["need"])], 11, UiKit.DIM, 0, -1.0, 2.0, false)
	# monedas / gemas
	_currency(Vector2(vs.x - 100.0 - safe.z, 22.0 + safe.y), UiKit.format_int(p.coins()), "coin", Color("ffd24a"))
	_currency(Vector2(vs.x - 100.0 - 188.0 - safe.z, 22.0 + safe.y), UiKit.format_int(p.gems()), "gem", UiKit.GEM)


func _currency(right_top: Vector2, s: String, icon: String, col: Color) -> void:
	var w := 172.0
	var r := Rect2(right_top.x - w, right_top.y, w, 46.0)
	UiKit.pill(self, r, Color(0.03, 0.05, 0.1, 0.9), Color(col, 0.75), 3.0)
	UiIcons.draw(self, icon, Vector2(r.position.x + 26.0, r.get_center().y), 13.0, col)
	UiKit.text(self, Vector2(r.position.x + 48.0, r.get_center().y + 8.0), s, 24, UiKit.TEXT, 0, w - 58.0, 4.0)


func _draw_chapter_selector(vs: Vector2) -> void:
	var ch := Catalog.chapter(chapter_id)
	var unlocked: bool = Profile.p.chapter_state(chapter_id).get("unlocked", false)
	var idx := Catalog.chapter_order.find(chapter_id) + 1
	var r := Rect2(vs.x - 372.0 + 62.0 - safe.z, vs.y - 208.0 - safe.w, 350.0 - 124.0, 54.0)
	UiKit.panel(self, r, Color("0b1224", 0.9), Color(ch.accent, 0.9 if unlocked else 0.3), 10.0)
	UiKit.text(self, Vector2(r.position.x, r.position.y + 22.0), "CAPÍTULO %d" % idx, 13, Color(ch.accent.lightened(0.3), 0.9), 1, r.size.x, 3.0)
	var line := ch.display_name
	if not unlocked:
		var req := Catalog.chapter(ch.unlock_requires)
		line = ("Completa: %s" % req.display_name) if req != null else "BLOQUEADO"
	UiKit.text(self, Vector2(r.position.x, r.position.y + 44.0), line, 15 if unlocked else 13, UiKit.TEXT if unlocked else UiKit.DIM, 1, r.size.x, 3.0)


func _draw_mission_chip(ci: CanvasItem, r: Rect2) -> void:
	var p := Profile.p
	var done := 0
	var total := 0
	for it in MissionSystem.items(p, "daily"):
		var def: MissionData = Catalog.missions.get(it["id"])
		if def != null:
			total += 1
			if MissionSystem.is_complete(it, def):
				done += 1
	UiIcons.draw(ci, "target", Vector2(34, r.get_center().y), 14.0, Color("5fffc8"))
	UiKit.text(ci, Vector2(60, r.get_center().y - 4.0), "MISIONES", 17, UiKit.TEXT, 0, -1.0, 3.0)
	UiKit.text(ci, Vector2(60, r.get_center().y + 18.0), "Hoy %d / %d" % [done, total], 14, Color("5fffc8"), 0, -1.0, 2.0, false)


func _draw_pass_chip(ci: CanvasItem, r: Rect2) -> void:
	var p := Profile.p
	var info := PassSystem.level_info(p, Catalog.season)
	UiIcons.draw(ci, "star", Vector2(34, r.get_center().y - 8.0), 14.0, Color("c47bff"))
	UiKit.text(ci, Vector2(60, r.get_center().y - 8.0), "PASE  NIV %d" % int(info["level"]), 17, UiKit.TEXT, 0, -1.0, 3.0)
	var f: float = 1.0 if bool(info["max"]) else float(info["into"]) / float(info["need"])
	UiKit.bar(ci, Rect2(60, r.get_center().y + 8.0, r.size.x - 78.0, 10.0), f, Color("c47bff"))


func _draw_gift_chip(ci: CanvasItem, r: Rect2) -> void:
	var pulse := 0.5 + 0.5 * sin(t * 4.0)
	Gfx.draw_glow(ci, r.get_center(), 90.0, Color(1.0, 0.8, 0.3, 0.12 + 0.12 * pulse))
	UiIcons.draw(ci, "gift", Vector2(36, r.get_center().y), 15.0, Color("ffd24a"))
	UiKit.text(ci, Vector2(64, r.get_center().y - 4.0), "REGALO", 17, UiKit.GOLD, 0, -1.0, 3.0)
	UiKit.text(ci, Vector2(64, r.get_center().y + 18.0), "¡Reclámalo gratis!", 13, UiKit.TEXT, 0, -1.0, 2.0, false)
