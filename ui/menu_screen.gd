class_name MenuScreen
extends Control
## Base de las pantallas de menu (Coleccion, Armeria, Pase, Misiones, Tienda, Novedades): entrada animada,
## cabecera con titulo / volver / monedas y gemas, y registro de botones dibujados con tap + retroalimentacion.

signal closed

var title := ""
var accent := Color("27e0cc")
var enter_k: float = 0.0
var t: float = 0.0
var regions: Array[Dictionary] = []
var pressed_id := ""
var _press_idx := -2
var back_btn: GButton
var closing := false
var toast_text := ""
var toast_t: float = 0.0
var toast_col := Color.WHITE
const HEADER_H := 104.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	back_btn = HomeButton.menu("", GButton.Style.ICON, "chev_l")
	back_btn.click_sound = "ui_back"
	back_btn.pressed.connect(close)
	add_child(back_btn)
	_build()
	resized.connect(_relayout)
	_relayout()
	AudioMgr.ui("ui_open", -4.0)


func _build() -> void:
	pass


func _relayout() -> void:
	back_btn.size = Vector2(76, 62)
	var sm := SafeArea.margins(self)
	back_btn.position = Vector2(18.0 + sm.x, 14.0)
	_layout()


func _layout() -> void:
	pass


func close() -> void:
	if closing:
		return
	closing = true
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.16)
	tw.parallel().tween_property(self, "position:x", 60.0, 0.16)
	await tw.finished
	closed.emit()
	queue_free()


func show_toast(s: String, c: Color = Color.WHITE) -> void:
	toast_text = s
	toast_col = c
	toast_t = 1.8


func _process(delta: float) -> void:
	t += delta
	if not closing:
		modulate.a = minf(1.0, t * 7.0)
	enter_k = minf(1.0, enter_k + delta * 4.5)
	toast_t = maxf(0.0, toast_t - delta)
	queue_redraw()


func _draw() -> void:
	regions.clear()
	var k := Gfx.ease_out(enter_k)
	MenuStyle.background(self, Rect2(Vector2.ZERO, size))
	_draw_header(k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_draw_body(k)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	if toast_t > 0.0:
		var a := clampf(toast_t * 2.5, 0.0, 1.0)
		var r := Rect2(size.x * 0.5 - 260.0, size.y - 130.0 + (1.0 - a) * 20.0, 520.0, 52.0)
		MenuStyle.panel(self, r, Color("0d1424", 0.95), Color(toast_col, a), 12.0, a)
		MenuStyle.text(self, Vector2(r.position.x, r.position.y + 35.0), toast_text, 22, Color(toast_col, a), 1, r.size.x, 4.0)


func _draw_body(_k: float) -> void:
	pass


func _draw_header(_k: float) -> void:
	draw_rect(Rect2(0, 0, size.x, HEADER_H), Color(MenuStyle.INK, 0.85))
	draw_line(Vector2(24, HEADER_H - 1), Vector2(size.x - 24, HEADER_H - 1), Color(MenuStyle.GOLD, 0.24), 1)
	var sx := SafeArea.margins(self).x
	MenuStyle.text(self, Vector2(108 + sx, 30), "RPG PREMIUM  /  TU REFUGIO", 12, MenuStyle.GOLD)
	MenuStyle.text(self, Vector2(108 + sx, 76), title, 42, MenuStyle.TEXT)
	var right := size.x - 24.0 - SafeArea.margins(self).z
	_pill(Vector2(right, 30), MenuStyle.format_int(Profile.p.coins()), "coin", MenuStyle.GOLD)
	_pill(Vector2(right - 184, 30), MenuStyle.format_int(Profile.p.gems()), "gem", MenuStyle.GEM)


func _pill(right_top: Vector2, s: String, icon: String, col: Color) -> void:
	var w := 170.0
	var r := Rect2(right_top.x - w, right_top.y, w, 42.0)
	MenuStyle.pill(self, r, Color(0.03, 0.05, 0.1, 0.9), Color(col, 0.7), 2.5)
	UiIcons.draw(self, icon, Vector2(r.position.x + 24.0, r.get_center().y), 12.0, col)
	MenuStyle.text(self, Vector2(r.position.x + 44.0, r.get_center().y + 8.0), s, 22, MenuStyle.TEXT, 0, w - 54.0, 3.0)


# ---- botones dibujados (con registro de zona) ----
func reg(id: String, r: Rect2) -> void:
	regions.append({"id": id, "rect": r})


func is_down(id: String) -> bool:
	return pressed_id == id


func button(id: String, r: Rect2, label: String, style: int = GButton.Style.SECONDARY, icon: String = "", fsize: int = 22, enabled: bool = true, sub: String = "") -> void:
	var top := MenuStyle.PANEL_HI
	var bot := MenuStyle.PANEL
	var txt := MenuStyle.TEXT
	match style:
		GButton.Style.PRIMARY, GButton.Style.GOLD:
			top = MenuStyle.GOLD
			txt = MenuStyle.INK
		GButton.Style.DANGER:
			top = MenuStyle.DANGER
		GButton.Style.TAB:
			top = Color("365164")
	if not enabled:
		top = top.lerp(Color("3a4056"), 0.75)
		bot = bot.lerp(Color("20243a"), 0.75)
		txt = MenuStyle.DIM
	var press := 1.0 if (is_down(id) and enabled) else 0.0
	var body := MenuStyle.chunky(self, r, top, bot, press, 1.0 if enabled and r.has_point(get_local_mouse_position()) else 0.0, minf(14.0, r.size.y * 0.3), 3.0)
	var cy := body.position.y + body.size.y * 0.5
	var tw := MenuStyle.text_width(label, fsize)
	var isz := float(fsize) * 0.78
	var total := tw + (isz * 2.2 if icon != "" else 0.0)
	var x0 := r.position.x + (r.size.x - total) * 0.5
	if icon != "":
		UiIcons.draw(self, icon, Vector2(x0 + isz, cy), isz, Color.WHITE if style != GButton.Style.GOLD else Color("3a2200"))
		x0 += isz * 2.2
	if sub != "":
		MenuStyle.text(self, Vector2(x0, cy - 1.0), label, fsize, txt, 0, -1.0, 4.0 if style != GButton.Style.GOLD else 0.0)
		MenuStyle.text(self, Vector2(r.position.x, cy + float(fsize) * 0.85), sub, int(fsize * 0.55), Color(txt, 0.8), 1, r.size.x, 0.0, false)
	else:
		MenuStyle.text(self, Vector2(x0, cy + float(fsize) * 0.36), label, fsize, txt, 0, -1.0, 4.0 if style != GButton.Style.GOLD else 0.0)
	if enabled:
		reg(id, r)


func tap(_id: String) -> void:
	pass


func _gui_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var down := false
	var up := false
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
		down = e.pressed
		up = not e.pressed
	elif e is InputEventScreenTouch:
		pos = e.position
		down = e.pressed
		up = not e.pressed
	else:
		return
	if down:
		pressed_id = ""
		for i in range(regions.size() - 1, -1, -1):
			if (regions[i]["rect"] as Rect2).has_point(pos):
				pressed_id = regions[i]["id"]
				break
	elif up:
		var id := pressed_id
		pressed_id = ""
		if id != "":
			for i in range(regions.size() - 1, -1, -1):
				if regions[i]["id"] == id and (regions[i]["rect"] as Rect2).has_point(pos):
					AudioMgr.ui("ui_click", -2.0)
					tap(id)
					break


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and e.physical_keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		close()
