class_name MenuStyle
extends RefCounted
## Presentation-only design system. Gameplay HUD keeps UiKit.
const INK := Color("070d14")
const PANEL := Color("101d29")
const PANEL_HI := Color("1b2b39")
const EDGE := Color("d7bb85")
const ORANGE := Color("e9b86e")
const GOLD := Color("edca87")
const TEXT := Color("f4f0e6")
const DIM := Color("a1b3c0")
const DANGER := Color("f18c89")
const OK := Color("8dd7c0")
const GEM := Color("b8a2e2")
const BODY = preload("res://assets/ui/fonts/Barlow-Regular.ttf")
const BOLD = preload("res://assets/ui/fonts/Barlow-SemiBold.ttf")
const DISPLAY = preload("res://assets/ui/fonts/BarlowCondensed-SemiBold.ttf")
static var _art: Dictionary = {}

static func font() -> Font:
	return BOLD

static func font_reg() -> Font:
	return BODY

static func text(ci: CanvasItem, pos: Vector2, s: String, fs: int, col: Color = TEXT, align: int = 0, width: float = -1.0, _outline: float = 0.0, bold: bool = true) -> void:
	var face: Font = DISPLAY if fs >= 26 else (BOLD if bold else BODY)
	ci.draw_string(face, pos, s, align as HorizontalAlignment, width, fs, col)

static func paragraph(ci: CanvasItem, r: Rect2, s: String, fs: int = 18, col: Color = DIM) -> void:
	var p := TextParagraph.new()
	p.add_string(s, BODY, fs)
	p.width = r.size.x
	p.max_lines_visible = maxi(1, int(r.size.y / (fs * 1.25)))
	p.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	p.draw(ci.get_canvas_item(), r.position, col)

static func text_width(s: String, fs: int, bold: bool = true) -> float:
	var face: Font = DISPLAY if fs >= 26 else (BOLD if bold else BODY)
	return face.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x

static func box(fill: Color, edge: Color, radius: int = 12, border: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = edge
	s.set_border_width_all(border)
	s.set_corner_radius_all(radius)
	return s

static func panel(ci: CanvasItem, r: Rect2, fill: Color = PANEL, edge: Color = Color(EDGE, 0.25), _cut: float = 12.0, alpha: float = 1.0, _grad: bool = true) -> void:
	if r.size.x <= 0 or r.size.y <= 0:
		return
	var surface := PANEL.lerp(fill, 0.22)
	surface.a = fill.a * alpha
	ci.draw_style_box(box(Color(0, 0, 0, 0.18 * alpha), Color.TRANSPARENT), Rect2(r.position + Vector2(0, 5), r.size))
	ci.draw_style_box(box(surface, Color(edge, minf(edge.a, 0.65) * alpha)), r)
	ci.draw_line(r.position + Vector2(16, 1), Vector2(r.end.x - 16, r.position.y + 1), Color(edge, 0.25 * alpha), 1)

static func chunky(ci: CanvasItem, r: Rect2, top: Color, _bot: Color, press: float = 0.0, hover: float = 0.0, _cut: float = 12.0, _outline: float = 1.0) -> Rect2:
	var body := Rect2(r.position + Vector2(0, press * 2), r.size - Vector2(0, 2))
	var warm := top.r > 0.7 and top.g > 0.4 and top.b < 0.6
	var fill := GOLD.darkened(0.1) if warm else PANEL_HI.lerp(top, 0.20)
	ci.draw_style_box(box(fill.lightened(hover * 0.08), GOLD if warm else Color(top, 0.45), 8), body)
	return body

static func pill(ci: CanvasItem, r: Rect2, fill: Color, edge: Color, _line: float = 1.0) -> void:
	ci.draw_style_box(box(fill, Color(edge, 0.35), int(r.size.y / 2)), r)

static func bar(ci: CanvasItem, r: Rect2, frac: float, col: Color, bg: Color = Color("263744"), _segments: int = 0) -> void:
	ci.draw_style_box(box(bg, Color.TRANSPARENT, 3, 0), r)
	if frac > 0.0:
		ci.draw_style_box(box(col, Color.TRANSPARENT, 3, 0), Rect2(r.position, Vector2(r.size.x * clampf(frac, 0, 1), r.size.y)))

static func gradient_rect(ci: CanvasItem, r: Rect2, top: Color, bottom: Color) -> void:
	UiKit.gradient_rect(ci, r, top, bottom)

static func format_int(n: int) -> String:
	return UiKit.format_int(n)

static func art(chapter: String) -> Texture2D:
	if not _art.has(chapter):
		var path := "res://assets/premium/presentation/backdrops/%s.jpg" % chapter
		_art[chapter] = load(path) if ResourceLoader.exists(path) else load("res://assets/premium/presentation/fortress.png")
	return _art[chapter]

static func cover(ci: CanvasItem, r: Rect2, texture: Texture2D, tint: Color = Color.WHITE) -> void:
	var ts := texture.get_size()
	var k := maxf(r.size.x / ts.x, r.size.y / ts.y)
	var src := r.size / k
	ci.draw_texture_rect_region(texture, r, Rect2((ts - src) * 0.5, src), tint)

static func shade_left(ci: CanvasItem, r: Rect2, strength: float = 1.0) -> void:
	ci.draw_polygon(PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]), PackedColorArray([Color(INK, strength), Color(INK, 0.10), Color(INK, 0.10), Color(INK, strength)]))

static func background(ci: CanvasItem, r: Rect2) -> void:
	ci.draw_rect(r, INK)
	cover(ci, r, art("ch4"), Color(0.32, 0.4, 0.5, 0.35))
	shade_left(ci, r)
	gradient_rect(ci, r, Color(INK, 0.1), Color(INK, 0.94))

static func portrait(ci: CanvasItem, char_id: String, r: Rect2, skin_id: String = "", tint: Color = Color.WHITE) -> void:
	# The cached portraits are 160x176. Preserve their proportions in wide offer cards.
	var fitted := Vector2(160, 176) * minf(r.size.x / 160.0, r.size.y / 176.0)
	PortraitCache.draw(ci, char_id, Rect2(r.get_center() - fitted * 0.5, fitted), skin_id, tint)
