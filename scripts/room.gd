class_name Room
extends Node2D
## La sala: suelo, muros, props, luces y compuertas de aparicion.

const FLOOR := Rect2(-600, -320, 1200, 640)
const BULLET_H := 26.0

var game: Game
var rects: Array[Rect2] = []
var bullet_rects: Array = []
var props: Array[Prop] = []
var hatches: Array[Vector2] = [
	Vector2(-515, -245), Vector2(515, -235), Vector2(-515, 235), Vector2(515, 245), Vector2(-15, -252), Vector2(-10, 262),
]
var hatch_open: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0])
var hatch_target: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0])
var hatch_glow: PackedFloat32Array = PackedFloat32Array([0, 0, 0, 0, 0, 0])
var traces: Array[PackedVector2Array] = []
var lamps: Array[Vector2] = [Vector2(-400, -385), Vector2(0, -385), Vector2(400, -385)]
var screens: Array[Rect2] = [Rect2(-300, -405, 120, 52), Rect2(180, -405, 120, 52)]

var floor_node: Node2D
var light_node: Node2D
var hatch_node: Node2D
var deco_node: Node2D
var wall_node: Node2D
var t: float = 0.0


class Layer extends Node2D:
	var room: Room
	var mode: int = 0
	func _draw() -> void:
		match mode:
			0: room.paint_floor(self)
			1: room.paint_lights(self)
			2: room.paint_hatches(self)
			3: room.paint_deco(self)
			4: room.paint_walls(self)


func build(g: Game) -> void:
	game = g
	_make_layer(0, -30, false)
	_make_layer(1, -28, true)
	hatch_node = _make_layer(2, -26, false)
	deco_node = _make_layer(3, -24, true)
	wall_node = _make_layer(4, -29, false)
	# traces del suelo
	traces = [
		PackedVector2Array([Vector2(-600, -90), Vector2(-470, -90), Vector2(-470, -40), Vector2(-250, -40), Vector2(-250, -2), Vector2(-150, -2)]),
		PackedVector2Array([Vector2(600, 80), Vector2(450, 80), Vector2(450, 20), Vector2(260, 20), Vector2(260, 4), Vector2(150, 4)]),
		PackedVector2Array([Vector2(-100, -320), Vector2(-100, -230), Vector2(-60, -230), Vector2(-60, -120), Vector2(-4, -120), Vector2(-4, -80)]),
		PackedVector2Array([Vector2(160, 320), Vector2(160, 250), Vector2(110, 250), Vector2(110, 130), Vector2(8, 130), Vector2(8, 82)]),
		PackedVector2Array([Vector2(-600, 150), Vector2(-420, 150), Vector2(-420, 60), Vector2(-280, 60), Vector2(-280, 30), Vector2(-130, 30)]),
	]
	_spawn_props()
	_rebuild_rects()


func _make_layer(mode: int, z: int, additive: bool) -> Node2D:
	var l := Layer.new()
	l.room = self
	l.mode = mode
	l.z_index = z
	if additive:
		l.material = Gfx.add_material()
	add_child(l)
	return l


func _spawn_props() -> void:
	var defs := [
		["crate_l", Rect2(-420, -190, 100, 56)],
		["crate_s", Rect2(-310, -168, 44, 34)],
		["barrel", Rect2(-395, -120, 30, 22)],
		["tank", Rect2(330, -250, 64, 44)],
		["terminal", Rect2(110, -314, 84, 34)],
		["pillar", Rect2(-190, -110, 40, 34)],
		["pillar", Rect2(200, 110, 40, 34)],
		["barrier_h", Rect2(-140, 150, 170, 22)],
		["barrier_v", Rect2(340, -20, 22, 130)],
		["crate_s", Rect2(300, 232, 44, 34)],
		["crate_s", Rect2(348, 250, 44, 34)],
		["barrel", Rect2(268, 206, 30, 22)],
		["crate_s", Rect2(-300, 226, 44, 34)],
		["barrel", Rect2(-252, 246, 30, 22)],
	]
	for d in defs:
		var p := Prop.create(game, d[0], d[1])
		props.append(p)
		game.ysort.add_child(p)


func remove_prop(p: Prop) -> void:
	props.erase(p)
	p.queue_free()
	_rebuild_rects()


