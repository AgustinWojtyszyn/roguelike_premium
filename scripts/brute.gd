class_name Brute
extends Enemy
## Pesado. Camina con pasos marcados, alza el puño hidraulico sobre la cabeza y lo estrella.

const ST_WALK := 1
const ST_WIND := 2
const ST_SLAM := 3
const ST_RECOVER := 4

var leg_b: Part
var leg_f: Part
var torso_p: Part
var head_p: Part
var shield_p: Part
var arm_p: Part
var glow_p: Part
var walk_ph: float = 0.0
var arm_ang: float = 1.35
var glow: float = 0.0
var cd: float = 1.2
var hit_done := false
var lean: float = 0.0
var step_sign: float = 1.0
var steam_t: float = 0.0
var shield_kick: float = 0.0


func _build() -> void:
	kind_name = "brute"
	hp = 58.0
	radius = 20.0
	hit_r = 27.0
	hit_off = Vector2(0, -34)
	speed = 64.0
	bar_y = -88.0
	glow_col = Color("ffae3a")
	big = true
	spawn_dur = 0.95
	cd = randf_range(1.0, 1.8)
	leg_b = Part.make(vis, _paint_leg, Vector2(-10, -20))
	leg_b.set_meta("dark", true)
	shield_p = Part.make(vis, _paint_shield, Vector2(20, -36))
	leg_f = Part.make(vis, _paint_leg, Vector2(10, -20))
	leg_f.set_meta("dark", false)
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -22))
	head_p = Part.make(vis, _paint_head, Vector2(6, -57))
	arm_p = Part.make(vis, _paint_arm, Vector2(-9, -47))
	glow_p = Part.make(vis, _paint_glow, Vector2(0, -40), true)


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(2, 0), 56.0, Color(0, 0, 0, 0.62))


func _death_chunks() -> Array:
	return [Color("4a3d5e"), Color("2c2438"), Color("6c5a82"), Color("d98a2a"), Color("1a1424")]


func mass() -> float:
	return 4.5


func dmg_mult(dir: Vector2) -> float:
	if state == ST_RECOVER:
		return 1.5
	# blindaje frontal: los disparos que entran contra su escudo rinden menos
	if dir.x * face < -0.15:
		return 0.5
	return 1.0


