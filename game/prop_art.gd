class_name PropArt
extends RefCounted
## Props tematicos de los capitulos 2-4 y extras del capitulo 1. Todos se dibujan desde el Prop (y-sort, altura `h`).

## kind -> {h, hp, shadow}. hp > 0 => destructible.
const STATS := {
	"block": {"h": 78.0, "hp": 0.0},
	"rack": {"h": 66.0, "hp": 0.0},
	"reactor": {"h": 96.0, "hp": 0.0},
	"crate_m": {"h": 44.0, "hp": 9.0},
	"stone_block": {"h": 44.0, "hp": 0.0},
	"urn": {"h": 38.0, "hp": 5.0},
	"totem": {"h": 100.0, "hp": 0.0},
	"brazier": {"h": 42.0, "hp": 0.0},
	"glyph_pillar": {"h": 84.0, "hp": 0.0},
	"wood_crate": {"h": 36.0, "hp": 7.0},
	"wood_barrel": {"h": 40.0, "hp": 6.0},
	"column": {"h": 92.0, "hp": 0.0},
	"statue": {"h": 88.0, "hp": 0.0},
	"table": {"h": 30.0, "hp": 0.0},
	"weapon_rack": {"h": 54.0, "hp": 0.0},
	"crystal": {"h": 74.0, "hp": 0.0},
	"rift_stone": {"h": 52.0, "hp": 0.0},
	"anomaly_box": {"h": 36.0, "hp": 7.0},
	"orb_pillar": {"h": 90.0, "hp": 0.0},
}


## Dibuja el prop con arte importado si hay perfil y la textura carga; si no, devuelve false (dibujo procedural).
static func _imported(p: Prop, kind: String, f: Rect2) -> bool:
	if not VisualProfiles.sprites_enabled():
		return false
	var pr := VisualProfiles.prop(kind)
	if pr.is_empty():
		return false
	var arts: Array = pr["art"]
	var id: String = arts[p.seed_v % arts.size()]
	var tex := AssetCatalog.tex(id)
	if tex == null:
		return false
	var info: Dictionary = AssetManifest.STATIC.get(AssetManifest.ALIASES.get(id, id), {})
	var bb: Array = info.get("bbox", [0, 0, tex.get_width(), tex.get_height()])
	var bw := maxf(1.0, float(bb[2]) - float(bb[0]))
	var bh := maxf(1.0, float(bb[3]) - float(bb[1]))
	var s := 1.0
	var hmul := float(pr.get("hmul", 1.0))
	if pr["fit"] == "w":
		s = minf(f.size.x * 1.05 / bw, p.h * 1.4 / bh)
	else:
		s = minf(p.h * hmul / bh, maxf(f.size.x, 40.0) * 1.7 / bw)
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST if absf(s - roundf(s)) < 0.08 else CanvasItem.TEXTURE_FILTER_LINEAR
	var base_y := f.end.y - f.size.y * 0.18
	var cx := f.position.x + f.size.x * 0.5
	p._shadow(f, 6.0)
	p.draw_texture_rect_region(tex, Rect2(cx - bw * s * 0.5, base_y - bh * s, bw * s, bh * s), Rect2(float(bb[0]), float(bb[1]), bw, bh))
	return true


static func paint(p: Prop, kind: String, f: Rect2) -> void:
	if _imported(p, kind, f):
		return
	match kind:
		"block":
			p.game.room.theme.paint_block(p, f, p.h, p.style, p.tt)
		"rack":
			_rack(p, f)
		"reactor":
			_reactor(p, f)
		"crate_m":
			p._crate(f, p.h, Color("4a5671"), false)
		"stone_block":
			_stone_block(p, f)
		"urn":
			_urn(p, f)
		"totem":
			_totem(p, f)
		"brazier":
			_brazier(p, f)
		"glyph_pillar":
			_glyph_pillar(p, f)
		"wood_crate":
			_wood_crate(p, f)
		"wood_barrel":
			_wood_barrel(p, f)
		"column":
			_column(p, f)
		"statue":
			_statue(p, f)
		"table":
			_table(p, f)
		"weapon_rack":
			_weapon_rack(p, f)
		"crystal":
			_crystal(p, f)
		"rift_stone":
			_rift_stone(p, f)
		"anomaly_box":
			_anomaly_box(p, f)
		"orb_pillar":
			_orb_pillar(p, f)


