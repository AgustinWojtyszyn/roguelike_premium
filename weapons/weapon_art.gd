class_name WeaponArt
extends RefCounted
## Dibujo vectorial de las armas. Todas apuntan a +x con el agarre en el origen.
## `heat` (0..1) enciende los nucleos; `t` anima piezas vivas (drones, arcos, aspas).

static func paint(ci: CanvasItem, w: WeaponData, heat: float = 0.0, t: float = 0.0) -> void:
	var pal: Dictionary = w.palette
	var glow: Color = pal.get("glow", w.color)
	match w.art:
		"pulsar": _pulsar(ci, heat)
		"maul": _maul(ci, heat)
		"lance": _lance(ci, heat)
		"pistol": _pistol(ci, pal, glow, heat)
		"burst_rifle": _burst_rifle(ci, pal, glow, heat)
		"minigun": _minigun(ci, pal, glow, heat, t)
		"plasma": _plasma(ci, pal, glow, heat, t)
		"grenade": _grenade(ci, pal, glow, heat)
		"arc": _arc(ci, pal, glow, heat, t)
		"bouncer": _bouncer(ci, pal, glow, heat)
		"pod": _pod(ci, pal, glow, heat)
		"blade": _blade(ci, pal, glow, heat, t)
		"claws": _claws(ci, pal, glow, heat)
		"nest": _nest(ci, pal, glow, heat, t)
		"anomaly": _anomaly(ci, pal, heat, t)
		"charge_rail": _charge_rail(ci, pal, glow, heat, t)
		"flamer": _flamer(ci, pal, glow, heat, t)
		"sniper": _sniper(ci, pal, glow, heat)
		_: _pulsar(ci, heat)


static func _c(pal: Dictionary, key: String, d: Color) -> Color:
	return pal.get(key, d)


