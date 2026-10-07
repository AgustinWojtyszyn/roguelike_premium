class_name Gfx
extends RefCounted
## Helpers de dibujo vectorial + geometria 2D usados por todo el juego.

const INK := Color("070a13")

static var _glow_tex: GradientTexture2D
static var _flash_shader: Shader
static var _add_mat: CanvasItemMaterial


static func glow() -> Texture2D:
	if _glow_tex == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.22, 0.55, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.5), Color(1, 1, 1, 0.1), Color(1, 1, 1, 0)])
		_glow_tex = GradientTexture2D.new()
		_glow_tex.gradient = g
		_glow_tex.fill = GradientTexture2D.FILL_RADIAL
		_glow_tex.fill_from = Vector2(0.5, 0.5)
		_glow_tex.fill_to = Vector2(1.0, 0.5)
		_glow_tex.width = 128
		_glow_tex.height = 128
	return _glow_tex


static func add_material() -> CanvasItemMaterial:
	if _add_mat == null:
		_add_mat = CanvasItemMaterial.new()
		_add_mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return _add_mat


static func flash_material() -> ShaderMaterial:
	if _flash_shader == null:
		_flash_shader = Shader.new()
		_flash_shader.code = "shader_type canvas_item;\nuniform float flash : hint_range(0.0, 1.0) = 0.0;\nvoid fragment() { COLOR.rgb = mix(COLOR.rgb, vec3(1.0), flash); }\n"
	var m := ShaderMaterial.new()
	m.shader = _flash_shader
	return m


static func draw_glow(ci: CanvasItem, pos: Vector2, r: float, col: Color) -> void:
	ci.draw_texture_rect(glow(), Rect2(pos.x - r, pos.y - r, r * 2.0, r * 2.0), false, col)


static func ell_pts(c: Vector2, rx: float, ry: float, n: int = 22, rot: float = 0.0) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * float(i) / float(n)
		var p := Vector2(cos(a) * rx, sin(a) * ry)
		if rot != 0.0:
			p = p.rotated(rot)
		pts.append(c + p)
	return pts


static func rr_pts(r: Rect2, rad: float, seg: int = 4) -> PackedVector2Array:
	rad = maxf(0.05, minf(rad, minf(r.size.x, r.size.y) * 0.5 - 0.04))   # evita puntos coincidentes (poligono degenerado)
	var pts := PackedVector2Array()
	var corners := [
		[Vector2(r.end.x - rad, r.position.y + rad), -PI * 0.5],
		[Vector2(r.end.x - rad, r.end.y - rad), 0.0],
		[Vector2(r.position.x + rad, r.end.y - rad), PI * 0.5],
		[Vector2(r.position.x + rad, r.position.y + rad), PI],
	]
	for cr in corners:
		var c: Vector2 = cr[0]
		var a0: float = cr[1]
		for i in seg + 1:
			var a: float = a0 + (PI * 0.5) * float(i) / float(seg)
			pts.append(c + Vector2(cos(a), sin(a)) * rad)
	return pts


static func outline(ci: CanvasItem, pts: PackedVector2Array, line: Color, w: float) -> void:
	var p := pts.duplicate()
	p.append(pts[0])
	ci.draw_polyline(p, line, w, true)


static var polycheck := false


static func poly(ci: CanvasItem, pts: PackedVector2Array, fill: Color, line: Color = INK, w: float = 2.0) -> void:
	if polycheck and Geometry2D.triangulate_polygon(pts).is_empty():
		print("BAD POLY ", pts)
		print_stack()
	ci.draw_colored_polygon(pts, fill)
	if w > 0.0:
		outline(ci, pts, line, w)


## Poligono con degradado vertical (top -> bot) + contorno.
static func gpoly(ci: CanvasItem, pts: PackedVector2Array, top: Color, bot: Color, line: Color = INK, w: float = 2.0) -> void:
	var mn := INF
	var mx := -INF
	for p in pts:
		mn = minf(mn, p.y)
		mx = maxf(mx, p.y)
	var span := maxf(mx - mn, 0.001)
	if polycheck and Geometry2D.triangulate_polygon(pts).is_empty():
		print("BAD GPOLY ", pts)
		print_stack()
	var cols := PackedColorArray()
	for p in pts:
		cols.append(top.lerp(bot, (p.y - mn) / span))
	ci.draw_polygon(pts, cols)
	if w > 0.0:
		outline(ci, pts, line, w)


## Rectangulo plano con degradado vertical (sin contorno).
static func grect_grad(ci: CanvasItem, r: Rect2, top: Color, bot: Color) -> void:
	var pts := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])
	ci.draw_polygon(pts, PackedColorArray([top, top, bot, bot]))