func _rebuild_rects() -> void:
	rects.clear()
	bullet_rects.clear()
	var walls: Array[Rect2] = [
		Rect2(-720, -520, 1440, 200),  # norte
		Rect2(-720, 320, 1440, 140),   # sur
		Rect2(-720, -520, 120, 1000),  # oeste
		Rect2(600, -520, 120, 1000),   # este
	]
	for w in walls:
		rects.append(w)
		bullet_rects.append([Rect2(w.position.x, w.position.y - BULLET_H, w.size.x, w.size.y), null])
	for p in props:
		rects.append(p.foot)
		bullet_rects.append([Rect2(p.foot.position.x, p.foot.position.y - BULLET_H, p.foot.size.x, p.foot.size.y), p])


## Linea de vision entre dos puntos del suelo (los props bajos tambien bloquean).
func los(a: Vector2, b: Vector2) -> bool:
	for r in rects:
		if Gfx.seg_rect(a, b, r) >= 0.0:
			return false
	return true


func free_point(p: Vector2, r: float) -> bool:
	if not FLOOR.grow(-r).has_point(p):
		return false
	for rc in rects:
		var rr: Rect2 = rc
		var cp := Vector2(clampf(p.x, rr.position.x, rr.end.x), clampf(p.y, rr.position.y, rr.end.y))
		if cp.distance_squared_to(p) < r * r:
			return false
	return true


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0)
	t += dt
	var changed := false
	for i in hatch_open.size():
		var o := hatch_open[i]
		var tg := hatch_target[i]
		if absf(o - tg) > 0.001:
			hatch_open[i] = move_toward(o, tg, dt * (3.5 if tg > o else 2.2))
			changed = true
		hatch_glow[i] = move_toward(hatch_glow[i], tg, dt * 4.0)
	if changed:
		hatch_node.queue_redraw()
	deco_node.queue_redraw()
	light_node = null


func open_hatch(i: int, open: bool) -> void:
	hatch_target[i] = 1.0 if open else 0.0


