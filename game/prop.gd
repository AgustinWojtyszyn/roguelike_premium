class_name Prop
extends Node2D
## Objetos de escenografia con colision (cajas, barriles, tanque, pilares...).

var game: Game
var kind: String = ""
var foot := Rect2()          # huella en coordenadas de mundo
var h: float = 40.0
var hp: float = 0.0
var destructible := false
var pop: float = 0.0
var fade: float = 1.0
var tt: float = 0.0
var seed_v: int = 0
var redraw_t: float = 0.0
var style: String = ""
## Sin animacion propia: solo se redibujan al recibir un golpe. Los demas, a 4-8 Hz.
const STATIC_KINDS := ["crate_l", "crate_s", "barrel", "barrier_h", "barrier_v", "pillar", "stone_block", "urn", "wood_crate", "wood_barrel", "column", "statue", "table", "weapon_rack", "crate_m"]
const FAST_KINDS := ["tank", "terminal", "reactor", "brazier", "totem", "glyph_pillar", "crystal", "rift_stone", "orb_pillar", "anomaly_box"]


static func create(g: Game, k: String, foot_rect: Rect2, st: String = "") -> Prop:
	var p := Prop.new()
	p.game = g
	p.kind = k
	p.style = st
	if PropArt.STATS.has(k):
		p.h = float(PropArt.STATS[k]["h"])
		p.hp = float(PropArt.STATS[k]["hp"])
		p.destructible = p.hp > 0.0
	p.foot = foot_rect
	p.position = Vector2(foot_rect.position.x + foot_rect.size.x * 0.5, foot_rect.end.y)
	p.seed_v = randi()
	match k:
		"crate_l":
			p.h = 54.0
		"crate_s":
			p.h = 34.0
			p.hp = 7.0
			p.destructible = true
		"barrel":
			p.h = 40.0
			p.hp = 6.0
			p.destructible = true
		"tank":
			p.h = 78.0
		"terminal":
			p.h = 46.0
		"pillar":
			p.h = 78.0
		"barrier_h":
			p.h = 26.0
		"barrier_v":
			p.h = 26.0
	return p


func hit(dmg: float, at: Vector2) -> void:
	pop = 1.0
	if not destructible:
		return
	hp -= dmg
	if hp <= 0.0:
		_break()


func _break() -> void:
	var fx := game.fx
	var c := position + Vector2(0, -h * 0.4)
	var col := Color("4a5572") if kind == "crate_s" else Color("5a4a66")
	var bp := PropArt.break_palette(kind)
	if not bp.is_empty():
		col = bp[0]
	for i in 11:
		fx.shard(c + Vector2(randf_range(-10, 10), randf_range(-6, 6)), Vector2.from_angle(randf() * TAU) * randf_range(60, 190), randf_range(80, 220), col.lerp(Color.WHITE, randf() * 0.25), randf_range(2.5, 5.5))
	var spark_col := Color("ffb23d") if kind == "barrel" else Color("8fe8ff")
	if not bp.is_empty():
		spark_col = bp[1]
	fx.burst(c, 14, 260.0, spark_col, 0.4)
	fx.puff(c, Vector2.ZERO, 26.0, Color(0.6, 0.65, 0.78, 0.5), 0.6, 2.0)
	fx.flash(c, 50.0, Color(spark_col, 0.7), 0.14)
	game.on_prop_broken(self)
	fx.add_decal(position + Vector2(0, -6), 0, 26.0, Color.BLACK)
	game.sfx.play("break", -3.0)
	game.shake(0.18)
	game.room.remove_prop(self)


