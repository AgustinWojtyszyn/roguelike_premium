class_name PauseMenu
extends Control
## Menu de pausa de la run: Continuar / Ajustes / Salir de la run (con confirmacion).

var game: Game
var btns: Array[GButton] = []
var settings: SettingsPanel
var confirm := false
var _anim: float = 0.0
var yes_btn: GButton
var no_btn: GButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var defs := [["CONTINUAR", GButton.Style.PRIMARY, "play"], ["AJUSTES", GButton.Style.SECONDARY, "gear"], ["SALIR DE LA RUN", GButton.Style.DANGER, ""]]
	for d in defs:
		var b := GButton.make(d[0], d[1], d[2])
		b.font_size = 28
		add_child(b)
		btns.append(b)
	btns[0].pressed.connect(func(): _close())
	btns[1].pressed.connect(_open_settings)
	btns[2].pressed.connect(func(): _set_confirm(true))
	yes_btn = GButton.make("SÍ, SALIR", GButton.Style.DANGER)
	no_btn = GButton.make("VOLVER", GButton.Style.SECONDARY)
	for b in [yes_btn, no_btn]:
		b.font_size = 26
		b.visible = false
		add_child(b)
	yes_btn.pressed.connect(func(): get_tree().paused = false; game.quit_to_home(true))
	no_btn.pressed.connect(func(): _set_confirm(false))
	resized.connect(_layout)
	_layout()
	AudioMgr.ui("ui_open")


func _layout() -> void:
	var w := 380.0
	var x := (size.x - w) * 0.5
	var y := size.y * 0.5 - 90.0
	for i in btns.size():
		btns[i].size = Vector2(w, 74)
		btns[i].position = Vector2(x, y + float(i) * 90.0)
	yes_btn.size = Vector2(250, 70)
	no_btn.size = Vector2(250, 70)
	yes_btn.position = Vector2(size.x * 0.5 - 265.0, size.y * 0.5 + 40.0)
	no_btn.position = Vector2(size.x * 0.5 + 15.0, size.y * 0.5 + 40.0)


func _set_confirm(on: bool) -> void:
	confirm = on
	for b in btns:
		b.visible = not on
	yes_btn.visible = on
	no_btn.visible = on


func _open_settings() -> void:
	settings = SettingsPanel.new()
	settings.closed.connect(func(): settings.queue_free(); settings = null)
	add_child(settings)


func _close() -> void:
	AudioMgr.ui("ui_back")
	game.resume_from_pause()
	queue_free()


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e.physical_keycode == KEY_ESCAPE or e.physical_keycode == KEY_P) and settings == null:
		_close()


func _process(delta: float) -> void:
	_anim = minf(1.0, _anim + delta * 6.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.05, 0.62 * _anim))
	var pw := 460.0
	var ph := 372.0 if not confirm else 260.0
	var pr := Rect2((size.x - pw) * 0.5, size.y * 0.5 - (150.0 if not confirm else 100.0), pw, ph)
	UiKit.panel(self, pr, UiKit.PANEL, Color(UiKit.EDGE, 0.7), 18.0, _anim)
	if confirm:
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 60.0), "¿SALIR DE LA RUN?", 32, UiKit.TEXT, 1, pw, 6.0)
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 100.0), "Conservas las monedas y la XP ganadas.", 18, UiKit.DIM, 1, pw, 3.0, false)
	else:
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 56.0), "PAUSA", 40, UiKit.TEXT, 1, pw, 7.0)
		var c := game.chapter
		UiKit.text(self, Vector2(pr.position.x, pr.position.y + 84.0), c.display_name, 16, Color(c.accent, 0.9), 1, pw, 3.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and settings == null and is_inside_tree():
		if confirm:
			_set_confirm(false)
		else:
			_close()
