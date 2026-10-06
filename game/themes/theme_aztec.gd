class_name ThemeAztec
extends RoomTheme
## Capitulo 2: civilizacion antigua azteca-tecnologica. Piedra tallada calida, greca escalonada, jade luminoso, antorchas y oro.

const STONE_A := Color("4a3b32")
const STONE_B := Color("34291f")
const JADE := Color("3dd9a8")
const GOLD := Color("e8c06a")
const INKC := Color("120c08")


func _init() -> void:
	id = "aztec"
	accent = JADE
	void_col = Color("0a0605")
	tile = 80.0
	block_top = [Color("8a7a62"), Color("5e5242")]
	block_front = [Color("5a4e3c"), Color("30281c")]
	block_trim = JADE


func spawn_color() -> Color:
	return Color("3dd9a8")


func build_dressing(room: Room, rng: RandomNumberGenerator) -> Dictionary:
	var F := room.floor_rect
	var torches: Array[Vector2] = []
	var n := maxi(2, int(round(F.size.x / 320.0)))
	for i in n:
		torches.append(Vector2(F.get_center().x + (float(i) - float(n - 1) * 0.5) * F.size.x / float(n), F.position.y))
	return {"torches": torches, "sun": Vector2(F.get_center().x, F.position.y - 58.0)}


func _floor_panels(ci: CanvasItem, R: Rect2, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ts := tile
	ci.draw_rect(R, STONE_B)
	var cols := int(R.size.x / ts)
	var rows := int(R.size.y / ts)
	for ix in cols:
		for iy in rows:
			var x := R.position.x + ix * ts
			var y := R.position.y + iy * ts
			var v := rng.randf()
			var base := STONE_A.lerp(Color("574638"), v * 0.7)
			if (ix + iy) % 2 == 0:
				base = base.darkened(0.07)
			ci.draw_rect(Rect2(x + 1, y + 1, ts - 2, ts - 2), base)
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + ts - 2, y + 2), Color(1, 0.9, 0.7, 0.09), 2.0)
			ci.draw_line(Vector2(x + 2, y + ts - 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.4), 2.0)
			ci.draw_line(Vector2(x + ts - 2, y + 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.3), 2.0)
			var k := rng.randf()
			if k < 0.22:
				# greca escalonada en el borde interior
				var m := 11.0
				var pts := PackedVector2Array([Vector2(x + m, y + ts - m), Vector2(x + m, y + m + 14), Vector2(x + m + 14, y + m + 14), Vector2(x + m + 14, y + m), Vector2(x + ts - m, y + m)])
				ci.draw_polyline(pts, Color(0, 0, 0, 0.35), 3.0, true)
				ci.draw_polyline(pts, Color(GOLD, 0.35), 1.4, true)
			elif k < 0.34:
				# incrustacion de jade
				var c := Vector2(x + ts * 0.5, y + ts * 0.5)
				ci.draw_rect(Rect2(c.x - 14, c.y - 3, 28, 6), Color(0, 0, 0, 0.45))
				ci.draw_rect(Rect2(c.x - 12, c.y - 1.2, 24, 2.4), Color(JADE, 0.55))
				ci.draw_rect(Rect2(c.x - 3, c.y - 14, 6, 28), Color(0, 0, 0, 0.45))
				ci.draw_rect(Rect2(c.x - 1.2, c.y - 12, 2.4, 24), Color(JADE, 0.55))
			elif k < 0.42:
				var p0 := Vector2(x + rng.randf_range(10, 40), y + rng.randf_range(10, 40))
				var pts2 := PackedVector2Array([p0])
				for s in 4:
					p0 += Vector2(rng.randf_range(-16, 16), rng.randf_range(4, 18))
					pts2.append(p0)
				ci.draw_polyline(pts2, Color(0.04, 0.02, 0.01, 0.8), 1.7, true)
			elif k < 0.48:
				Gfx.draw_glow(ci, Vector2(x + 40, y + 40), 34.0, Color(0, 0, 0, 0.3))