func _process(delta: float) -> void:
	Prof.begin("prop_proc")
	__process_impl(delta)
	Prof.end("prop_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	tt += dt
	pop = maxf(0.0, pop - dt * 6.0)
	scale = Vector2(1.0 + pop * 0.02, 1.0 - pop * 0.03)
	# transparencia cuando alguien queda detras
	var behind := false
	var pl := game.player
	if pl != null:
		var area := Rect2(foot.position.x - 14, foot.end.y - h - 24, foot.size.x + 28, h + 24)
		if pl.position.y < foot.end.y - 2.0 and area.has_point(pl.position):
			behind = true
		for e in game.enemies:
			if e.position.y < foot.end.y - 2.0 and area.has_point(e.position):
				behind = true
	var target := 0.5 if behind else 1.0
	fade = lerpf(fade, target, clampf(dt * 10.0, 0.0, 1.0))
	modulate.a = fade
	redraw_t -= dt
	if pop > 0.0 or (redraw_t <= 0.0 and not STATIC_KINDS.has(kind)):
		redraw_t = 0.12 if FAST_KINDS.has(kind) else 0.25
		queue_redraw()


func _draw() -> void:
	Prof.begin("prop_draw")
	__draw_impl()
	Prof.end("prop_draw")


func __draw_impl() -> void:
	var f := Rect2(foot.position - position, foot.size)
	match kind:
		"crate_l":
			_crate(f, h, Color("46526f"), true)
		"crate_s":
			_crate(f, h, Color("3d4965"), false)
		"barrel":
			_barrel(f)
		"tank":
			if not PropArt._imported(self, kind, f):
				_tank(f)
		"terminal":
			if not PropArt._imported(self, kind, f):
				_terminal(f)
		"pillar":
			_pillar(f)
		"barrier_h":
			_barrier(f, true)
		"barrier_v":
			_barrier(f, false)
		_:
			PropArt.paint(self, kind, f)


func _shadow(f: Rect2, spread: float = 10.0) -> void:
	var c := Vector2(f.position.x + f.size.x * 0.5 + 6.0, f.end.y - f.size.y * 0.2)
	Gfx.draw_glow(self, c, maxf(f.size.x, f.size.y) * 0.8 + spread, Color(0, 0, 0, 0.5))


func _box(f: Rect2, hh: float, top_a: Color, top_b: Color, front_a: Color, front_b: Color) -> void:
	var ink := Gfx.INK
	var top := Rect2(f.position.x, f.position.y - hh, f.size.x, f.size.y)
	var front := Rect2(f.position.x, f.end.y - hh, f.size.x, hh)
	Gfx.grrect(self, front, 2.0, front_a, front_b, ink, 2.0)
	Gfx.grrect(self, top, 3.0, top_a, top_b, ink, 2.0)
	# bisel superior
	draw_line(top.position + Vector2(3, 2), Vector2(top.end.x - 3, top.position.y + 2), Color(1, 1, 1, 0.16), 1.5)
	draw_line(front.position + Vector2(2, 1), front.position + Vector2(2, front.size.y - 2), Color(1, 1, 1, 0.07), 1.5)


func _crate(f: Rect2, hh: float, base: Color, large: bool) -> void:
	_shadow(f)
	var ink := Gfx.INK
	_box(f, hh, base.lightened(0.2), base, base.darkened(0.15), base.darkened(0.45))
	var top := Rect2(f.position.x, f.position.y - hh, f.size.x, f.size.y)
	var front := Rect2(f.position.x, f.end.y - hh, f.size.x, hh)
	# marco en la tapa
	Gfx.rrect(self, top.grow(-6), 2.0, Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.45), 1.5)
	draw_line(top.position + Vector2(8, 8), top.end - Vector2(8, 8), Color(0, 0, 0, 0.3), 1.5)
	draw_line(Vector2(top.end.x - 8, top.position.y + 8), Vector2(top.position.x + 8, top.end.y - 8), Color(0, 0, 0, 0.3), 1.5)
	# franja de advertencia en el frente
	var sy := front.position.y + front.size.y * 0.55
	var sh := front.size.y * 0.22
	draw_rect(Rect2(front.position.x + 3, sy, front.size.x - 6, sh), Color("1a1d29"))
	var n := int((front.size.x - 6) / 12.0)
	for i in n:
		var x := front.position.x + 3 + i * 12.0
		var pts := PackedVector2Array([Vector2(x, sy), Vector2(x + 6, sy), Vector2(x + 2, sy + sh), Vector2(x - 4, sy + sh)])
		for k in pts.size():
			pts[k].x = clampf(pts[k].x, front.position.x + 3, front.end.x - 3)
		draw_colored_polygon(pts, Color("e9a72c"))
	# esquineros
	for cx in [front.position.x, front.end.x - 7.0]:
		draw_rect(Rect2(cx, front.position.y, 7, front.size.y), Color("232b40"))
		draw_rect(Rect2(cx + 1, front.position.y + 2, 2, front.size.y - 4), Color(1, 1, 1, 0.1))
	# LED + remaches
	var led := Color("3df2dc") if (int(tt * 1.2 + float(seed_v % 7)) % 2 == 0) else Color("1a6e66")
	draw_circle(Vector2(front.end.x - 14, front.position.y + 9), 2.4, ink)
	draw_circle(Vector2(front.end.x - 14, front.position.y + 9), 1.7, led)
	if large:
		# etiqueta
		draw_rect(Rect2(front.position.x + 14, front.position.y + 7, 26, 9), Color("c8d2e6"))
		for i in 4:
			draw_line(Vector2(front.position.x + 17 + i * 5, front.position.y + 9), Vector2(front.position.x + 17 + i * 5, front.position.y + 14), Color("1a1d29"), 1.4)


