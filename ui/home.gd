class_name Home
extends Control
## Portada 2D con arte de entorno pre-renderizado; el heroe se elige desde la barra lateral.

var cover: Texture2D
const TITLE_BUTTON = preload("res://ui/home_button.gd")
var play_btn: GButton
var chap_prev: GButton
var chap_next: GButton
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
	play_btn.grab_focus()
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
	play_btn.font_size = 40
	chap_prev = _button("", func(): _cycle_chapter(-1), "chev_l")
	chap_next = _button("", func(): _cycle_chapter(1), "chev_r")
	gear_btn = _button("", _open_settings, "gear")
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
	if b is HomeButton:
		b.ui_scale = content_scale


func _layout() -> void:
	safe = SafeArea.margins(self)
	var usable := size - Vector2(safe.x + safe.z, safe.y + safe.w)
	content_scale = minf(usable.x / 1280.0, usable.y / 720.0)
	content_origin = Vector2(safe.x, safe.y) + (usable - Vector2(1280, 720) * content_scale) * 0.5
	_place(play_btn, Rect2(936, 548, 304, 94))
	_place(chap_prev, Rect2(1120, 444, 48, 44))
	_place(chap_next, Rect2(1180, 444, 48, 44))
	_place(gear_btn, Rect2(1192, 36, 48, 48))
	for i in nav.size():
		_place(nav[i], Rect2(24, 180 + i * 72, 166, 58))


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
	play_btn.font_size = 40


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
	_set_menu_focus(false)
	add_child(screen)


func _set_menu_focus(active: bool) -> void:
	for child in get_children():
		if child is HomeButton:
			child.focus_mode = Control.FOCUS_ALL if active else Control.FOCUS_NONE


func _on_screen_closed() -> void:
	screen = null
	_set_menu_focus(true)
	_refresh_badges()
	play_btn.grab_focus()


func _open_settings() -> void:
	if settings != null or screen != null:
		return
	settings = SettingsPanel.new()
	settings.closed.connect(func(): settings.queue_free(); settings = null; _set_menu_focus(true); gear_btn.grab_focus())
	_set_menu_focus(false)
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
	_set_menu_focus(false)
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
		var first := chapter_id if ModeRules.CHAPTER_MODES.has(mode_id) else Catalog.chapter_order[0]
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
	MenuStyle.background(self, Rect2(Vector2.ZERO, size))
	draw_set_transform(content_origin, 0, Vector2.ONE * content_scale)
	var gold := MenuStyle.GOLD
	var p := Profile.p
	var ch := Catalog.chapter(chapter_id)
	var unlocked: bool = p.chapter_state(chapter_id).get("unlocked", false)
	# Persistent navigation rail and a deliberately larger chapter showcase.
	draw_rect(Rect2(0, 0, 212, 720), Color("09121c", 0.92))
	draw_line(Vector2(212, 32), Vector2(212, 688), Color(gold, 0.18), 1)
	MenuStyle.text(self, Vector2(24, 67), "RPG", 52, MenuStyle.TEXT)
	MenuStyle.text(self, Vector2(26, 92), "P R E M I U M", 15, gold)
	MenuStyle.text(self, Vector2(24, 155), "TU REFUGIO", 12, MenuStyle.DIM)
	MenuStyle.text(self, Vector2(24, 676), "CADA RUN, UNA LEYENDA", 11, gold)
	MenuStyle.text(self, Vector2(240, 49), "EL DESCENSO TE ESPERA", 12, gold)
	MenuStyle.text(self, Vector2(240, 91), "Prepará tu próxima leyenda.", 36, MenuStyle.TEXT)
	_draw_profile(Vector2(1280,720))
	var feature := Rect2(240, 126, 1000, 386)
	MenuStyle.cover(self, feature, cover)
	MenuStyle.shade_left(self, feature, 0.99)
	MenuStyle.gradient_rect(self, feature, Color(MenuStyle.INK, 0.04), Color(MenuStyle.INK, 0.55))
	draw_style_box(MenuStyle.box(Color.TRANSPARENT, Color(gold, 0.4), 0), feature)
	MenuStyle.pill(self, Rect2(268, 154, 168, 30), Color("15232d"), gold)
	MenuStyle.text(self, Vector2(280, 175), "CAPÍTULO %02d  /  %s" % [Catalog.chapter_order.find(chapter_id) + 1, "LISTO" if unlocked else "BLOQUEADO"], 13, gold)
	# TextParagraph wraps the actual chapter name without changing content.
	var heading := TextParagraph.new()
	heading.add_string(ch.display_name.to_upper(), MenuStyle.DISPLAY, 62)
	heading.width = 510
	heading.draw(get_canvas_item(), Vector2(268, 208), MenuStyle.TEXT)
	MenuStyle.paragraph(self, Rect2(270, 368, 430, 62), "Una nueva ruta. Nuevos peligros.\nElegí tu modo y entrá al descenso." if unlocked else "Completá el capítulo anterior para abrir esta ruta. Supervivencia sigue disponible.", 20)
	MenuStyle.text(self, Vector2(270, 478), "01 — 04   /   ELEGÍ TU DESTINO", 13, gold)
	MenuStyle.text(self, Vector2(936, 676), "ELEGIR MODO Y DIFICULTAD", 12, gold, 1, 304)
	MenuStyle.text(self, Vector2(240, 693), "EXPLORÁ · COMBATÍ · VOLVÉ MÁS FUERTE", 12, MenuStyle.DIM)
	draw_set_transform(Vector2.ZERO)
	if _launching:
		draw_rect(Rect2(Vector2.ZERO,size),Color("edd3a0",clampf(_launch_t,0,0.25)))

func _draw_profile(_vs: Vector2) -> void:
	var p := Profile.p
	var lv := p.account_level()
	MenuStyle.text(self, Vector2(790, 56), "NIVEL %02d" % int(lv["level"]), 14, MenuStyle.DIM)
	MenuStyle.bar(self, Rect2(790, 69, 106, 3), _lv_anim, MenuStyle.GOLD)
	UiIcons.draw(self, "gem", Vector2(939, 59), 9, MenuStyle.GEM)
	MenuStyle.text(self, Vector2(959, 65), MenuStyle.format_int(p.gems()), 18, MenuStyle.TEXT)
	UiIcons.draw(self, "coin", Vector2(1060, 59), 9, MenuStyle.GOLD)
	MenuStyle.text(self, Vector2(1080, 65), MenuStyle.format_int(p.coins()), 18, MenuStyle.TEXT)


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