func _floor_extras(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "sun":
		# piedra del sol: anillos concentricos con muescas
		for k in 4:
			var rr := 70.0 + float(k) * 34.0
			ci.draw_arc(C, rr, 0, TAU, 64, Color(0, 0, 0, 0.5), 7.0, true)
			ci.draw_arc(C, rr, 0, TAU, 64, Color(GOLD, 0.22 + 0.04 * float(k)), 1.8, true)
		for k in 20:
			var a := TAU * float(k) / 20.0
			var d := Vector2.from_angle(a)
			ci.draw_colored_polygon(PackedVector2Array([C + d * 150.0, C + d.rotated(0.09) * 178.0, C + d.rotated(-0.09) * 178.0]), Color(GOLD, 0.18))
		var hex := Gfx.ell_pts(C, 46.0, 46.0, 8, PI / 8.0)
		ci.draw_colored_polygon(hex, Color(0.02, 0.1, 0.08, 0.7))
		Gfx.outline(ci, hex, Color(JADE, 0.6), 2.4)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91
	for i in int(dec.get("stains", 8)):
		var p := Vector2(rng.randf_range(F.position.x + 80, F.end.x - 80), rng.randf_range(F.position.y + 70, F.end.y - 70))
		Gfx.draw_glow(ci, p, rng.randf_range(24, 56), Color(0, 0, 0, 0.3))
	for i in int(dec.get("litter", 20)):
		var p := Vector2(rng.randf_range(F.position.x + 40, F.end.x - 40), rng.randf_range(F.position.y + 30, F.end.y - 30))
		var s := rng.randf_range(1.5, 3.4)
		ci.draw_rect(Rect2(p, Vector2(s * 1.4, s)), Color(0.55, 0.45, 0.35, 0.45))
	for line in dec.get("jade_lines", []):
		var pts: PackedVector2Array = line
		ci.draw_polyline(pts, Color(0, 0, 0, 0.5), 6.0, true)
		ci.draw_polyline(pts, Color(JADE, 0.35), 2.0, true)
	for i in 8:
		var a := 0.5 * (1.0 - float(i) / 8.0)
		var o := float(i) * 4.0
		if room.exit_side != "N" and room.entry_side != "N":
			ci.draw_rect(Rect2(F.position.x, F.position.y + o, F.size.x, 4.0), Color(0, 0, 0, a))
		if room.exit_side != "S" and room.entry_side != "S":
			ci.draw_rect(Rect2(F.position.x, F.end.y - o - 4.0, F.size.x, 4.0), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "W" and room.entry_side != "W":
			ci.draw_rect(Rect2(F.position.x + o, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "E" and room.entry_side != "E":
			ci.draw_rect(Rect2(F.end.x - o - 4.0, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))


# ------------------------------------------------------------ muros
func _wall_n(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var w := x1 - x0
	var top := edge - FACE_H
	ci.draw_rect(Rect2(x0 - 70, top - 100, w + 140, 102), Color("0b0705"))
	Gfx.grect_grad(ci, Rect2(x0, top, w, FACE_H), Color("5e4c3e"), Color("2c2218"))
	# bloques grandes
	var px := x0
	while px < x1:
		var bw := minf(110.0, x1 - px)
		ci.draw_rect(Rect2(px + 2, top + 2, bw - 4, FACE_H - 4), Color(1, 0.9, 0.7, 0.03))
		ci.draw_line(Vector2(px, top), Vector2(px, edge), INKC, 3.0)
		ci.draw_line(Vector2(px + 2, top), Vector2(px + 2, edge), Color(1, 0.9, 0.7, 0.1), 1.5)
		# relieve de greca
		var gy := top + 26.0
		var pts := PackedVector2Array()
		var s := px + 10.0
		while s < px + bw - 14.0:
			pts.append(Vector2(s, gy + 12.0))
			pts.append(Vector2(s, gy))
			pts.append(Vector2(s + 12.0, gy))
			pts.append(Vector2(s + 12.0, gy + 12.0))
			s += 24.0
		if pts.size() > 1:
			ci.draw_polyline(pts, Color(0, 0, 0, 0.45), 3.0, true)
			ci.draw_polyline(pts, Color(GOLD, 0.4), 1.4, true)
		px += 110.0
	# banda de jade con circuitos
	ci.draw_rect(Rect2(x0, edge - 46.0, w, 10.0), INKC)
	ci.draw_rect(Rect2(x0, edge - 44.0, w, 6.0), Color(JADE, 0.35))
	px = x0 + 20.0
	while px < x1 - 20.0:
		ci.draw_rect(Rect2(px, edge - 44.0, 30.0, 6.0), Color(JADE, 0.7))
		px += 70.0
	# zocalo
	ci.draw_rect(Rect2(x0, edge - 16.0, w, 16.0), INKC)
	ci.draw_rect(Rect2(x0, edge - 15.0, w, 3.0), Color(GOLD, 0.35))
	# cornisa escalonada (dientes de piramide)
	Gfx.grect_grad(ci, Rect2(x0, top - 30.0, w, 32.0), Color("7a6650"), Color("463a2c"))
	ci.draw_rect(Rect2(x0, top - 30.0, w, 3.0), Color(1, 0.9, 0.7, 0.25))
	px = x0
	while px < x1 - 20.0:
		ci.draw_colored_polygon(PackedVector2Array([Vector2(px, top - 30.0), Vector2(px + 14.0, top - 48.0), Vector2(px + 28.0, top - 30.0)]), Color("5a4a3a"))
		ci.draw_line(Vector2(px, top - 30.0), Vector2(px + 14.0, top - 48.0), Color(1, 0.9, 0.7, 0.18), 1.4)
		px += 56.0
	var F := room.floor_rect
	if absf(edge - F.position.y) < 1.0:
		var d: Dictionary = room.dressing
		for tp in d.get("torches", []):
			var v: Vector2 = tp
			if v.x > x0 + 24.0 and v.x < x1 - 24.0:
				# soporte de antorcha
				Gfx.rrect(ci, Rect2(v.x - 7, edge - 98.0, 14, 40), 3.0, Color("3a3028"), Gfx.INK, 2.0)
				ci.draw_rect(Rect2(v.x - 10, edge - 102.0, 20, 8), Color("70604a"))
		var sc: Vector2 = d.get("sun", Vector2.ZERO)
		if sc != Vector2.ZERO and sc.x > x0 + 50.0 and sc.x < x1 - 50.0:
			var disc := Gfx.ell_pts(sc, 30.0, 30.0, 20)
			ci.draw_colored_polygon(disc, Color("2a2018"))
			Gfx.outline(ci, disc, Color(GOLD, 0.8), 3.0)
			ci.draw_circle(sc, 11.0, Color(GOLD, 0.5))
			for k in 8:
				var a := TAU * float(k) / 8.0
				ci.draw_line(sc + Vector2.from_angle(a) * 18.0, sc + Vector2.from_angle(a) * 27.0, Color(JADE, 0.7), 2.4)


func _wall_s(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var sr := Rect2(x0, edge, x1 - x0, 140)
	Gfx.grect_grad(ci, sr, Color("5a4a3c"), Color("251c14"))
	ci.draw_rect(Rect2(x0, edge, sr.size.x, 4), INKC)
	ci.draw_rect(Rect2(x0, edge + 4, sr.size.x, 2), Color(1, 0.9, 0.7, 0.18))
	var sx := x0
	while sx < x1:
		ci.draw_line(Vector2(sx, edge + 4), Vector2(sx, edge + 140), INKC, 2.0)
		ci.draw_rect(Rect2(sx + 30, edge + 18, 60, 6), Color(JADE, 0.5))
		sx += 110.0


func _wall_we(ci: CanvasItem, room: Room, side: String, a: float, b: float, edge: float) -> void:
	var y0 := a - 142.0
	var y1 := b + 18.0
	var x0 := edge - 50.0 if side == "W" else edge
	Gfx.grect_grad(ci, Rect2(x0, y0, 50, y1 - y0), Color("56463a"), Color("261d15"))
	var ex := edge - 4.0 if side == "W" else edge
	ci.draw_rect(Rect2(ex, a - 110.0, 4, b - a + 110.0), INKC)
	ci.draw_rect(Rect2(ex + (0.0 if side == "W" else 4.0), a - 110.0, 2, b - a + 110.0), Color(1, 0.9, 0.7, 0.15))
	var yy := y0 + 36.0
	while yy < y1 - 20.0:
		ci.draw_rect(Rect2(x0 + 8, yy, 34, 20), Color(0, 0, 0, 0.28))
		ci.draw_rect(Rect2(x0 + 14, yy + 8, 22, 4), Color(JADE, 0.45))
		yy += 64.0
	ci.draw_rect(Rect2(x0, y0, 50, 32), Color("7a6650"))
	ci.draw_rect(Rect2(x0, y0, 50, 3), Color(1, 0.9, 0.7, 0.25))


# ------------------------------------------------------------ luces / deco
func paint_lights(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		var pts := PackedVector2Array([Vector2(v.x - 20, F.position.y + 2), Vector2(v.x + 20, F.position.y + 2), Vector2(v.x + 170, F.position.y + 230), Vector2(v.x - 170, F.position.y + 230)])
		var cols := PackedColorArray([Color(1.0, 0.65, 0.25, 0.14), Color(1.0, 0.65, 0.25, 0.14), Color(1.0, 0.65, 0.25, 0.0), Color(1.0, 0.65, 0.25, 0.0)])
		ci.draw_polygon(pts, cols)
	Gfx.draw_glow(ci, F.get_center(), minf(F.size.x, F.size.y) * 0.45, Color(0.24, 0.85, 0.65, 0.05))
	for p in room.props:
		var c := p.foot.get_center()
		match p.kind:
			"brazier":
				Gfx.draw_glow(ci, c + Vector2(0, -10), 150.0, Color(1.0, 0.6, 0.2, 0.16))
			"totem", "glyph_pillar":
				Gfx.draw_glow(ci, c, 90.0, Color(JADE, 0.1))


func paint_deco(ci: CanvasItem, room: Room, t: float) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "sun":
		var pulse := 0.5 + 0.5 * sin(t * 1.4)
		for k in 4:
			ci.draw_arc(C, 70.0 + float(k) * 34.0, t * (0.2 + float(k) * 0.05), t * (0.2 + float(k) * 0.05) + TAU * 0.55, 40, Color(JADE, 0.15 + 0.18 * pulse), 3.0, true)
		Gfx.draw_glow(ci, C, 90.0, Color(JADE, 0.06 + 0.06 * pulse))
	for line in dec.get("jade_lines", []):
		var pts: PackedVector2Array = line
		var total := 0.0
		for k in pts.size() - 1:
			total += pts[k].distance_to(pts[k + 1])
		var dd := fposmod(t * 70.0, total + 80.0)
		var acc := 0.0
		for k in pts.size() - 1:
			var seg := pts[k].distance_to(pts[k + 1])
			if dd <= acc + seg and dd >= acc:
				Gfx.draw_glow(ci, pts[k].lerp(pts[k + 1], (dd - acc) / seg), 12.0, Color(JADE, 0.6))
				break
			acc += seg
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		var fl := 0.75 + 0.25 * sin(t * 13.0 + v.x)
		var fy := F.position.y - 104.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(v.x - 8, fy), Vector2(v.x - 3, fy - 16 * fl), Vector2(v.x, fy - 8), Vector2(v.x + 4, fy - 20 * fl), Vector2(v.x + 8, fy)]), Color(1.0, 0.55, 0.15, 0.9))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(v.x - 4, fy), Vector2(v.x, fy - 11 * fl), Vector2(v.x + 4, fy)]), Color(1.0, 0.9, 0.5, 0.9))
		Gfx.draw_glow(ci, Vector2(v.x, fy - 8), 46.0, Color(1.0, 0.6, 0.2, 0.3 * fl))
	var sc: Vector2 = room.dressing.get("sun", Vector2.ZERO)
	if sc != Vector2.ZERO and not room.in_exit_gap(sc.x, "N"):
		Gfx.draw_glow(ci, sc, 46.0, Color(GOLD, 0.2 + 0.1 * sin(t * 2.0)))
	for R in room.corridor_rects():
		var along_x := R.size.x > R.size.y
		var n := int(maxf(R.size.x, R.size.y) / 200.0)
		for k in n:
			var c := Vector2(R.position.x + 100.0 + k * 200.0, R.get_center().y) if along_x else Vector2(R.get_center().x, R.position.y + 100.0 + k * 200.0)
			Gfx.draw_glow(ci, c, 70.0, Color(1.0, 0.65, 0.3, 0.07 + 0.02 * sin(t * 3.0 + k)))


# ------------------------------------------------------------ puntos de aparicion: glifo de jade
func paint_spawn(ci: CanvasItem, c: Vector2, o: float, t: float, i: int) -> void:
	var ink := Gfx.INK
	var base := Gfx.ell_pts(c, 50.0, 30.0, 28)
	ci.draw_colored_polygon(base, Color(0.05, 0.03, 0.02, 0.8))
	Gfx.outline(ci, base, Color("6a5846"), 4.0)
	Gfx.outline(ci, Gfx.ell_pts(c, 42.0, 25.0, 24), Color(0, 0, 0, 0.6), 2.0)
	for k in 8:
		var a := TAU * float(k) / 8.0
		var p := c + Vector2(cos(a) * 36.0, sin(a) * 21.0)
		ci.draw_rect(Rect2(p.x - 3, p.y - 2, 6, 4), Color(JADE, 0.3 + 0.6 * o))
	if o > 0.0:
		ci.draw_colored_polygon(Gfx.ell_pts(c, 34.0 * (0.4 + 0.6 * o), 19.0 * (0.4 + 0.6 * o), 20), Color(0.05, 0.3, 0.22, 0.8 * o))


func paint_spawn_glow(ci: CanvasItem, c: Vector2, g: float, t: float, i: int) -> void:
	if g > 0.01:
		var f := 0.7 + 0.3 * sin(t * 16.0 + i)
		Gfx.draw_glow(ci, c, 110.0 * g, Color(JADE, 0.4 * g * f))
		Gfx.draw_glow(ci, c, 50.0 * g, Color(0.8, 1.0, 0.9, 0.35 * g))
		for k in 5:
			var a := t * 4.0 + float(k) * 1.26
			ci.draw_circle(c + Vector2(cos(a) * 22.0, sin(a) * 12.0 - fposmod(t * 40.0 + float(k) * 11.0, 40.0) * g), 1.8, Color(JADE.lightened(0.4), 0.8 * g))
	else:
		ci.draw_rect(Rect2(c.x - 3, c.y - 2, 6, 4), Color(JADE, 0.3 + 0.2 * sin(t * 2.0 + i)))


func _block_dressing(ci: CanvasItem, f: Rect2, top: Rect2, front: Rect2, style: String, t: float) -> void:
	var m := front.position.y + 12.0
	var x := front.position.x + 10.0
	while x < front.end.x - 22.0:
		ci.draw_polyline(PackedVector2Array([Vector2(x, m + 10), Vector2(x, m), Vector2(x + 10, m), Vector2(x + 10, m + 10)]), Color(0, 0, 0, 0.4), 2.6, true)
		ci.draw_polyline(PackedVector2Array([Vector2(x, m + 10), Vector2(x, m), Vector2(x + 10, m), Vector2(x + 10, m + 10)]), Color(GOLD, 0.35), 1.2, true)
		x += 22.0
	ci.draw_rect(Rect2(front.position.x + 6, front.end.y - 9, front.size.x - 12, 3), Color(JADE, 0.45 + 0.2 * sin(t * 2.0)))
