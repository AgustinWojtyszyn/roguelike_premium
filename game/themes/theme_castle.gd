class_name ThemeCastle
extends RoomTheme
## Capitulo 3: fortaleza oscura de caballeros. Losas frias, muros de ladrillo con almenas, antorchas, estandartes carmesi.

const SLATE_A := Color("2c3044")
const SLATE_B := Color("1a1d2c")
const TORCH := Color("ff9a3d")
const CRIM := Color("a01c3c")
const INKC := Color("07080f")

## Arte pre-renderizado (KayKit Dungeon Remastered, CC0) para suelo/muros/estandartes/antorchas. Si falta, se usa el dibujo vectorial original.
const PRE := "premium/dungeon/castle/"
const PREMIUM_ART := [
	"premium/dungeon/castle/floor_tile_small", "premium/dungeon/castle/floor_tile_small_broken_A", "premium/dungeon/castle/floor_tile_small_broken_B",
	"premium/dungeon/castle/floor_tile_small_weeds_A", "premium/dungeon/castle/floor_tile_small_decorated", "premium/dungeon/castle/floor_tile_grate",
	"premium/dungeon/castle/wall", "premium/dungeon/castle/wall_cracked", "premium/dungeon/castle/wall_arched", "premium/dungeon/castle/wall_window_closed",
	"premium/dungeon/castle/banner_red", "premium/dungeon/castle/banner_patternA_red", "premium/dungeon/castle/banner_shield_red", "premium/dungeon/castle/banner_thin_red",
	"premium/dungeon/castle/torch_mounted", "premium/dungeon/castle/sword_shield_gold",
]
const PROP_TINT := Color("e3e1f2")
const FLOOR_TINT := Color("8a90b8")
const WALL_TINT := Color("a9afd4")
const FLOOR_VARIANTS := [
	["floor_tile_small", 0.80], ["floor_tile_small_broken_A", 0.06], ["floor_tile_small_broken_B", 0.05],
	["floor_tile_small_weeds_A", 0.04], ["floor_tile_small_decorated", 0.03], ["floor_tile_grate", 0.02],
]
const WALL_VARIANTS := [["wall", 0.62], ["wall_cracked", 0.14], ["wall_arched", 0.14], ["wall_window_closed", 0.10]]
const TORCH_FLAME_Y := 56.0   # altura de la llama sobre el borde del muro (la antorcha premium cuelga a esa altura)


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
	# piezas de muro compuestas a mano (escudo heraldico, etc.) desplazan antorchas y banderas que choquen con ellas
	for wi in room.def.decor.get("wall_items", []):
		var wx: float = F.get_center().x + float(wi["x"])
		var kt: Array[Vector2] = []
		for v in torches:
			if absf(v.x - wx) > 80.0:
				kt.append(v)
		torches = kt
		var kb: Array[float] = []
		for bx in banners:
			if absf(bx - wx) > 70.0:
				kb.append(bx)
		banners = kb
	return {"torches": torches, "banners": banners}


func _pre(id: String) -> Dictionary:
	if not VisualProfiles.sprites_enabled():
		return {}
	var inf := AssetCatalog.info(PRE + id)
	if inf.is_empty() or AssetCatalog.tex(PRE + id) == null:
		return {}
	return inf


static func _pick(variants: Array, rng: RandomNumberGenerator) -> String:
	var r := rng.randf()
	var acc := 0.0
	for v in variants:
		acc += float(v[1])
		if r <= acc:
			return v[0]
	return variants[0][0]


## Suelo premium: losetas pre-renderizadas con la rejilla de la propia loseta (se hornea en RoomBake: coste cero en juego).
var _room: Room


func paint_floor(ci: CanvasItem, room: Room) -> void:
	_room = room
	super.paint_floor(ci, room)


## Variante de loseta segun la zona: ruinas junto a los muros, aro decorado alrededor del sigilo, carril central mas limpio.
func _zone_variant(p: Vector2, rng: RandomNumberGenerator) -> String:
	if _room != null and _room.def.decor.get("composed", false):
		var F := _room.floor_rect
		var edge := minf(minf(p.x - F.position.x, F.end.x - p.x), minf(p.y - F.position.y, F.end.y - p.y))
		var c: Vector2 = _room.def.decor.get("emblem_pos", F.get_center())
		var dc := p.distance_to(c)
		var r := rng.randf()
		if dc > 128.0 and dc < 172.0 and r < 0.55:
			return "floor_tile_small_decorated"
		if edge < 70.0:
			if r < 0.16:
				return "floor_tile_small_broken_A"
			if r < 0.30:
				return "floor_tile_small_broken_B"
			if r < 0.40:
				return "floor_tile_small_weeds_A"
		elif absf(p.y - c.y) < 60.0:
			return "floor_tile_small" if r < 0.97 else "floor_tile_grate"
		elif r < 0.05:
			return "floor_tile_small_broken_A"
		elif r > 0.985:
			return "floor_tile_grate"
		return "floor_tile_small"
	return _pick(FLOOR_VARIANTS, rng)


