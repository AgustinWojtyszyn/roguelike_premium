class_name Caballero
extends RoleMelee
## Caballero de la fortaleza: armadura completa, escudo de cometa y espadon. Avanza con paso firme, alza el espadon
## sobre la cabeza (anticipacion) y descarga un tajo ancho. El escudo frontal absorbe la mayor parte de los disparos.

var legs_f: Part
var legs_b: Part
var torso_p: Part
var head_p: Part
var arm_p: Part
var shield_p: Part
var walk_ph := 0.0
var arm_ang := 1.0
var glow_p: Part


func _build() -> void:
	kind_name = "caballero"
	hp = 40.0
	radius = 16.0
	hit_r = 22.0
	hit_off = Vector2(0, -28)
	speed = 76.0
	bar_y = -76.0
	glow_col = Color("e0405a")
	big = true
	spawn_dur = 0.9
	ring_r = 160.0
	approach_mult = 1.0
	windup = 0.75
	strike_dur = 0.16
	rec_dur = 1.0
	reach = 86.0
	strike_dmg = 2
	strike_knock = 280.0
	attack_cd_min = 1.6
	attack_cd_max = 3.0
	cone = 1.3
	legs_b = Part.make(vis, _paint_leg, Vector2(-7, -17))
	legs_b.set_meta("dark", true)
	legs_f = Part.make(vis, _paint_leg, Vector2(7, -17))
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -19))
	head_p = Part.make(vis, _paint_head, Vector2(3, -46))
	shield_p = Part.make(vis, _paint_shield, Vector2(-12, -30))
	arm_p = Part.make(vis, _paint_arm, Vector2(9, -38))
	glow_p = Part.make(arm_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("6a6e88"), Color("34364a"), Color("a8acc8"), Color("a01c3c")]


func mass() -> float:
	return 3.2


func dmg_mult(dir: Vector2) -> float:
	if state == ST_REC:
		return 1.4
	if state != ST_WIND and state != ST_STRIKE and dir.x * face < -0.2:
		return 0.35
	return 1.0


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(2, 0), 36.0, Color(0, 0, 0, 0.55))


func _paint_leg(c: Part) -> void:
	var ink := Gfx.INK
	var dark: bool = c.get_meta("dark", false)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-5.5, 0), Vector2(5.5, 0), Vector2(6, 10), Vector2(-6, 10)]), Color("8a8ea8") if not dark else Color("505470"), Color("34364a"), ink, 2.0)
	Gfx.ell(c, Vector2(0, 5), 4.2, 3.2, Color("b4b8d0") if not dark else Color("686c88"), ink, 1.4)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-7, 9), Vector2(8, 9), Vector2(12, 13), Vector2(12, 17), Vector2(-7, 17)]), Color("6a6e88") if not dark else Color("3a3c52"), Color("1e2030"), ink, 2.0)


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gpoly(c, PackedVector2Array([Vector2(-12, 0), Vector2(12, 0), Vector2(14, -10), Vector2(10, -24), Vector2(-10, -24), Vector2(-14, -10)]), Color("8a8ea8"), Color("3a3c52"), ink, 2.6)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-8, -3), Vector2(8, -3), Vector2(9, -19), Vector2(-9, -19)]), Color("b4b8d0"), Color("6a6e88"), ink, 1.6)
	c.draw_line(Vector2(0, -19), Vector2(0, -3), Color(0, 0, 0, 0.35), 1.6)
	# tabardo carmesi
	Gfx.gpoly(c, PackedVector2Array([Vector2(-6, 0), Vector2(6, 0), Vector2(5, 10), Vector2(0, 12), Vector2(-5, 10)]), Color("a01c3c"), Color("5a0a1e"), ink, 1.6)
	c.draw_rect(Rect2(-13, -4, 26, 4), Color("2a2c40"))
	# hombreras
	for s in [-1.0, 1.0]:
		Gfx.gell(c, Vector2(s * 13.0, -20.0), 7.0, 5.6, Color("a8acc8"), Color("505470"), ink, 2.0)
		Gfx.poly(c, PackedVector2Array([Vector2(s * 11.0, -24.0), Vector2(s * 14.0, -31.0), Vector2(s * 16.0, -23.0)]), Color("c8ccdc"), ink, 1.4)


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(0, -7), 9.5, 10.5, Color("b4b8d0"), Color("505470"), ink, 2.4)
	# visera con ranura
	c.draw_rect(Rect2(-8, -9, 18, 3.2), Color("0a0a12"))
	c.draw_rect(Rect2(-1, -17, 3, 17), Color("0a0a12", 0.7))
	c.draw_rect(Rect2(1, -8.2, 8, 1.6), Color(glow_col, 0.5 + windup_k * 0.5))
	# penacho
	var sway := sin(t * 3.0) * 2.0
	Gfx.poly(c, PackedVector2Array([Vector2(-3, -17), Vector2(-9 + sway, -26), Vector2(-14 + sway, -18), Vector2(-6, -12)]), Color("c8203c"), ink, 1.6)
	Gfx.poly(c, PackedVector2Array([Vector2(0, -17), Vector2(-3 + sway, -28), Vector2(-9 + sway, -22), Vector2(-3, -13)]), Color("a01c3c"), ink, 1.4)


