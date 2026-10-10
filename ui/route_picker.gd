class_name RoutePicker
extends Control
## Eleccion de ruta de la EXPEDICION (2-3 tramos compatibles con el capitulo). Pausa la run, como el selector de mejoras.
## Cada tarjeta muestra: tipo de tramo, sala, modificador (riesgo) y recompensa. Tarjetas grandes, aptas para toque.

var game: Game
var options: Array = []
var leg: int = 1
var _anim: float = 0.0
var _picked := -1
var _picked_t: float = 0.0
var _closing := false

const KIND_COL := {"combat": Color("27e0cc"), "elite": Color("ffd24a"), "cache": Color("c47bff"), "rest": Color("5fffc8")}
const KIND_ICON := {"combat": "sword", "elite": "star", "cache": "chest", "rest": "heart"}
const KIND_DESC := {
	"combat": "Una sala de combate del capítulo.",
	"elite": "Encuentro de élite: más peligro y mejor botín.",
	"cache": "Sala de cofres: moneda, arma o mejora.",
	"rest": "Un respiro: vida, escudo y energía completos.",
}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	game.get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	game.input_locked = true
	game.input.reset()
	AudioMgr.ui("perk", -2.0)
	if game.bot:
		get_tree().create_timer(0.7, true, false, true).timeout.connect(func():
			if not _closing and is_inside_tree() and _picked < 0:
				_choose(0))


func _card(i: int) -> Rect2:
	var n := options.size()
	var gap := 22.0
	var w := minf(330.0, (size.x - 60.0 - gap * float(n - 1)) / float(maxi(n, 1)))
	var h := minf(380.0, size.y - 220.0)
	var total := w * float(n) + gap * float(n - 1)
	return Rect2((size.x - total) * 0.5 + float(i) * (w + gap), 130.0, w, h)


func _process(delta: float) -> void:
	_anim += delta
	if _picked >= 0:
		_picked_t += delta
		if _picked_t > 0.32 and not _closing:
			_finish()
	queue_redraw()


func _draw() -> void:
	var k := Gfx.ease_out(clampf(_anim * 4.0, 0.0, 1.0))
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.01, 0.02, 0.05, 0.86 * k))
	MenuStyle.text(self, Vector2(0, 76.0), "ELIGE TU RUTA", 44, Color("ffe27a"), 1, size.x, 8.0)
	MenuStyle.text(self, Vector2(0, 108.0), "Tramo %d de %d · %s" % [leg + 1, ModeRules.EXP_LEGS + 1, game.chapter.display_name], 20, MenuStyle.DIM, 1, size.x, 4.0, false)
	for i in options.size():
		_draw_card(i, k)
	MenuStyle.text(self, Vector2(0, size.y - 36.0), "El último tramo es el jefe del capítulo.", 17, MenuStyle.DIM, 1, size.x, 3.0, false)


func _draw_card(i: int, k: float) -> void:
	var o: Dictionary = options[i]
	var kind: String = str(o["kind"])
	var col: Color = KIND_COL.get(kind, Color("27e0cc"))
	var r := _card(i)
	var pressed := _picked == i
	if pressed:
		r = r.grow(-4.0)
	r.position.y += (1.0 - k) * 30.0
	MenuStyle.panel(self, r, Color("101a30", 0.97), Color(col, 0.95), 16.0, k)
	var art_rect := Rect2(r.position + Vector2(3, 3), Vector2(r.size.x - 6, 120))
	MenuStyle.cover(self, art_rect, MenuStyle.art(game.chapter.id), Color(0.8, 0.9, 1.0, k * 0.5))
	MenuStyle.gradient_rect(self, art_rect, Color(MenuStyle.INK, 0.1), Color(MenuStyle.PANEL, k))
	var c := Vector2(r.get_center().x, r.position.y + 62.0)
	draw_circle(c, 38.0, Color(col.darkened(0.65), k))
	draw_arc(c, 38.0, 0, TAU, 28, Color(col, k), 3.5, true)
	UiIcons.draw(self, KIND_ICON.get(kind, "door"), c, 20.0, col.lightened(0.3))
	MenuStyle.text(self, Vector2(r.position.x, r.position.y + 136.0), ModeRules.EXP_KIND_NAMES.get(kind, kind.to_upper()), 28, MenuStyle.TEXT, 1, r.size.x, 5.0)
	MenuStyle.text(self, Vector2(r.position.x, r.position.y + 162.0), str(o["name"]), 17, Color(col.lightened(0.4), 0.95), 1, r.size.x, 3.0, false)
	var y := r.position.y + 196.0
	draw_multiline_string(MenuStyle.font_reg(), Vector2(r.position.x + 16.0, y), KIND_DESC.get(kind, ""), HORIZONTAL_ALIGNMENT_LEFT, r.size.x - 32.0, 16, 4, Color(0.8, 0.9, 1.0, 0.9))
	var mid := str(o.get("modifier", ""))
	if mid != "":
		var m: Dictionary = ModeRules.EXP_MODIFIERS[mid]
		var mr := Rect2(r.position.x + 12.0, r.position.y + 246.0, r.size.x - 24.0, 78.0)
		MenuStyle.panel(self, mr, Color("2a1020", 0.95), Color("ff4f6a", 0.9), 10.0, k, false)
		MenuStyle.text(self, Vector2(mr.position.x, mr.position.y + 26.0), "⚠ " + str(m["name"]) + "  " + "●".repeat(int(m["risk"])), 18, Color("ff9aa8"), 1, mr.size.x, 3.0)
		draw_multiline_string(MenuStyle.font_reg(), Vector2(mr.position.x + 10.0, mr.position.y + 48.0), str(m["desc"]), HORIZONTAL_ALIGNMENT_LEFT, mr.size.x - 20.0, 14, 3, Color(1, 0.85, 0.88, 0.95))
	else:
		MenuStyle.text(self, Vector2(r.position.x, r.position.y + 292.0), "Sin modificadores", 16, MenuStyle.DIM, 1, r.size.x, 3.0, false)
	var coins := ModeRules.option_reward_coins(o, leg)
	var line := ("+%d monedas" % coins) if coins > 0 else ("Recuperación total" if kind == "rest" else "Cofres")
	MenuStyle.text(self, Vector2(r.position.x, r.end.y - 28.0), line, 18, MenuStyle.GOLD, 1, r.size.x, 3.0)


func _gui_input(e: InputEvent) -> void:
	if _picked >= 0 or _anim < 0.25:
		return
	var pos := Vector2.ZERO
	var up := false
	if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT and not e.pressed:
		pos = e.position
		up = true
	elif e is InputEventScreenTouch and not e.pressed:
		pos = e.position
		up = true
	if not up:
		return
	for i in options.size():
		if _card(i).has_point(pos):
			_choose(i)
			return


func _choose(i: int) -> void:
	if _picked >= 0 or i < 0 or i >= options.size():
		return
	_picked = i
	_picked_t = 0.0
	AudioMgr.ui("ui_confirm", -2.0)


func _finish() -> void:
	_closing = true
	game.get_tree().paused = false
	game.input_locked = false
	game.input.reset()
	if not game.touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var opt: Dictionary = options[_picked]
	queue_free()
	game.director._exp_choose(opt)