func _floor_premium(ci: CanvasItem, R: Rect2, seed_v: int) -> bool:
	var base := _pre("floor_tile_small")
	if base.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var sc: float = float(base["scale"])
	if _room != null and _room.def.decor.get("composed", false):
		sc *= 1.4
	var tw: float = float((base["size"] as Array)[0]) * sc
	ci.draw_rect(R, Color("14172a"))
	var y := R.position.y
	while y < R.end.y - 0.5:
		var x := R.position.x
		while x < R.end.x - 0.5:
			var id := _zone_variant(Vector2(x + tw * 0.5, y + tw * 0.5), rng)
			var inf := _pre(id)
			if inf.is_empty():
				inf = base
				id = "floor_tile_small"
			var w := minf(tw, R.end.x - x)
			var h := minf(tw, R.end.y - y)
			var tex := AssetCatalog.tex(PRE + id)
			var rot := int(rng.randi() % 4) if id == "floor_tile_small" else 0
			var tint := FLOOR_TINT
			if _room != null and _room.def.decor.get("composed", false):
				var center := _room.floor_rect.get_center()
				var distance := Vector2(x + tw * 0.5, y + tw * 0.5).distance_to(center)
				tint = Color("b0b5b2").lerp(Color("566779"), clampf(distance / 590.0, 0.0, 1.0))
			var src := Rect2(0, 0, w / sc, h / sc)
			if rot == 0 or w < tw or h < tw:
				ci.draw_texture_rect_region(tex, Rect2(x, y, w, h), src, tint)
			else:
				ci.draw_set_transform(Vector2(x + tw * 0.5, y + tw * 0.5), float(rot) * PI * 0.5, Vector2.ONE)
				ci.draw_texture_rect(tex, Rect2(-tw * 0.5, -tw * 0.5, tw, tw), false, tint)
				ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			x += tw
		y += tw
	return true


func _floor_panels(ci: CanvasItem, R: Rect2, seed_v: int) -> void:
	if _floor_premium(ci, R, seed_v):
		return
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
	if dec.get("composed", false):
		_benchmark_floor(ci, room)
	if dec.get("emblem", "") == "sigil" and not dec.get("composed", false):
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


## Authored stonework, cloth and directional contact shadows. All of this is in RoomBake.
func _benchmark_floor(ci: CanvasItem, room: Room) -> void:
	var f := room.floor_rect
	var c := f.get_center()
	var gold := Color("b49b70", 0.48)
	# A quiet walking lane, visually connecting the east/west combat entrances.
	var runner := Rect2(f.position.x, c.y - 49, f.size.x, 98)
	ci.draw_rect(runner, Color("311d2b", 0.84))
	for y in [c.y - 43, c.y + 43]:
		ci.draw_line(Vector2(f.position.x,y),Vector2(f.end.x,y),gold,1.5)
		ci.draw_line(Vector2(f.position.x,y + 4),Vector2(f.end.x,y + 4),Color("0b1019",0.7),1)
	# Inlaid octagonal dais; no change to walkability or collision.
	for spec in [[178.0, Color("090f18",0.9)], [173.0, Color("877758",0.65)], [170.0,Color("303e49")], [145.0,Color("54616a",0.7)], [142.0,Color("26333f")]]:
		var points := PackedVector2Array()
		for i in 8:
			points.append(c + Vector2.from_angle(TAU * float(i) / 8.0 + PI / 8.0) * float(spec[0]))
		ci.draw_colored_polygon(points,spec[1])
	for i in 8:
		var dir := Vector2.from_angle(TAU * float(i) / 8.0 + PI / 8.0)
		ci.draw_line(c + dir * 146,c + dir * 169,Color("121e29"),2)
		ci.draw_circle(c + dir * 158,2.0,gold)
	# Restrained heraldic compass, kept below actors and projectiles.
	for i in 4:
		var a := TAU * float(i) / 4.0
		var dir := Vector2.from_angle(a)
		var side := dir.orthogonal()
		ci.draw_colored_polygon(PackedVector2Array([c + dir * 100,c + side * 15,c - dir * 12]),Color("7f7762",0.55))
		ci.draw_colored_polygon(PackedVector2Array([c + dir * 100,c - side * 15,c - dir * 12]),Color("111d2a",0.8))
	ci.draw_arc(c,108,0,TAU,64,Color(gold,0.32),1,true)
	# Perimeter border and dark corners frame the playable center.
	ci.draw_rect(f.grow(-18),Color("080f19",0.4),false,16)
	ci.draw_rect(f.grow(-29),Color(gold,0.24),false,1)
	for prop in room.props:
		# Destructible cover keeps its own live shadow; never bake a ghost after destruction.
		if prop.kind not in ["column", "statue", "weapon_rack", "table"]:
			continue
		var foot: Rect2 = prop.foot
		var at := foot.get_center()
		var tall: bool = prop.kind in ["column","statue","weapon_rack"]
		var reach := Vector2(42,65) if tall else Vector2(20,30)
		var half := foot.size.x * 0.42
		var shape := PackedVector2Array([at + Vector2(-half,-3),at + Vector2(half,-3),at + reach + Vector2(half * 0.65,4),at + reach - Vector2(half * 0.65,-4)])
		ci.draw_polygon(shape,PackedColorArray([Color(0.01,0.02,0.04,0.42),Color(0.01,0.02,0.04,0.42),Color(0.01,0.02,0.04,0),Color(0.01,0.02,0.04,0)]))


