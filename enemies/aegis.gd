class_name Aegis
extends Enemy
## Guardia con escudo de energia frontal. Avanza protegido; para golpear baja el escudo (se vuelve vulnerable).
## Los disparos de frente rinden muy poco: hay que rodearlo o esperar su ataque.

const ST_ADVANCE := 1
const ST_WIND := 2
const ST_BASH := 3
const ST_RECOVER := 4

var legs_f: Part
var legs_b: Part
var torso_p: Part
var head_p: Part
var arm_p: Part
var shield_p: Part
var glow_p: Part
var walk_ph := 0.0
var shield_up := 1.0
var cd := 1.5
var hit_done := false
var arm_ang := 0.9
var strafe := 1.0


func _build() -> void:
	kind_name = "aegis"
	hp = 34.0
	radius = 16.0
	hit_r = 21.0
	hit_off = Vector2(0, -26)
	speed = 82.0
	bar_y = -68.0
	glow_col = Color("3fe8d0")
	big = true
	spawn_dur = 0.85
	cd = randf_range(1.2, 2.2)
	strafe = 1.0 if randf() < 0.5 else -1.0
	legs_b = Part.make(vis, _paint_leg, Vector2(-6, -16))
	legs_b.set_meta("dark", true)
	legs_f = Part.make(vis, _paint_leg, Vector2(6, -16))
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -18))
	head_p = Part.make(vis, _paint_head, Vector2(4, -44))
	arm_p = Part.make(vis, _paint_arm, Vector2(8, -36))
	shield_p = Part.make(vis, _paint_shield, Vector2(16, -26))
	glow_p = Part.make(shield_p, _paint_shield_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("4a5a78"), Color("232e44"), Color("8ab0c8"), Color("3fe8d0")]


func mass() -> float:
	return 2.6


func dmg_mult(dir: Vector2) -> float:
	if state == ST_RECOVER:
		return 1.4
	# el escudo cubre el frente: balas que vienen de cara apenas dañan
	if shield_up > 0.5 and dir.x * face < -0.2:
		return 0.22
	return 1.0


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(2, 0), 34.0, Color(0, 0, 0, 0.55))


func _paint_leg(c: Part) -> void:
	var ink := Gfx.INK
	var dark: bool = c.get_meta("dark", false)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-5, 0), Vector2(5, 0), Vector2(6, 10), Vector2(-6, 10)]), Color("3a4a68") if not dark else Color("232e44"), Color("1a2236"), ink, 2.0)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-7, 9), Vector2(8, 9), Vector2(12, 14), Vector2(12, 17), Vector2(-7, 17)]), Color("56688a") if not dark else Color("2e3a54"), Color("1c2438"), ink, 2.0)


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gpoly(c, PackedVector2Array([Vector2(-11, 0), Vector2(11, 0), Vector2(13, -10), Vector2(9, -22), Vector2(-9, -22), Vector2(-13, -10)]), Color("5a6e92"), Color("26324c"), ink, 2.4)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-7, -3), Vector2(7, -3), Vector2(8, -17), Vector2(-8, -17)]), Color("c8d8ea"), Color("7a90b0"), ink, 1.6)
	c.draw_rect(Rect2(-2, -14, 4, 8), glow_col)
	c.draw_rect(Rect2(-12, -3, 24, 3), Color("1a2236"))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(0, -6), 9.5, 9.0, Color("8ea4c4"), Color("3a4a68"), ink, 2.2)
	Gfx.rrect(c, Rect2(-1, -10, 11, 6), 2.5, Color("06151c"), ink, 1.6)
	c.draw_rect(Rect2(1, -8, 8, 2), glow_col)
	Gfx.poly(c, PackedVector2Array([Vector2(-6, -13), Vector2(0, -19), Vector2(5, -13)]), Color("3fe8d0"), ink, 1.6)


func _paint_arm(c: Part) -> void:
	var ink := Gfx.INK
	# porra de descarga
	c.draw_line(Vector2.ZERO, Vector2(8, 4), ink, 8.0, true)
	c.draw_line(Vector2.ZERO, Vector2(8, 4), Color("5a6e92"), 5.0, true)
	Gfx.grrect(c, Rect2(6, -1, 24, 7), 2.0, Color("c0cce0"), Color("5a6a88"), ink, 1.8)
	c.draw_rect(Rect2(22, 0.5, 7, 4), glow_col)
	c.draw_circle(Vector2(8, 4), 4.2, ink)
	c.draw_circle(Vector2(8, 4), 3.0, Color("d8e4f2"))


