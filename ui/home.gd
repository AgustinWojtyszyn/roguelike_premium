class_name Home
extends Control
## Portada 2D con arte de entorno pre-renderizado; el heroe se elige mediante su ficha.

var cover: Texture2D
const TITLE_BUTTON = preload("res://ui/home_button.gd")
var hero_hit: GButton
var play_btn: GButton
var chap_prev: GButton
var chap_next: GButton
var char_prev: GButton
var char_next: GButton
var gear_btn: GButton
var nav: Array[GButton] = []
var mode_id: String = ModeRules.CAMPAIGN
var challenge_id: String = "one_weapon"
var screen: MenuScreen = null
var settings: SettingsPanel = null
var content_origin := Vector2.ZERO
var content_scale := 1.0
var chapter_id := "ch1"
var _launching := false
var _launch_t: float = 0.0
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
	_apply_chapter_cover()
	mode_id = str(p.data.get("selected_mode", ModeRules.CAMPAIGN))
	if not ModeRules.ORDER.has(mode_id):
		mode_id = ModeRules.CAMPAIGN
	challenge_id = str(p.data.get("selected_challenge", "one_weapon"))
	if not ModeRules.CHALLENGES.has(challenge_id):
		challenge_id = "one_weapon"
	if Boot.has_flag("mode") and ModeRules.ORDER.has(Boot.get_arg("mode")):
		mode_id = Boot.get_arg("mode")
	if Boot.has_flag("challenge") and ModeRules.CHALLENGES.has(Boot.get_arg("challenge")):
		challenge_id = Boot.get_arg("challenge")
	_make_buttons()
	resized.connect(_layout)
	_layout()
	_refresh_badges()
	AudioMgr.play_music("menu")
	AudioMgr.stop_hum()
	if Boot.has_flag("shots"):
		_shots_mode()
	if Boot.has_flag("autoplay"):
		get_tree().create_timer(1.0).timeout.connect(func(): _start_run(mode_id, challenge_id))
	Boot.log_stage(8, "home ready")


func _button(label_text: String, cb: Callable, ic: String = "", primary: bool = false) -> GButton:
	var b := TITLE_BUTTON.new()
	b.label = label_text
	b.icon = ic
	b.style = GButton.Style.PRIMARY if primary else GButton.Style.GHOST
	b.pressed.connect(cb)
	add_child(b)
	return b


func _make_buttons() -> void:
	play_btn = _button("JUGAR", _on_play, "", true)
	play_btn.font_size = 28
	chap_prev = _button("", func(): _cycle_chapter(-1), "chev_l")
	chap_next = _button("", func(): _cycle_chapter(1), "chev_r")
	char_prev = _button("", func(): _cycle_char(-1), "chev_l")
	char_next = _button("", func(): _cycle_char(1), "chev_r")
	gear_btn = _button("", _open_settings, "gear")
	hero_hit = _button("", func(): _open("chars"))
	hero_hit.modulate.a = 0.0
	var defs := [["TIENDA", "cart", "shop"], ["PERSONAJES", "person", "chars"], ["ARMAS", "sword", "arms"],
		["PASE", "star", "pass"], ["MISIONES", "target", "missions"], ["NOVEDADES", "news", "news"]]
	for d in defs:
		var key: String = d[2]
		var b := _button(d[0], func(): _open(key), d[1])
		b.navigation = true
		nav.append(b)


func _place(b: Control, r: Rect2) -> void:
	b.position = content_origin + r.position * content_scale
	b.size = r.size * content_scale


func _layout() -> void:
	safe = SafeArea.margins(self)
	var usable := size - Vector2(safe.x + safe.z, safe.y + safe.w)
	content_scale = minf(usable.x / 1280.0, usable.y / 720.0)
	content_origin = Vector2(safe.x, safe.y) + (usable - Vector2(1280, 720) * content_scale) * 0.5
	_place(play_btn, Rect2(64, 478, 352, 68))
	_place(chap_prev, Rect2(64, 409, 48, 52))
	_place(chap_next, Rect2(368, 409, 48, 52))
	_place(char_prev, Rect2(882, 508, 48, 52))
	_place(char_next, Rect2(1156, 508, 48, 52))
	_place(hero_hit, Rect2(938, 502, 210, 70))
	_place(gear_btn, Rect2(1156, 28, 48, 48))
	for i in nav.size():
		_place(nav[i], Rect2(64 + i * 192, 623, 180, 56))


