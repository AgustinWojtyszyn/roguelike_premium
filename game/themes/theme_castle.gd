class_name ThemeCastle
extends RoomTheme
## Capitulo 3: fortaleza oscura de caballeros. Losas frias, muros de ladrillo con almenas, antorchas, estandartes carmesi.

const SLATE_A := Color("2c3044")
const SLATE_B := Color("1a1d2c")
const TORCH := Color("ff9a3d")
const CRIM := Color("a01c3c")
const INKC := Color("07080f")


func _init() -> void:
	id = "castle"
	accent = Color("e0405a")
	void_col = Color("04050a")
	tile = 80.0
	block_top = [Color("5a5e78"), Color("3a3d54")]
	block_front = [Color("3e4260"), Color("1a1d2e")]
	block_trim = Color("c04060")


func spawn_color() -> Color:
	return Color("b04aff")


func build_dressing(room: Room, rng: RandomNumberGenerator) -> Dictionary:
	var F := room.floor_rect
	var torches: Array[Vector2] = []
	var n := maxi(2, int(round(F.size.x / 300.0)))
	for i in n:
		torches.append(Vector2(F.get_center().x + (float(i) - float(n - 1) * 0.5) * F.size.x / float(n), F.position.y))
	var banners: Array[float] = []
	for i in n - 1:
		banners.append(F.get_center().x + (float(i) - float(n - 2) * 0.5) * F.size.x / float(n))
	return {"torches": torches, "banners": banners}


