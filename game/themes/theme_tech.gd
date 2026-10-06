class_name ThemeTech
extends RoomTheme
## Capitulo 1: estacion de tecnologia corrupta (la sala original de la vertical slice, generalizada).

func _init() -> void:
	id = "tech"
	accent = Color("27e0cc")
	void_col = Color("04060c")


func build_dressing(room: Room, rng: RandomNumberGenerator) -> Dictionary:
	var F := room.floor_rect
	var d: Dictionary = {}
	var cx := F.get_center().x
	var lamps: Array[Vector2] = []
	var n := maxi(2, int(round(F.size.x / 400.0)))
	for i in n:
		lamps.append(Vector2(cx + (float(i) - float(n - 1) * 0.5) * F.size.x / float(n), F.position.y + 25.0))
	d["lamps"] = lamps
	var screens: Array[Rect2] = []
	if F.size.x >= 900.0 and not bool(room.def.decor.get("no_screens", false)):
		screens.append(Rect2(cx - F.size.x * 0.25, F.position.y - 85.0, 120, 52))
		screens.append(Rect2(cx + F.size.x * 0.15, F.position.y - 85.0, 120, 52))
	d["screens"] = screens
	d["vents"] = [Vector2(F.position.x + 40.0, F.position.y - 98.0), Vector2(F.end.x - 80.0, F.position.y - 98.0)]
	d["drops"] = [cx - F.size.x * 0.39, cx + F.size.x * 0.075, cx + F.size.x * 0.39]
	d["wall_emblem"] = Vector2(cx, F.position.y - 58.0)
	return d


