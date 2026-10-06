class_name ThemeAnomaly
extends RoomTheme
## Capitulo 4: interdimensional. Suelo fracturado flotando sobre el vacio, muros de cristal, grietas de neon magenta/cian.

const VOID_A := Color("1a0f30")
const VOID_B := Color("0a0518")
const MAG := Color("ff4fd8")
const CYAN := Color("4fffe8")


func _init() -> void:
	id = "anomaly"
	accent = MAG
	void_col = Color("030012")
	tile = 80.0
	block_top = [Color("5a3a9a"), Color("2e1c5a")]
	block_front = [Color("3a2470"), Color("120a2a")]
	block_trim = MAG


func spawn_color() -> Color:
	return Color("ff4fd8")


func build_dressing(room: Room, rng: RandomNumberGenerator) -> Dictionary:
	var F := room.floor_rect
	var shards: Array[Dictionary] = []
	for i in 14:
		shards.append({"p": Vector2(rng.randf_range(F.position.x - 220.0, F.end.x + 220.0), rng.randf_range(F.position.y - 120.0, F.end.y + 160.0)), "s": rng.randf_range(8.0, 22.0), "ph": rng.randf() * 6.0})
	return {"shards": shards}


func _floor_panels(ci: CanvasItem, R: Rect2, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var ts := tile
	# estrellas del vacio bajo las losas
	ci.draw_rect(R, VOID_B)
	for i in int(R.size.x * R.size.y / 5000.0):
		ci.draw_circle(R.position + Vector2(rng.randf() * R.size.x, rng.randf() * R.size.y), rng.randf_range(0.6, 1.6), Color(0.8, 0.7, 1.0, rng.randf_range(0.2, 0.7)))
	var cols := int(R.size.x / ts)
	var rows := int(R.size.y / ts)
	for ix in cols:
		for iy in rows:
			var x := R.position.x + ix * ts
			var y := R.position.y + iy * ts
			var k := rng.randf()
			if k < 0.08:
				continue   # hueco al vacio
			var base := VOID_A.lerp(Color("2a1650"), rng.randf() * 0.8)
			# losa poligonal irregular
			var j := 5.0
			var pts := PackedVector2Array([Vector2(x + rng.randf_range(1, j), y + rng.randf_range(1, j)), Vector2(x + ts - rng.randf_range(1, j), y + rng.randf_range(1, j)), Vector2(x + ts - rng.randf_range(1, j), y + ts - rng.randf_range(1, j)), Vector2(x + rng.randf_range(1, j), y + ts - rng.randf_range(1, j))])
			ci.draw_colored_polygon(pts, base)
			var edge_col := Color(MAG if rng.randf() < 0.5 else CYAN, 0.18)
			Gfx.outline(ci, pts, edge_col, 1.6)
			ci.draw_line(pts[0], pts[1], Color(1, 1, 1, 0.08), 1.6)
			if k < 0.22:
				var c := Vector2(x + ts * 0.5, y + ts * 0.5)
				var tri := PackedVector2Array([c + Vector2(0, -14), c + Vector2(12, 8), c + Vector2(-12, 8)])
				Gfx.outline(ci, tri, Color(CYAN, 0.35), 1.8)
			elif k < 0.34:
				var p0 := Vector2(x + rng.randf_range(10, 40), y + rng.randf_range(6, 20))
				var cr := PackedVector2Array([p0])
				for s in 4:
					p0 += Vector2(rng.randf_range(-18, 18), rng.randf_range(4, 16))
					cr.append(p0)
				ci.draw_polyline(cr, Color(0, 0, 0, 0.7), 3.0, true)
				ci.draw_polyline(cr, Color(MAG, 0.6), 1.2, true)


func _floor_extras(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "tri":
		for k in 3:
			var rr := 70.0 + float(k) * 36.0
			var tri := PackedVector2Array()
			for q in 3:
				tri.append(C + Vector2.from_angle(-PI * 0.5 + TAU * float(q) / 3.0 + float(k) * 0.5) * rr)
			Gfx.outline(ci, tri, Color(0, 0, 0, 0.5), 6.0)
			Gfx.outline(ci, tri, Color(MAG if k % 2 == 0 else CYAN, 0.3), 1.8)
	for i in 8:
		var a := 0.55 * (1.0 - float(i) / 8.0)
		var o := float(i) * 4.0
		if room.exit_side != "N" and room.entry_side != "N":
			ci.draw_rect(Rect2(F.position.x, F.position.y + o, F.size.x, 4.0), Color(0, 0, 0, a * 0.8))
		if room.exit_side != "S" and room.entry_side != "S":
			ci.draw_rect(Rect2(F.position.x, F.end.y - o - 4.0, F.size.x, 4.0), Color(0, 0, 0, a * 0.7))


func _facet(ci: CanvasItem, x0: float, x1: float, top: float, bot: float, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	Gfx.grect_grad(ci, Rect2(x0, top, x1 - x0, bot - top), Color("3a2470"), Color("0c0620"))
	var x := x0
	while x < x1:
		var w := rng.randf_range(40.0, 90.0)
		var pts := PackedVector2Array([Vector2(x, bot), Vector2(x + w * 0.4, top + rng.randf_range(0, 20)), Vector2(minf(x + w, x1), bot)])
		ci.draw_colored_polygon(pts, Color(0.35 + rng.randf() * 0.2, 0.15, 0.6, 0.35))
		ci.draw_line(pts[0], pts[1], Color(MAG if rng.randf() < 0.5 else CYAN, 0.55), 1.8)
		x += w * 0.8


func _wall_n(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var top := edge - FACE_H
	ci.draw_rect(Rect2(x0 - 70, top - 100, x1 - x0 + 140, 102), Color("02000c"))
	_facet(ci, x0, x1, top, edge, int(x0) + 17)
	ci.draw_rect(Rect2(x0, edge - 14.0, x1 - x0, 14.0), Color("06020f"))
	ci.draw_rect(Rect2(x0, edge - 15.0, x1 - x0, 2.0), Color(MAG, 0.6))
	# cornisa de cristal irregular
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x0) + 3
	var px := x0
	while px < x1:
		var w := rng.randf_range(22.0, 50.0)
		var h := rng.randf_range(14.0, 44.0)
		var pts := PackedVector2Array([Vector2(px, top), Vector2(px + w * 0.5, top - h), Vector2(px + w, top)])
		ci.draw_colored_polygon(pts, Color(0.28, 0.12, 0.5))
		ci.draw_line(pts[0], pts[1], Color(CYAN, 0.6), 1.6)
		px += w


func _wall_s(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	_facet(ci, x0, x1, edge, edge + 140.0, int(x0) + 5)
	ci.draw_rect(Rect2(x0, edge, x1 - x0, 3), Color(MAG, 0.5))


func _wall_we(ci: CanvasItem, room: Room, side: String, a: float, b: float, edge: float) -> void:
	var y0 := a - 142.0
	var y1 := b + 18.0
	var x0 := edge - 50.0 if side == "W" else edge
	Gfx.grect_grad(ci, Rect2(x0, y0, 50, y1 - y0), Color("35206a"), Color("0c0620"))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(a) + 9
	var y := y0 + 20.0
	while y < y1 - 20.0:
		var h := rng.randf_range(30.0, 70.0)
		ci.draw_line(Vector2(x0 + 4, y), Vector2(x0 + 46, y + h), Color(MAG if rng.randf() < 0.5 else CYAN, 0.45), 1.6)
		y += h
	var ex := edge - 4.0 if side == "W" else edge
	ci.draw_rect(Rect2(ex, a - 110.0, 4, b - a + 110.0), Color("02000c"))
	ci.draw_rect(Rect2(ex + (0.0 if side == "W" else 4.0), a - 110.0, 2, b - a + 110.0), Color(CYAN, 0.35))
	ci.draw_rect(Rect2(x0, y0, 50, 34), Color("4a2a90"))


func paint_lights(ci: CanvasItem, room: Room) -> void:
	var F := room.floor_rect
	Gfx.draw_glow(ci, F.get_center(), minf(F.size.x, F.size.y) * 0.5, Color(0.6, 0.2, 0.9, 0.08))
	for p in room.props:
		var c := p.foot.get_center()
		match p.kind:
			"crystal":
				Gfx.draw_glow(ci, c, 120.0, Color(0.7, 0.3, 1.0, 0.14))
			"orb_pillar":
				Gfx.draw_glow(ci, c + Vector2(0, -50), 110.0, Color(0.8, 0.4, 1.0, 0.12))
			"rift_stone":
				Gfx.draw_glow(ci, c, 70.0, Color(1.0, 0.3, 0.85, 0.08))


func paint_deco(ci: CanvasItem, room: Room, t: float) -> void:
	var F := room.floor_rect
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "tri":
		for k in 3:
			var rr := 70.0 + float(k) * 36.0
			var tri := PackedVector2Array()
			for q in 3:
				tri.append(C + Vector2.from_angle(-PI * 0.5 + TAU * float(q) / 3.0 + float(k) * 0.5 + t * (0.25 + float(k) * 0.12)) * rr)
			Gfx.outline(ci, tri, Color(MAG if k % 2 == 0 else CYAN, 0.3 + 0.2 * sin(t * 2.0 + k)), 2.4)
	for s in room.dressing.get("shards", []):
		var p: Vector2 = s["p"]
		var sz: float = s["s"]
		var y := p.y + sin(t * 0.9 + float(s["ph"])) * 10.0
		var pts := PackedVector2Array([Vector2(p.x, y - sz), Vector2(p.x + sz * 0.6, y), Vector2(p.x, y + sz), Vector2(p.x - sz * 0.6, y)])
		ci.draw_colored_polygon(pts, Color(0.6, 0.25, 1.0, 0.14))
		Gfx.outline(ci, pts, Color(CYAN if int(float(s["ph"])) % 2 == 0 else MAG, 0.5), 1.4)
	# grietas del vacio que laten
	var pulse := 0.5 + 0.5 * sin(t * 2.0)
	Gfx.draw_glow(ci, Vector2(F.get_center().x, F.end.y - 20.0), F.size.x * 0.4, Color(MAG, 0.03 + 0.03 * pulse))
	for R in room.corridor_rects():
		var along_x := R.size.x > R.size.y
		var n := int(maxf(R.size.x, R.size.y) / 200.0)
		for k in n:
			var c := Vector2(R.position.x + 100.0 + k * 200.0, R.get_center().y) if along_x else Vector2(R.get_center().x, R.position.y + 100.0 + k * 200.0)
			Gfx.draw_glow(ci, c, 66.0, Color(0.8, 0.3, 1.0, 0.08 + 0.03 * sin(t * 3.0 + k)))


func paint_spawn(ci: CanvasItem, c: Vector2, o: float, t: float, i: int) -> void:
	# grieta en el suelo: elipse oscura con bordes de neon
	var rift := Gfx.ell_pts(c, 44.0 * (0.6 + 0.4 * o), 24.0 * (0.6 + 0.4 * o), 24)
	ci.draw_colored_polygon(rift, Color(0.01, 0.0, 0.05, 0.9))
	Gfx.outline(ci, rift, Color(MAG, 0.5 + 0.5 * o), 3.0)


func paint_spawn_glow(ci: CanvasItem, c: Vector2, g: float, t: float, i: int) -> void:
	if g > 0.01:
		var f := 0.7 + 0.3 * sin(t * 18.0 + i)
		Gfx.draw_glow(ci, c, 120.0 * g, Color(1.0, 0.3, 0.85, 0.4 * g * f))
		for k in 3:
			ci.draw_arc(c, (16.0 + float(k) * 12.0) * g + 4.0, t * 6.0 + float(k), t * 6.0 + float(k) + 2.4, 14, Color(CYAN, 0.6 * g), 2.0, true)
	else:
		ci.draw_circle(c, 3.0, Color(MAG, 0.35 + 0.2 * sin(t * 2.0 + i)))


func _block_dressing(ci: CanvasItem, f: Rect2, top: Rect2, front: Rect2, style: String, t: float) -> void:
	ci.draw_line(Vector2(front.position.x + 4, front.position.y + 16), Vector2(front.end.x - 4, front.end.y - 14), Color(MAG, 0.6), 1.8)
	ci.draw_line(Vector2(front.end.x - 4, front.position.y + 10), Vector2(front.position.x + 10, front.end.y - 20), Color(CYAN, 0.4), 1.4)
	ci.draw_rect(Rect2(front.position.x + 4, front.end.y - 7, front.size.x - 8, 3), Color(MAG, 0.5 + 0.2 * sin(t * 3.0)))