# ---------------------------------------------------------------- las 3 originales (sin cambios visuales)
static func _pulsar(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	Gfx.poly(ci, PackedVector2Array([Vector2(-3, 2), Vector2(4.5, 2), Vector2(6, 11), Vector2(-1.5, 12)]), Color("232a3f"), ink, 2.0)
	Gfx.gell(ci, Vector2(12, 7.5), 5.5, 5.0, Color("4b5878"), Color("252d45"), ink, 2.0)
	Gfx.ell(ci, Vector2(12, 7.5), 2.6, 2.2, Color("3df2dc"), Color(0, 0, 0, 0), 0.0)
	Gfx.grrect(ci, Rect2(-9, -6.5, 29, 12), 3.0, Color("7684a8"), Color("2c3552"), ink, 2.0)
	Gfx.rrect(ci, Rect2(-7, -4.5, 12, 3.0), 1.0, Color("a9b6d4"), Color(0, 0, 0, 0), 0.0)
	ci.draw_rect(Rect2(-4, -1.2, 19, 2.4), Color("0c2a33"))
	ci.draw_rect(Rect2(-3, -0.8, 17, 1.6), Color("3df2dc").lerp(Color.WHITE, heat * 0.6))
	ci.draw_rect(Rect2(3, -5.5, 6, 2.2), Color("141a2b"))
	Gfx.grrect(ci, Rect2(19, -4.6, 13, 8.6), 2.0, Color("4a5675"), Color("1f2640"), ink, 2.0)
	for k in 3:
		ci.draw_line(Vector2(22 + k * 3.2, -3.2), Vector2(22 + k * 3.2, 2.6), Color("11172a"), 1.4)
	Gfx.rrect(ci, Rect2(31.5, -5.6, 4.0, 10.4), 1.2, Color("2c3552"), ink, 1.8)
	ci.draw_rect(Rect2(32.2, -1.0, 2.5, 2.0), Color("3df2dc").lerp(Color.WHITE, heat))
	Gfx.poly(ci, PackedVector2Array([Vector2(1, -6.5), Vector2(14, -6.5), Vector2(12, -9), Vector2(3, -9)]), Color("39445f"), ink, 1.6)
	ci.draw_circle(Vector2(12.4, -7.8), 1.0, Color("ff8a3d"))


static func _maul(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	Gfx.poly(ci, PackedVector2Array([Vector2(-4, 4), Vector2(4, 4), Vector2(5.5, 13), Vector2(-3, 14)]), Color("2a2336"), ink, 2.0)
	Gfx.grrect(ci, Rect2(8, 6, 14, 6), 2.5, Color("5a4a6a"), Color("2a2336"), ink, 2.0)
	Gfx.grrect(ci, Rect2(-11, -9, 26, 18), 4.0, Color("8a7aa0"), Color("342b46"), ink, 2.0)
	Gfx.rrect(ci, Rect2(-8, -7, 14, 3.4), 1.2, Color("b7a9cd"), Color(0, 0, 0, 0), 0.0)
	Gfx.gell(ci, Vector2(-1, 2), 6.0, 5.0, Color("4a3d5e"), Color("231c33"), ink, 1.8)
	Gfx.ell(ci, Vector2(-1, 2), 3.2, 2.6, Color("ffb23d").lerp(Color.WHITE, heat * 0.5), Color(0, 0, 0, 0), 0.0)
	Gfx.gpoly(ci, PackedVector2Array([Vector2(14, -7), Vector2(30, -11), Vector2(35, -11), Vector2(35, 11), Vector2(30, 11), Vector2(14, 7)]), Color("6c5d82"), Color("2a2238"), ink, 2.0)
	for k in 3:
		var x := 18.0 + k * 5.0
		var h := 8.0 + k * 1.1
		ci.draw_line(Vector2(x, -h), Vector2(x, h), Color("ffb23d").lerp(Color.WHITE, heat * 0.5), 2.2)
		ci.draw_line(Vector2(x + 1.6, -h), Vector2(x + 1.6, h), ink, 1.0)
	Gfx.ell(ci, Vector2(35, 0), 3.4, 10.5, Color("120d1c"), ink, 2.0)
	Gfx.ell(ci, Vector2(35.4, 0), 1.6, 6.5, Color("ffb23d").lerp(Color.WHITE, heat), Color(0, 0, 0, 0), 0.0)


static func _lance(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	var glow_c := Color("6cc4ff").lerp(Color.WHITE, heat * 0.7)
	Gfx.poly(ci, PackedVector2Array([Vector2(-15, -3), Vector2(-9, -4), Vector2(-9, 4), Vector2(-15, 5)]), Color("39445f"), ink, 2.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(-3, 3), Vector2(3, 3), Vector2(4, 11), Vector2(-3, 12)]), Color("232a3f"), ink, 2.0)
	Gfx.grrect(ci, Rect2(-10, -5, 26, 9.5), 3.0, Color("d3dcf0"), Color("6e7ba0"), ink, 2.0)
	Gfx.rrect(ci, Rect2(-3, -2.4, 14, 4.6), 2.0, Color("0d2038"), Color(0, 0, 0, 0), 0.0)
	Gfx.rrect(ci, Rect2(-2, -1.4, 12, 2.6), 1.2, glow_c, Color(0, 0, 0, 0), 0.0)
	Gfx.grrect(ci, Rect2(0, -10.5, 15, 5.2), 2.2, Color("56638a"), Color("232b46"), ink, 1.8)
	ci.draw_circle(Vector2(15.2, -7.9), 2.2, glow_c)
	Gfx.grrect(ci, Rect2(15, -5.0, 29, 3.4), 1.4, Color("b9c5e3"), Color("55628a"), ink, 1.8)
	Gfx.grrect(ci, Rect2(15, 1.0, 29, 3.4), 1.4, Color("8d9bc0"), Color("424d70"), ink, 1.8)
	ci.draw_rect(Rect2(16, -1.6, 27, 2.6), Color("0d2038"))
	ci.draw_rect(Rect2(17, -0.9, 25, 1.2), glow_c)
	for k in 3:
		var x := 22.0 + k * 7.0
		Gfx.rrect(ci, Rect2(x, -6.2, 3.0, 12.4), 1.0, Color("2f3a5c"), ink, 1.6)
	Gfx.poly(ci, PackedVector2Array([Vector2(44, -4.4), Vector2(50, 0), Vector2(44, 4.4)]), glow_c, ink, 1.8)


# ---------------------------------------------------------------- nuevas
static func _grip(ci: CanvasItem, col: Color, x: float = 0.0, h: float = 11.0) -> void:
	Gfx.poly(ci, PackedVector2Array([Vector2(x - 3, 2), Vector2(x + 3.5, 2), Vector2(x + 5, h), Vector2(x - 2, h + 1)]), col, Gfx.INK, 2.0)


static func _pistol(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("9aa7c8"))
	var dark := _c(pal, "dark", Color("38425f"))
	_grip(ci, dark, 0.0, 11.0)
	Gfx.grrect(ci, Rect2(-6, -6.0, 25, 8.5), 2.5, body, dark, ink, 2.0)
	Gfx.rrect(ci, Rect2(-4, -4.5, 9, 2.0), 1.0, Color(1, 1, 1, 0.45), Color(0, 0, 0, 0), 0.0)
	ci.draw_rect(Rect2(6, -1.6, 12, 1.6), glow.lerp(Color.WHITE, heat * 0.7))
	Gfx.grrect(ci, Rect2(17, -4.6, 7, 5.6), 1.6, dark.lightened(0.15), dark, ink, 1.8)
	ci.draw_circle(Vector2(21, -6.4), 1.0, Color("ff8a3d"))
	ci.draw_arc(Vector2(5, 3), 4.5, 0.2, PI - 0.2, 8, ink, 1.6)


static func _burst_rifle(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("7f8a6a"))
	var dark := _c(pal, "dark", Color("2f3626"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(-16, -4), Vector2(-9, -5), Vector2(-9, 3), Vector2(-16, 5)]), dark.lightened(0.1), ink, 2.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(12, 2), Vector2(18, 2), Vector2(19, 12), Vector2(13, 13)]), dark, ink, 1.8)
	Gfx.grrect(ci, Rect2(-10, -6.5, 31, 11), 3.0, body, dark, ink, 2.0)
	for k in 3:
		ci.draw_circle(Vector2(-2 + k * 5.0, -1.0), 1.5, glow.lerp(Color.WHITE, heat * 0.6))
	Gfx.grrect(ci, Rect2(20, -5.0, 19, 6.4), 1.8, dark.lightened(0.2), dark, ink, 1.8)
	Gfx.rrect(ci, Rect2(36, -6.2, 5, 8.8), 1.2, dark, ink, 1.6)
	Gfx.grrect(ci, Rect2(2, -10.5, 11, 4.4), 1.6, dark.lightened(0.25), dark, ink, 1.6)
	ci.draw_rect(Rect2(11, -9.2, 1.6, 2.0), glow)