# ============================================================ SUELO
func paint_floor(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	ci.draw_rect(room.bounds.grow(900.0), void_col)
	var idx := 0
	for R in room.walk:
		_floor_panels(ci, R, 4242 + idx * 17)
		idx += 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242 + 999
	# trazas de circuito
	for tr in dec.get("traces", []):
		var pts: PackedVector2Array = tr
		ci.draw_polyline(pts, Color("070b15"), 7.0, true)
		ci.draw_polyline(pts, Color(0.18, 0.7, 0.68, 0.32), 1.8, true)
		for p in [pts[0], pts[pts.size() - 1]]:
			ci.draw_rect(Rect2(p.x - 5, p.y - 5, 10, 10), Color("070b15"))
		var e := pts[pts.size() - 1]
		ci.draw_circle(e, 3.5, Color(0.2, 0.9, 0.85, 0.5))
		for i in range(1, pts.size() - 1):
			ci.draw_circle(pts[i], 2.4, Color("0a0f1b"))
			ci.draw_circle(pts[i], 1.4, Color(0.2, 0.8, 0.75, 0.4))
	# emblema
	var emb: String = dec.get("emblem", "")
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if emb == "hex":
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
	elif emb == "core":
		# anillo de reactor: marcas concentricas
		for k in 3:
			var rr := 90.0 + k * 38.0
			ci.draw_arc(C, rr, 0, TAU, 64, Color("070b15"), 7.0, true)
			ci.draw_arc(C, rr, 0, TAU, 64, Color(0.2, 0.75, 0.72, 0.18 + 0.05 * k), 1.6, true)
		for k in 16:
			var a := TAU * float(k) / 16.0
			ci.draw_line(C + Vector2.from_angle(a) * 100.0, C + Vector2.from_angle(a) * 200.0, Color(0.9, 0.62, 0.2, 0.18), 2.0)
	# lineas de pasillo (pintura desgastada)
	if bool(dec.get("lane", false)):
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
	# franjas de peligro centrales (salas de tuberia / almacen)
	for stripe in dec.get("hazard", []):
		var sr: Rect2 = stripe
		var hx := sr.position.x
		while hx < sr.end.x:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, sr.end.y), Vector2(hx + 10, sr.position.y), Vector2(hx + 20, sr.position.y), Vector2(hx + 10, sr.end.y)]), Color(0.78, 0.54, 0.13, 0.28))
			hx += 20.0
	# manchas
	for i in int(dec.get("stains", 9)):
		var p := Vector2(rng.randf_range(F.position.x + 80, F.end.x - 80), rng.randf_range(F.position.y + 70, F.end.y - 70))
		Gfx.draw_glow(ci, p, rng.randf_range(24, 52), Color(0, 0, 0, 0.28))
	for cb in dec.get("cables", []):
		var arr: Array = cb
		var pts := PackedVector2Array()
		for i in arr.size() - 1:
			for s in 8:
				pts.append((arr[i] as Vector2).lerp(arr[i + 1], float(s) / 8.0))
		pts.append(arr[arr.size() - 1])
		ci.draw_polyline(pts, Color("04060b"), 7.0, true)
		ci.draw_polyline(pts, Color("1c2438"), 4.5, true)
		ci.draw_polyline(pts, Color(1, 1, 1, 0.07), 1.5, true)
	for i in int(dec.get("litter", 26)):
		var p := Vector2(rng.randf_range(F.position.x + 40, F.end.x - 40), rng.randf_range(F.position.y + 30, F.end.y - 30))
		var s := rng.randf_range(1.5, 3.0)
		ci.draw_rect(Rect2(p, Vector2(s * 1.4, s)), Color(0.35, 0.4, 0.5, 0.5))
		ci.draw_rect(Rect2(p + Vector2(0, s), Vector2(s * 1.4, 1.0)), Color(0, 0, 0, 0.5))
	# sombra ambiental junto a los muros (solo bordes expuestos de la sala principal)
	for i in 10:
		var a := 0.5 * (1.0 - float(i) / 10.0)
		var o := float(i) * 4.0
		if room.exit_side != "N" and room.entry_side != "N":
			ci.draw_rect(Rect2(F.position.x, F.position.y + o, F.size.x, 4.0), Color(0, 0, 0, a))
		if room.exit_side != "S" and room.entry_side != "S":
			ci.draw_rect(Rect2(F.position.x, F.end.y - o - 4.0, F.size.x, 4.0), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "W" and room.entry_side != "W":
			ci.draw_rect(Rect2(F.position.x + o, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "E" and room.entry_side != "E":
			ci.draw_rect(Rect2(F.end.x - o - 4.0, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))


func _floor_panels(ci: CanvasItem, R: Rect2, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ts := tile
	ci.draw_rect(R, Color("0f1524"))
	var cols := int(R.size.x / ts)
	var rows := int(R.size.y / ts)
	for ix in cols:
		for iy in rows:
			var x := R.position.x + ix * ts
			var y := R.position.y + iy * ts
			var v := rng.randf()
			var base := Color("151c2e").lerp(Color("1a2236"), v)
			if (ix + iy) % 2 == 0:
				base = base.darkened(0.06)
			ci.draw_rect(Rect2(x + 1, y + 1, ts - 2, ts - 2), base)
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + ts - 2, y + 2), Color(1, 1, 1, 0.07), 2.0)
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + 2, y + ts - 2), Color(1, 1, 1, 0.04), 2.0)
			ci.draw_line(Vector2(x + 2, y + ts - 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.35), 2.0)
			ci.draw_line(Vector2(x + ts - 2, y + 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.25), 2.0)
			ci.draw_rect(Rect2(x + 10, y + 10, ts - 20, ts - 20), Color(0, 0, 0, 0.12), false, 1.5)
			for c in [Vector2(x + 6, y + 6), Vector2(x + ts - 6, y + 6), Vector2(x + 6, y + ts - 6), Vector2(x + ts - 6, y + ts - 6)]:
				ci.draw_circle(c, 1.7, Color("0a0f1b"))
				ci.draw_circle(c + Vector2(-0.4, -0.4), 1.0, Color("2a3550"))
			var k := rng.randf()
			if k < 0.12:
				for g in 6:
					ci.draw_rect(Rect2(x + 18, y + 18 + g * 7.0, ts - 36, 3.0), Color("070a12"))
					ci.draw_rect(Rect2(x + 18, y + 21 + g * 7.0, ts - 36, 1.0), Color(1, 1, 1, 0.05))
			elif k < 0.2:
				var p0 := Vector2(x + rng.randf_range(10, 40), y + rng.randf_range(10, 40))
				var pts := PackedVector2Array([p0])
				for s in 4:
					p0 += Vector2(rng.randf_range(-16, 16), rng.randf_range(4, 18))
					pts.append(p0)
				ci.draw_polyline(pts, Color(0.02, 0.03, 0.06, 0.8), 1.6, true)
			elif k < 0.27:
				Gfx.draw_glow(ci, Vector2(x + 40, y + 40), 34.0, Color(0, 0, 0, 0.35))