func _paint_leg(c: Part) -> void:
	var ink := Gfx.INK
	var dark: bool = c.get_meta("dark", false)
	var a := Color("4a3a64") if not dark else Color("2e2342")
	var b := Color("1e1630") if not dark else Color("120c1c")
	Gfx.gpoly(c, PackedVector2Array([Vector2(-8, 0), Vector2(8, 0), Vector2(9, 10), Vector2(7, 17), Vector2(-7, 17), Vector2(-9, 10)]), a, b, ink, 2.4)
	Gfx.ell(c, Vector2(1, 8), 6.0, 4.5, Color("7a68a0") if not dark else Color("4a3c66"), ink, 1.8)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-11, 15), Vector2(12, 15), Vector2(16, 19), Vector2(16, 22), Vector2(-11, 22)]), Color("5a4a78") if not dark else Color("30244a"), Color("1a1224"), ink, 2.2)
	c.draw_rect(Rect2(-10, 19, 26, 2), Color(0, 0, 0, 0.4))
	c.draw_rect(Rect2(-8, 15.5, 6, 2.0), Color("ffae3a") if not dark else Color("8a5a1e"))


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	# espalda / tanques
	Gfx.grrect(c, Rect2(-24, -34, 16, 30), 4.0, Color("3a2e4c"), Color("1e1628"), ink, 2.2)
	for k in 2:
		c.draw_rect(Rect2(-21 + k * 7, -30, 3, 22), Color("ffae3a", 0.7))
	var body := PackedVector2Array([Vector2(-17, 0), Vector2(17, 0), Vector2(23, -8), Vector2(24, -26), Vector2(15, -34), Vector2(-15, -34), Vector2(-24, -26), Vector2(-23, -8)])
	Gfx.gpoly(c, body, Color("6f5d90"), Color("2a2040"), ink, 2.6)
	c.draw_polyline(PackedVector2Array([Vector2(-22, -24), Vector2(-14, -32), Vector2(14, -32), Vector2(22, -24)]), Color(1, 1, 1, 0.35), 2.0, true)
	# placas
	var plate := PackedVector2Array([Vector2(-14, -5), Vector2(14, -5), Vector2(18, -13), Vector2(16, -26), Vector2(8, -30), Vector2(-8, -30), Vector2(-16, -26), Vector2(-18, -13)])
	Gfx.gpoly(c, plate, Color("8a78ac"), Color("3a2d54"), Color("160f20"), 1.8)
	c.draw_line(Vector2(-12, -28), Vector2(12, -28), Color(1, 1, 1, 0.35), 1.6, true)
	# nucleo con rejilla
	Gfx.rrect(c, Rect2(-8, -22, 16, 12), 3.0, Color("14091c"), ink, 1.8)
	var gl := 0.35 + glow * 0.65
	c.draw_rect(Rect2(-6, -20, 12, 8), Color("ffae3a").lerp(Color.WHITE, glow * 0.4) * Color(1, 1, 1, gl))
	for k in 4:
		c.draw_rect(Rect2(-7, -21 + k * 3.0, 14, 1.4), Color("14091c"))
	# cinturon con peligro
	c.draw_rect(Rect2(-18, -4, 36, 6), ink)
	for k in 7:
		var x := -17.0 + k * 5.0
		c.draw_colored_polygon(PackedVector2Array([Vector2(x, 1), Vector2(x + 3, -3), Vector2(x + 5.5, -3), Vector2(x + 2.5, 1)]), Color("d9962a") if k % 2 == 0 else Color("1a1424"))
	# remaches
	for p in [Vector2(-19, -22), Vector2(19, -22), Vector2(-19, -12), Vector2(19, -12)]:
		c.draw_circle(p, 1.8, ink)
		c.draw_circle(p + Vector2(-0.4, -0.4), 1.0, Color("b0a0c4"))
	# hombrera de la espalda
	Gfx.gell(c, Vector2(-17, -31), 9.0, 7.0, Color("a08cc0"), Color("46385e"), ink, 2.2)


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var shell := Gfx.ell_pts(Vector2(0, -6), 11.5, 9.5, 20)
	Gfx.gpoly(c, shell, Color("7a68a0"), Color("2a2040"), ink, 2.4)
	c.draw_arc(Vector2(0, -6), 9.5, PI * 1.05, PI * 1.6, 10, Color(1, 1, 1, 0.4), 1.6, true)
	Gfx.poly(c, PackedVector2Array([Vector2(-8, -13), Vector2(0, -17), Vector2(8, -13), Vector2(0, -11)]), Color("ffae3a", 0.0), ink, 0.0)
	# visor en ranura
	Gfx.rrect(c, Rect2(-2, -10.5, 14, 7), 2.5, Color("120a1a"), ink, 1.6)
	c.draw_rect(Rect2(0, -8.8, 10.5, 3.6), Color("ffc24a").lerp(Color.WHITE, glow * 0.5))
	# cresta
	Gfx.poly(c, PackedVector2Array([Vector2(-9, -12), Vector2(-3, -18), Vector2(4, -15), Vector2(-2, -12)]), Color("5a4a70"), ink, 1.6)


func _paint_shield(c: Part) -> void:
	var ink := Gfx.INK
	var k := shield_kick
	var plate := PackedVector2Array([Vector2(0, -22), Vector2(12 + k, -17), Vector2(15 + k, -4), Vector2(14 + k, 14), Vector2(8 + k, 22), Vector2(-2, 20), Vector2(-3, -17)])
	Gfx.gpoly(c, plate, Color("d4cfe6"), Color("6a6486"), ink, 2.6)
	# nervadura y marcas
	c.draw_polyline(PackedVector2Array([Vector2(7 + k, -15), Vector2(9 + k, 0), Vector2(7 + k, 16)]), Color(0.1, 0.06, 0.16, 0.6), 2.0, true)
	c.draw_line(Vector2(2, -16), Vector2(10 + k, -12), Color(1, 1, 1, 0.5), 1.6, true)
	for p in [Vector2(5 + k, -12), Vector2(5 + k, 12)]:
		c.draw_circle(p, 2.0, ink)
		c.draw_circle(p, 1.1, Color("ffae3a"))
	# franja de aviso
	for i in 4:
		var y := -5.0 + i * 4.5
		c.draw_colored_polygon(PackedVector2Array([Vector2(3 + k, y), Vector2(10 + k, y - 2), Vector2(10 + k, y + 1), Vector2(3 + k, y + 3)]), Color("d9962a") if i % 2 == 0 else Color("1a1424"))