static func _minigun(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("8a6a5a"))
	var dark := _c(pal, "dark", Color("3a2a26"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(8, 4, 16, 10), 3.0, dark.lightened(0.15), dark, ink, 2.0)     # caja de municion
	ci.draw_line(Vector2(14, 4), Vector2(14, 14), glow, 1.4)
	Gfx.grrect(ci, Rect2(-12, -9, 26, 17), 4.0, body, dark, ink, 2.0)
	Gfx.rrect(ci, Rect2(-8, -7, 12, 3.0), 1.0, Color(1, 1, 1, 0.35), Color(0, 0, 0, 0), 0.0)
	# haz de canones giratorios
	Gfx.grrect(ci, Rect2(13, -8, 5, 16), 1.5, dark, dark.darkened(0.3), ink, 1.8)
	var spin := t * (6.0 + heat * 40.0)
	for k in 3:
		var a := spin + TAU * float(k) / 3.0
		var y := sin(a) * 6.0
		var shade := 0.55 + 0.45 * cos(a)
		Gfx.grrect(ci, Rect2(17, y - 1.9, 28, 3.8), 1.0, body.lerp(Color.WHITE, 0.2 * shade), dark, ink, 1.4)
	Gfx.rrect(ci, Rect2(30, -8.4, 3.5, 16.8), 1.2, dark, ink, 1.6)
	Gfx.rrect(ci, Rect2(41, -8.0, 4.0, 16.0), 1.2, dark.lightened(0.1), ink, 1.6)
	ci.draw_circle(Vector2(-4, 0), 3.0, glow.lerp(Color.WHITE, heat * 0.7))


static func _plasma(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("6a8a6a"))
	var dark := _c(pal, "dark", Color("24362a"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-10, -8, 24, 15), 4.0, body, dark, ink, 2.0)
	# camara de plasma con burbujas
	Gfx.rrect(ci, Rect2(2, -13, 18, 8), 3.5, Color("0a1a10"), ink, 1.8)
	Gfx.rrect(ci, Rect2(3.5, -11.6, 15, 5.2), 2.5, glow.darkened(0.15).lerp(Color.WHITE, heat * 0.4), Color(0, 0, 0, 0), 0.0)
	for k in 3:
		var bx := 6.0 + fposmod(t * 12.0 + k * 5.0, 12.0)
		ci.draw_circle(Vector2(bx, -8.5 + sin(t * 6.0 + k) * 1.4), 1.2, Color(1, 1, 1, 0.65))
	Gfx.gpoly(ci, PackedVector2Array([Vector2(13, -6), Vector2(30, -8), Vector2(34, -6), Vector2(34, 5), Vector2(30, 7), Vector2(13, 6)]), body.lightened(0.1), dark, ink, 2.0)
	for k in 3:
		ci.draw_line(Vector2(18 + k * 4.5, -6.5), Vector2(18 + k * 4.5, 5.5), glow.darkened(0.2), 1.8)
	Gfx.ell(ci, Vector2(34, -0.5), 2.6, 5.6, Color("0a1410"), ink, 1.8)
	Gfx.ell(ci, Vector2(34.4, -0.5), 1.2, 3.4, glow.lerp(Color.WHITE, heat), Color(0, 0, 0, 0), 0.0)


static func _grenade(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("8a7a5a"))
	var dark := _c(pal, "dark", Color("3a3024"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-10, -9, 22, 16), 4.0, body, dark, ink, 2.0)
	Gfx.gell(ci, Vector2(8, 4), 8.0, 7.5, dark.lightened(0.2), dark, ink, 2.0)                 # tambor
	for k in 6:
		var a := TAU * float(k) / 6.0
		ci.draw_circle(Vector2(8, 4) + Vector2.from_angle(a) * 4.8, 1.3, ink)
	Gfx.gpoly(ci, PackedVector2Array([Vector2(12, -9), Vector2(28, -11), Vector2(36, -11), Vector2(36, 7), Vector2(28, 7), Vector2(12, 6)]), body, dark, ink, 2.0)
	ci.draw_rect(Rect2(16, -6, 17, 3.0), glow.lerp(Color.WHITE, heat * 0.5))
	Gfx.ell(ci, Vector2(36, -2), 3.4, 9.0, Color("0d0a08"), ink, 2.0)
	Gfx.ell(ci, Vector2(36.3, -2), 1.7, 5.4, glow.darkened(0.2).lerp(Color.WHITE, heat), Color(0, 0, 0, 0), 0.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(-2, -9), Vector2(8, -9), Vector2(7, -13), Vector2(0, -13)]), dark.lightened(0.15), ink, 1.6)


