class_name Weapons
extends RefCounted
## Datos y dibujo de las 3 armas. Todas se dibujan apuntando a +x con el agarre en el origen.

const W: Array[Dictionary] = [
	{
		"name": "PULSAR", "sub": "AUTOMÁTICA", "rate": 0.088, "dmg": 2.0, "speed": 840.0, "spread": 0.055,
		"count": 1, "life": 0.8, "kick": 3.2, "shake": 0.05, "knock": 38.0, "pierce": 0,
		"muzzle": Vector2(35, -0.5), "grip2": Vector2(15, 3.5), "col": Color("3df2dc"), "kind": 0, "casing": true,
		"hit": 0.012,
	},
	{
		"name": "MAUL-12", "sub": "CORTO ALCANCE", "rate": 0.78, "dmg": 2.5, "speed": 640.0, "spread": 0.30,
		"count": 7, "life": 0.3, "kick": 10.0, "shake": 0.28, "knock": 150.0, "pierce": 0,
		"muzzle": Vector2(36, 0.0), "grip2": Vector2(15, 6.0), "col": Color("ffc24a"), "kind": 1, "casing": true,
		"hit": 0.03,
	},
	{
		"name": "LANCE-X", "sub": "ENERGÉTICA PRECISA", "rate": 0.4, "dmg": 13.0, "speed": 1500.0, "spread": 0.0,
		"count": 1, "life": 0.75, "kick": 7.0, "shake": 0.16, "knock": 90.0, "pierce": 2,
		"muzzle": Vector2(47, 0.0), "grip2": Vector2(24, 3.0), "col": Color("6cc4ff"), "kind": 2, "casing": false,
		"hit": 0.025,
	},
]


static func paint(ci: CanvasItem, idx: int, heat: float = 0.0) -> void:
	match idx:
		0:
			_pulsar(ci, heat)
		1:
			_maul(ci, heat)
		2:
			_lance(ci, heat)