# ============================================================ MUROS
func paint_wall_run(ci: CanvasItem, room: Room, run: Dictionary) -> void:
	var side: String = run["side"]
	var a: float = run["a"]
	var b: float = run["b"]
	var edge: float = run["edge"]
	var ea: float = run["ext_a"]
	var eb: float = run["ext_b"]
	var ink := Gfx.INK
	match side:
		"N":
			var x0 := a - ea
			var x1 := b + eb
			var w := x1 - x0
			var top := edge - FACE_H
			ci.draw_rect(Rect2(x0 - 70, top - 100, w + 140, 100 + 2), Color("0a0e18"))
			Gfx.grect_grad(ci, Rect2(x0, top, w, FACE_H), Color("27314a"), Color("141a2b"))
			var px := x0
			while px < x1:
				var pw := minf(130.0, x1 - px)
				ci.draw_rect(Rect2(px + 2, top + 2, pw - 4, FACE_H - 4), Color(1, 1, 1, 0.025))
				ci.draw_line(Vector2(px, top), Vector2(px, edge), Color("0b0f1a"), 3.0)
				ci.draw_line(Vector2(px + 2, top), Vector2(px + 2, edge), Color(1, 1, 1, 0.07), 1.5)
				for c in [Vector2(px + 10, top + 10), Vector2(px + pw - 10, top + 10), Vector2(px + 10, edge - 4), Vector2(px + pw - 10, edge - 4)]:
					ci.draw_circle(c, 2.0, Color("0b0f1a"))
					ci.draw_circle(c + Vector2(-0.5, -0.5), 1.2, Color("56648a"))
				px += 130.0
			# tuberia
			ci.draw_rect(Rect2(x0, edge - 68, w, 12), ink)
			Gfx.grect_grad(ci, Rect2(x0, edge - 67, w, 10), Color("5a6890"), Color("273050"))
			ci.draw_rect(Rect2(x0, edge - 66, w, 2), Color(1, 1, 1, 0.2))
			px = x0
			while px < x1:
				ci.draw_rect(Rect2(px - 5, edge - 71, 10, 18), ink)
				ci.draw_rect(Rect2(px - 4, edge - 70, 8, 16), Color("3a4670"))
				px += 130.0
			# zocalo con franja de peligro
			ci.draw_rect(Rect2(x0, edge - 16, w, 16), Color("0b0f1a"))
			var hx := x0
			while hx < x1:
				if int(hx / 12.0) % 2 == 0:
					ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, edge - 2), Vector2(hx + 8, edge - 14), Vector2(minf(hx + 14, x1), edge - 14), Vector2(minf(hx + 6, x1), edge - 2)]), Color("c98a22"))
				hx += 12.0
			ci.draw_rect(Rect2(x0, edge - 17, w, 2), Color(1, 1, 1, 0.15))
			# cornisa
			var cap := Rect2(x0, top - CORNICE_H, w, CORNICE_H + 2)
			Gfx.grect_grad(ci, cap, Color("46557a"), Color("2b3654"))
			ci.draw_rect(Rect2(x0, top - CORNICE_H, w, 3), Color(1, 1, 1, 0.22))
			ci.draw_rect(Rect2(x0, top, w, 3), Color("0b0f1a"))
			px = x0
			while px < x1:
				ci.draw_line(Vector2(px, top - CORNICE_H), Vector2(px, top), Color("1a2238"), 2.0)
				px += 130.0
			_wall_items(ci, room, x0, x1, edge)
		"S":
			var x0 := a - ea
			var x1 := b + eb
			var sr := Rect2(x0, edge, x1 - x0, 140)
			Gfx.grect_grad(ci, sr, Color("3a4668"), Color("1d2540"))
			ci.draw_rect(Rect2(x0, edge, sr.size.x, 4), Color("0b0f1a"))
			ci.draw_rect(Rect2(x0, edge + 4, sr.size.x, 2), Color(1, 1, 1, 0.18))
			var sx := x0
			while sx < x1:
				ci.draw_line(Vector2(sx, edge + 4), Vector2(sx, edge + 140), Color("0b0f1a"), 2.0)
				ci.draw_rect(Rect2(sx + 40, edge + 14, 50, 6), Color("e9a72c", 0.6))
				sx += 130.0
		"W", "E":
			var y0: float = a - 142.0 if run.get("tall_a", true) else a
			var y1: float = b + 18.0
			var x0: float = edge - 50.0 if side == "W" else edge
			var wall := Rect2(x0, y0, 50, y1 - y0)
			Gfx.grect_grad(ci, wall, Color("2f3a5a"), Color("1c2438"))
			var ex: float = edge - 4.0 if side == "W" else edge
			ci.draw_rect(Rect2(ex, a - 110.0, 4, b - a + 110.0), Color("0b0f1a"))
			ci.draw_rect(Rect2(ex + (0.0 if side == "W" else 4.0), a - 110.0, 2, b - a + 110.0), Color(1, 1, 1, 0.15))
			var yy := y0 + 32.0
			while yy < y1:
				ci.draw_line(Vector2(x0, yy), Vector2(x0 + 50, yy), Color("0b0f1a"), 2.0)
				ci.draw_circle(Vector2(x0 + 12, yy + 12), 2.0, Color("56648a"))
				ci.draw_circle(Vector2(x0 + 38, yy + 12), 2.0, Color("56648a"))
				yy += 110.0
			var cdx := x0 + (30.0 if side == "W" else 10.0)
			ci.draw_rect(Rect2(cdx - 1, y0 + 32.0, 12, y1 - y0 - 32.0), ink)
			Gfx.grect_grad(ci, Rect2(cdx, y0 + 32.0, 10, y1 - y0 - 32.0), Color("5a6890"), Color("2a3352"))
			# esquina superior
			ci.draw_rect(Rect2(x0, y0, 50, 34), Color("56648e"))
			ci.draw_rect(Rect2(x0, y0, 50, 3), Color(1, 1, 1, 0.25))