static func _arc(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("8a8fcf"))
	var dark := _c(pal, "dark", Color("2c2f5e"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-8, -6, 20, 11), 4.0, body, dark, ink, 2.0)
	Gfx.ell(ci, Vector2(0, -0.5), 3.2, 3.2, glow.lerp(Color.WHITE, heat * 0.6), ink, 1.4)
	Gfx.grrect(ci, Rect2(11, -3.4, 18, 6.0), 2.0, body.lightened(0.1), dark, ink, 1.8)
	for k in 3:
		Gfx.rrect(ci, Rect2(14.0 + k * 5.0, -7.0, 3.0, 13.0), 1.2, dark.lightened(0.2), ink, 1.5)
	# tres puntas con arco vivo entre ellas
	var tips := [Vector2(40, -10), Vector2(43, 0), Vector2(40, 10)]
	for tp in tips:
		ci.draw_line(Vector2(28, 0), tp, ink, 4.0, true)
		ci.draw_line(Vector2(28, 0), tp, body.lightened(0.15), 2.0, true)
		ci.draw_circle(tp, 2.4, glow)
	for k in 2:
		var a: Vector2 = tips[k]
		var b: Vector2 = tips[k + 1]
		var pts := PackedVector2Array()
		for s in 7:
			var f := float(s) / 6.0
			var p := a.lerp(b, f)
			var j := sin(t * 55.0 + float(s) * 1.9 + float(k)) * 3.2 * sin(f * PI)
			pts.append(p + Vector2(j, 0))
		ci.draw_polyline(pts, Color(glow, 0.9), 2.0, true)
		ci.draw_polyline(pts, Color(1, 1, 1, 0.85), 0.9, true)