func _barrel(f: Rect2) -> void:
	_shadow(f, 4.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5 + 1.0
	var ry := f.size.y * 0.5
	# cuerpo
	var body := Rect2(cx - rx, base - h, rx * 2.0, h)
	Gfx.grrect(self, body, 3.0, Color("6a5a7c"), Color("2c2438"), ink, 2.0)
	draw_circle(Vector2.ZERO, 0.0, Color.WHITE)
	Gfx.ell(self, Vector2(cx, base), rx, ry, Color("2c2438"), ink, 2.0)
	# aros
	for yy in [base - h * 0.78, base - h * 0.2]:
		draw_rect(Rect2(cx - rx, yy, rx * 2.0, 4.0), Color("1e1828"))
		draw_rect(Rect2(cx - rx, yy, rx * 2.0, 1.5), Color(1, 1, 1, 0.14))
	# simbolo de peligro (luminoso)
	var sy := base - h * 0.55
	var tri := PackedVector2Array([Vector2(cx, sy - 7), Vector2(cx + 7, sy + 5), Vector2(cx - 7, sy + 5)])
	Gfx.poly(self, tri, Color("e9a72c"), ink, 1.5)
	draw_rect(Rect2(cx - 0.8, sy - 3, 1.6, 4.5), ink)
	# tapa
	Gfx.gell(self, Vector2(cx, base - h), rx, ry, Color("8a7a9c"), Color("4a3d5c"), ink, 2.0)
	Gfx.ell(self, Vector2(cx, base - h), rx * 0.5, ry * 0.5, Color("2c2438"), Color(0, 0, 0, 0), 0.0)
	draw_line(Vector2(cx - rx + 4, base - h - 1), Vector2(cx - 4, base - h - ry * 0.6), Color(1, 1, 1, 0.3), 1.4)


func _tank(f: Rect2) -> void:
	_shadow(f, 16.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5
	var ry := f.size.y * 0.5
	var body := Rect2(cx - rx, base - h, rx * 2.0, h)
	Gfx.gell(self, Vector2(cx, base), rx, ry, Color("2d3652"), Color("1a2036"), ink, 2.0)
	Gfx.grrect(self, body, 4.0, Color("5c6a92"), Color("2a3354"), ink, 2.0)
	# cristal con liquido
	var win := Rect2(cx - rx + 8, base - h + 12, rx * 2.0 - 16, h - 26)
	Gfx.rrect(self, win, 8.0, Color("08141f"), ink, 2.0)
	var lv := 0.78
	var liq := Rect2(win.position.x + 2, win.position.y + win.size.y * (1.0 - lv), win.size.x - 4, win.size.y * lv - 2)
	Gfx.grrect(self, liq, 6.0, Color("2fe9c0"), Color("0e7f78"), Color(0, 0, 0, 0), 0.0)
	for i in 5:
		var bx := liq.position.x + 5.0 + fposmod(float(i) * 11.7 + float(seed_v % 5), liq.size.x - 10.0)
		var by := liq.end.y - fposmod(tt * (14.0 + float(i) * 4.0) + float(i) * 17.0, liq.size.y - 6.0) - 3.0
		draw_circle(Vector2(bx, by), 1.5 + float(i % 2) * 0.8, Color(0.85, 1.0, 0.95, 0.65))
	draw_line(win.position + Vector2(4, 6), win.position + Vector2(4, win.size.y - 8), Color(1, 1, 1, 0.3), 2.0)
	# bandas
	for yy in [base - h + 4.0, base - 8.0]:
		draw_rect(Rect2(cx - rx, yy, rx * 2.0, 5.0), Color("1a2036"))
		draw_rect(Rect2(cx - rx, yy, rx * 2.0, 1.5), Color(1, 1, 1, 0.16))
	# tapa y tuberias
	Gfx.gell(self, Vector2(cx, base - h), rx, ry, Color("8793b8"), Color("4b587e"), ink, 2.0)
	Gfx.ell(self, Vector2(cx, base - h), rx * 0.45, ry * 0.45, Color("232a45"), ink, 1.6)
	Gfx.rrect(self, Rect2(cx + rx - 10, base - h - 18, 8, 18), 2.0, Color("39446a"), ink, 1.8)
	Gfx.rrect(self, Rect2(cx - rx + 2, base - h - 12, 8, 12), 2.0, Color("39446a"), ink, 1.8)


func _terminal(f: Rect2) -> void:
	_shadow(f, 8.0)
	var ink := Gfx.INK
	_box(f, 22.0, Color("56648a"), Color("3a4666"), Color("2f3956"), Color("1a2036"))
	# pantalla inclinada sobre la caja
	var sx := f.position.x + 8
	var sw := f.size.x - 16
	var sy := f.position.y - 22.0
	var scr := PackedVector2Array([Vector2(sx, sy + 2), Vector2(sx + sw, sy + 2), Vector2(sx + sw - 4, sy - 24), Vector2(sx + 4, sy - 24)])
	Gfx.poly(self, scr, Color("2a3452"), ink, 2.0)
	var inner := PackedVector2Array([Vector2(sx + 4, sy - 1), Vector2(sx + sw - 4, sy - 1), Vector2(sx + sw - 7, sy - 21), Vector2(sx + 7, sy - 21)])
	Gfx.gpoly(self, inner, Color("0f3a40"), Color("07181f"), Color(0, 0, 0, 0), 0.0)
	for i in 5:
		var w := 8.0 + fposmod(float(i * 37 + seed_v % 11), 24.0)
		var yy := sy - 18.0 + i * 3.6
		draw_line(Vector2(sx + 9, yy), Vector2(sx + 9 + w, yy), Color("3df2dc", 0.8), 1.6)
	# teclas
	for i in 7:
		draw_rect(Rect2(f.position.x + 8 + i * ((f.size.x - 16) / 7.0), f.end.y - 15, (f.size.x - 16) / 7.0 - 2, 5), Color("151b2d"))
	draw_circle(Vector2(f.end.x - 8, f.end.y - 6), 2.0, Color("ff8a3d") if int(tt * 2.0) % 2 == 0 else Color("5a2f18"))


func _pillar(f: Rect2) -> void:
	_shadow(f, 14.0)
	var ink := Gfx.INK
	_box(f, h, Color("5d6b92"), Color("434f74"), Color("39446a"), Color("1a2036"))
	var front := Rect2(f.position.x, f.end.y - h, f.size.x, h)
	# nervaduras
	for i in 3:
		var yy := front.position.y + 10.0 + float(i) * (h - 20.0) / 2.0
		draw_rect(Rect2(front.position.x, yy, front.size.x, 5.0), Color("232b46"))
		draw_rect(Rect2(front.position.x, yy, front.size.x, 1.5), Color(1, 1, 1, 0.13))
	# tira de luz vertical
	var gx := front.position.x + front.size.x * 0.5
	draw_rect(Rect2(gx - 2.5, front.position.y + 6, 5, h - 14), Color("0b2a30"))
	draw_rect(Rect2(gx - 1.2, front.position.y + 8, 2.4, h - 18), Color("3df2dc"))
	# casquete
	var top := Rect2(f.position.x - 3, f.position.y - h - 3, f.size.x + 6, f.size.y + 6)
	Gfx.grrect(self, top, 4.0, Color("8795bb"), Color("56648e"), ink, 2.0)
	Gfx.ell(self, top.get_center(), 9.0, 7.0, Color("202845"), ink, 1.6)


func _barrier(f: Rect2, horizontal: bool) -> void:
	_shadow(f, 6.0)
	var ink := Gfx.INK
	_box(f, h, Color("6d7aa0"), Color("4c587e"), Color("3a4568"), Color("1c2339"))
	var front := Rect2(f.position.x, f.end.y - h, f.size.x, h)
	if horizontal:
		var n := int(f.size.x / 28.0)
		for i in n:
			var x := f.position.x + 6.0 + i * 28.0
			draw_rect(Rect2(x, front.position.y + 6, 3, h - 12), Color(0, 0, 0, 0.35))
		# chevrones
		var sy := front.position.y + h * 0.5 - 4.0
		for i in int(f.size.x / 14.0):
			var x := f.position.x + 4.0 + i * 14.0
			if x + 8 > f.end.x - 4:
				break
			draw_colored_polygon(PackedVector2Array([Vector2(x, sy), Vector2(x + 7, sy), Vector2(x + 11, sy + 8), Vector2(x + 4, sy + 8)]), Color("e9a72c") if i % 2 == 0 else Color("1a1d29"))
		draw_circle(Vector2(f.end.x - 8, front.position.y + 6), 2.0, Color("3df2dc"))
		draw_circle(Vector2(f.position.x + 8, front.position.y + 6), 2.0, Color("3df2dc"))
	else:
		var top := Rect2(f.position.x, f.position.y - h, f.size.x, f.size.y)
		var n := int(f.size.y / 22.0)
		for i in n:
			var y := top.position.y + 8.0 + i * 22.0
			draw_circle(Vector2(top.get_center().x, y), 2.4, Color("e9a72c"))
			draw_circle(Vector2(top.get_center().x, y), 1.0, Color("fff2c0"))