## Colores de los fragmentos al romperse: [color_fragmentos, color_chispa]
static func break_palette(kind: String) -> Array:
	match kind:
		"urn":
			return [Color("a0603a"), Color("ffcf7a")]
		"wood_crate", "wood_barrel":
			return [Color("6a4a2c"), Color("ffcf7a")]
		"anomaly_box":
			return [Color("5a3a7a"), Color("ff4fd8")]
		"crate_m":
			return [Color("4a5572"), Color("8fe8ff")]
	return []


# ------------------------------------------------------------------ tech
static func _rack(p: Prop, f: Rect2) -> void:
	p._shadow(f, 8.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("4a5677"), Color("333e5c"), Color("2a3350"), Color("141a2c"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var rows := int((p.h - 10.0) / 9.0)
	for i in rows:
		var y := front.position.y + 6.0 + float(i) * 9.0
		p.draw_rect(Rect2(front.position.x + 4, y, front.size.x - 8, 6.0), Color("0c1020"))
		var on := (int(p.tt * 3.0 + float(i * 7 + p.seed_v % 5)) % 3) != 0
		for k in 4:
			p.draw_circle(Vector2(front.position.x + 9 + k * 6.0, y + 3.0), 1.2, Color("3df2dc") if (on and k % 2 == 0) else Color("1a6e66"))
		p.draw_rect(Rect2(front.end.x - 16, y + 1, 10, 4), Color("141c30"))
	p.draw_circle(Vector2(front.end.x - 8, front.position.y + 4), 1.6, Color("ff8a3d") if int(p.tt * 2.0) % 2 == 0 else Color("5a2f18"))


static func _reactor(p: Prop, f: Rect2) -> void:
	p._shadow(f, 28.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5
	var ry := f.size.y * 0.5
	Gfx.gell(p, Vector2(cx, base), rx, ry, Color("2d3652"), Color("1a2036"), ink, 2.0)
	var body := Rect2(cx - rx * 0.86, base - p.h, rx * 1.72, p.h)
	Gfx.grrect(p, body, 6.0, Color("56648e"), Color("262e4c"), ink, 2.0)
	var win := Rect2(cx - rx * 0.55, base - p.h + 14, rx * 1.1, p.h - 34)
	Gfx.rrect(p, win, 12.0, Color("06141c"), ink, 2.0)
	var pulse := 0.6 + 0.4 * sin(p.tt * 3.0)
	var coreh := (win.size.y - 8) * (0.55 + 0.1 * pulse)
	Gfx.grrect(p, Rect2(win.position.x + 4, win.end.y - 4 - coreh, win.size.x - 8, coreh), 8.0, Color("7ffff0"), Color("12a09a"), Color(0, 0, 0, 0), 0.0)
	for yy in [base - p.h + 4.0, base - 10.0, base - p.h * 0.5]:
		p.draw_rect(Rect2(cx - rx * 0.86, yy, rx * 1.72, 5.0), Color("1a2036"))
		p.draw_rect(Rect2(cx - rx * 0.86, yy, rx * 1.72, 1.5), Color(1, 1, 1, 0.16))
	Gfx.gell(p, Vector2(cx, base - p.h), rx * 0.86, ry * 0.86, Color("8793b8"), Color("4b587e"), ink, 2.0)
	Gfx.ell(p, Vector2(cx, base - p.h), rx * 0.4, ry * 0.4, Color("232a45"), ink, 1.6)


# ------------------------------------------------------------------ azteca tecnologica
static func _stone_block(p: Prop, f: Rect2) -> void:
	p._shadow(f, 8.0)
	p._box(f, p.h, Color("8a7a62"), Color("6a5c48"), Color("5a4e3c"), Color("3a3226"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	# greca tallada
	var y := front.position.y + p.h * 0.5
	var n := int(front.size.x / 12.0)
	for i in n:
		var x := front.position.x + 6.0 + i * 12.0
		p.draw_polyline(PackedVector2Array([Vector2(x, y + 4), Vector2(x, y - 4), Vector2(x + 6, y - 4), Vector2(x + 6, y)]), Color("2a2418"), 1.8)
	p.draw_line(Vector2(front.position.x + 3, front.position.y + 4), Vector2(front.end.x - 3, front.position.y + 4), Color("c8b08a", 0.5), 1.4)
	p.draw_rect(Rect2(front.position.x + 4, front.end.y - 7, front.size.x - 8, 2), Color("3dd9a8", 0.55 + 0.25 * sin(p.tt * 2.0)))


static func _urn(p: Prop, f: Rect2) -> void:
	p._shadow(f, 4.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5 + 1.0
	var h := p.h
	var body := PackedVector2Array([Vector2(cx - rx * 0.6, base - h), Vector2(cx + rx * 0.6, base - h), Vector2(cx + rx * 1.05, base - h * 0.55), Vector2(cx + rx * 0.7, base), Vector2(cx - rx * 0.7, base), Vector2(cx - rx * 1.05, base - h * 0.55)])
	Gfx.gpoly(p, body, Color("c2764a"), Color("6e3a22"), ink, 2.0)
	p.draw_line(Vector2(cx - rx * 0.9, base - h * 0.62), Vector2(cx + rx * 0.9, base - h * 0.62), Color("3dd9a8"), 2.4)
	p.draw_line(Vector2(cx - rx * 0.8, base - h * 0.4), Vector2(cx + rx * 0.8, base - h * 0.4), Color("e8c06a"), 1.6)
	Gfx.ell(p, Vector2(cx, base - h), rx * 0.62, f.size.y * 0.3, Color("2a1810"), ink, 1.8)
	p.draw_line(Vector2(cx - rx * 0.4, base - h * 0.85), Vector2(cx - rx * 0.7, base - h * 0.35), Color(1, 1, 1, 0.25), 1.6)


static func _totem(p: Prop, f: Rect2) -> void:
	p._shadow(f, 12.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("9a8a70"), Color("6e6048"), Color("5e5240"), Color("30281c"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var cx := front.position.x + front.size.x * 0.5
	# tres caras talladas superpuestas
	for k in 3:
		var y := front.position.y + 10.0 + float(k) * (p.h - 20.0) / 3.0
		var w := front.size.x - 10.0
		Gfx.rrect(p, Rect2(cx - w * 0.5, y, w, (p.h - 20.0) / 3.0 - 4.0), 3.0, Color("7a6a50"), ink, 1.4)
		p.draw_rect(Rect2(cx - w * 0.3, y + 5, w * 0.2, 4), Color("3dd9a8"))
		p.draw_rect(Rect2(cx + w * 0.1, y + 5, w * 0.2, 4), Color("3dd9a8"))
		p.draw_rect(Rect2(cx - w * 0.25, y + 13, w * 0.5, 3), Color("2a2418"))
	Gfx.draw_glow(p, Vector2(cx, front.position.y + 14.0), 22.0, Color(0.24, 0.85, 0.65, 0.2 + 0.1 * sin(p.tt * 2.5)))
	var top := Rect2(f.position.x - 2, f.position.y - p.h - 2, f.size.x + 4, f.size.y + 4)
	Gfx.poly(p, PackedVector2Array([Vector2(top.position.x, top.end.y), Vector2(cx, top.position.y - 16), Vector2(top.end.x, top.end.y)]), Color("b8a888"), ink, 2.0)


static func _brazier(p: Prop, f: Rect2) -> void:
	p._shadow(f, 8.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5
	Gfx.grrect(p, Rect2(cx - rx * 0.45, base - p.h * 0.7, rx * 0.9, p.h * 0.7), 3.0, Color("7a6a52"), Color("3e3426"), ink, 2.0)
	Gfx.gell(p, Vector2(cx, base - p.h * 0.7), rx * 1.1, f.size.y * 0.42, Color("8a7a60"), Color("4a3e2e"), ink, 2.0)
	Gfx.ell(p, Vector2(cx, base - p.h * 0.72), rx * 0.8, f.size.y * 0.3, Color("1a0e08"), Color(0, 0, 0, 0), 0.0)
	var fl := 0.8 + 0.2 * sin(p.tt * 14.0 + float(p.seed_v % 7))
	var fy := base - p.h * 0.78
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx - rx * 0.6, fy), Vector2(cx - rx * 0.2, fy - 18 * fl), Vector2(cx, fy - 8), Vector2(cx + rx * 0.25, fy - 22 * fl), Vector2(cx + rx * 0.6, fy)]), Color(1.0, 0.55, 0.15, 0.95))
	p.draw_colored_polygon(PackedVector2Array([Vector2(cx - rx * 0.3, fy), Vector2(cx, fy - 13 * fl), Vector2(cx + rx * 0.3, fy)]), Color(1.0, 0.9, 0.5, 0.95))
	Gfx.draw_glow(p, Vector2(cx, fy - 8), 46.0, Color(1.0, 0.6, 0.2, 0.25 * fl))


static func _glyph_pillar(p: Prop, f: Rect2) -> void:
	p._shadow(f, 12.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("8e7e66"), Color("665a46"), Color("54483a"), Color("2c261c"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var gx := front.position.x + front.size.x * 0.5
	var glow := 0.6 + 0.4 * sin(p.tt * 2.0 + float(p.seed_v % 5))
	for k in 4:
		var y := front.position.y + 10.0 + float(k) * (p.h - 16.0) / 4.0
		p.draw_rect(Rect2(gx - 6, y, 12, 3), Color(0.24, 0.85, 0.65, 0.55 + 0.35 * glow))
		p.draw_rect(Rect2(gx - 2, y + 5, 4, 7), Color(0.24, 0.85, 0.65, 0.4 + 0.4 * glow))
	var top := Rect2(f.position.x - 3, f.position.y - p.h - 3, f.size.x + 6, f.size.y + 6)
	Gfx.grrect(p, top, 3.0, Color("b8a888"), Color("7e705a"), ink, 2.0)


# ------------------------------------------------------------------ fortaleza oscura
static func _wood_crate(p: Prop, f: Rect2) -> void:
	p._shadow(f)
	var ink := Gfx.INK
	p._box(f, p.h, Color("8a6a44"), Color("6a4e30"), Color("5e4430"), Color("34241a"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var top := Rect2(f.position.x, f.position.y - p.h, f.size.x, f.size.y)
	for k in 3:
		var y := front.position.y + 4.0 + float(k) * front.size.y / 3.0
		p.draw_line(Vector2(front.position.x + 2, y), Vector2(front.end.x - 2, y), Color(0, 0, 0, 0.35), 1.4)
	p.draw_line(top.position + Vector2(5, 5), top.end - Vector2(5, 5), Color(0, 0, 0, 0.3), 1.6)
	p.draw_line(Vector2(top.end.x - 5, top.position.y + 5), Vector2(top.position.x + 5, top.end.y - 5), Color(0, 0, 0, 0.3), 1.6)
	for cx in [front.position.x + 3.0, front.end.x - 7.0]:
		p.draw_rect(Rect2(cx, front.position.y, 4, front.size.y), Color("3a3a48"))
		p.draw_circle(Vector2(cx + 2, front.position.y + 5), 1.2, Color("8a8aa0"))


static func _wood_barrel(p: Prop, f: Rect2) -> void:
	p._shadow(f, 4.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var base := f.end.y - f.size.y * 0.5
	var rx := f.size.x * 0.5 + 1.0
	var ry := f.size.y * 0.5
	var body := PackedVector2Array([Vector2(cx - rx * 0.88, base - p.h), Vector2(cx + rx * 0.88, base - p.h), Vector2(cx + rx * 1.08, base - p.h * 0.5), Vector2(cx + rx, base), Vector2(cx - rx, base), Vector2(cx - rx * 1.08, base - p.h * 0.5)])
	Gfx.gpoly(p, body, Color("8a6038"), Color("3e2814"), ink, 2.0)
	Gfx.ell(p, Vector2(cx, base), rx, ry, Color("3e2814"), ink, 2.0)
	for yy in [base - p.h * 0.8, base - p.h * 0.2]:
		p.draw_rect(Rect2(cx - rx * 1.02, yy, rx * 2.04, 4.0), Color("2a2a38"))
		p.draw_rect(Rect2(cx - rx * 1.02, yy, rx * 2.04, 1.4), Color(1, 1, 1, 0.14))
	Gfx.gell(p, Vector2(cx, base - p.h), rx * 0.88, ry * 0.9, Color("a07848"), Color("6a4a28"), ink, 2.0)
	p.draw_arc(Vector2(cx, base - p.h), rx * 0.5, 0, TAU, 14, Color(0, 0, 0, 0.3), 1.2)


static func _column(p: Prop, f: Rect2) -> void:
	p._shadow(f, 14.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("6a6a82"), Color("4a4a60"), Color("3e3e54"), Color("1e1e2c"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	for k in 3:
		var x := front.position.x + 6.0 + float(k) * (front.size.x - 12.0) / 2.0
		p.draw_line(Vector2(x, front.position.y + 8), Vector2(x, front.end.y - 6), Color(0, 0, 0, 0.35), 2.0)
		p.draw_line(Vector2(x + 2, front.position.y + 8), Vector2(x + 2, front.end.y - 6), Color(1, 1, 1, 0.1), 1.2)
	p.draw_rect(Rect2(front.position.x - 2, front.end.y - 8, front.size.x + 4, 8), Color("34344a"))
	var top := Rect2(f.position.x - 4, f.position.y - p.h - 4, f.size.x + 8, f.size.y + 8)
	Gfx.grrect(p, top, 3.0, Color("8a8aa4"), Color("52526a"), ink, 2.0)
	p.draw_circle(top.get_center(), 4.0, Color("2a2a3c"))


static func _statue(p: Prop, f: Rect2) -> void:
	p._shadow(f, 12.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var by := f.end.y
	# plinto
	Gfx.grrect(p, Rect2(f.position.x, by - 20, f.size.x, 20), 2.0, Color("6a6a82"), Color("34344a"), ink, 2.0)
	# caballero de piedra: cuerpo
	var top := by - p.h
	Gfx.gpoly(p, PackedVector2Array([Vector2(cx - 12, by - 20), Vector2(cx + 12, by - 20), Vector2(cx + 15, by - 46), Vector2(cx + 9, top + 20), Vector2(cx - 9, top + 20), Vector2(cx - 15, by - 46)]), Color("8a8aa2"), Color("4a4a62"), ink, 2.0)
	Gfx.ell(p, Vector2(cx, top + 12), 9.0, 10.0, Color("9a9ab4"), ink, 2.0)
	p.draw_rect(Rect2(cx - 5, top + 9, 10, 3), Color("14141e"))
	Gfx.poly(p, PackedVector2Array([Vector2(cx - 3, top + 3), Vector2(cx, top - 6), Vector2(cx + 3, top + 3)]), Color("c0c0d6"), ink, 1.4)
	# espada clavada
	p.draw_line(Vector2(cx, top + 24), Vector2(cx, by - 22), ink, 5.0)
	p.draw_line(Vector2(cx, top + 24), Vector2(cx, by - 22), Color("c8c8e0"), 2.4)
	p.draw_line(Vector2(cx - 10, top + 28), Vector2(cx + 10, top + 28), Color("d8c070"), 3.0)
	p.draw_circle(Vector2(cx + 3, top + 12), 1.2, Color("ff5a3a"))


static func _table(p: Prop, f: Rect2) -> void:
	p._shadow(f, 6.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("8a6a44"), Color("6a4e30"), Color("4a3422"), Color("261a12"))
	var top := Rect2(f.position.x, f.position.y - p.h, f.size.x, f.size.y)
	p.draw_line(top.position + Vector2(8, top.size.y * 0.5), Vector2(top.end.x - 8, top.position.y + top.size.y * 0.5), Color(0, 0, 0, 0.25), 1.4)
	# velas
	var c := top.position + Vector2(top.size.x * 0.25, top.size.y * 0.4)
	p.draw_rect(Rect2(c.x - 2, c.y - 9, 4, 9), Color("e8e0c8"))
	var fl := 0.8 + 0.2 * sin(p.tt * 12.0 + float(p.seed_v % 5))
	p.draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -9), c + Vector2(0, -15 * fl), c + Vector2(2, -9)]), Color(1.0, 0.75, 0.3))
	Gfx.draw_glow(p, c + Vector2(0, -10), 26.0, Color(1.0, 0.7, 0.3, 0.2 * fl))


static func _weapon_rack(p: Prop, f: Rect2) -> void:
	p._shadow(f, 6.0)
	var ink := Gfx.INK
	p._box(f, p.h, Color("5e4a36"), Color("40322a"), Color("3a2c22"), Color("1e1610"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var n := int(front.size.x / 18.0)
	for i in n:
		var x := front.position.x + 10.0 + float(i) * 18.0
		p.draw_line(Vector2(x, front.position.y + 6), Vector2(x - 2, front.end.y - 6), ink, 4.0, true)
		p.draw_line(Vector2(x, front.position.y + 6), Vector2(x - 2, front.end.y - 6), Color("b8bcd0"), 2.0, true)
		p.draw_rect(Rect2(x - 5, front.position.y + 18, 10, 3), Color("d8c070"))
	p.draw_rect(Rect2(front.position.x + 2, front.position.y + 4, front.size.x - 4, 3), Color("2a2230"))


# ------------------------------------------------------------------ interdimensional
static func _crystal(p: Prop, f: Rect2) -> void:
	p._shadow(f, 14.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var by := f.end.y - f.size.y * 0.3
	var pulse := 0.6 + 0.4 * sin(p.tt * 2.4 + float(p.seed_v % 7))
	for k in 3:
		var dx := float(k - 1) * f.size.x * 0.28
		var hh := p.h * (1.0 - absf(float(k - 1)) * 0.32)
		var w := f.size.x * 0.2
		var col := Color("7a4aff").lerp(Color("ff4fd8"), float(k) * 0.4)
		Gfx.gpoly(p, PackedVector2Array([Vector2(cx + dx - w, by), Vector2(cx + dx - w * 0.7, by - hh * 0.7), Vector2(cx + dx, by - hh), Vector2(cx + dx + w * 0.7, by - hh * 0.7), Vector2(cx + dx + w, by)]), col.lightened(0.25), col.darkened(0.45), ink, 2.0)
		p.draw_line(Vector2(cx + dx - w * 0.3, by - hh * 0.2), Vector2(cx + dx - w * 0.2, by - hh * 0.75), Color(1, 1, 1, 0.5), 1.6)
	Gfx.draw_glow(p, Vector2(cx, by - p.h * 0.5), 60.0, Color(0.7, 0.3, 1.0, 0.22 * pulse))


static func _rift_stone(p: Prop, f: Rect2) -> void:
	p._shadow(f, 6.0)
	var ink := Gfx.INK
	var cx := f.position.x + f.size.x * 0.5
	var fy := f.end.y - 14.0 - 6.0 * sin(p.tt * 1.6 + float(p.seed_v % 5))
	var s := f.size.x * 0.5
	Gfx.gpoly(p, PackedVector2Array([Vector2(cx - s, fy), Vector2(cx - s * 0.7, fy - p.h * 0.6), Vector2(cx, fy - p.h), Vector2(cx + s * 0.8, fy - p.h * 0.55), Vector2(cx + s, fy - 4), Vector2(cx, fy + 6)]), Color("5a4a86"), Color("1e1636"), ink, 2.2)
	p.draw_line(Vector2(cx - s * 0.2, fy - p.h * 0.9), Vector2(cx + s * 0.1, fy - p.h * 0.2), Color("ff4fd8"), 2.0)
	Gfx.draw_glow(p, Vector2(cx, fy - p.h * 0.45), 34.0, Color(1.0, 0.3, 0.85, 0.16))


static func _anomaly_box(p: Prop, f: Rect2) -> void:
	p._shadow(f)
	p._box(f, p.h, Color("5a4a86"), Color("3a2e5e"), Color("3a2e5e"), Color("1a1230"))
	var front := Rect2(f.position.x, f.end.y - p.h, f.size.x, p.h)
	var a := 0.5 + 0.5 * sin(p.tt * 3.0 + float(p.seed_v % 6))
	p.draw_rect(Rect2(front.position.x + 5, front.position.y + p.h * 0.5 - 2, front.size.x - 10, 4), Color(1.0, 0.3, 0.85, 0.5 + 0.4 * a))
	p.draw_circle(Vector2(front.end.x - 9, front.position.y + 8), 2.4, Color(0.4, 1.0, 0.9, 0.5 + 0.5 * a))


static func _orb_pillar(p: Prop, f: Rect2) -> void:
	p._shadow(f, 12.0)
	var ink := Gfx.INK
	p._box(f, p.h * 0.7, Color("4a3e72"), Color("302654"), Color("2a2046"), Color("120c24"))
	var cx := f.position.x + f.size.x * 0.5
	var oy := f.position.y - p.h * 0.7 - 16.0 + sin(p.tt * 2.0 + float(p.seed_v % 5)) * 4.0
	Gfx.ell(p, Vector2(cx, oy), 11.0, 11.0, Color("c8a0ff"), ink, 2.0)
	p.draw_circle(Vector2(cx - 3, oy - 3), 3.4, Color(1, 1, 1, 0.75))
	p.draw_arc(Vector2(cx, oy), 16.0, p.tt * 2.0, p.tt * 2.0 + TAU * 0.6, 14, Color(1.0, 0.4, 0.9, 0.8), 2.0, true)
	Gfx.draw_glow(p, Vector2(cx, oy), 48.0, Color(0.75, 0.4, 1.0, 0.25))