static func _bouncer(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("9a6ab0"))
	var dark := _c(pal, "dark", Color("3a2450"))
	_grip(ci, dark, 0.0, 11.0)
	Gfx.gpoly(ci, PackedVector2Array([Vector2(-10, -3), Vector2(-5, -8), Vector2(14, -8), Vector2(20, -4), Vector2(20, 4), Vector2(14, 6), Vector2(-5, 6), Vector2(-10, 3)]), body, dark, ink, 2.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(2, -8), Vector2(10, -15), Vector2(14, -8)]), dark.lightened(0.2), ink, 1.6)
	Gfx.poly(ci, PackedVector2Array([Vector2(2, 6), Vector2(10, 13), Vector2(14, 6)]), dark.lightened(0.2), ink, 1.6)
	ci.draw_rect(Rect2(-4, -1.0, 16, 2.0), glow.lerp(Color.WHITE, heat * 0.6))
	for k in 2:
		Gfx.ell(ci, Vector2(24 + k * 7.0, 0), 3.0 + k, 5.0 + k * 1.5, dark, ink, 1.8)
		ci.draw_arc(Vector2(24 + k * 7.0, 0), 2.0 + k * 0.6, 0, TAU, 12, glow.lerp(Color.WHITE, heat), 1.6, true)
	ci.draw_circle(Vector2(32, 0), 1.8, glow.lerp(Color.WHITE, heat * 0.8))


static func _pod(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("9a8a5a"))
	var dark := _c(pal, "dark", Color("3a3220"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-8, -13, 38, 21), 4.0, body, dark, ink, 2.0)
	for r in 2:
		for c in 3:
			var p := Vector2(3.0 + c * 9.0, -7.0 + r * 9.0)
			Gfx.ell(ci, p + Vector2(8, 0), 3.4, 3.4, Color("0a0806"), ink, 1.4)
			ci.draw_circle(p + Vector2(8, 0), 1.6, glow.darkened(0.3).lerp(Color.WHITE, heat * 0.5))
	ci.draw_rect(Rect2(-6, -11, 10, 2.4), Color(1, 1, 1, 0.3))
	Gfx.rrect(ci, Rect2(-4, 3, 8, 6), 2.0, dark.lightened(0.2), ink, 1.4)
	ci.draw_rect(Rect2(25, -12, 3, 18), dark)


static func _blade(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("d9dff2"))
	var dark := _c(pal, "dark", Color("39425f"))
	Gfx.grrect(ci, Rect2(-10, -2.8, 18, 5.6), 2.0, dark.lightened(0.15), dark, ink, 1.8)       # empuñadura
	for k in 3:
		ci.draw_line(Vector2(-6 + k * 5.0, -2.5), Vector2(-4 + k * 5.0, 2.5), ink, 1.4)
	Gfx.rrect(ci, Rect2(7, -8.5, 4.5, 17.0), 1.8, body, ink, 1.8)                              # guarda
	ci.draw_rect(Rect2(8.2, -1.4, 2.2, 2.8), glow)
	var l := 40.0
	var pts := PackedVector2Array([Vector2(11, -3.4), Vector2(11 + l * 0.8, -4.2), Vector2(11 + l, 0), Vector2(11 + l * 0.8, 4.2), Vector2(11, 3.4)])
	Gfx.poly(ci, pts, Color(glow, 0.95).lerp(Color.WHITE, 0.25 + heat * 0.4), ink, 1.8)
	ci.draw_line(Vector2(12, 0), Vector2(11 + l * 0.92, 0), Color(1, 1, 1, 0.9), 2.0, true)
	Gfx.draw_glow(ci, Vector2(30, 0), 26.0, Color(glow, 0.2 + 0.1 * sin(t * 12.0) + heat * 0.3))