static func ell(ci: CanvasItem, c: Vector2, rx: float, ry: float, fill: Color, line: Color = INK, w: float = 2.0) -> void:
	poly(ci, ell_pts(c, rx, ry), fill, line, w)


static func gell(ci: CanvasItem, c: Vector2, rx: float, ry: float, top: Color, bot: Color, line: Color = INK, w: float = 2.0) -> void:
	gpoly(ci, ell_pts(c, rx, ry, 24), top, bot, line, w)


static func rrect(ci: CanvasItem, r: Rect2, rad: float, fill: Color, line: Color = INK, w: float = 2.0) -> void:
	poly(ci, rr_pts(r, rad), fill, line, w)


static func grrect(ci: CanvasItem, r: Rect2, rad: float, top: Color, bot: Color, line: Color = INK, w: float = 2.0) -> void:
	gpoly(ci, rr_pts(r, rad), top, bot, line, w)


## Rectangulo dibujable con transform (para pivots / partes).
static func limb(ci: CanvasItem, pts: PackedVector2Array, col: Color, w: float, line: Color = INK) -> void:
	ci.draw_polyline(pts, line, w + 3.0, true)
	ci.draw_polyline(pts, col, w, true)
	for p in pts:
		ci.draw_circle(p, (w + 3.0) * 0.5, line)
	for p in pts:
		ci.draw_circle(p, w * 0.5, col)


## IK de dos huesos: devuelve el codo.
static func elbow(s: Vector2, h: Vector2, l1: float, l2: float, bend: float) -> Vector2:
	var d := s.distance_to(h)
	d = clampf(d, 0.001, l1 + l2 - 0.01)
	var dir := (h - s).normalized()
	var a := (l1 * l1 - l2 * l2 + d * d) / (2.0 * d)
	var hh := sqrt(maxf(l1 * l1 - a * a, 0.0))
	return s + dir * a + Vector2(-dir.y, dir.x) * hh * bend


## Interseccion segmento-rect (slab). Devuelve t de entrada en [0,1] o -1.
static func seg_rect(a: Vector2, b: Vector2, r: Rect2) -> float:
	var d := b - a
	var t0 := 0.0
	var t1 := 1.0
	for axis in 2:
		var da: float = d[axis]
		var aa: float = a[axis]
		var lo: float = r.position[axis]
		var hi: float = r.end[axis]
		if absf(da) < 0.000001:
			if aa < lo or aa > hi:
				return -1.0
		else:
			var ta := (lo - aa) / da
			var tb := (hi - aa) / da
			if ta > tb:
				var tmp := ta
				ta = tb
				tb = tmp
			t0 = maxf(t0, ta)
			t1 = minf(t1, tb)
			if t0 > t1:
				return -1.0
	return t0


static func rect_normal(r: Rect2, p: Vector2) -> Vector2:
	var dl := absf(p.x - r.position.x)
	var dr := absf(p.x - r.end.x)
	var dt := absf(p.y - r.position.y)
	var db := absf(p.y - r.end.y)
	var m := minf(minf(dl, dr), minf(dt, db))
	if m == dl:
		return Vector2.LEFT
	if m == dr:
		return Vector2.RIGHT
	if m == dt:
		return Vector2.UP
	return Vector2.DOWN


static func seg_point_dist2(a: Vector2, b: Vector2, p: Vector2) -> float:
	var ab := b - a
	var l2 := ab.length_squared()
	if l2 < 0.0001:
		return a.distance_squared_to(p)
	var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0)
	return (a + ab * t).distance_squared_to(p)


## Empuja un circulo fuera de los rectangulos (deslizamiento natural, sin engancharse).
static func push_out(p: Vector2, r: float, rects: Array) -> Vector2:
	for _i in 3:
		var moved := false
		for rc in rects:
			var rr: Rect2 = rc
			var cp := Vector2(clampf(p.x, rr.position.x, rr.end.x), clampf(p.y, rr.position.y, rr.end.y))
			var d := p - cp
			var l2 := d.length_squared()
			if l2 < r * r:
				moved = true
				if l2 > 0.0001:
					p = cp + d / sqrt(l2) * r
				else:
					var dl := p.x - rr.position.x
					var dr := rr.end.x - p.x
					var dt := p.y - rr.position.y
					var db := rr.end.y - p.y
					var m := minf(minf(dl, dr), minf(dt, db))
					if m == dl:
						p.x = rr.position.x - r
					elif m == dr:
						p.x = rr.end.x + r
					elif m == dt:
						p.y = rr.position.y - r
					else:
						p.y = rr.end.y + r
		if not moved:
			break
	return p


static func ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)
