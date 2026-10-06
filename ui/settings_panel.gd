class_name SettingsPanel
extends Control
## Ajustes: musica y efectos por separado (interruptores + volumen), vibracion, asistencia de punteria y FPS.
## Se usa en el menu principal y en la pausa. Guarda en el perfil al instante.

signal closed

var rows: Array[Dictionary] = []
var title := "AJUSTES"
var _vol_drag := ""
var _anim: float = 0.0
var close_btn: GButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)
	size = get_viewport_rect().size
	get_viewport().size_changed.connect(func(): size = get_viewport_rect().size)
	close_btn = GButton.make("LISTO", GButton.Style.PRIMARY)
	close_btn.font_size = 26
	close_btn.pressed.connect(func(): closed.emit())
	add_child(close_btn)
	resized.connect(_layout)
	_layout()


func _panel_rect() -> Rect2:
	var w := minf(620.0, size.x - 40.0)
	var h := minf(470.0, size.y - 40.0)
	return Rect2((size.x - w) * 0.5, (size.y - h) * 0.5, w, h)


func _layout() -> void:
	var pr := _panel_rect()
	close_btn.size = Vector2(220, 64)
	close_btn.position = Vector2(pr.get_center().x - 110.0, pr.end.y - 84.0)


func _process(delta: float) -> void:
	_anim = minf(1.0, _anim + delta * 5.0)
	queue_redraw()


func _row_rect(i: int) -> Rect2:
	var pr := _panel_rect()
	return Rect2(pr.position.x + 28.0, pr.position.y + 82.0 + float(i) * 66.0, pr.size.x - 56.0, 56.0)


func _items() -> Array[Dictionary]:
	var s: Dictionary = Profile.p.data["settings"]
	return [
		{"key": "music", "label": "MÚSICA", "vol": "music_vol", "on": bool(s["music"]), "v": float(s["music_vol"])},
		{"key": "sfx", "label": "EFECTOS", "vol": "sfx_vol", "on": bool(s["sfx"]), "v": float(s["sfx_vol"])},
		{"key": "aim_assist", "label": "AYUDA DE PUNTERÍA", "on": bool(s["aim_assist"])},
		{"key": "vibration", "label": "VIBRACIÓN", "on": bool(s["vibration"])},
		{"key": "show_fps", "label": "MOSTRAR FPS", "on": bool(s["show_fps"])},
	]


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.05, 0.7 * _anim))
	var pr := _panel_rect()
	var sc := 0.92 + 0.08 * Gfx.ease_out(_anim)
	draw_set_transform(pr.get_center() * (1.0 - sc), 0.0, Vector2.ONE * sc)
	UiKit.panel(self, pr, UiKit.PANEL, Color(UiKit.EDGE, 0.8), 18.0)
	UiKit.text(self, Vector2(pr.position.x, pr.position.y + 54.0), title, 34, UiKit.TEXT, 1, pr.size.x, 6.0)
	var items := _items()
	for i in items.size():
		var it: Dictionary = items[i]
		var r := _row_rect(i)
		UiKit.panel(self, r, UiKit.PANEL_HI, Color(1, 1, 1, 0.08), 8.0, 1.0, false)
		UiKit.text(self, Vector2(r.position.x + 18.0, r.get_center().y + 8.0), it["label"], 22, UiKit.TEXT, 0, -1.0, 3.0)
		# interruptor
		var sw := Rect2(r.end.x - 92.0, r.position.y + 11.0, 76.0, 34.0)
		var on: bool = it["on"]
		UiKit.pill(self, sw, Color("1fb89a") if on else Color("3a4258"), UiKit.INK, 3.0)
		var kx := sw.end.x - 18.0 if on else sw.position.x + 18.0
		draw_circle(Vector2(kx, sw.get_center().y), 12.0, Color.WHITE if on else Color(0.7, 0.75, 0.85))
		draw_arc(Vector2(kx, sw.get_center().y), 12.0, 0, TAU, 16, UiKit.INK, 2.0, true)
		if it.has("vol"):
			var vr := Rect2(r.position.x + 190.0, r.position.y + 21.0, r.size.x - 190.0 - 112.0, 14.0)
			UiKit.bar(self, vr, float(it["v"]), Color("3fb8ff") if on else Color("5a6278"))
			draw_circle(Vector2(vr.position.x + vr.size.x * float(it["v"]), vr.get_center().y), 11.0, Color.WHITE)
			draw_arc(Vector2(vr.position.x + vr.size.x * float(it["v"]), vr.get_center().y), 11.0, 0, TAU, 14, UiKit.INK, 2.0, true)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _gui_input(e: InputEvent) -> void:
	var pos := Vector2.ZERO
	var down := false
	var up := false
	var drag := false
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
		pos = e.position
		down = e.pressed
		up = not e.pressed
	elif e is InputEventScreenTouch:
		pos = e.position
		down = e.pressed
		up = not e.pressed
	elif e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		pos = e.position
		drag = true
	elif e is InputEventScreenDrag:
		pos = e.position
		drag = true
	else:
		return
	var items := _items()
	if up:
		_vol_drag = ""
		return
	for i in items.size():
		var it: Dictionary = items[i]
		var r := _row_rect(i)
		var sw := Rect2(r.end.x - 92.0, r.position.y + 11.0, 76.0, 34.0)
		var vr := Rect2(r.position.x + 190.0, r.position.y + 5.0, r.size.x - 190.0 - 112.0, 46.0)
		if down and sw.grow(10.0).has_point(pos):
			_toggle(it["key"], not bool(it["on"]))
			AudioMgr.ui("ui_click", -2.0)
			return
		if it.has("vol") and (down or (drag and _vol_drag == it["vol"])) and (vr.has_point(pos) or _vol_drag == it["vol"]):
			_vol_drag = it["vol"]
			var v := clampf((pos.x - vr.position.x) / vr.size.x, 0.0, 1.0)
			Profile.p.set_setting(it["vol"], v)
			AudioMgr.apply_settings()
			return


func _toggle(key: String, on: bool) -> void:
	if key == "music":
		AudioMgr.set_music_enabled(on)
	elif key == "sfx":
		AudioMgr.set_sfx_enabled(on)
	else:
		Profile.p.set_setting(key, on)