static func _claws(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("d8e0ee"))
	var dark := _c(pal, "dark", Color("3a4258"))
	Gfx.grrect(ci, Rect2(-6, -5, 14, 10), 3.0, dark.lightened(0.1), dark, ink, 2.0)
	ci.draw_rect(Rect2(-3, -1.5, 8, 3.0), glow)
	for sy in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(7, sy * 2.0), Vector2(26, sy * 1.5), Vector2(34, sy * 3.8), Vector2(26, sy * 5.0), Vector2(7, sy * 6.0)])
		Gfx.gpoly(ci, pts, body, body.darkened(0.35), ink, 1.8)
		ci.draw_line(Vector2(9, sy * 3.6), Vector2(30, sy * 3.7), Color(1, 1, 1, 0.8), 1.2, true)
	Gfx.draw_glow(ci, Vector2(22, 0), 14.0, Color(glow, 0.15 + heat * 0.3))


static func _nest(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("6a9a8a"))
	var dark := _c(pal, "dark", Color("24403a"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-8, -7, 28, 14), 4.0, body, dark, ink, 2.0)
	for k in 4:
		var hc := Vector2(1.0 + k * 5.5, -0.5)
		Gfx.poly(ci, Gfx.ell_pts(hc, 3.0, 3.0, 6), dark.darkened(0.3), ink, 1.0)
	Gfx.gpoly(ci, PackedVector2Array([Vector2(18, -6), Vector2(30, -8), Vector2(30, 7), Vector2(18, 6)]), body.lightened(0.1), dark, ink, 1.8)
	ci.draw_rect(Rect2(20, -2, 8, 2.4), glow.lerp(Color.WHITE, heat * 0.6))
	# mini dron posado que flota
	var hp := Vector2(8, -15 + sin(t * 5.0) * 1.4)
	Gfx.ell(ci, hp, 5.5, 3.6, dark.lightened(0.25), ink, 1.4)
	ci.draw_circle(hp + Vector2(2, 0), 1.4, glow)
	ci.draw_line(hp + Vector2(-6, -3), hp + Vector2(6, -3), Color(1, 1, 1, 0.5 + 0.3 * sin(t * 50.0)), 1.4)


static func _anomaly(ci: CanvasItem, pal: Dictionary, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("8a5aa8"))
	var dark := _c(pal, "dark", Color("2c1a46"))
	var hue := fposmod(0.8 + t * 0.35, 1.0)
	var glow := Color.from_hsv(hue, 0.7, 1.0)
	_grip(ci, dark, 0.0, 11.0)
	Gfx.gpoly(ci, PackedVector2Array([Vector2(-12, -2), Vector2(-4, -10), Vector2(10, -6), Vector2(24, -9), Vector2(30, -2), Vector2(22, 7), Vector2(8, 4), Vector2(-3, 8)]), body, dark, ink, 2.0)
	ci.draw_line(Vector2(-6, 0), Vector2(22, -1), glow.lerp(Color.WHITE, heat * 0.5), 2.4, true)
	for k in 4:
		var a := t * 2.0 + TAU * float(k) / 4.0
		var p := Vector2(34, 0) + Vector2(cos(a) * 5.0, sin(a) * 9.0)
		var c := Color.from_hsv(fposmod(hue + float(k) * 0.2, 1.0), 0.8, 1.0)
		Gfx.poly(ci, PackedVector2Array([p + Vector2(0, -3.2), p + Vector2(2.4, 0), p + Vector2(0, 3.2), p + Vector2(-2.4, 0)]), c, ink, 1.2)
	Gfx.draw_glow(ci, Vector2(34, 0), 16.0, Color(glow, 0.3 + heat * 0.3))