func _refresh_badges() -> void:
	var p := Profile.p
	var claim_m := MissionSystem.claimable_count(p, Catalog.missions)
	var claim_p := PassSystem.claimable_count(p, Catalog.season)
	nav[4].badge = claim_m
	nav[3].badge = claim_p
	nav[0].badge_text = "!" if ShopSystem.gift_available(p, MissionSystem.today_key()) else ""
	nav[5].badge_text = "!" if _news_new else ""
	_update_play_state()


func _update_play_state() -> void:
	# JUGAR siempre abre el selector de modo; alli se indica que modos estan disponibles (campana segun el capitulo elegido)
	play_btn.enabled = true
	play_btn.label = "JUGAR"
	play_btn.icon = ""
	play_btn.font_size = 28


func _cycle_chapter(d: int) -> void:
	var order: Array[String] = Catalog.chapter_order
	var i := order.find(chapter_id)
	i = posmod(i + d, order.size())
	chapter_id = order[i]
	Profile.p.data["selected_chapter"] = chapter_id
	Profile.p.touch()
	_apply_chapter_cover()
	_update_play_state()


## Un fondo por capitulo (arte Playground promovido, uno cargado a la vez); sin el, la portada KayKit original.
func _apply_chapter_cover() -> void:
	var path := "res://assets/premium/presentation/backdrops/%s.jpg" % chapter_id
	if not ResourceLoader.exists(path):
		path = "res://assets/premium/presentation/fortress.png"
	cover = load(path)
	queue_redraw()


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
	AudioMgr.ui("swap", -4.0)
	queue_redraw()


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
		"modes":
			screen = ModeSelectScreen.new()
			screen.chapter_id = chapter_id
			screen.chosen.connect(_start_run)
	screen.closed.connect(_on_screen_closed)
	add_child(screen)


func _on_screen_closed() -> void:
	screen = null
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
	AudioMgr.ui("ui_confirm", -2.0)
	var sel := ModeSelectScreen.new()
	sel.chapter_id = chapter_id
	sel.chosen.connect(_start_run)
	sel.closed.connect(_on_screen_closed)
	screen = sel
	add_child(sel)


func _start_run(mode: String, challenge: String) -> void:
	mode_id = mode
	challenge_id = challenge
	if screen != null:
		screen.queue_free()
		screen = null
	_launching = true
	_launch_t = 0.0
	var p := Profile.p
	AudioMgr.ui("ui_confirm", 0.0)
	AudioMgr.ui("smg", -4.0)
	var ch := Catalog.chapter(chapter_id)
	get_tree().create_timer(0.35).timeout.connect(func():
		var first := chapter_id if (mode_id == ModeRules.CAMPAIGN or mode_id == ModeRules.CHALLENGE) else Catalog.chapter_order[0]
		Router.goto("run", {"character": p.selected_character(), "chapter": first, "seed": randi(), "mode": mode_id, "challenge": challenge_id}, ch.accent.darkened(0.75)))


func _shots_mode() -> void:
	var which := Boot.get_arg("screen", "")
	if which != "":
		get_tree().create_timer(0.6).timeout.connect(func(): _open(which))


func _process(delta: float) -> void:
	if _launching:
		_launch_t += delta
	var p := Profile.p
	_lv_anim = lerpf(_lv_anim, float(p.account_level()["into"]) / float(p.account_level()["need"]), clampf(delta * 5.0, 0.0, 1.0))
	if Engine.get_frames_drawn() % 3 == 0:
		queue_redraw()