static func _pulsar(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	# empuñadura
	Gfx.poly(ci, PackedVector2Array([Vector2(-3, 2), Vector2(4.5, 2), Vector2(6, 11), Vector2(-1.5, 12)]), Color("232a3f"), ink, 2.0)
	# cargador tambor
	Gfx.gell(ci, Vector2(12, 7.5), 5.5, 5.0, Color("4b5878"), Color("252d45"), ink, 2.0)
	Gfx.ell(ci, Vector2(12, 7.5), 2.6, 2.2, Color("3df2dc"), Color(0, 0, 0, 0), 0.0)
	# cuerpo
	Gfx.grrect(ci, Rect2(-9, -6.5, 29, 12), 3.0, Color("7684a8"), Color("2c3552"), ink, 2.0)
	Gfx.rrect(ci, Rect2(-7, -4.5, 12, 3.0), 1.0, Color("a9b6d4"), Color(0, 0, 0, 0), 0.0)
	# franja de energia
	ci.draw_rect(Rect2(-4, -1.2, 19, 2.4), Color("0c2a33"))
	ci.draw_rect(Rect2(-3, -0.8, 17, 1.6), Color("3df2dc").lerp(Color.WHITE, heat * 0.6))
	# ventana de eyeccion
	ci.draw_rect(Rect2(3, -5.5, 6, 2.2), Color("141a2b"))
	# cañon + disipador
	Gfx.grrect(ci, Rect2(19, -4.6, 13, 8.6), 2.0, Color("4a5675"), Color("1f2640"), ink, 2.0)
	for k in 3:
		ci.draw_line(Vector2(22 + k * 3.2, -3.2), Vector2(22 + k * 3.2, 2.6), Color("11172a"), 1.4)
	# freno de boca
	Gfx.rrect(ci, Rect2(31.5, -5.6, 4.0, 10.4), 1.2, Color("2c3552"), ink, 1.8)
	ci.draw_rect(Rect2(32.2, -1.0, 2.5, 2.0), Color("3df2dc").lerp(Color.WHITE, heat))
	# mira
	Gfx.poly(ci, PackedVector2Array([Vector2(1, -6.5), Vector2(14, -6.5), Vector2(12, -9), Vector2(3, -9)]), Color("39445f"), ink, 1.6)
	ci.draw_circle(Vector2(12.4, -7.8), 1.0, Color("ff8a3d"))


static func _maul(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	# bomba / empuñadura
	Gfx.poly(ci, PackedVector2Array([Vector2(-4, 4), Vector2(4, 4), Vector2(5.5, 13), Vector2(-3, 14)]), Color("2a2336"), ink, 2.0)
	Gfx.grrect(ci, Rect2(8, 6, 14, 6), 2.5, Color("5a4a6a"), Color("2a2336"), ink, 2.0)
	# cuerpo
	Gfx.grrect(ci, Rect2(-11, -9, 26, 18), 4.0, Color("8a7aa0"), Color("342b46"), ink, 2.0)
	Gfx.rrect(ci, Rect2(-8, -7, 14, 3.4), 1.2, Color("b7a9cd"), Color(0, 0, 0, 0), 0.0)
	# tanque de energia
	Gfx.gell(ci, Vector2(-1, 2), 6.0, 5.0, Color("4a3d5e"), Color("231c33"), ink, 1.8)
	Gfx.ell(ci, Vector2(-1, 2), 3.2, 2.6, Color("ffb23d").lerp(Color.WHITE, heat * 0.5), Color(0, 0, 0, 0), 0.0)
	# boca evasé
	Gfx.gpoly(ci, PackedVector2Array([Vector2(14, -7), Vector2(30, -11), Vector2(35, -11), Vector2(35, 11), Vector2(30, 11), Vector2(14, 7)]), Color("6c5d82"), Color("2a2238"), ink, 2.0)
	# bobinas
	for k in 3:
		var x := 18.0 + k * 5.0
		var h := 8.0 + k * 1.1
		ci.draw_line(Vector2(x, -h), Vector2(x, h), Color("ffb23d").lerp(Color.WHITE, heat * 0.5), 2.2)
		ci.draw_line(Vector2(x + 1.6, -h), Vector2(x + 1.6, h), ink, 1.0)
	# boca
	Gfx.ell(ci, Vector2(35, 0), 3.4, 10.5, Color("120d1c"), ink, 2.0)
	Gfx.ell(ci, Vector2(35.4, 0), 1.6, 6.5, Color("ffb23d").lerp(Color.WHITE, heat), Color(0, 0, 0, 0), 0.0)


static func _lance(ci: CanvasItem, heat: float) -> void:
	var ink := Gfx.INK
	var glow_c := Color("6cc4ff").lerp(Color.WHITE, heat * 0.7)
	# culata
	Gfx.poly(ci, PackedVector2Array([Vector2(-15, -3), Vector2(-9, -4), Vector2(-9, 4), Vector2(-15, 5)]), Color("39445f"), ink, 2.0)
	# empuñadura
	Gfx.poly(ci, PackedVector2Array([Vector2(-3, 3), Vector2(3, 3), Vector2(4, 11), Vector2(-3, 12)]), Color("232a3f"), ink, 2.0)
	# cuerpo
	Gfx.grrect(ci, Rect2(-10, -5, 26, 9.5), 3.0, Color("d3dcf0"), Color("6e7ba0"), ink, 2.0)
	# nucleo energetico
	Gfx.rrect(ci, Rect2(-3, -2.4, 14, 4.6), 2.0, Color("0d2038"), Color(0, 0, 0, 0), 0.0)
	Gfx.rrect(ci, Rect2(-2, -1.4, 12, 2.6), 1.2, glow_c, Color(0, 0, 0, 0), 0.0)
	# mira telescopica
	Gfx.grrect(ci, Rect2(0, -10.5, 15, 5.2), 2.2, Color("56638a"), Color("232b46"), ink, 1.8)
	ci.draw_circle(Vector2(15.2, -7.9), 2.2, glow_c)
	# rieles
	Gfx.grrect(ci, Rect2(15, -5.0, 29, 3.4), 1.4, Color("b9c5e3"), Color("55628a"), ink, 1.8)
	Gfx.grrect(ci, Rect2(15, 1.0, 29, 3.4), 1.4, Color("8d9bc0"), Color("424d70"), ink, 1.8)
	ci.draw_rect(Rect2(16, -1.6, 27, 2.6), Color("0d2038"))
	ci.draw_rect(Rect2(17, -0.9, 25, 1.2), glow_c)
	# anillos de bobina
	for k in 3:
		var x := 22.0 + k * 7.0
		Gfx.rrect(ci, Rect2(x, -6.2, 3.0, 12.4), 1.0, Color("2f3a5c"), ink, 1.6)
	# emisor
	Gfx.poly(ci, PackedVector2Array([Vector2(44, -4.4), Vector2(50, 0), Vector2(44, 4.4)]), glow_c, ink, 1.8)
