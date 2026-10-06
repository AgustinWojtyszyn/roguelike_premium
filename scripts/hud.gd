class_name Hud
extends Control
## HUD minimo: integridad, arma, oleada, mira y controles tactiles flotantes.

var game: Game
var damage_flash: float = 0.0
var banner_text := ""
var banner_t: float = 0.0
var banner_dur: float = 1.0
var vignette: GradientTexture2D
var font: Font
var t: float = 0.0
var hp_lag: float = 10.0
var redraw_t: float = 0.0


func _ready() -> void:
	font = ThemeDB.fallback_font
	var g := Gradient.new()
	g.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	g.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62)])
	vignette = GradientTexture2D.new()
	vignette.gradient = g
	vignette.fill = GradientTexture2D.FILL_RADIAL
	vignette.fill_from = Vector2(0.5, 0.5)
	vignette.fill_to = Vector2(1.05, 0.5)
	vignette.width = 256
	vignette.height = 144


func banner(text: String, dur: float) -> void:
	banner_text = text
	banner_t = dur
	banner_dur = dur


func swap_rect(vs: Vector2) -> Rect2:
	return Rect2(vs.x - 150.0, 34.0, 100.0, 100.0)


func _process(delta: float) -> void:
	t += delta
	damage_flash = maxf(0.0, damage_flash - delta * 2.6)
	banner_t = maxf(0.0, banner_t - delta)
	hp_lag = move_toward(hp_lag, float(game.player.hp), delta * 6.0)
	redraw_t -= delta
	if redraw_t <= 0.0 or not game.touch_mode:
		redraw_t = 0.033
		queue_redraw()


func _draw() -> void:
	var vs := get_viewport_rect().size
	# vineta
	draw_texture_rect(vignette, Rect2(Vector2.ZERO, vs), false)
	if damage_flash > 0.0:
		draw_texture_rect(vignette, Rect2(Vector2.ZERO, vs), false, Color(1.0, 0.25, 0.3, damage_flash * 1.6))
	_draw_hp()
	_draw_wave(vs)
	_draw_weapons(vs)
	_draw_banner(vs)
	if game.touch_mode:
		_draw_touch(vs)
	else:
		_draw_reticle()
	if game.over or game.victory:
		_draw_end(vs)


func _panel(r: Rect2, a: float = 0.55) -> void:
	var pts := PackedVector2Array([r.position + Vector2(8, 0), Vector2(r.end.x, r.position.y), Vector2(r.end.x - 8, r.end.y), Vector2(r.position.x, r.end.y)])
	draw_colored_polygon(pts, Color(0.02, 0.04, 0.09, a))
	var line := pts.duplicate()
	line.append(pts[0])
	draw_polyline(line, Color(0.25, 0.9, 0.85, 0.5), 1.5, true)


func _draw_hp() -> void:
	var p := Vector2(28, 24)
	_panel(Rect2(p, Vector2(274, 50)))
	draw_string(font, p + Vector2(16, 17), "INTEGRIDAD", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.95, 0.9, 0.85))
	var hp := game.player.hp
	for i in Player.MAX_HP:
		var x := p.x + 16.0 + i * 24.5
		var y := p.y + 24.0
		var pts := PackedVector2Array([Vector2(x + 5, y), Vector2(x + 23, y), Vector2(x + 18, y + 16), Vector2(x, y + 16)])
		draw_colored_polygon(pts, Color(0.06, 0.09, 0.15))
		if i < hp:
			var low := hp <= 3
			var col := Color("33e8d0") if not low else Color("ff5f7a")
			if low:
				col = col.lerp(Color.WHITE, 0.3 * (0.5 + 0.5 * sin(t * 10.0)))
			var inner := PackedVector2Array([Vector2(x + 6.5, y + 2), Vector2(x + 21, y + 2), Vector2(x + 17, y + 14), Vector2(x + 2.5, y + 14)])
			draw_colored_polygon(inner, col)
			draw_rect(Rect2(x + 7, y + 3, 12, 2.5), Color(1, 1, 1, 0.35))
		elif float(i) < hp_lag:
			var inner := PackedVector2Array([Vector2(x + 6.5, y + 2), Vector2(x + 21, y + 2), Vector2(x + 17, y + 14), Vector2(x + 2.5, y + 14)])
			draw_colored_polygon(inner, Color(1, 1, 1, 0.8))


func _draw_wave(vs: Vector2) -> void:
	if game.wave < 0:
		return
	var left := game.enemies.size() + game.pending.size()
	var txt := "OLEADA %d/%d   ·   AMENAZAS %d" % [game.wave + 1, Game.WAVES.size(), left]
	var w := 300.0
	var r := Rect2(vs.x * 0.5 - w * 0.5, 20, w, 34)
	_panel(r, 0.5)
	draw_string(font, Vector2(r.position.x, r.position.y + 23), txt, HORIZONTAL_ALIGNMENT_CENTER, w, 15, Color(0.85, 0.97, 1.0, 0.95))


