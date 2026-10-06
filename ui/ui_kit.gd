class_name UiKit
extends RefCounted
## Lenguaje visual de la interfaz: paneles de esquinas cortadas, botones gruesos con contorno, barras y texto con borde.
## Todo vectorial y barato de dibujar; la misma paleta que el juego (tinta oscura + cian + naranja + oro).

const INK := Color("070a13")
const PANEL := Color("0d1424")
const PANEL_HI := Color("18223a")
const EDGE := Color("27e0cc")
const ORANGE := Color("ff8a3d")
const GOLD := Color("ffd24a")
const TEXT := Color("e8f6ff")
const DIM := Color("8fa8c8")
const DANGER := Color("ff5f7a")
const OK := Color("5fffc8")
const GEM := Color("c47bff")

static var _font_bold: FontVariation
static var _font_reg: Font


static func font() -> Font:
	if _font_bold == null:
		_font_reg = ThemeDB.fallback_font
		_font_bold = FontVariation.new()
		_font_bold.base_font = _font_reg
		_font_bold.variation_embolden = 0.55
	return _font_bold


static func font_reg() -> Font:
	font()
	return _font_reg


## Texto con borde. align: 0 izq, 1 centro, 2 der (usa `width` como caja).
static func text(ci: CanvasItem, pos: Vector2, s: String, size: int, col: Color = TEXT, align: int = 0, width: float = -1.0, outline: float = 0.0, bold: bool = true) -> void:
	var f := font() if bold else font_reg()
	var a := HORIZONTAL_ALIGNMENT_LEFT
	if align == 1:
		a = HORIZONTAL_ALIGNMENT_CENTER
	elif align == 2:
		a = HORIZONTAL_ALIGNMENT_RIGHT
	if outline > 0.0:
		ci.draw_string_outline(f, pos, s, a, width, size, int(outline), Color(INK, col.a))
	ci.draw_string(f, pos, s, a, width, size, col)


static func text_width(s: String, size: int, bold: bool = true) -> float:
	var f := font() if bold else font_reg()
	return f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func cut_poly(r: Rect2, cut: float = 10.0, cut_br: bool = true) -> PackedVector2Array:
	var c := minf(cut, minf(r.size.x, r.size.y) * 0.45)
	if cut_br:
		return PackedVector2Array([r.position + Vector2(c, 0), Vector2(r.end.x, r.position.y), Vector2(r.end.x, r.end.y - c), Vector2(r.end.x - c, r.end.y), Vector2(r.position.x, r.end.y), Vector2(r.position.x, r.position.y + c)])
	return PackedVector2Array([r.position + Vector2(c, 0), Vector2(r.end.x - c, r.position.y), Vector2(r.end.x, r.position.y + c), Vector2(r.end.x, r.end.y), Vector2(r.position.x + c, r.end.y), Vector2(r.position.x, r.end.y - c)])


static func panel(ci: CanvasItem, r: Rect2, fill: Color = PANEL, edge: Color = Color(EDGE, 0.55), cut: float = 12.0, alpha: float = 1.0, grad: bool = true) -> void:
	if r.size.x < 6.0 or r.size.y < 6.0:
		return
	var pts := cut_poly(r, cut)
	var top := Color(fill.lightened(0.12), fill.a * alpha)
	var bot := Color(fill.darkened(0.25), fill.a * alpha)
	if grad:
		var cols := PackedColorArray()
		var span := maxf(r.size.y, 1.0)
		for p in pts:
			cols.append(top.lerp(bot, clampf((p.y - r.position.y) / span, 0.0, 1.0)))
		ci.draw_polygon(pts, cols)
	else:
		ci.draw_colored_polygon(pts, Color(fill, fill.a * alpha))
	var line := pts.duplicate()
	line.append(pts[0])
	ci.draw_polyline(line, edge, 2.0, true)


## Boton "chunky": cuerpo con degradado, brillo superior, sombra inferior gruesa y contorno de tinta.
static func chunky(ci: CanvasItem, r: Rect2, top: Color, bot: Color, press: float = 0.0, hover: float = 0.0, cut: float = 14.0, outline: float = 3.0) -> Rect2:
	if r.size.x < 12.0 or r.size.y < 14.0:
		return r
	var off := press * 4.0
	var body := Rect2(r.position + Vector2(0, off), r.size - Vector2(0, 5.0))
	# sombra / canto inferior
	var base := Rect2(r.position + Vector2(0, 5.0), body.size)
	var bp := cut_poly(base, cut)
	ci.draw_colored_polygon(bp, bot.darkened(0.45))
	var bl := bp.duplicate()
	bl.append(bp[0])
	ci.draw_polyline(bl, INK, outline, true)
	var pts := cut_poly(body, cut)
	var cols := PackedColorArray()
	var span := maxf(body.size.y, 1.0)
	var t1 := top.lightened(hover * 0.15)
	var b1 := bot.lightened(hover * 0.1)
	for p in pts:
		cols.append(t1.lerp(b1, clampf((p.y - body.position.y) / span, 0.0, 1.0)))
	ci.draw_polygon(pts, cols)
	# brillo
	var hl := Rect2(body.position + Vector2(cut * 0.6, 3), Vector2(body.size.x - cut * 1.4, body.size.y * 0.32))
	ci.draw_rect(hl, Color(1, 1, 1, 0.16 + hover * 0.08))
	var line := pts.duplicate()
	line.append(pts[0])
	ci.draw_polyline(line, INK, outline, true)
	return body


static func bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, bg: Color = Color(0.1, 0.14, 0.26, 1.0), segments: int = 0) -> void:
	ci.draw_rect(r.grow(2.0), INK)
	ci.draw_rect(r, bg)
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y)), col)
		ci.draw_rect(Rect2(r.position, Vector2(r.size.x * f, r.size.y * 0.4)), Color(1, 1, 1, 0.28))
	if segments > 1:
		for i in range(1, segments):
			var x := r.position.x + r.size.x * float(i) / float(segments)
			ci.draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color(0, 0, 0, 0.6), 1.5)


static func gradient_rect(ci: CanvasItem, r: Rect2, top: Color, bot: Color) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([top, top, bot, bot]))


static func pill(ci: CanvasItem, r: Rect2, fill: Color, edge: Color = Color(INK, 1.0), w: float = 2.0) -> void:
	if r.size.x < 6.0 or r.size.y < 6.0:
		return
	var rad := r.size.y * 0.5
	var pts := Gfx.rr_pts(r, rad, 6)
	ci.draw_colored_polygon(pts, fill)
	Gfx.outline(ci, pts, edge, w)


static func rarity_color(tier: int) -> Color:
	return Rarity.color(tier)


## Brillo suave (para fondos).
static func glow(ci: CanvasItem, p: Vector2, r: float, col: Color) -> void:
	Gfx.draw_glow(ci, p, r, col)


static func format_int(n: int) -> String:
	var s := str(absi(n))
	var out := ""
	var cnt := 0
	for i in range(s.length() - 1, -1, -1):
		out = s[i] + out
		cnt += 1
		if cnt % 3 == 0 and i > 0:
			out = "." + out
	return ("-" if n < 0 else "") + out