func _wall_items(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var d: Dictionary = room.dressing
	var F := room.floor_rect
	if absf(edge - F.position.y) > 1.0:
		# pasillos: lamparas simples cada 200
		var lx := x0 + 80.0
		while lx < x1 - 40.0:
			Gfx.rrect(ci, Rect2(lx - 18, edge - 110, 36, 14), 4.0, Color("1a2236"), Gfx.INK, 2.0)
			Gfx.rrect(ci, Rect2(lx - 14, edge - 107, 28, 7), 3.0, Color("d6f6ff"), Color(0, 0, 0, 0), 0.0)
			lx += 200.0
		return
	for s in d.get("screens", []):
		var sr: Rect2 = s
		if sr.position.x > x0 and sr.end.x < x1:
			Gfx.rrect(ci, sr.grow(5), 4.0, Color("1a2036"), Gfx.INK, 2.5)
			Gfx.rrect(ci, sr, 2.0, Color("06151c"), Gfx.INK, 1.5)
	var ec: Vector2 = d.get("wall_emblem", Vector2.ZERO)
	if ec != Vector2.ZERO and ec.x > x0 + 40 and ec.x < x1 - 40:
		var hexp := Gfx.ell_pts(ec, 26.0, 26.0, 6, PI / 6.0)
		ci.draw_colored_polygon(hexp, Color("0c1322"))
		Gfx.outline(ci, hexp, Gfx.INK, 3.0)
		Gfx.outline(ci, hexp, Color(0.25, 0.85, 0.8, 0.8), 1.5)
	for v in d.get("vents", []):
		var vp: Vector2 = v
		if vp.x > x0 + 20 and vp.x + 52 < x1 - 20:
			Gfx.rrect(ci, Rect2(vp.x - 6, vp.y, 52, 40), 3.0, Color("0b0f1a"), Gfx.INK, 2.0)
			for k in 6:
				ci.draw_rect(Rect2(vp.x, vp.y + 6 + k * 6.0, 40, 3.0), Color("2b3654"))
	for l in d.get("lamps", []):
		var lp: Vector2 = l
		if lp.x > x0 + 20 and lp.x < x1 - 20:
			Gfx.rrect(ci, Rect2(lp.x - 18, edge - 110, 36, 14), 4.0, Color("1a2236"), Gfx.INK, 2.0)
			Gfx.rrect(ci, Rect2(lp.x - 14, edge - 107, 28, 7), 3.0, Color("d6f6ff"), Color(0, 0, 0, 0), 0.0)
	for cx in d.get("drops", []):
		if cx > x0 + 20 and cx < x1 - 20:
			var pts := PackedVector2Array([Vector2(cx, edge - 108), Vector2(cx + 6, edge - 80), Vector2(cx - 4, edge - 50), Vector2(cx + 8, edge - 25)])
			ci.draw_polyline(pts, Gfx.INK, 6.0, true)
			ci.draw_polyline(pts, Color("2a3452"), 3.5, true)


# ============================================================ LUCES
func paint_lights(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	var d: Dictionary = room.dressing
	for l in d.get("lamps", []):
		var lp: Vector2 = l
		if room.in_exit_gap(lp.x, "N"):
			continue
		var top_w := 26.0
		var bot_w := 190.0
		var y0 := F.position.y + 2.0
		var y1 := F.position.y + 230.0
		var pts := PackedVector2Array([Vector2(lp.x - top_w, y0), Vector2(lp.x + top_w, y0), Vector2(lp.x + bot_w, y1), Vector2(lp.x - bot_w, y1)])
		var cols := PackedColorArray([Color(0.55, 0.85, 1.0, 0.16), Color(0.55, 0.85, 1.0, 0.16), Color(0.55, 0.85, 1.0, 0.0), Color(0.55, 0.85, 1.0, 0.0)])
		ci.draw_polygon(pts, cols)
		Gfx.draw_glow(ci, Vector2(lp.x, F.position.y + 20.0), 130.0, Color(0.5, 0.85, 1.0, 0.18))
	Gfx.draw_glow(ci, F.get_center(), minf(F.size.x, F.size.y) * 0.4, Color(0.2, 0.7, 0.9, 0.06))
	for p in room.props:
		var c := p.foot.get_center()
		match p.kind:
			"tank":
				Gfx.draw_glow(ci, c + Vector2(0, 18), 150.0, Color(0.15, 0.9, 0.75, 0.16))
			"terminal":
				Gfx.draw_glow(ci, c + Vector2(0, -6), 110.0, Color(0.2, 0.9, 0.8, 0.12))
			"barrel":
				Gfx.draw_glow(ci, c, 90.0, Color(1.0, 0.65, 0.2, 0.08))
			"reactor":
				Gfx.draw_glow(ci, c, 260.0, Color(0.2, 0.9, 0.85, 0.12))
			"rack":
				Gfx.draw_glow(ci, c, 70.0, Color(0.2, 0.85, 1.0, 0.07))


# ============================================================ DECORADO VIVO
func paint_deco(ci: CanvasItem, room: Room, t: float) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var d: Dictionary = room.dressing
	var traces: Array = dec.get("traces", [])
	for i in traces.size():
		var tr: PackedVector2Array = traces[i]
		var total := 0.0
		for k in tr.size() - 1:
			total += tr[k].distance_to(tr[k + 1])
		var dd0 := fposmod(t * 90.0 + float(i) * 130.0, total + 120.0)
		for q in 5:
			var dd := dd0 - q * 9.0
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
	var emb: String = dec.get("emblem", "")
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	var pulse := 0.5 + 0.5 * sin(t * 1.6)
	if emb == "hex":
		ci.draw_arc(C, 172.0, 0, TAU, 72, Color(0.2, 0.9, 0.85, 0.08 + 0.1 * pulse), 2.5, true)
		var hex := Gfx.ell_pts(C, 66.0, 66.0, 6, PI / 6.0)
		Gfx.outline(ci, hex, Color(0.3, 1.0, 0.9, 0.12 + 0.18 * pulse), 3.0)
		Gfx.draw_glow(ci, C, 70.0, Color(0.2, 0.9, 0.85, 0.05 + 0.05 * pulse))
	elif emb == "core":
		for k in 3:
			ci.draw_arc(C, 90.0 + k * 38.0, t * (0.3 + k * 0.1), t * (0.3 + k * 0.1) + TAU * 0.6, 40, Color(0.3, 1.0, 0.9, 0.15 + 0.15 * pulse), 3.0, true)
	var scr: Array = d.get("screens", [])
	for si in scr.size():
		var s: Rect2 = scr[si]
		var flick := 0.85 + 0.15 * sin(t * 23.0 + si * 3.0)
		ci.draw_rect(s, Color(0.1, 0.55, 0.55, 0.22 * flick))
		for k in 6:
			var w := 18.0 + fposmod(float(k * 41 + si * 17) + sin(t * 0.7 + k) * 20.0, 64.0)
			var y := s.position.y + 7.0 + k * 7.0
			ci.draw_line(Vector2(s.position.x + 8, y), Vector2(s.position.x + 8 + minf(w, s.size.x - 16.0), y), Color(0.3, 1.0, 0.9, 0.7 * flick), 2.0)
		var sy := s.position.y + fposmod(t * 22.0 + si * 9.0, s.size.y)
		ci.draw_line(Vector2(s.position.x, sy), Vector2(s.end.x, sy), Color(0.6, 1.0, 1.0, 0.3), 2.0)
		Gfx.draw_glow(ci, s.get_center() + Vector2(0, 40), 90.0, Color(0.2, 0.9, 0.85, 0.08 * flick))
	var ec: Vector2 = d.get("wall_emblem", Vector2.ZERO)
	if ec != Vector2.ZERO and not room.in_exit_gap(ec.x, "N"):
		var wp := 0.6 + 0.4 * sin(t * 2.2)
		Gfx.draw_glow(ci, ec, 40.0, Color(0.3, 1.0, 0.9, 0.18 * wp))
	for l in d.get("lamps", []):
		var lp: Vector2 = l
		if not room.in_exit_gap(lp.x, "N"):
			Gfx.draw_glow(ci, Vector2(lp.x, F.position.y - 100.0), 40.0, Color(0.7, 0.92, 1.0, 0.45))
	# luces de los pasillos
	for R in room.corridor_rects():
		var along_x := R.size.x > R.size.y
		var n := int(maxf(R.size.x, R.size.y) / 200.0)
		for k in n:
			var c := Vector2(R.position.x + 100.0 + k * 200.0, R.get_center().y) if along_x else Vector2(R.get_center().x, R.position.y + 100.0 + k * 200.0)
			Gfx.draw_glow(ci, c, 70.0, Color(0.5, 0.85, 1.0, 0.09 + 0.02 * sin(t * 2.0 + k)))


# ============================================================ PUNTOS DE APARICION (compuertas)
func spawn_color() -> Color:
	return Color("c07aff")


func paint_spawn(ci: CanvasItem, c: Vector2, o: float, t: float, i: int) -> void:
	var ink := Gfx.INK
	var base := Rect2(c.x - 44, c.y - 30, 88, 60)
	Gfx.rrect(ci, base.grow(7), 9.0, Color("0b0f1a"), ink, 2.0)
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
	if o < 0.05:
		ci.draw_line(Vector2(c.x, c.y - 28), Vector2(c.x, c.y + 28), Color(0.5, 0.25, 0.9, 0.6), 2.0)


func paint_spawn_glow(ci: CanvasItem, c: Vector2, g: float, t: float, i: int) -> void:
	if g > 0.01:
		var f := 0.7 + 0.3 * sin(t * 18.0 + i)
		Gfx.draw_glow(ci, c, 120.0 * g, Color(0.7, 0.3, 1.0, 0.45 * g * f))
		Gfx.draw_glow(ci, c, 60.0 * g, Color(0.9, 0.7, 1.0, 0.35 * g))
	else:
		ci.draw_rect(Rect2(c.x - 3, c.y - 3, 6, 6), Color(0.4, 0.2, 0.7, 0.35 + 0.2 * sin(t * 2.0 + i)))


func _block_dressing(ci: CanvasItem, f: Rect2, top: Rect2, front: Rect2, style: String, t: float) -> void:
	# base con franja de peligro y luces de estado
	ci.draw_rect(Rect2(front.position.x + 2, front.end.y - 12, front.size.x - 4, 10), Color("0b0f1a"))
	var hx := front.position.x + 2.0
	while hx < front.end.x - 14.0:
		if int(hx / 12.0) % 2 == 0:
			ci.draw_colored_polygon(PackedVector2Array([Vector2(hx, front.end.y - 3), Vector2(hx + 7, front.end.y - 11), Vector2(hx + 13, front.end.y - 11), Vector2(hx + 6, front.end.y - 3)]), Color("c98a22"))
		hx += 12.0
	if style == "machine":
		var n := int(front.size.x / 26.0)
		for i in n:
			var on := (int(t * 2.0 + float(i * 3)) % 3) != 0
			ci.draw_circle(Vector2(front.position.x + 14.0 + i * 26.0, front.position.y + 14.0), 2.4, Color("3df2dc") if on else Color("1a6e66"))
		ci.draw_rect(Rect2(front.position.x + 8, front.position.y + 26, front.size.x - 16, 4), Color(0.2, 0.9, 0.85, 0.35))
	else:
		ci.draw_rect(Rect2(front.position.x + 6, front.position.y + 10, front.size.x - 12, 3), Color(1, 1, 1, 0.07))
	ci.draw_rect(Rect2(top.position.x + 8, top.position.y + 8, top.size.x - 16, top.size.y - 16), Color(0, 0, 0, 0.12), false, 1.5)