## Franja de muro premium: tramos de la pieza `wall` (variantes aleatorias deterministas) entre x0 y x1 con su base en `base_y`.
func _wall_strip(ci: CanvasItem, x0: float, x1: float, y_anchor: float, tint: Color, seed_v: int, from_top: bool) -> bool:
	var base := _pre("wall")
	if base.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var sc: float = float(base["scale"])
	var tw: float = float((base["size"] as Array)[0]) * sc
	var th: float = float((base["size"] as Array)[1]) * sc
	var ay: float = float((base["anchor"] as Array)[1]) * sc
	var y0 := y_anchor if from_top else y_anchor - ay
	var x := x0
	while x < x1 - 0.5:
		var id := _pick(WALL_VARIANTS, rng)
		var tex := AssetCatalog.tex(PRE + id)
		if tex == null:
			tex = AssetCatalog.tex(PRE + "wall")
		var w := minf(tw, x1 - x)
		ci.draw_texture_rect_region(tex, Rect2(x, y0, w, th), Rect2(0, 0, w / sc, th / sc), tint)
		x += tw
	return true


func _wall_n(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var w := x1 - x0
	var top := edge - FACE_H
	if not _pre("wall").is_empty():
		ci.draw_rect(Rect2(x0 - 70, edge - 260, w + 140, 262), Color("05060c"))
		_wall_strip(ci, x0, x1, edge, WALL_TINT, 777 + int(x0), false)
		ci.draw_rect(Rect2(x0, edge - 2.0, w, 6.0), Color(0, 0, 0, 0.35))
		var F0 := room.floor_rect
		if absf(edge - F0.position.y) < 1.0:
			var d0: Dictionary = room.dressing
			for tp in d0.get("torches", []):
				var v0: Vector2 = tp
				if v0.x > x0 + 24.0 and v0.x < x1 - 24.0:
					_premium_sprite(ci, "torch_mounted", Vector2(v0.x, edge - 34.0), 1.5, WALL_TINT)
			var bi := 0
			var items: Array = room.def.decor.get("wall_items", [])
			for wi in items:
				var wx: float = room.floor_rect.get_center().x + float(wi["x"])
				if wx > x0 + 30.0 and wx < x1 - 30.0:
					_premium_sprite(ci, str(wi["art"]), Vector2(wx, edge - 44.0), float(wi.get("k", 1.0)), WALL_TINT)
			for bx0 in d0.get("banners", []):
				var clash := false
				for wi in items:
					if absf(bx0 - (room.floor_rect.get_center().x + float(wi["x"]))) < 70.0:
						clash = true
				if clash:
					bi += 1
					continue
				if bx0 > x0 + 40.0 and bx0 < x1 - 40.0:
					var bid: String = ["banner_red", "banner_patternA_red", "banner_shield_red", "banner_thin_red"][bi % 4]
					_premium_sprite(ci, bid, Vector2(bx0, edge - 10.0), 1.0, WALL_TINT)
				bi += 1
		return
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


## Dibuja una pieza premium con su ancla (origen del modelo) en `at`; `k` multiplica la escala de juego de la pieza.
func _premium_sprite(ci: CanvasItem, id: String, at: Vector2, k: float, tint: Color) -> void:
	var inf := _pre(id)
	if inf.is_empty():
		return
	var sc: float = float(inf["scale"]) * k
	var sz: Array = inf["size"]
	var an: Array = inf["anchor"]
	ci.draw_texture_rect(AssetCatalog.tex(PRE + id), Rect2(at.x - float(an[0]) * sc, at.y - float(an[1]) * sc, float(sz[0]) * sc, float(sz[1]) * sc), false, tint)


func _wall_s(ci: CanvasItem, room: Room, x0: float, x1: float, edge: float) -> void:
	var sr := Rect2(x0, edge, x1 - x0, 140)
	Gfx.grect_grad(ci, sr, Color("3a3e58"), Color("14162a"))
	if _wall_strip(ci, x0, x1, edge + 2.0, WALL_TINT.darkened(0.25), 991 + int(x0), true):
		ci.draw_rect(Rect2(x0, edge, x1 - x0, 3.0), INKC)
		return
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
	var pw := _pre("wall")
	if not pw.is_empty():
		# lateral: la misma pieza girada 90 grados y comprimida al ancho del muro lateral (cara interior en vista cenital)
		var sc: float = float(pw["scale"])
		var tw: float = float((pw["size"] as Array)[0]) * sc
		var th: float = float((pw["size"] as Array)[1]) * sc
		var yy := y0
		var rng := RandomNumberGenerator.new()
		rng.seed = 313 + int(edge)
		while yy < y1 - 0.5:
			var len_ := minf(tw, y1 - yy)
			var tex := AssetCatalog.tex(PRE + _pick(WALL_VARIANTS, rng))
			if side == "W":
				ci.draw_set_transform(Vector2(edge, yy), PI * 0.5, Vector2(1.0, 50.0 / th))
				ci.draw_texture_rect_region(tex, Rect2(0, 0, len_, th), Rect2(0, 0, len_ / sc, th / sc), WALL_TINT.darkened(0.2))
			else:
				ci.draw_set_transform(Vector2(edge, yy + len_), -PI * 0.5, Vector2(1.0, 50.0 / th))
				ci.draw_texture_rect_region(tex, Rect2(0, 0, len_, th), Rect2(0, 0, len_ / sc, th / sc), WALL_TINT.darkened(0.2))
			ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			yy += tw
		var ex2 := edge - 4.0 if side == "W" else edge
		ci.draw_rect(Rect2(ex2, a - 110.0, 4, b - a + 110.0), INKC)
		return
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
	for L in room.def.decor.get("lights", []):
		if not L.get("flicker", false):
			Gfx.draw_glow(ci, L["p"], float(L["r"]), Color(L["col"], float(L["a"])))
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		# Soft reflected firelight baked once, instead of triangular spotlight cones.
		Gfx.draw_glow(ci, Vector2(v.x, F.position.y + 24), 155, Color(1.0, 0.56, 0.24, 0.19))
		Gfx.draw_glow(ci, Vector2(v.x, F.position.y - 30), 68, Color(1.0, 0.7, 0.38, 0.18))
	for p in room.props:
		var c := p.foot.get_center()
		match p.kind:
			"table":
				Gfx.draw_glow(ci, c, 90.0, Color(1.0, 0.7, 0.3, 0.1))
			"statue":
				Gfx.draw_glow(ci, c, 100.0, Color(0.5, 0.55, 1.0, 0.06))


func paint_deco(ci: CanvasItem, room: Room, t: float) -> void:
	var F := room.floor_rect
	for L in room.def.decor.get("lights", []):
		if L.get("flicker", false):
			var fl := 0.8 + 0.2 * sin(t * 9.0 + float((L["p"] as Vector2).x) * 0.05) + 0.05 * sin(t * 23.0)
			Gfx.draw_glow(ci, L["p"], float(L["r"]) * (0.95 + 0.05 * fl), Color(L["col"], float(L["a"]) * fl))
	var dec: Dictionary = room.def.decor
	var C: Vector2 = dec.get("emblem_pos", F.get_center())
	if dec.get("emblem", "") == "sigil" and not dec.get("composed", false):
		var pulse := 0.5 + 0.5 * sin(t * 1.5)
		ci.draw_arc(C, 150.0, t * 0.2, t * 0.2 + TAU * 0.7, 48, Color(CRIM, 0.18 + 0.2 * pulse), 3.0, true)
		Gfx.draw_glow(ci, C, 120.0, Color(CRIM, 0.05 + 0.05 * pulse))
	for tp in room.dressing.get("torches", []):
		var v: Vector2 = tp
		if room.in_exit_gap(v.x, "N"):
			continue
		var fl := 0.75 + 0.25 * sin(t * 12.0 + v.x * 0.1)
		var fy := F.position.y - (TORCH_FLAME_Y if not _pre("wall").is_empty() else 106.0)
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