# =====================================================================
#  SUELO
# =====================================================================
func paint_floor(ci: CanvasItem) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	var F := FLOOR
	ci.draw_rect(Rect2(-900, -700, 1800, 1500), Color("04060c"))
	ci.draw_rect(F, Color("0f1524"))
	var ts := 80.0
	var cols := int(F.size.x / ts)
	var rows := int(F.size.y / ts)
	for ix in cols:
		for iy in rows:
			var x := F.position.x + ix * ts
			var y := F.position.y + iy * ts
			var v := rng.randf()
			var base := Color("151c2e").lerp(Color("1a2236"), v)
			if (ix + iy) % 2 == 0:
				base = base.darkened(0.06)
			var r := Rect2(x + 1, y + 1, ts - 2, ts - 2)
			ci.draw_rect(r, base)
			# bisel
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + ts - 2, y + 2), Color(1, 1, 1, 0.07), 2.0)
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + 2, y + ts - 2), Color(1, 1, 1, 0.04), 2.0)
			ci.draw_line(Vector2(x + 2, y + ts - 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.35), 2.0)
			ci.draw_line(Vector2(x + ts - 2, y + 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.25), 2.0)
			# insercion interior
			var inn := Rect2(x + 10, y + 10, ts - 20, ts - 20)
			ci.draw_rect(inn, Color(0, 0, 0, 0.12), false, 1.5)
			# remaches
			for c in [Vector2(x + 6, y + 6), Vector2(x + ts - 6, y + 6), Vector2(x + 6, y + ts - 6), Vector2(x + ts - 6, y + ts - 6)]:
				ci.draw_circle(c, 1.7, Color("0a0f1b"))
				ci.draw_circle(c + Vector2(-0.4, -0.4), 1.0, Color("2a3550"))
			var k := rng.randf()
			if k < 0.12:
				# rejilla
				for g in 6:
					ci.draw_rect(Rect2(x + 18, y + 18 + g * 7.0, ts - 36, 3.0), Color("070a12"))
					ci.draw_rect(Rect2(x + 18, y + 21 + g * 7.0, ts - 36, 1.0), Color(1, 1, 1, 0.05))
			elif k < 0.2:
				# grieta
				var p0 := Vector2(x + rng.randf_range(10, 40), y + rng.randf_range(10, 40))
				var pts := PackedVector2Array([p0])
				for s in 4:
					p0 += Vector2(rng.randf_range(-16, 16), rng.randf_range(4, 18))
					pts.append(p0)
				ci.draw_polyline(pts, Color(0.02, 0.03, 0.06, 0.8), 1.6, true)
			elif k < 0.27:
				# marca de calor
				Gfx.draw_glow(ci, Vector2(x + 40, y + 40), 34.0, Color(0, 0, 0, 0.35))
	# trazas de circuito
	for tr in traces:
		ci.draw_polyline(tr, Color("070b15"), 7.0, true)
		ci.draw_polyline(tr, Color(0.18, 0.7, 0.68, 0.32), 1.8, true)
		for p in [tr[0], tr[tr.size() - 1]]:
			ci.draw_rect(Rect2(p.x - 5, p.y - 5, 10, 10), Color("070b15"))
		var e := tr[tr.size() - 1]
		ci.draw_circle(e, 3.5, Color(0.2, 0.9, 0.85, 0.5))
		for i in range(1, tr.size() - 1):
			ci.draw_circle(tr[i], 2.4, Color("0a0f1b"))
			ci.draw_circle(tr[i], 1.4, Color(0.2, 0.8, 0.75, 0.4))
	# emblema central
	var C := Vector2(0, 0)
	ci.draw_arc(C, 172.0, 0, TAU, 72, Color("070b15"), 7.0, true)
	ci.draw_arc(C, 172.0, 0, TAU, 72, Color(0.2, 0.75, 0.72, 0.25), 1.6, true)
	for k in 24:
		var a := TAU * float(k) / 24.0
		ci.draw_line(C + Vector2.from_angle(a) * 160.0, C + Vector2.from_angle(a) * (150.0 if k % 2 == 0 else 154.0), Color(0.25, 0.8, 0.78, 0.28), 2.0)
	var hex := Gfx.ell_pts(C, 112.0, 112.0, 6, PI / 6.0)
	Gfx.outline(ci, hex, Color("070b15"), 8.0)
	Gfx.outline(ci, hex, Color(0.22, 0.75, 0.72, 0.3), 2.0)
	var hex2 := Gfx.ell_pts(C, 66.0, 66.0, 6, PI / 6.0)
	ci.draw_colored_polygon(hex2, Color(0.03, 0.05, 0.1, 0.55))
	Gfx.outline(ci, hex2, Color(0.25, 0.85, 0.8, 0.35), 2.0)
	for k in 4:
		var a := PI * 0.5 * float(k) + PI * 0.25
		var d := Vector2.from_angle(a)
		var pp := C + d * 136.0
		var n := Vector2(-d.y, d.x)
		ci.draw_colored_polygon(PackedVector2Array([pp + d * 9.0, pp - d * 5.0 + n * 9.0, pp - d * 1.0, pp - d * 5.0 - n * 9.0]), Color(0.9, 0.62, 0.2, 0.55))
	# lineas de pasillo (pintura desgastada)
	var lane := Rect2(F.position + Vector2(46, 46), F.size - Vector2(92, 92))
	for side in 4:
		var a: Vector2
		var b: Vector2
		match side:
			0:
				a = lane.position
				b = Vector2(lane.end.x, lane.position.y)
			1:
				a = Vector2(lane.end.x, lane.position.y)
				b = lane.end
			2:
				a = lane.end
				b = Vector2(lane.position.x, lane.end.y)
			_:
				a = Vector2(lane.position.x, lane.end.y)
				b = lane.position
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var s := 0.0
		while s < len:
			var l := rng.randf_range(24.0, 60.0)
			if rng.randf() < 0.8:
				ci.draw_line(a + dir * s, a + dir * minf(s + l, len), Color(0.85, 0.6, 0.2, 0.2), 4.0)
			s += l + rng.randf_range(10.0, 26.0)
	# manchas, rejillas de desague y cables
	for i in 9:
		var p := Vector2(rng.randf_range(-520, 520), rng.randf_range(-250, 250))
		Gfx.draw_glow(ci, p, rng.randf_range(24, 52), Color(0, 0, 0, 0.28))
	var cables := [
		[Vector2(-600, 200), Vector2(-540, 215), Vector2(-470, 190), Vector2(-420, 215)],
		[Vector2(600, -150), Vector2(540, -135), Vector2(480, -160), Vector2(430, -140), Vector2(400, -150)],
		[Vector2(200, -300), Vector2(215, -250), Vector2(190, -210), Vector2(225, -170)],
		[Vector2(-100, 320), Vector2(-90, 290), Vector2(-120, 265), Vector2(-90, 240)],
	]
	for cb in cables:
		var pts := PackedVector2Array()
		for i in cb.size() - 1:
			for s in 8:
				pts.append(cb[i].lerp(cb[i + 1], float(s) / 8.0))
		pts.append(cb[cb.size() - 1])
		ci.draw_polyline(pts, Color("04060b"), 7.0, true)
		ci.draw_polyline(pts, Color("1c2438"), 4.5, true)
		ci.draw_polyline(pts, Color(1, 1, 1, 0.07), 1.5, true)
	for i in 26:
		var p := Vector2(rng.randf_range(-560, 560), rng.randf_range(-290, 290))
		var s := rng.randf_range(1.5, 3.0)
		ci.draw_rect(Rect2(p, Vector2(s * 1.4, s)), Color(0.35, 0.4, 0.5, 0.5))
		ci.draw_rect(Rect2(p + Vector2(0, s), Vector2(s * 1.4, 1.0)), Color(0, 0, 0, 0.5))
	# sombra ambiental junto a los muros
	for i in 10:
		var a := 0.5 * (1.0 - float(i) / 10.0)
		var o := float(i) * 4.0
		ci.draw_rect(Rect2(F.position.x, F.position.y + o, F.size.x, 4.0), Color(0, 0, 0, a))
		ci.draw_rect(Rect2(F.position.x, F.end.y - o - 4.0, F.size.x, 4.0), Color(0, 0, 0, a * 0.8))
		ci.draw_rect(Rect2(F.position.x + o, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))
		ci.draw_rect(Rect2(F.end.x - o - 4.0, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))


