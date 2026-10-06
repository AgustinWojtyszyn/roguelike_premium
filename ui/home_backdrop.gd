class_name HomeBackdrop
extends RefCounted
## Fondo dinamico del menu principal por tema de capitulo (tech / aztec / castle / anomaly).
## Capas: degradado de cielo, siluetas del horizonte, suelo en perspectiva, particulas y brillo tras el heroe.

static func paint(ci: CanvasItem, size: Vector2, t: float, theme: String, accent: Color, hero_center: Vector2) -> void:
	var horizon := size.y * 0.58
	var sky_top := Color("060914")
	var sky_bot := Color("111a33")
	match theme:
		"aztec":
			sky_top = Color("1a0f12")
			sky_bot = Color("5a2a22")
		"castle":
			sky_top = Color("0a0a16")
			sky_bot = Color("2a2440")
		"anomaly":
			sky_top = Color("0a0420")
			sky_bot = Color("3a1260")
	UiKit.gradient_rect(ci, Rect2(0, 0, size.x, horizon), sky_top, sky_bot)
	UiKit.gradient_rect(ci, Rect2(0, horizon, size.x, size.y - horizon), sky_bot.darkened(0.5), sky_top.darkened(0.2))
	_stars(ci, size, t, horizon, theme, accent)
	match theme:
		"aztec":
			_aztec(ci, size, t, horizon, accent)
		"castle":
			_castle(ci, size, t, horizon, accent)
		"anomaly":
			_anomaly(ci, size, t, horizon, accent)
		_:
			_tech(ci, size, t, horizon, accent)
	_floor(ci, size, t, horizon, accent, theme)
	Gfx.draw_glow(ci, hero_center + Vector2(0, -20), size.y * 0.62, Color(accent, 0.22))
	Gfx.draw_glow(ci, hero_center + Vector2(0, 90), size.y * 0.42, Color(accent, 0.18))
	_motes(ci, size, t, accent)
	# vineta
	Gfx.draw_glow(ci, Vector2(size.x * 0.5, size.y * 0.5), maxf(size.x, size.y) * 0.9, Color(0, 0, 0, 0.0))


static func _stars(ci: CanvasItem, size: Vector2, t: float, horizon: float, theme: String, accent: Color) -> void:
	var n := 46
	for i in n:
		var h := hash(i * 7919)
		var x := float(h % 1000) / 1000.0 * size.x
		var y := float((h / 1000) % 1000) / 1000.0 * horizon * 0.9
		var tw := 0.5 + 0.5 * sin(t * (0.6 + float(h % 7) * 0.2) + float(i))
		ci.draw_circle(Vector2(x, y), 0.8 + float(h % 3) * 0.4, Color(1, 1, 1, 0.12 + 0.3 * tw))


static func _tech(ci: CanvasItem, size: Vector2, t: float, horizon: float, accent: Color) -> void:
	# torres de servidores y antenas en el horizonte
	for i in 14:
		var h := hash(i * 131 + 7)
		var w := 46.0 + float(h % 50)
		var th := 70.0 + float((h / 7) % 150)
		var x := -20.0 + float(i) * (size.x + 40.0) / 14.0
		var r := Rect2(x, horizon - th, w, th)
		ci.draw_rect(r, Color(0.05, 0.08, 0.16))
		ci.draw_rect(Rect2(r.position.x, r.position.y, r.size.x, 3.0), Color(accent, 0.35))
		for k in int(th / 14.0):
			if (h >> (k % 20)) & 1 == 1:
				var lit := 0.4 + 0.6 * sin(t * 1.3 + float(i * 3 + k))
				ci.draw_rect(Rect2(r.position.x + 6.0 + float((k * 7) % int(w - 14.0)), r.position.y + 10.0 + float(k) * 14.0, 6, 3), Color(accent, 0.15 + 0.4 * maxf(lit, 0.0)))
		if h % 3 == 0:
			ci.draw_line(Vector2(x + w * 0.5, r.position.y), Vector2(x + w * 0.5, r.position.y - 30.0), Color(accent, 0.5), 1.5)
			ci.draw_circle(Vector2(x + w * 0.5, r.position.y - 30.0), 2.0, Color("ff8a3d") if int(t * 2.0 + float(i)) % 2 == 0 else Color("5a2f18"))