func _floor_panels(ci: CanvasItem, R: Rect2, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ts := tile
	ci.draw_rect(R, SLATE_B)
	var cols := int(R.size.x / ts)
	var rows := int(R.size.y / ts)
	for ix in cols:
		for iy in rows:
			var x := R.position.x + ix * ts
			var y := R.position.y + iy * ts
			var v := rng.randf()
			var base := SLATE_A.lerp(Color("3a3e56"), v * 0.6)
			if (ix + iy) % 2 == 0:
				base = base.darkened(0.08)
			# losas irregulares: dos mitades con juntas distintas
			var split := ts * rng.randf_range(0.35, 0.65)
			ci.draw_rect(Rect2(x + 1, y + 1, split - 1, ts - 2), base)
			ci.draw_rect(Rect2(x + split + 1, y + 1, ts - split - 2, ts - 2), base.lerp(Color("1e2132"), 0.25))
			ci.draw_line(Vector2(x + split, y), Vector2(x + split, y + ts), Color(0, 0, 0, 0.55), 2.0)
			ci.draw_line(Vector2(x + 2, y + 2), Vector2(x + ts - 2, y + 2), Color(1, 1, 1, 0.06), 2.0)
			ci.draw_line(Vector2(x + 2, y + ts - 2), Vector2(x + ts - 2, y + ts - 2), Color(0, 0, 0, 0.45), 2.0)
			var k := rng.randf()
			if k < 0.2:
				var p0 := Vector2(x + rng.randf_range(8, 50), y + rng.randf_range(8, 30))
				var pts := PackedVector2Array([p0])
				for s in 5:
					p0 += Vector2(rng.randf_range(-14, 14), rng.randf_range(4, 14))
					pts.append(p0)
				ci.draw_polyline(pts, Color(0.01, 0.01, 0.03, 0.85), 1.8, true)
			elif k < 0.3:
				Gfx.draw_glow(ci, Vector2(x + rng.randf_range(20, 60), y + rng.randf_range(20, 60)), rng.randf_range(14, 30), Color(0.35, 0.02, 0.06, 0.28))   # mancha de sangre vieja
			elif k < 0.36:
				ci.draw_circle(Vector2(x + 20, y + 52), 4.0, Color(0.1, 0.12, 0.08, 0.7))   # musgo


func _floor_extras(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "sigil":
		ci.draw_arc(C, 150.0, 0, TAU, 64, Color(0, 0, 0, 0.55), 8.0, true)
		ci.draw_arc(C, 150.0, 0, TAU, 64, Color(CRIM, 0.45), 2.0, true)
		ci.draw_arc(C, 118.0, 0, TAU, 56, Color(CRIM, 0.3), 1.6, true)
		for k in 16:
			var a := TAU * float(k) / 16.0
			ci.draw_line(C + Vector2.from_angle(a) * 150.0, C + Vector2.from_angle(a) * 164.0, Color(CRIM, 0.4), 2.0)
		# espada y cruz
		ci.draw_line(C + Vector2(0, -96), C + Vector2(0, 96), Color(0, 0, 0, 0.5), 7.0)
		ci.draw_line(C + Vector2(0, -96), C + Vector2(0, 96), Color(0.7, 0.72, 0.85, 0.28), 2.0)
		ci.draw_line(C + Vector2(-34, -40), C + Vector2(34, -40), Color(0, 0, 0, 0.5), 7.0)
		ci.draw_line(C + Vector2(-34, -40), C + Vector2(34, -40), Color(0.7, 0.72, 0.85, 0.28), 2.0)
	if dec.get("carpet", false):
		var cr := Rect2(F.get_center().x - 60.0, F.position.y, 120.0, F.size.y)
		ci.draw_rect(cr, Color(0.36, 0.05, 0.12, 0.7))
		ci.draw_rect(Rect2(cr.position.x + 8, cr.position.y, 3, cr.size.y), Color("c8a050", 0.55))
		ci.draw_rect(Rect2(cr.end.x - 11, cr.position.y, 3, cr.size.y), Color("c8a050", 0.55))
	var rng := RandomNumberGenerator.new()
	rng.seed = 313
	for i in int(dec.get("stains", 8)):
		Gfx.draw_glow(ci, Vector2(rng.randf_range(F.position.x + 80, F.end.x - 80), rng.randf_range(F.position.y + 70, F.end.y - 70)), rng.randf_range(24, 56), Color(0, 0, 0, 0.3))
	for i in int(dec.get("litter", 18)):
		var p := Vector2(rng.randf_range(F.position.x + 40, F.end.x - 40), rng.randf_range(F.position.y + 30, F.end.y - 30))
		ci.draw_rect(Rect2(p, Vector2(rng.randf_range(2, 5), 1.6)), Color(0.5, 0.5, 0.58, 0.4))
	for i in 8:
		var a := 0.55 * (1.0 - float(i) / 8.0)
		var o := float(i) * 4.0
		if room.exit_side != "N" and room.entry_side != "N":
			ci.draw_rect(Rect2(F.position.x, F.position.y + o, F.size.x, 4.0), Color(0, 0, 0, a))
		if room.exit_side != "S" and room.entry_side != "S":
			ci.draw_rect(Rect2(F.position.x, F.end.y - o - 4.0, F.size.x, 4.0), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "W" and room.entry_side != "W":
			ci.draw_rect(Rect2(F.position.x + o, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "E" and room.entry_side != "E":
			ci.draw_rect(Rect2(F.end.x - o - 4.0, F.position.y, 4.0, F.size.y), Color(0, 0, 0, a * 0.8))


func _wall_n(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var w := x1 - x0
	var top := edge - FACE_H
	ci.draw_rect(Rect2(x0 - 70, top - 100, w + 140, 102), Color("05060c"))
	Gfx.grect_grad(ci, Rect2(x0, top, w, FACE_H), Color("3e4260"), Color("1a1d2e"))
	# ladrillos
	var row := 0
	var yy := top
	while yy < edge - 4.0:
		var off := 0.0 if row % 2 == 0 else 28.0
		var bx := x0 - off
		while bx < x1:
			var bw := 56.0
			var lx := maxf(bx, x0)
			var rx := minf(bx + bw, x1)
			if rx > lx:
				ci.draw_rect(Rect2(lx, yy, rx - lx, 1.6), Color(0, 0, 0, 0.5))
				ci.draw_rect(Rect2(lx, yy + 1.6, rx - lx, 1.2), Color(1, 1, 1, 0.04))
			if bx > x0:
				ci.draw_line(Vector2(bx, yy), Vector2(bx, yy + 18.0), Color(0, 0, 0, 0.5), 1.6)
			bx += bw
		yy += 18.0
		row += 1
	# arcos ciegos
	var ax := x0 + 60.0
	while ax < x1 - 60.0:
		var arch := PackedVector2Array()
		for k in 11:
			var a := PI + PI * float(k) / 10.0
			arch.append(Vector2(ax + cos(a) * 24.0, edge - 62.0 + sin(a) * 24.0))
		arch.append(Vector2(ax + 24.0, edge - 16.0))
		arch.append(Vector2(ax - 24.0, edge - 16.0))
		ci.draw_colored_polygon(arch, Color(0.02, 0.02, 0.05, 0.7))
		Gfx.outline(ci, arch, Color(0, 0, 0, 0.8), 3.0)
		ax += 150.0
	# zocalo
	ci.draw_rect(Rect2(x0, edge - 14.0, w, 14.0), INKC)
	ci.draw_rect(Rect2(x0, edge - 15.0, w, 2.0), Color(1, 1, 1, 0.12))
	# almenas
	Gfx.grect_grad(ci, Rect2(x0, top - 22.0, w, 24.0), Color("565a78"), Color("2e3148"))
	ci.draw_rect(Rect2(x0, top - 22.0, w, 3.0), Color(1, 1, 1, 0.2))
	var mx := x0 + 8.0
	while mx < x1 - 40.0:
		Gfx.grect_grad(ci, Rect2(mx, top - 50.0, 32.0, 30.0), Color("606480"), Color("34364e"))
		ci.draw_rect(Rect2(mx, top - 50.0, 32.0, 3.0), Color(1, 1, 1, 0.2))
		ci.draw_rect(Rect2(mx, top - 50.0, 2.0, 30.0), Color(0, 0, 0, 0.5))
		mx += 64.0
	var F := room.floor_rect
	if absf(edge - F.position.y) < 1.0:
		var d: Dictionary = room.dressing
		for tp in d.get("torches", []):
			var v: Vector2 = tp
			if v.x > x0 + 24.0 and v.x < x1 - 24.0:
				ci.draw_rect(Rect2(v.x - 3, edge - 96.0, 6, 34), INKC)
				Gfx.rrect(ci, Rect2(v.x - 9, edge - 104.0, 18, 14), 3.0, Color("5a4a3a"), Gfx.INK, 2.0)
		for bx2 in d.get("banners", []):
			if bx2 > x0 + 40.0 and bx2 < x1 - 40.0:
				ci.draw_line(Vector2(bx2 - 22, edge - 104.0), Vector2(bx2 + 22, edge - 104.0), Color("8a7a5a"), 4.0)
				var bp := PackedVector2Array([Vector2(bx2 - 18, edge - 102.0), Vector2(bx2 + 18, edge - 102.0), Vector2(bx2 + 18, edge - 42.0), Vector2(bx2, edge - 30.0), Vector2(bx2 - 18, edge - 42.0)])
				Gfx.gpoly(ci, bp, CRIM, Color("5a0a1e"), Gfx.INK, 2.0)
				ci.draw_line(Vector2(bx2, edge - 90.0), Vector2(bx2, edge - 52.0), Color("e0c070"), 3.0)
				ci.draw_line(Vector2(bx2 - 9, edge - 74.0), Vector2(bx2 + 9, edge - 74.0), Color("e0c070"), 3.0)


func _wall_s(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var sr := Rect2(x0, edge, x1 - x0, 140)
	Gfx.grect_grad(ci, sr, Color("3a3e58"), Color("14162a"))
	ci.draw_rect(Rect2(x0, edge, sr.size.x, 4), INKC)
	ci.draw_rect(Rect2(x0, edge + 4, sr.size.x, 2), Color(1, 1, 1, 0.16))
	var yy := edge + 20.0
	while yy < edge + 130.0:
		ci.draw_line(Vector2(x0, yy), Vector2(x1, yy), Color(0, 0, 0, 0.5), 2.0)
		yy += 22.0
	var sx := x0
	while sx < x1:
		ci.draw_line(Vector2(sx, edge + 4), Vector2(sx, edge + 140), INKC, 2.0)
		sx += 96.0


func _wall_we(ci: CanvasItem, room: Room, side: String, a: float, b: float, edge: float, ea: float, eb: float) -> void:
	var y0 := a - (142.0 if ea > 0.0 else 0.0)
	var y1 := b + (18.0 if eb > 0.0 else 0.0)
	var x0 := edge - 50.0 if side == "W" else edge
	Gfx.grect_grad(ci, Rect2(x0, y0, 50, y1 - y0), Color("3a3e58"), Color("171a2c"))
	var ex := edge - 4.0 if side == "W" else edge
	ci.draw_rect(Rect2(ex, a - 110.0, 4, b - a + 110.0), INKC)
	ci.draw_rect(Rect2(ex + (0.0 if side == "W" else 4.0), a - 110.0, 2, b - a + 110.0), Color(1, 1, 1, 0.13))
	var yy := y0 + 40.0
	while yy < y1:
		ci.draw_line(Vector2(x0, yy), Vector2(x0 + 50, yy), Color(0, 0, 0, 0.5), 2.0)
		ci.draw_line(Vector2(x0 + 25 + sin(yy) * 10.0, yy), Vector2(x0 + 25 + sin(yy) * 10.0, yy + 22.0), Color(0, 0, 0, 0.4), 1.6)
		yy += 22.0
	if ea > 0.0:
		ci.draw_rect(Rect2(x0, y0, 50, 36), Color("606480"))
		ci.draw_rect(Rect2(x0, y0, 50, 3), Color(1, 1, 1, 0.22))


func paint_lights(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		var pts := PackedVector2Array([Vector2(v.x - 20, F.position.y + 2), Vector2(v.x + 20, F.position.y + 2), Vector2(v.x + 160, F.position.y + 220), Vector2(v.x - 160, F.position.y + 220)])
		var cols := PackedColorArray([Color(1.0, 0.6, 0.25, 0.13), Color(1.0, 0.6, 0.25, 0.13), Color(1.0, 0.6, 0.25, 0.0), Color(1.0, 0.6, 0.25, 0.0)])
		ci.draw_polygon(pts, cols)
	for p in room.props:
		var c := p.foot.get_center()
		match p.kind:
			"table":
				Gfx.draw_glow(ci, c, 90.0, Color(1.0, 0.7, 0.3, 0.1))
			"statue":
				Gfx.draw_glow(ci, c, 100.0, Color(0.5, 0.55, 1.0, 0.06))


func paint_deco(ci: CanvasItem, room: Room, t: float) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "sigil":
		var pulse := 0.5 + 0.5 * sin(t * 1.5)
		ci.draw_arc(C, 150.0, t * 0.2, t * 0.2 + TAU * 0.7, 48, Color(CRIM, 0.18 + 0.2 * pulse), 3.0, true)
		Gfx.draw_glow(ci, C, 120.0, Color(CRIM, 0.05 + 0.05 * pulse))
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		var fl := 0.75 + 0.25 * sin(t * 12.0 + v.x * 0.1)
		var fy := F.position.y - 106.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(v.x - 7, fy), Vector2(v.x - 3, fy - 15 * fl), Vector2(v.x, fy - 7), Vector2(v.x + 4, fy - 19 * fl), Vector2(v.x + 7, fy)]), Color(1.0, 0.5, 0.12, 0.9))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(v.x - 3, fy), Vector2(v.x, fy - 10 * fl), Vector2(v.x + 3, fy)]), Color(1.0, 0.9, 0.5, 0.9))
		Gfx.draw_glow(ci, Vector2(v.x, fy - 8), 44.0, Color(1.0, 0.6, 0.2, 0.3 * fl))
		# brasas que suben
		for k in 3:
			var f := fposmod(t * 0.7 + float(k) * 0.33 + v.x * 0.01, 1.0)
			ci.draw_circle(Vector2(v.x + sin(f * 9.0 + float(k)) * 8.0, fy - 14.0 - f * 50.0), 1.4, Color(1.0, 0.7, 0.3, 0.7 * (1.0 - f)))
	for R in room.corridor_rects():
		var along_x := R.size.x > R.size.y
		var n := int(maxf(R.size.x, R.size.y) / 220.0)
		for k in n:
			var c := Vector2(R.position.x + 110.0 + k * 220.0, R.get_center().y) if along_x else Vector2(R.get_center().x, R.position.y + 110.0 + k * 220.0)
			Gfx.draw_glow(ci, c, 70.0, Color(1.0, 0.6, 0.25, 0.08 + 0.03 * sin(t * 5.0 + k)))


func paint_spawn(ci: CanvasItem, c: Vector2, o: float, t: float, i: int) -> void:
	var base := Gfx.ell_pts(c, 48.0, 28.0, 28)
	ci.draw_colored_polygon(base, Color(0.03, 0.02, 0.05, 0.85))
	Gfx.outline(ci, base, Color("4a3a66"), 4.0)
	Gfx.outline(ci, Gfx.ell_pts(c, 38.0, 22.0, 24), Color(0.6, 0.3, 1.0, 0.25 + 0.55 * o), 2.0)
	for k in 6:
		var a := TAU * float(k) / 6.0
		var p := c + Vector2(cos(a) * 30.0, sin(a) * 17.0)
		ci.draw_polyline(PackedVector2Array([p + Vector2(-3, 2), p + Vector2(0, -3), p + Vector2(3, 2)]), Color(0.7, 0.4, 1.0, 0.3 + 0.7 * o), 2.0, true)


func paint_spawn_glow(ci: CanvasItem, c: Vector2, g: float, t: float, i: int) -> void:
	if g > 0.01:
		var f := 0.7 + 0.3 * sin(t * 14.0 + i)
		Gfx.draw_glow(ci, c, 110.0 * g, Color(0.6, 0.25, 1.0, 0.42 * g * f))
		Gfx.draw_glow(ci, c, 50.0 * g, Color(0.9, 0.7, 1.0, 0.3 * g))
		for k in 6:
			var f2 := fposmod(t * 0.9 + float(k) / 6.0, 1.0)
			Gfx.draw_glow(ci, c + Vector2(sin(f2 * 7.0 + float(k)) * 20.0, -f2 * 46.0), 14.0 * g, Color(0.4, 0.15, 0.7, 0.4 * (1.0 - f2) * g))
	else:
		ci.draw_circle(c, 3.0, Color(0.5, 0.25, 0.9, 0.3 + 0.2 * sin(t * 2.0 + i)))


func _block_dressing(ci: CanvasItem, f: Rect2, top: Rect2, front: Rect2, style: String, t: float) -> void:
	var y := front.position.y + 14.0
	while y < front.end.y - 8.0:
		ci.draw_line(Vector2(front.position.x + 2, y), Vector2(front.end.x - 2, y), Color(0, 0, 0, 0.4), 1.6)
		y += 16.0
	ci.draw_rect(Rect2(front.position.x + 4, front.end.y - 7, front.size.x - 8, 3), Color(CRIM, 0.7))