# =====================================================================
#  MUROS
# =====================================================================
func paint_walls(ci: CanvasItem) -> void:
	var ink := Gfx.INK
	var F := FLOOR
	# --- muro norte: cara frontal
	var face := Rect2(-650, -430, 1300, 110)
	ci.draw_rect(Rect2(-720, -520, 1440, 100), Color("0a0e18"))
	Gfx.gpoly(ci, PackedVector2Array([face.position, Vector2(face.end.x, face.position.y), face.end, Vector2(face.position.x, face.end.y)]), Color("27314a"), Color("141a2b"), Color(0, 0, 0, 0), 0.0)
	# paneles
	var px := -650.0
	while px < 650.0:
		var w := 130.0
		ci.draw_rect(Rect2(px + 2, -428, w - 4, 106), Color(1, 1, 1, 0.025))
		ci.draw_line(Vector2(px, -430), Vector2(px, -322), Color("0b0f1a"), 3.0)
		ci.draw_line(Vector2(px + 2, -430), Vector2(px + 2, -322), Color(1, 1, 1, 0.07), 1.5)
		for c in [Vector2(px + 10, -420), Vector2(px + w - 10, -420), Vector2(px + 10, -334), Vector2(px + w - 10, -334)]:
			ci.draw_circle(c, 2.0, Color("0b0f1a"))
			ci.draw_circle(c + Vector2(-0.5, -0.5), 1.2, Color("56648a"))
		px += w
	# tuberia horizontal
	ci.draw_rect(Rect2(-650, -388, 1300, 12), ink)
	Gfx.grrect(ci, Rect2(-650, -387, 1300, 10), 0.0, Color("5a6890"), Color("273050"), Color(0, 0, 0, 0), 0.0)
	ci.draw_rect(Rect2(-650, -386, 1300, 2), Color(1, 1, 1, 0.2))
	px = -650.0
	while px < 650.0:
		ci.draw_rect(Rect2(px - 5, -391, 10, 18), ink)
		ci.draw_rect(Rect2(px - 4, -390, 8, 16), Color("3a4670"))
		px += 130.0
	# zocalo con franja de peligro
	ci.draw_rect(Rect2(-650, -336, 1300, 16), Color("0b0f1a"))
	var hx := -650.0
	while hx < 650.0:
		var hz := Rect2(hx, -334, 12, 12)
		if int(hx / 12.0) % 2 == 0 and (absf(hx) > 240.0 or true):
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, -322), Vector2(hx + 8, -334), Vector2(hx + 14, -334), Vector2(hx + 6, -322)]), Color("c98a22"))
		hx += 12.0
	ci.draw_rect(Rect2(-650, -337, 1300, 2), Color(1, 1, 1, 0.15))
	# cornisa superior
	var cap := Rect2(-650, -462, 1300, 34)
	Gfx.grrect(ci, cap, 0.0, Color("46557a"), Color("2b3654"), Color(0, 0, 0, 0), 0.0)
	ci.draw_rect(Rect2(-650, -462, 1300, 3), Color(1, 1, 1, 0.22))
	ci.draw_rect(Rect2(-650, -430, 1300, 3), Color("0b0f1a"))
	px = -650.0
	while px < 650.0:
		ci.draw_line(Vector2(px, -462), Vector2(px, -430), Color("1a2238"), 2.0)
		px += 130.0
	# pantallas
	for s in screens:
		Gfx.rrect(ci, s.grow(5), 4.0, Color("1a2036"), ink, 2.5)
		Gfx.rrect(ci, s, 2.0, Color("06151c"), ink, 1.5)
	# emblema central del muro
	var ec := Vector2(0, -378)
	var hexp := Gfx.ell_pts(ec, 26.0, 26.0, 6, PI / 6.0)
	ci.draw_colored_polygon(hexp, Color("0c1322"))
	Gfx.outline(ci, hexp, ink, 3.0)
	Gfx.outline(ci, hexp, Color(0.25, 0.85, 0.8, 0.8), 1.5)
	# rejillas de ventilacion
	for vx in [-560.0, 520.0]:
		Gfx.rrect(ci, Rect2(vx - 6, -418, 52, 40), 3.0, Color("0b0f1a"), ink, 2.0)
		for k in 6:
			ci.draw_rect(Rect2(vx, -412 + k * 6.0, 40, 3.0), Color("2b3654"))
	# lamparas en la cornisa
	for l in lamps:
		Gfx.rrect(ci, Rect2(l.x - 18, -430, 36, 14), 4.0, Color("1a2236"), ink, 2.0)
		Gfx.rrect(ci, Rect2(l.x - 14, -427, 28, 7), 3.0, Color("d6f6ff"), Color(0, 0, 0, 0), 0.0)
	# cables colgantes
	for cx in [-470.0, 90.0, 470.0]:
		var pts := PackedVector2Array([Vector2(cx, -428), Vector2(cx + 6, -400), Vector2(cx - 4, -370), Vector2(cx + 8, -345)])
		ci.draw_polyline(pts, ink, 6.0, true)
		ci.draw_polyline(pts, Color("2a3452"), 3.5, true)
	# --- muros laterales (vistos de canto) + sur
	for side in [-1, 1]:
		var x0: float = -650.0 if side < 0 else 600.0
		var wall := Rect2(x0, -462, 50, 800)
		Gfx.grrect(ci, wall, 0.0, Color("2f3a5a"), Color("1c2438"), Color(0, 0, 0, 0), 0.0)
		var inner_x: float = 600.0 if side < 0 else 600.0
		var edge_x: float = -604.0 if side < 0 else 600.0
		ci.draw_rect(Rect2(edge_x, -430, 4, 760), Color("0b0f1a"))
		ci.draw_rect(Rect2(edge_x + (0.0 if side < 0 else 4.0), -430, 2, 760), Color(1, 1, 1, 0.15))
		var yy := -430.0
		while yy < 320.0:
			ci.draw_line(Vector2(x0, yy), Vector2(x0 + 50, yy), Color("0b0f1a"), 2.0)
			ci.draw_circle(Vector2(x0 + 12, yy + 12), 2.0, Color("56648a"))
			ci.draw_circle(Vector2(x0 + 38, yy + 12), 2.0, Color("56648a"))
			yy += 110.0
		# conducto vertical
		var cdx := x0 + (30.0 if side < 0 else 10.0)
		ci.draw_rect(Rect2(cdx - 1, -430, 12, 760), ink)
		Gfx.grrect(ci, Rect2(cdx, -430, 10, 760), 0.0, Color("5a6890"), Color("2a3352"), Color(0, 0, 0, 0), 0.0)
	var south := Rect2(-650, 320, 1300, 140)
	Gfx.grrect(ci, south, 0.0, Color("3a4668"), Color("1d2540"), Color(0, 0, 0, 0), 0.0)
	ci.draw_rect(Rect2(-650, 320, 1300, 4), Color("0b0f1a"))
	ci.draw_rect(Rect2(-650, 324, 1300, 2), Color(1, 1, 1, 0.18))
	var sx := -650.0
	while sx < 650.0:
		ci.draw_line(Vector2(sx, 324), Vector2(sx, 460), Color("0b0f1a"), 2.0)
		ci.draw_rect(Rect2(sx + 40, 334, 50, 6), Color("e9a72c", 0.6))
		sx += 130.0
	# esquinas
	for cx in [-650.0, 600.0]:
		ci.draw_rect(Rect2(cx, -462, 50, 34), Color("56648e"))
		ci.draw_rect(Rect2(cx, -462, 50, 3), Color(1, 1, 1, 0.25))