func _paint_shield(c: Part) -> void:
	var ink := Gfx.INK
	var h := 46.0 * (0.45 + 0.55 * shield_up)
	var pts := PackedVector2Array([Vector2(-5, -h * 0.5), Vector2(6, -h * 0.5 + 4), Vector2(9, 0), Vector2(6, h * 0.5 - 4), Vector2(-5, h * 0.5), Vector2(-8, 0)])
	Gfx.gpoly(c, pts, Color("2a4a5c"), Color("0c1c28"), ink, 2.6)
	c.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[4]]), Color(glow_col, 0.9), 2.4, true)
	c.draw_line(Vector2(-1, -h * 0.4), Vector2(-1, h * 0.4), Color(glow_col, 0.5), 3.0)


func _paint_shield_glow(c: Part) -> void:
	var h := 46.0 * (0.45 + 0.55 * shield_up)
	Gfx.draw_glow(c, Vector2(2, 0), h * 0.8, Color(glow_col, 0.28 * shield_up))


func _after_spawn() -> void:
	state = ST_ADVANCE
	st = 0.0


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_ADVANCE:
			shield_up = move_toward(shield_up, 1.0, dt * 4.0)
			face_toward(pl.position, dt, 9.0)
			cd -= dt
			var dir := dirp
			var side := Vector2(-dirp.y, dirp.x) * strafe
			if dist < 120.0:
				dir = (dirp * 0.2 + side * 0.9).normalized()
			elif dist < 190.0:
				dir = (dirp * 0.7 + side * 0.5).normalized()
			if randf() < dt * 0.4:
				strafe = -strafe
			steer(dir, speed if stun <= 0.0 else 0.0, dt, 420.0)
			if dist < 104.0 and cd <= 0.0 and not pl.dead:
				state = ST_WIND
				st = 0.0
				hit_done = false
				game.sfx.play("wind", -6.0, 0.7)
		ST_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 7.0)
			shield_up = move_toward(shield_up, 0.0, dt * 3.0)
			if int(st * 40.0) % 5 == 0:
				var pp := position + Vector2(face * 24.0, -34.0)
				game.fx.mote(pp + Vector2.from_angle(randf() * TAU) * 20.0, pp, glow_col, 0.2)
			if st >= 0.6:
				state = ST_BASH
				st = 0.0
		ST_BASH:
			vel = vel.move_toward(Vector2(face * 60.0, 0), 900.0 * dt)
			if not hit_done and st >= 0.05:
				hit_done = true
				_bash()
			if st >= 0.16:
				state = ST_RECOVER
				st = 0.0
		ST_RECOVER:
			shield_up = move_toward(shield_up, 0.0, dt * 3.0)
			vel = vel.move_toward(Vector2.ZERO, 700.0 * dt)
			if st >= 0.95:
				state = ST_ADVANCE
				st = 0.0
				cd = randf_range(1.6, 2.6)


func _bash() -> void:
	var pl := game.player
	var c := position + Vector2(face * 34.0, -12.0)
	game.fx.arc(position + Vector2(face * 6.0, -24.0), 0.0 if face > 0.0 else PI, 46.0, glow_col, 0.2, 2.0)
	game.fx.ring(c, 6.0, 40.0, glow_col, 0.22, 3.5)
	game.fx.spark(c, Vector2(face, 0), 8, 300.0, glow_col, 0.25, 0.9)
	game.sfx.play("stomp", -4.0)
	game.shake(0.12)
	var to := pl.position - position
	if to.length() < 78.0 and signf(to.x) == face and pl.can_be_hit():
		pl.take_damage(1, to.normalized(), 260.0)


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (2.0 + spd * 0.07)
	var sw := sin(walk_ph)
	var amp := clampf(spd / speed, 0.0, 1.2)
	legs_f.position = Vector2(6, -16 - maxf(0.0, sw) * 3.0 * amp)
	legs_b.position = Vector2(-6, -16 - maxf(0.0, -sw) * 3.0 * amp)
	var bob := absf(sw) * 2.0 * amp
	torso_p.position = Vector2(0, -18 - bob)
	head_p.position = Vector2(4, -44 - bob * 1.1)
	var tgt := 0.9
	match state:
		ST_WIND:
			tgt = -1.9
		ST_BASH:
			tgt = 1.2
		ST_RECOVER:
			tgt = 1.0
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * (22.0 if state == ST_BASH else 9.0), 0.0, 1.0))
	arm_p.rotation = arm_ang
	arm_p.position = Vector2(8, -36 - bob)
	shield_p.position = Vector2(16 + (6.0 if state == ST_BASH else 0.0), -26 - bob)
	torso_p.queue_redraw()
	head_p.queue_redraw()
	arm_p.queue_redraw()
	shield_p.queue_redraw()
	glow_p.soft_redraw()