func _paint_arm(c: Part) -> void:
	var ink := Gfx.INK
	# hombro
	Gfx.gell(c, Vector2(0, 0), 9.0, 8.5, Color("a894c8"), Color("4a3d6a"), ink, 2.4)
	# brazo superior
	Gfx.limb(c, PackedVector2Array([Vector2(0, 0), Vector2(15, 0)]), Color("4a3a66"), 11.0, ink)
	# piston
	c.draw_rect(Rect2(6, -9, 20, 3), ink)
	c.draw_rect(Rect2(7, -8.2, 18, 1.6), Color("c8c0d8"))
	# antebrazo + puño
	Gfx.grrect(c, Rect2(12, -9, 20, 18), 3.0, Color("6f5d90"), Color("2a2040"), ink, 2.2)
	var fist := PackedVector2Array([Vector2(28, -15), Vector2(48, -13), Vector2(52, -4), Vector2(52, 6), Vector2(46, 15), Vector2(28, 14)])
	Gfx.gpoly(c, fist, Color("8a78ac"), Color("2e2346"), ink, 2.6)
	c.draw_line(Vector2(32, -13), Vector2(47, -11), Color(1, 1, 1, 0.45), 1.8, true)
	# nudillos
	for k in 3:
		var y := -10.0 + k * 8.0
		c.draw_line(Vector2(40, y), Vector2(51, y + 1.0), Color(0.08, 0.04, 0.12, 0.6), 2.0, true)
	# costura luminosa
	c.draw_line(Vector2(31, -11), Vector2(31, 11), Color("ffae3a").lerp(Color.WHITE, glow * 0.6), 2.4, true)
	c.draw_circle(Vector2(0, 0), 3.0, ink)
	c.draw_circle(Vector2(0, 0), 2.0, Color("ffae3a").lerp(Color.WHITE, glow * 0.6))


func _paint_glow(c: Part) -> void:
	var g := 0.3 + glow
	Gfx.draw_glow(c, Vector2(0, -2), 26.0 + glow * 12.0, Color(1.0, 0.65, 0.2, 0.3 * g))
	Gfx.draw_glow(c, Vector2(5.0, -17.0), 10.0 + glow * 8.0, Color(1.0, 0.7, 0.25, 0.5 * g))
	var tip := arm_p.position - glow_p.position + Vector2(40.0, 0.0).rotated(arm_ang)
	if glow > 0.2:
		Gfx.draw_glow(c, tip, 14.0 + glow * 14.0, Color(1.0, 0.65, 0.2, 0.4 * glow))


func _after_spawn() -> void:
	state = ST_WALK
	st = 0.0


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_WALK:
			face_toward(pl.position, dt, 8.0)
			cd -= dt
			var goal_d := 92.0
			var dir := dirp
			if dist < goal_d - 10.0:
				dir = -dirp * 0.3
			steer(dir, speed, dt, 380.0)
			if dist < 118.0 and cd <= 0.0 and not pl.dead:
				state = ST_WIND
				st = 0.0
				hit_done = false
				game.sfx.play("wind", -4.0, 0.55)
		ST_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 5.0)
			glow = clampf(st / 0.9, 0.0, 1.0)
			steam_t -= dt
			if steam_t <= 0.0:
				steam_t = 0.07
				game.fx.puff(position + Vector2(-face * 14.0, -62.0), Vector2(-face * 20.0, -30.0), 7.0, Color(0.85, 0.85, 0.95, 0.4), 0.55, 2.4)
			if st >= 0.95:
				state = ST_SLAM
				st = 0.0
		ST_SLAM:
			vel = Vector2.ZERO
			if not hit_done and st >= 0.07:
				hit_done = true
				_slam()
			if st >= 0.14:
				state = ST_RECOVER
				st = 0.0
				vulnerable_mult = 1.5
		ST_RECOVER:
			glow = maxf(glow - dt * 0.4, 0.45)
			steam_t -= dt
			if steam_t <= 0.0:
				steam_t = 0.09
				game.fx.puff(position + Vector2(face * 2.0, -40.0), Vector2(randf_range(-20, 20), -36.0), 8.0, Color(0.85, 0.85, 0.95, 0.38), 0.6, 2.4)
			if st >= 1.45:
				state = ST_WALK
				st = 0.0
				vulnerable_mult = 1.0
				cd = randf_range(1.2, 2.2)
				glow = 0.0