# =====================================================================
#  LUCES ESTATICAS (aditivas)
# =====================================================================
func paint_lights(ci: CanvasItem) -> void:
	# conos de luz de las lamparas
	for l in lamps:
		var top_w := 26.0
		var bot_w := 190.0
		var y0 := -318.0
		var y1 := -90.0
		var pts := PackedVector2Array([Vector2(l.x - top_w, y0), Vector2(l.x + top_w, y0), Vector2(l.x + bot_w, y1), Vector2(l.x - bot_w, y1)])
		var cols := PackedColorArray([Color(0.55, 0.85, 1.0, 0.16), Color(0.55, 0.85, 1.0, 0.16), Color(0.55, 0.85, 1.0, 0.0), Color(0.55, 0.85, 1.0, 0.0)])
		ci.draw_polygon(pts, cols)
		Gfx.draw_glow(ci, Vector2(l.x, -300), 130.0, Color(0.5, 0.85, 1.0, 0.18))
	# pozo de luz del tanque, centro, barriles
	Gfx.draw_glow(ci, Vector2(362, -210), 150.0, Color(0.15, 0.9, 0.75, 0.16))
	Gfx.draw_glow(ci, Vector2(0, 0), 260.0, Color(0.2, 0.7, 0.9, 0.06))
	Gfx.draw_glow(ci, Vector2(150, -290), 110.0, Color(0.2, 0.9, 0.8, 0.12))
	Gfx.draw_glow(ci, Vector2(-380, -110), 90.0, Color(1.0, 0.65, 0.2, 0.08))
	Gfx.draw_glow(ci, Vector2(283, 218), 90.0, Color(1.0, 0.65, 0.2, 0.08))
	Gfx.draw_glow(ci, Vector2(-237, 258), 90.0, Color(1.0, 0.65, 0.2, 0.08))