static func _charge_rail(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("b6a6e6"))
	var dark := _c(pal, "dark", Color("2e2650"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(-17, -4), Vector2(-10, -6), Vector2(-10, 5), Vector2(-17, 6)]), dark.lightened(0.15), ink, 2.0)
	Gfx.grrect(ci, Rect2(-11, -7, 26, 13), 3.5, body, dark, ink, 2.0)
	# esfera de carga: crece con `heat`
	var cr := 3.0 + heat * 4.5
	Gfx.ell(ci, Vector2(1, -0.5), cr + 1.6, cr + 1.6, dark.darkened(0.3), ink, 1.6)
	Gfx.ell(ci, Vector2(1, -0.5), cr, cr, glow.lerp(Color.WHITE, heat * 0.8), Color(0, 0, 0, 0), 0.0)
	Gfx.grrect(ci, Rect2(15, -6, 34, 4.2), 1.6, body.lightened(0.1), dark, ink, 1.8)
	Gfx.grrect(ci, Rect2(15, 0.5, 34, 4.2), 1.6, body.darkened(0.1), dark, ink, 1.8)
	ci.draw_rect(Rect2(16, -2.0, 33, 2.4), Color("120d22"))
	ci.draw_rect(Rect2(17, -1.4, 31, 1.2), glow.lerp(Color.WHITE, heat * 0.7))
	for k in 4:
		var x := 20.0 + k * 7.5
		Gfx.rrect(ci, Rect2(x, -8.0, 3.2, 16.0), 1.0, dark.lightened(0.15), ink, 1.5)
		ci.draw_rect(Rect2(x + 0.8, -6.0, 1.6, 12.0), Color(glow, 0.35 + heat * 0.65))
	Gfx.poly(ci, PackedVector2Array([Vector2(49, -5), Vector2(56, 0), Vector2(49, 5)]), glow.lerp(Color.WHITE, heat), ink, 1.8)
	if heat > 0.2:
		Gfx.draw_glow(ci, Vector2(56, 0), 10.0 + heat * 18.0, Color(glow, 0.5 * heat))


static func _flamer(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float, t: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("8a6a5a"))
	var dark := _c(pal, "dark", Color("3a2820"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.grrect(ci, Rect2(-10, -7, 24, 13), 3.5, body, dark, ink, 2.0)
	Gfx.grrect(ci, Rect2(-8, -17, 20, 9), 4.5, body.lightened(0.1), dark, ink, 2.0)            # deposito
	ci.draw_rect(Rect2(-5, -14.5, 14, 3.4), glow.darkened(0.3))
	ci.draw_rect(Rect2(-5, -14.5, 14.0 * 0.8, 3.4), glow)
	Gfx.grrect(ci, Rect2(13, -4.6, 22, 7.6), 2.0, dark.lightened(0.2), dark, ink, 1.8)
	for k in 3:
		ci.draw_line(Vector2(17 + k * 5.0, -4.0), Vector2(17 + k * 5.0, 2.4), ink, 1.3)
	Gfx.rrect(ci, Rect2(33, -5.6, 5.0, 9.6), 1.6, dark, ink, 1.6)
	var pf := 0.7 + 0.3 * sin(t * 24.0)
	Gfx.draw_glow(ci, Vector2(39, -0.8), 5.0 + 3.0 * pf, Color(glow, 0.8))
	ci.draw_colored_polygon(PackedVector2Array([Vector2(38, -2), Vector2(38 + 5.0 * pf + heat * 6.0, -0.8), Vector2(38, 0.4)]), Color(1.0, 0.8, 0.3, 0.9))


static func _sniper(ci: CanvasItem, pal: Dictionary, glow: Color, heat: float) -> void:
	var ink := Gfx.INK
	var body := _c(pal, "body", Color("b0a07a"))
	var dark := _c(pal, "dark", Color("3a3424"))
	_grip(ci, dark, 0.0, 12.0)
	Gfx.poly(ci, PackedVector2Array([Vector2(-20, -4), Vector2(-9, -6), Vector2(-9, 4), Vector2(-20, 7)]), dark.lightened(0.1), ink, 2.0)
	Gfx.grrect(ci, Rect2(-10, -6, 30, 10), 3.0, body, dark, ink, 2.0)
	Gfx.grrect(ci, Rect2(19, -3.6, 38, 5.2), 1.4, dark.lightened(0.25), dark, ink, 1.8)
	Gfx.rrect(ci, Rect2(54, -4.8, 6, 7.6), 1.4, dark, ink, 1.6)
	# mira larga
	Gfx.grrect(ci, Rect2(2, -13, 24, 6.4), 3.0, dark.lightened(0.3), dark, ink, 1.8)
	Gfx.ell(ci, Vector2(26, -9.8), 2.4, 3.8, dark, ink, 1.4)
	ci.draw_circle(Vector2(26.4, -9.8), 1.5, glow.lerp(Color.WHITE, heat * 0.6))
	# bipode
	ci.draw_line(Vector2(30, 1.5), Vector2(27, 9), ink, 3.0, true)
	ci.draw_line(Vector2(34, 1.5), Vector2(37, 9), ink, 3.0, true)
	ci.draw_rect(Rect2(2, -1.6, 10, 1.6), glow.lerp(Color.WHITE, heat))