func _slam() -> void:
	var pl := game.player
	var c := position + Vector2(face * 40.0, -4.0)
	var fx := game.fx
	fx.ring(c, 10.0, 108.0, Color(1.0, 0.85, 0.55), 0.3, 5.0)
	fx.ring(c, 6.0, 90.0, Color(0.75, 0.72, 0.85, 0.5), 0.35, 12.0, false)
	fx.flash(c, 90.0, Color(1.0, 0.75, 0.35, 0.8), 0.14)
	fx.burst(c, 22, 380.0, Color("ffc86a"), 0.45)
	for i in 14:
		fx.puff(c + Vector2.from_angle(randf() * TAU) * randf_range(8, 50), Vector2.from_angle(randf() * TAU) * 40.0, 12.0, Color(0.55, 0.55, 0.68, 0.5), 0.7, 2.4)
	for i in 10:
		fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(80, 260), randf_range(120, 260), Color("3a3350"), randf_range(2.5, 5.5))
	fx.add_decal(c, 1, 70.0, Color.BLACK)
	fx.add_decal(c, 0, 50.0, Color.BLACK)
	game.sfx.play("slam", 0.0)
	game.shake(0.55)
	game.hitstop(0.05)
	shield_kick = 3.0
	if pl.position.distance_to(c) < 104.0 and pl.can_be_hit():
		pl.take_damage(2, (pl.position - c).normalized(), 300.0)


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (2.0 + spd * 0.075)
	var sw := sin(walk_ph)
	var amp := clampf(spd / speed, 0.0, 1.2)
	# patas
	leg_f.position = Vector2(10, -20 - maxf(0.0, sw) * 5.0 * amp)
	leg_b.position = Vector2(-10, -20 - maxf(0.0, -sw) * 5.0 * amp)
	leg_f.rotation = sw * 0.3 * amp
	leg_b.rotation = -sw * 0.3 * amp
	# paso pesado
	var ss := signf(sw)
	if ss != step_sign and amp > 0.4:
		step_sign = ss
		game.fx.puff(position + Vector2(ss * 10.0, 0), Vector2(0, -6), 12.0, Color(0.55, 0.58, 0.7, 0.35), 0.5, 2.2)
		game.sfx.play("stomp", -12.0 if position.distance_to(game.player.position) > 250.0 else -6.0, 1.0, 0.1, 0.05)
		if position.distance_to(game.player.position) < 260.0:
			game.shake(0.04)
	elif amp <= 0.4:
		step_sign = ss
	var bob := absf(sw) * 3.0 * amp
	# brazo
	var tgt := 1.35
	var rate := 6.0
	match state:
		ST_WIND:
			tgt = lerpf(1.35, -2.05, Gfx.ease_out(clampf(st / 0.8, 0.0, 1.0))) + sin(t * 45.0) * 0.025 * glow
			rate = 30.0
		ST_SLAM:
			tgt = 1.55
			rate = 60.0
		ST_RECOVER:
			tgt = 1.58 if st < 1.1 else 1.35
			rate = 12.0
		_:
			tgt = 1.35 + sw * 0.1 * amp
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * rate, 0.0, 1.0))
	arm_p.rotation = arm_ang
	arm_p.position = Vector2(-9, -47 - bob + (1.0 if state == ST_WIND else 0.0) * 2.0)
	# torso/cabeza
	var lean_t := 0.0
	if state == ST_WIND:
		lean_t = -0.16 * glow
	elif state == ST_SLAM or state == ST_RECOVER:
		lean_t = 0.14
	lean = lerpf(lean, lean_t, clampf(dt * 10.0, 0.0, 1.0))
	torso_p.rotation = lean + sw * 0.03 * amp
	torso_p.position = Vector2(0, -22 - bob)
	head_p.position = Vector2(6 + lean * 20.0, -57 - bob * 1.1 + (1.0 if state == ST_RECOVER else 0.0) * 2.0)
	head_p.rotation = lean * 0.8
	shield_kick = lerpf(shield_kick, 0.0, clampf(dt * 10.0, 0.0, 1.0))
	shield_p.position = Vector2(20 + lean * 18.0, -36 - bob)
	glow_p.position = Vector2(0, -40 - bob)
	torso_p.queue_redraw()
	head_p.queue_redraw()
	arm_p.queue_redraw()
	glow_p.queue_redraw()
	shield_p.queue_redraw()