func paint_hatches(ci: CanvasItem) -> void:
	var ink := Gfx.INK
	for i in hatches.size():
		var c := hatches[i]
		var o := hatch_open[i]
		var base := Rect2(c.x - 44, c.y - 30, 88, 60)
		Gfx.rrect(ci, base.grow(7), 9.0, Color("0b0f1a"), ink, 2.0)
		# marco con franjas de peligro
		var frame := base.grow(5)
		Gfx.outline(ci, Gfx.rr_pts(frame, 8.0), Color("b9791f"), 3.0)
		Gfx.rrect(ci, base, 6.0, Color("05070d"), ink, 2.0)
		if o > 0.0:
			Gfx.rrect(ci, base.grow(-4), 4.0, Color(0.16, 0.04, 0.26).lerp(Color(0.4, 0.14, 0.62), o), Color(0, 0, 0, 0), 0.0)
		var slide := o * 36.0
		var lid_l := Rect2(c.x - 44 - slide, c.y - 30, 44, 60)
		var lid_r := Rect2(c.x + slide, c.y - 30, 44, 60)
		Gfx.grrect(ci, lid_l, 5.0, Color("56648a"), Color("2a3354"), ink, 2.0)
		Gfx.grrect(ci, lid_r, 5.0, Color("56648a"), Color("2a3354"), ink, 2.0)
		for side in 2:
			var lid := lid_l if side == 0 else lid_r
			var dir := -1.0 if side == 0 else 1.0
			var mx := lid.get_center().x
			for k in 2:
				var yy := c.y - 8.0 + k * 16.0
				var x0 := mx - dir * 6.0
				ci.draw_polyline(PackedVector2Array([Vector2(x0, yy - 6), Vector2(x0 + dir * 10, yy), Vector2(x0, yy + 6)]), Color("e0a02e", 0.85), 3.0, true)
			ci.draw_line(Vector2(lid.position.x + 4, lid.position.y + 4), Vector2(lid.end.x - 4, lid.position.y + 4), Color(1, 1, 1, 0.14), 1.5)
		# costura central
		if o < 0.05:
			ci.draw_line(Vector2(c.x, c.y - 28), Vector2(c.x, c.y + 28), Color(0.5, 0.25, 0.9, 0.6), 2.0)