static func _aztec(ci: CanvasItem, size: Vector2, t: float, horizon: float, accent: Color) -> void:
	var sun := Vector2(size.x * 0.72, horizon - 130.0)
	Gfx.draw_glow(ci, sun, 200.0, Color(1.0, 0.6, 0.25, 0.35))
	ci.draw_circle(sun, 52.0, Color("ffb86a", 0.9))
	ci.draw_arc(sun, 70.0, 0, TAU, 40, Color("ffd9a0", 0.35), 2.0, true)
	# piramide escalonada
	var cx := size.x * 0.28
	var base_w := 520.0
	for s in 7:
		var w := base_w * (1.0 - float(s) / 7.5)
		var y := horizon - float(s) * 34.0
		ci.draw_rect(Rect2(cx - w * 0.5, y - 34.0, w, 34.0), Color(0.18, 0.1, 0.1).lerp(Color(0.3, 0.16, 0.12), float(s) / 7.0))
		ci.draw_rect(Rect2(cx - w * 0.5, y - 34.0, w, 3.0), Color(1, 0.8, 0.5, 0.18))
		var g := 0.5 + 0.5 * sin(t * 1.5 + float(s))
		ci.draw_rect(Rect2(cx - w * 0.22, y - 20.0, w * 0.44, 3.0), Color(0.24, 0.85, 0.65, 0.15 + 0.3 * g))
	ci.draw_rect(Rect2(cx - 24.0, horizon - 7.0 * 34.0 - 22.0, 48.0, 22.0), Color(0.34, 0.2, 0.14))
	Gfx.draw_glow(ci, Vector2(cx, horizon - 7.0 * 34.0 - 30.0), 60.0, Color(0.24, 0.85, 0.65, 0.35))
	# totems laterales
	for sx in [0.06, 0.94]:
		var x: float = size.x * sx
		ci.draw_rect(Rect2(x - 16.0, horizon - 110.0, 32.0, 110.0), Color(0.22, 0.13, 0.1))
		for k in 3:
			ci.draw_rect(Rect2(x - 10.0, horizon - 100.0 + float(k) * 32.0, 20.0, 6.0), Color(0.24, 0.85, 0.65, 0.5))


static func _castle(ci: CanvasItem, size: Vector2, t: float, horizon: float, accent: Color) -> void:
	var moon := Vector2(size.x * 0.78, horizon - 190.0)
	Gfx.draw_glow(ci, moon, 170.0, Color(0.7, 0.75, 1.0, 0.18))
	ci.draw_circle(moon, 38.0, Color(0.9, 0.92, 1.0, 0.85))
	ci.draw_circle(moon + Vector2(-10, 6), 38.0, Color(0.1, 0.1, 0.18, 0.65))
	var cx := size.x * 0.3
	# muralla + torres
	ci.draw_rect(Rect2(cx - 320.0, horizon - 70.0, 640.0, 70.0), Color(0.07, 0.07, 0.12))
	for i in 12:
		ci.draw_rect(Rect2(cx - 320.0 + float(i) * 54.0, horizon - 84.0, 28.0, 16.0), Color(0.07, 0.07, 0.12))
	for tx in [-250.0, -90.0, 110.0, 270.0]:
		var th := 150.0 + absf(tx) * 0.2
		ci.draw_rect(Rect2(cx + tx - 30.0, horizon - th, 60.0, th), Color(0.09, 0.09, 0.15))
		ci.draw_colored_polygon(PackedVector2Array([Vector2(cx + tx - 40.0, horizon - th), Vector2(cx + tx, horizon - th - 56.0), Vector2(cx + tx + 40.0, horizon - th)]), Color(0.12, 0.1, 0.2))
		for k in 3:
			var lit := 0.5 + 0.5 * sin(t * 2.0 + tx + float(k))
			ci.draw_rect(Rect2(cx + tx - 5.0, horizon - th + 24.0 + float(k) * 34.0, 10.0, 16.0), Color(1.0, 0.7, 0.3, 0.3 + 0.4 * lit))
	# estandartes
	for bx in [0.62, 0.9]:
		var x: float = size.x * bx
		ci.draw_line(Vector2(x, horizon), Vector2(x, horizon - 140.0), Color(0.15, 0.15, 0.22), 4.0)
		var sway := sin(t * 1.4 + x) * 6.0
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x, horizon - 140.0), Vector2(x + 44.0 + sway, horizon - 132.0), Vector2(x + 40.0 + sway * 1.4, horizon - 90.0), Vector2(x + 22.0, horizon - 80.0), Vector2(x, horizon - 92.0)]), Color(0.5, 0.1, 0.18))