func _draw_weapons(vs: Vector2) -> void:
	if game.touch_mode:
		# boton de cambio de arma
		var r := swap_rect(vs)
		var c := r.get_center()
		draw_circle(c, 46.0, Color(0.02, 0.05, 0.1, 0.5))
		draw_arc(c, 46.0, 0, TAU, 40, Color(0.3, 0.95, 0.9, 0.55), 2.5, true)
		draw_set_transform(c + Vector2(-20, 4), 0.0, Vector2(0.9, 0.9))
		Weapons.paint(self, game.player.weapon, 0.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, c + Vector2(-40, 36), "CAMBIAR", HORIZONTAL_ALIGNMENT_CENTER, 80, 10, Color(0.7, 0.95, 1.0, 0.8))
		return
	var base := Vector2(28, vs.y - 78)
	for i in 3:
		var r := Rect2(base + Vector2(i * 112, 0), Vector2(104, 56))
		var sel := game.player.weapon == i
		_panel(r, 0.7 if sel else 0.4)
		if sel:
			draw_rect(Rect2(r.position.x + 8, r.end.y - 3, r.size.x - 8, 3), Color(0.25, 0.95, 0.88))
		draw_set_transform(r.position + Vector2(34, 28), 0.0, Vector2(0.75, 0.75) if sel else Vector2(0.65, 0.65))
		Weapons.paint(self, i, 0.0)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_string(font, r.position + Vector2(8, 12), str(i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(0.5, 0.95, 0.9, 0.9))
	var wd: Dictionary = Weapons.W[game.player.weapon]
	draw_string(font, base + Vector2(2, -8), "%s  ·  %s" % [wd["name"], wd["sub"]], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.8, 0.96, 1.0, 0.9))


func _draw_banner(vs: Vector2) -> void:
	if banner_t <= 0.0 or banner_text == "":
		return
	var age := banner_dur - banner_t
	var a := clampf(minf(age * 5.0, banner_t * 3.0), 0.0, 1.0)
	var sc := 1.0 + (1.0 - clampf(age * 6.0, 0.0, 1.0)) * 0.25
	var size := int(54 * sc)
	var pos := Vector2(0, vs.y * 0.32)
	draw_string_outline(font, pos, banner_text, HORIZONTAL_ALIGNMENT_CENTER, vs.x, size, 10, Color(0.02, 0.05, 0.1, a))
	draw_string(font, pos, banner_text, HORIZONTAL_ALIGNMENT_CENTER, vs.x, size, Color(0.75, 1.0, 0.98, a))
	var w := 260.0 * (0.6 + 0.4 * a)
	draw_rect(Rect2(vs.x * 0.5 - w * 0.5, pos.y + 14, w, 3), Color(0.25, 0.95, 0.88, a * 0.8))


func _draw_reticle() -> void:
	var m := get_viewport().get_mouse_position()
	var kick := game.player.kick
	var over_enemy := false
	var wm := game.get_global_mouse_position()
	for e in game.enemies:
		if e.hit_center().distance_to(wm) < e.hit_r:
			over_enemy = true
			break
	var col := Color(0.55, 1.0, 0.95, 0.95) if not over_enemy else Color(1.0, 0.5, 0.75, 1.0)
	var gap := 9.0 + kick * 6.0 + (-2.0 if over_enemy else 0.0)
	for k in 4:
		var a := PI * 0.5 * k + PI * 0.25
		var d := Vector2.from_angle(a)
		draw_line(m + d * gap, m + d * (gap + 8.0), Color(0, 0, 0, 0.7), 4.0, true)
		draw_line(m + d * gap, m + d * (gap + 8.0), col, 2.0, true)
	draw_circle(m, 2.6, Color(0, 0, 0, 0.7))
	draw_circle(m, 1.6, col)


func _draw_touch(vs: Vector2) -> void:
	# joystick izquierdo (flotante)
	var lo := game.touch_move_o if game.touch_move_id != -1 else Vector2(150, vs.y - 150)
	var lk := game.touch_move_p if game.touch_move_id != -1 else lo
	var la := 0.5 if game.touch_move_id != -1 else 0.22
	_stick(lo, lk, la)
	var ro := game.touch_aim_o if game.touch_aim_id != -1 else Vector2(vs.x - 160, vs.y - 150)
	var rk := game.touch_aim_p if game.touch_aim_id != -1 else ro
	var ra := 0.5 if game.touch_aim_id != -1 else 0.22
	_stick(ro, rk, ra, true)
	# indicador de apuntado
	if game.touch_aim_id != -1:
		var d := rk - ro
		if d.length() > 6.0:
			var dd := d.normalized()
			var firing := d.length() > 26.0
			draw_circle(ro + dd * 70.0, 5.0, Color(1.0, 0.6, 0.8, 0.9) if firing else Color(0.6, 1, 1, 0.5))


func _stick(o: Vector2, k: Vector2, a: float, red: bool = false) -> void:
	var base := Color(0.3, 0.95, 0.9, a)
	if red:
		base = Color(0.6, 0.9, 1.0, a)
	draw_circle(o, 70.0, Color(0.02, 0.05, 0.1, a * 0.8))
	draw_arc(o, 70.0, 0, TAU, 48, base, 3.0, true)
	draw_arc(o, 30.0, 0, TAU, 32, Color(base, a * 0.5), 1.5, true)
	var kk := o + (k - o).limit_length(70.0)
	draw_circle(kk, 30.0, Color(0.05, 0.15, 0.2, a + 0.2))
	draw_circle(kk, 26.0, Color(base, a + 0.15))
	draw_circle(kk, 14.0, Color(1, 1, 1, a * 0.5))


func _draw_end(vs: Vector2) -> void:
	var a := clampf(game.end_t * 1.2, 0.0, 1.0)
	if game.over:
		draw_rect(Rect2(Vector2.ZERO, vs), Color(0.0, 0.0, 0.03, 0.45 * a))
	if game.end_t > 1.4:
		var pulse := 0.6 + 0.4 * sin(t * 4.0)
		var msg := "TOCÁ LA PANTALLA PARA REINTENTAR" if game.touch_mode else "CLICK / R PARA REINTENTAR"
		draw_string_outline(font, Vector2(0, vs.y * 0.5 + 40), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, 6, Color(0.02, 0.05, 0.1, pulse))
		draw_string(font, Vector2(0, vs.y * 0.5 + 40), msg, HORIZONTAL_ALIGNMENT_CENTER, vs.x, 22, Color(0.8, 1.0, 1.0, pulse))