# =====================================================================
#  DECORADO DINAMICO (aditivo)
# =====================================================================
func paint_deco(ci: CanvasItem) -> void:
	# pulsos por las trazas
	for i in traces.size():
		var tr: PackedVector2Array = traces[i]
		var total := 0.0
		for k in tr.size() - 1:
			total += tr[k].distance_to(tr[k + 1])
		var d := fposmod(t * 90.0 + float(i) * 130.0, total + 120.0)
		for q in 5:
			var dd := d - q * 9.0
			if dd < 0.0 or dd > total:
				continue
			var acc := 0.0
			for k in tr.size() - 1:
				var seg := tr[k].distance_to(tr[k + 1])
				if dd <= acc + seg:
					var p := tr[k].lerp(tr[k + 1], (dd - acc) / seg)
					Gfx.draw_glow(ci, p, 9.0 - q, Color(0.3, 1.0, 0.9, 0.5 - q * 0.08))
					break
				acc += seg
	# emblema pulsante
	var pulse := 0.5 + 0.5 * sin(t * 1.6)
	ci.draw_arc(Vector2.ZERO, 172.0, 0, TAU, 72, Color(0.2, 0.9, 0.85, 0.08 + 0.1 * pulse), 2.5, true)
	var hex := Gfx.ell_pts(Vector2.ZERO, 66.0, 66.0, 6, PI / 6.0)
	Gfx.outline(ci, hex, Color(0.3, 1.0, 0.9, 0.12 + 0.18 * pulse), 3.0)
	Gfx.draw_glow(ci, Vector2.ZERO, 70.0, Color(0.2, 0.9, 0.85, 0.05 + 0.05 * pulse))
	# pantallas del muro
	for si in screens.size():
		var s := screens[si]
		var flick := 0.85 + 0.15 * sin(t * 23.0 + si * 3.0)
		ci.draw_rect(s, Color(0.1, 0.55, 0.55, 0.22 * flick))
		for k in 6:
			var w := 18.0 + fposmod(float(k * 41 + si * 17) + sin(t * 0.7 + k) * 20.0, 64.0)
			var y := s.position.y + 7.0 + k * 7.0
			ci.draw_line(Vector2(s.position.x + 8, y), Vector2(s.position.x + 8 + minf(w, s.size.x - 16.0), y), Color(0.3, 1.0, 0.9, 0.7 * flick), 2.0)
		# barrido
		var sy := s.position.y + fposmod(t * 22.0 + si * 9.0, s.size.y)
		ci.draw_line(Vector2(s.position.x, sy), Vector2(s.end.x, sy), Color(0.6, 1.0, 1.0, 0.3), 2.0)
		Gfx.draw_glow(ci, s.get_center() + Vector2(0, 40), 90.0, Color(0.2, 0.9, 0.85, 0.08 * flick))
	# emblema de pared
	var wp := 0.6 + 0.4 * sin(t * 2.2)
	Gfx.draw_glow(ci, Vector2(0, -378), 40.0, Color(0.3, 1.0, 0.9, 0.18 * wp))
	# lamparas
	for l in lamps:
		Gfx.draw_glow(ci, Vector2(l.x, -420), 40.0, Color(0.7, 0.92, 1.0, 0.45))
	# compuertas
	for i in hatches.size():
		var g := hatch_glow[i]
		if g > 0.01:
			var c := hatches[i]
			var f := 0.7 + 0.3 * sin(t * 18.0 + i)
			Gfx.draw_glow(ci, c, 120.0 * g, Color(0.7, 0.3, 1.0, 0.45 * g * f))
			Gfx.draw_glow(ci, c, 60.0 * g, Color(0.9, 0.7, 1.0, 0.35 * g))
		else:
			ci.draw_rect(Rect2(hatches[i].x - 3, hatches[i].y - 3, 6, 6), Color(0.4, 0.2, 0.7, 0.35 + 0.2 * sin(t * 2.0 + i)))