func _paint_arm(c: Part) -> void:
	var ink := Gfx.INK
	# antebrazo
	c.draw_line(Vector2.ZERO, Vector2(9, 3), ink, 8.0, true)
	c.draw_line(Vector2.ZERO, Vector2(9, 3), Color("8a8ea8"), 5.0, true)
	c.draw_circle(Vector2(9, 3), 4.4, ink)
	c.draw_circle(Vector2(9, 3), 3.2, Color("c8ccdc"))
	# espadon
	var blade := PackedVector2Array([Vector2(9, 0.0), Vector2(14, -2.8), Vector2(52, -2.0), Vector2(60, 3), Vector2(52, 5.6), Vector2(14, 6.6)])
	Gfx.gpoly(c, blade, Color("e4e8f4"), Color("8a90b0"), ink, 1.8)
	c.draw_line(Vector2(16, 2), Vector2(56, 2.4), Color(1, 1, 1, 0.7), 1.2, true)
	Gfx.rrect(c, Rect2(10, -7, 4, 20), 1.6, Color("d8c070"), ink, 1.4)
	c.draw_circle(Vector2(4, 3), 2.6, Color("d8c070"))


func _paint_shield(c: Part) -> void:
	var ink := Gfx.INK
	var pts := PackedVector2Array([Vector2(-10, -22), Vector2(8, -22), Vector2(11, -8), Vector2(6, 12), Vector2(-2, 20), Vector2(-10, 12), Vector2(-14, -8)])
	Gfx.gpoly(c, pts, Color("5a5e78"), Color("22243a"), ink, 2.6)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-7, -18), Vector2(5, -18), Vector2(7, -7), Vector2(3, 8), Vector2(-2, 14), Vector2(-7, 8), Vector2(-10, -7)]), Color("a01c3c"), Color("5a0a1e"), ink, 1.6)
	c.draw_line(Vector2(-2, -14), Vector2(-2, 10), Color("e0c070"), 2.6)
	c.draw_line(Vector2(-8, -3), Vector2(5, -3), Color("e0c070"), 2.6)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(34, 2), 14.0 + windup_k * 22.0, Color(glow_col, 0.1 + windup_k * 0.5))


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (2.0 + spd * 0.075)
	var sw := sin(walk_ph)
	var amp := clampf(spd / maxf(speed, 1.0), 0.0, 1.3)
	legs_f.position = Vector2(7, -17 - maxf(0.0, sw) * 3.0 * amp)
	legs_b.position = Vector2(-7, -17 - maxf(0.0, -sw) * 3.0 * amp)
	var bob := absf(sw) * 2.0 * amp
	var tgt := 1.0
	var rate := 8.0
	match state:
		ST_WIND:
			tgt = -2.3 + sin(t * 40.0) * 0.03 * windup_k
			rate = 14.0
		ST_STRIKE:
			tgt = 1.6
			rate = 55.0
		ST_REC:
			tgt = 1.4
			rate = 8.0
		_:
			tgt = 1.0 + sw * 0.08 * amp
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * rate, 0.0, 1.0))
	arm_p.rotation = arm_ang
	arm_p.position = Vector2(9, -38 - bob)
	var lean := -0.12 * windup_k + (0.12 if state == ST_STRIKE else 0.0)
	torso_p.rotation = lean
	torso_p.position = Vector2(0, -19 - bob)
	head_p.position = Vector2(3 + lean * 20.0, -46 - bob * 1.1)
	shield_p.position = Vector2(-12 + lean * 10.0 + (-4.0 if state == ST_WIND else 0.0), -30 - bob)
	legs_f.queue_redraw()
	legs_b.queue_redraw()
	torso_p.queue_redraw()
	head_p.queue_redraw()
	arm_p.queue_redraw()
	glow_p.queue_redraw()