static func _anomaly(ci: CanvasItem, size: Vector2, t: float, horizon: float, accent: Color) -> void:
	var c := Vector2(size.x * 0.72, horizon - 150.0)
	for k in 7:
		var rr := 40.0 + float(k) * 22.0
		ci.draw_arc(c, rr, t * (0.3 + float(k) * 0.07), t * (0.3 + float(k) * 0.07) + TAU * 0.62, 30, Color.from_hsv(fposmod(0.78 + float(k) * 0.04, 1.0), 0.7, 1.0, 0.35 - float(k) * 0.03), 3.0, true)
	Gfx.draw_glow(ci, c, 150.0, Color(0.8, 0.3, 1.0, 0.3))
	ci.draw_circle(c, 22.0, Color(0.02, 0.0, 0.06))
	# rocas flotantes
	for i in 8:
		var h := hash(i * 53 + 3)
		var x := float(h % 1000) / 1000.0 * size.x
		var y := horizon - 60.0 - float((h / 13) % 240) + sin(t * 0.8 + float(i)) * 8.0
		var s := 16.0 + float(h % 28)
		ci.draw_colored_polygon(PackedVector2Array([Vector2(x - s, y), Vector2(x - s * 0.4, y - s * 0.7), Vector2(x + s * 0.6, y - s * 0.5), Vector2(x + s, y + s * 0.1), Vector2(x, y + s * 0.8)]), Color(0.16, 0.1, 0.28))
		ci.draw_line(Vector2(x - s * 0.4, y - s * 0.7), Vector2(x + s * 0.6, y - s * 0.5), Color(1.0, 0.4, 0.9, 0.5), 1.4)


static func _floor(ci: CanvasItem, size: Vector2, t: float, horizon: float, accent: Color, theme: String) -> void:
	var vp := Vector2(size.x * 0.5, horizon - 40.0)
	# lineas radiales en perspectiva
	for i in range(-14, 15):
		var x := size.x * 0.5 + float(i) * size.x * 0.11
		ci.draw_line(vp + Vector2(float(i) * 6.0, 40.0), Vector2(x * 1.0 + float(i) * 50.0, size.y), Color(accent, 0.1), 1.5)
	# lineas horizontales que se acercan
	for k in 9:
		var f := fposmod(float(k) / 9.0 + t * 0.03, 1.0)
		var y := horizon + (size.y - horizon) * f * f
		ci.draw_line(Vector2(0, y), Vector2(size.x, y), Color(accent, 0.05 + 0.12 * f), 1.5 + f * 1.5)
	ci.draw_line(Vector2(0, horizon), Vector2(size.x, horizon), Color(accent, 0.5), 2.0)
	Gfx.draw_glow(ci, Vector2(size.x * 0.5, horizon), size.x * 0.55, Color(accent, 0.1))


static func _motes(ci: CanvasItem, size: Vector2, t: float, accent: Color) -> void:
	for i in 34:
		var h := hash(i * 977 + 11)
		var sp := 8.0 + float(h % 30)
		var x := fposmod(float(h % 1300) + t * sp * 0.6, size.x + 40.0) - 20.0
		var y := size.y - fposmod(float((h / 7) % 800) + t * sp, size.y + 40.0)
		var a := 0.08 + 0.3 * (0.5 + 0.5 * sin(t * 1.4 + float(i)))
		ci.draw_circle(Vector2(x, y), 1.2 + float(h % 3) * 0.6, Color(accent.lightened(0.4), a))