func _draw() -> void:
	# Fill/crop once, with negative space for the title. No runtime 3D or enlarged combat sprite.
	draw_rect(Rect2(Vector2.ZERO, size), Color("080e17"))
	var k := maxf(size.x / 1920.0, size.y / 1080.0)
	var art_size := Vector2(1920, 1080) * k
	draw_texture_rect(cover, Rect2((size - art_size) * 0.5 + Vector2(size.x * 0.16, 0), art_size), false)
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(size.x * 0.78,0), Vector2(size.x * 0.78,size.y), Vector2(0,size.y)])
	draw_polygon(pts, PackedColorArray([Color("080e17"), Color("080e17",0), Color("080e17",0), Color("080e17")]))
	UiKit.gradient_rect(self, Rect2(0, size.y * 0.65, size.x, size.y * 0.35), Color("080e17",0), Color("080e17"))
	draw_set_transform(content_origin, 0, Vector2.ONE * content_scale)
	var gold := Color("c6a477")
	var ivory := Color("eee5d5")
	var p := Profile.p
	var c := Catalog.character(p.selected_character())
	UiKit.text(self, Vector2(64,57), "R P G   /   P R E M I U M", 15, gold)
	draw_line(Vector2(64,82),Vector2(1216,82),Color(gold,0.23),1)
	UiKit.text(self, Vector2(64,190), "CADA DESCENSO, UNA NUEVA LEYENDA", 13, gold)
	UiKit.text(self, Vector2(59,265), "ROGUELIKE", 62, ivory)
	UiKit.text(self, Vector2(64,309), "P R E M I U M", 28, gold)
	draw_line(Vector2(64,339),Vector2(116,339),gold,2)
	UiKit.text(self, Vector2(64,371), "Entrá. Resistí. Volvé más fuerte.", 18, Color("abb4bd"), 0, -1, 0, false)
	_draw_chapter_selector(Vector2(1280,720))
	UiKit.text(self, Vector2(64,576), "ELEGÍ TU MODO Y COMENZÁ EL DESCENSO", 11, Color("8795a5"))
	# Compact loadout card retains quick hero cycling and opens the full collection.
	draw_rect(Rect2(866,460,350,122),Color("0a111b",0.86))
	draw_line(Vector2(866,460),Vector2(1216,460),Color(gold,0.6),1)
	UiKit.text(self,Vector2(888,488),"TU COMBATIENTE",11,gold)
	UiKit.text(self,Vector2(932,545),Catalog.weapon(c.start_weapon).display_name,18,ivory,1,220)
	_draw_profile(Vector2(1280,720))
	draw_set_transform(Vector2.ZERO)
	if _launching:
		draw_rect(Rect2(Vector2.ZERO,size),Color("edd3a0",clampf(_launch_t,0,0.25)))


func _draw_profile(_vs: Vector2) -> void:
	var p := Profile.p
	var lv := p.account_level()
	var gold := Color("c6a477")
	UiKit.text(self,Vector2(675,58),"NIVEL %02d" % int(lv["level"]),14,Color("b9c3cc"))
	draw_rect(Rect2(675,68,130,2),Color("293544"))
	draw_rect(Rect2(675,68,130 * _lv_anim,2),gold)
	UiIcons.draw(self,"gem",Vector2(867,51),9,Color("a49eb8"))
	UiKit.text(self,Vector2(885,57),UiKit.format_int(p.gems()),16,UiKit.TEXT)
	UiIcons.draw(self,"coin",Vector2(997,51),9,gold)
	UiKit.text(self,Vector2(1015,57),UiKit.format_int(p.coins()),16,UiKit.TEXT)


func _draw_chapter_selector(_vs: Vector2) -> void:
	var ch := Catalog.chapter(chapter_id)
	var unlocked: bool = Profile.p.chapter_state(chapter_id).get("unlocked", false)
	var idx := Catalog.chapter_order.find(chapter_id) + 1
	UiKit.text(self,Vector2(117,427),"CAPÍTULO %02d" % idx,11,Color("c6a477"),1,245)
	var line := ch.display_name if unlocked else "BLOQUEADO · " + ch.display_name
	UiKit.text(self,Vector2(117,450),line,13 if unlocked else 11,UiKit.TEXT if unlocked else UiKit.DIM,1,245)


func _unhandled_input(e: InputEvent) -> void:
	# Atajos de teclado / mando: Enter o Espacio = JUGAR; Esc cierra la pantalla abierta
	if screen != null or settings != null or _launching:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		if e.physical_keycode == KEY_ENTER or e.physical_keycode == KEY_KP_ENTER or e.physical_keycode == KEY_SPACE:
			if play_btn.enabled:
				_on_play()
	elif e is InputEventJoypadButton and e.pressed and e.button_index == JOY_BUTTON_A:
		if play_btn.enabled:
			_on_play()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if settings != null:
			return      # el panel de ajustes gestiona su propio "atras"
		if screen == null and not _launching:
			get_tree().quit()      # atras desde el inicio = salir de la app
