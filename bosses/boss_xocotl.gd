class_name BossXocotl
extends Boss
## XOCOTL, Guardian del Sol: un coloso de piedra y jade con un disco solar en el pecho. Se lee por la POSTURA:
## brazos en alto + glifos orbitando (lluvia de glifos), maza sobre la cabeza (mazazo), pecho abierto (invoca),
## agazapado con polvo (embestida: acelera, y si choca con un muro queda aturdido y expuesto).

const ST_WALK := 1
const ST_GLYPH_WIND := 2
const ST_GLYPH_FIRE := 3
const ST_SMASH_WIND := 4
const ST_SMASH_HIT := 5
const ST_SPIN := 6
const ST_SUMMON := 7
const ST_CHARGE_WIND := 8
const ST_CHARGE := 9
const ST_STUN := 10
const ST_REC := 11
const ST_PHASE := 12

var legs_p: Part
var torso_p: Part
var disc_p: Part
var head_p: Part
var arm_f: Part
var arm_b: Part
var glyphs_p: Part
var glow_p: Part
var walk_ph := 0.0
var step_sign := 1.0
var cd := 1.6
var lean := 0.0
var squat := 0.0
var arm_ang := 0.7
var disc_ang := 0.0
var disc_speed := 0.6
var core_glow := 0.3
var chest_open := 0.0
var phase_flash := 0.0
var last_attack := ""
var steam_t := 0.0
var glyph_k := 0.0              # 0 = junto al cuerpo, 1 = en orbita amplia
var glyph_ang := 0.0
var glyph_targets: Array[Vector2] = []
var volley_i := 0
var volley_t := 0.0
var charge_dir := Vector2.DOWN
var charge_speed_cur := 0.0
var spiral_a := 0.0
var spiral_t := 0.0
var summon_done := false
var hit_done := false
var eye := Vector2.DOWN

const JADE := Color("3dd9a8")
const GOLD := Color("e8c06a")
const PHASE_COLS := [Color("3dd9a8"), Color("e8c06a"), Color("ff7a3a")]


func _build() -> void:
	kind_name = "xocotl"
	hp = boss_data.hp
	radius = 34.0
	hit_r = 46.0
	hit_off = Vector2(0, -56.0)
	speed = 50.0
	bar_y = -150.0
	glow_col = boss_data.accent
	big = true
	spawn_dur = 1.6
	phase_marks_arr = [boss_data.phases[1], boss_data.phases[2]]
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	arm_b = Part.make(vis, _paint_arm, Vector2(-46, -80))
	arm_b.set_meta("back", true)
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -26))
	disc_p = Part.make(torso_p, _paint_disc, Vector2(0, -36))
	glow_p = Part.make(torso_p, _paint_glow, Vector2(0, -36), true)
	head_p = Part.make(vis, _paint_head, Vector2(0, -112))
	glyphs_p = Part.make(vis, _paint_glyphs, Vector2(0, -62))
	arm_f = Part.make(vis, _paint_arm, Vector2(46, -80))
	arm_f.set_meta("back", false)


func _death_chunks() -> Array:
	return [Color("8a7a62"), Color("4a3e30"), Color("3dd9a8"), Color("e8c06a"), Color("2a2218")]


func mass() -> float:
	return 40.0


func dmg_mult(_dir: Vector2) -> float:
	match state:
		ST_STUN:
			return 1.8
		ST_REC:
			return 1.3
		ST_PHASE:
			return 0.25
		S_SPAWN:
			return 0.0
	return 0.8


func targetable() -> bool:
	return state != S_DYING and state != S_SPAWN


func _pc() -> Color:
	return PHASE_COLS[phase]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, 2), 100.0, Color(0, 0, 0, 0.62))


# ------------------------------------------------------------------ dibujo
func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for s in [-1.0, 1.0]:
		var lift: float = maxf(0.0, sin(walk_ph + (0.0 if s < 0.0 else PI))) * 7.0 * clampf(vel.length() / speed, 0.0, 1.0)
		var x: float = s * 26.0
		var y := -6.0 - lift - squat * 4.0
		Gfx.grrect(c, Rect2(x - 15, y - 40, 30, 36), 4.0, Color("8a7a62"), Color("4a3e30"), ink, 2.4)
		for k in 3:
			c.draw_rect(Rect2(x - 12, y - 34 + float(k) * 10.0, 24, 3), Color(JADE, 0.55))
		var foot := PackedVector2Array([Vector2(x - 20, y - 6), Vector2(x + 20, y - 6), Vector2(x + 24, y + 6), Vector2(x - 24, y + 6)])
		Gfx.gpoly(c, foot, Color("a09070"), Color("5a4e3c"), ink, 2.4)
		c.draw_rect(Rect2(x - 18, y + 2, 36, 3), Color(GOLD, 0.6))


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var body := PackedVector2Array([Vector2(-42, 0), Vector2(42, 0), Vector2(54, -26), Vector2(48, -56), Vector2(30, -74), Vector2(-30, -74), Vector2(-48, -56), Vector2(-54, -26)])
	Gfx.gpoly(c, body, Color("9a8a70"), Color("4a3e30"), ink, 3.0)
	# greca tallada
	var gy := -62.0
	var pts := PackedVector2Array()
	var x := -36.0
	while x < 34.0:
		pts.append(Vector2(x, gy + 8.0))
		pts.append(Vector2(x, gy))
		pts.append(Vector2(x + 9.0, gy))
		pts.append(Vector2(x + 9.0, gy + 8.0))
		x += 18.0
	c.draw_polyline(pts, Color(0, 0, 0, 0.45), 3.0, true)
	c.draw_polyline(pts, Color(GOLD, 0.6), 1.4, true)
	# paneles de jade laterales
	for s in [-1.0, 1.0]:
		Gfx.gpoly(c, PackedVector2Array([Vector2(s * 40, -8), Vector2(s * 52, -24), Vector2(s * 48, -48), Vector2(s * 36, -52)]), Color("6a5a48"), Color("342a20"), ink, 2.0)
		c.draw_line(Vector2(s * 44, -14), Vector2(s * 44, -44), Color(col, 0.8), 2.4)
	# faja inferior
	c.draw_rect(Rect2(-42, -4, 84, 6), ink)
	c.draw_rect(Rect2(-40, -3, 80, 4), Color(GOLD, 0.7))
	# grietas segun fase
	if phase >= 1:
		c.draw_polyline(PackedVector2Array([Vector2(-20, -70), Vector2(-14, -56), Vector2(-24, -46), Vector2(-16, -32)]), ink, 3.0, true)
		c.draw_polyline(PackedVector2Array([Vector2(-20, -70), Vector2(-14, -56), Vector2(-24, -46), Vector2(-16, -32)]), Color(col, 0.9), 1.4, true)
	if phase >= 2:
		c.draw_polyline(PackedVector2Array([Vector2(24, -68), Vector2(18, -54), Vector2(26, -44)]), ink, 3.0, true)
		c.draw_polyline(PackedVector2Array([Vector2(24, -68), Vector2(18, -54), Vector2(26, -44)]), Color(col, 0.9), 1.4, true)


func _paint_disc(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var o := chest_open
	var R := 22.0 + o * 4.0
	Gfx.ell(c, Vector2.ZERO, R + 4.0, R + 4.0, Color("2a2218"), ink, 2.4)
	# anillo exterior con dientes (gira)
	for k in 12:
		var a := disc_ang + TAU * float(k) / 12.0
		var d := Vector2.from_angle(a)
		c.draw_colored_polygon(PackedVector2Array([d * (R + 3.0), d.rotated(0.13) * (R - 5.0), d.rotated(-0.13) * (R - 5.0)]), GOLD if k % 2 == 0 else Color("a8884a"))
	Gfx.ell(c, Vector2.ZERO, R - 6.0, R - 6.0, Color("120c06"), ink, 1.6)
	# nucleo de jade con radios
	for k in 4:
		var a2 := -disc_ang * 1.4 + PI * 0.5 * float(k)
		c.draw_line(Vector2.ZERO, Vector2.from_angle(a2) * (R - 8.0), Color(col, 0.7), 2.4)
	c.draw_circle(Vector2.ZERO, 6.0 + core_glow * 3.0, col.lerp(Color.WHITE, core_glow * 0.5))
	if o > 0.1:
		c.draw_arc(Vector2.ZERO, R + 8.0, -PI * 0.5 - o * 1.2, -PI * 0.5 + o * 1.2, 14, Color(1.0, 0.8, 0.4, 0.9), 3.0, true)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 40.0 + core_glow * 46.0, Color(_pc(), 0.22 + core_glow * 0.45))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	# corona de plumas de piedra
	for k in 7:
		var a := -PI * 0.5 + (float(k) - 3.0) * 0.3
		var tip := Vector2(cos(a), sin(a)) * (30.0 + float(3 - absi(k - 3)) * 3.0) + Vector2(0, -2)
		Gfx.poly(c, PackedVector2Array([Vector2(float(k - 3) * 6.0, -10), tip, Vector2(float(k - 3) * 6.0 + 5.0, -10)]), Color("8a7a62") if k % 2 == 0 else Color(JADE.darkened(0.2)), ink, 1.8)
	var mask := PackedVector2Array([Vector2(-24, 4), Vector2(-26, -12), Vector2(-16, -24), Vector2(16, -24), Vector2(26, -12), Vector2(24, 4), Vector2(14, 12), Vector2(-14, 12)])
	Gfx.gpoly(c, mask, Color("aa9a7c"), Color("5a4e3c"), ink, 2.6)
	# ojos que siguen al jugador
	for s in [-1.0, 1.0]:
		var ec := Vector2(s * 10.0, -9.0)
		Gfx.rrect(c, Rect2(ec.x - 8, ec.y - 5, 16, 10), 3.0, Color("0c0a06"), ink, 1.6)
		c.draw_rect(Rect2(ec.x - 5 + clampf(eye.x * 3.0, -3.0, 3.0), ec.y - 2.0, 10, 4), col.lerp(Color.WHITE, phase_flash))
	# boca con colmillos
	Gfx.rrect(c, Rect2(-12, 2, 24, 7), 2.0, Color("0c0a06"), ink, 1.4)
	for k in 4:
		c.draw_colored_polygon(PackedVector2Array([Vector2(-10 + float(k) * 6.0, 2), Vector2(-7 + float(k) * 6.0, 2), Vector2(-8.5 + float(k) * 6.0, 8)]), Color("e8e0c8"))
	c.draw_line(Vector2(-18, -18), Vector2(18, -18), Color(GOLD, 0.8), 2.0)


func _paint_arm(c: Part) -> void:
	var ink := Gfx.INK
	var back: bool = c.get_meta("back", false)
	var col := _pc()
	var a := arm_ang if not back else 0.55 + sin(walk_ph) * 0.1
	if back and state in [ST_GLYPH_WIND, ST_GLYPH_FIRE, ST_PHASE]:
		a = -1.3
	var elbow := Vector2.from_angle(a) * 24.0
	var hand := elbow + Vector2.from_angle(a + (0.5 if not back else 0.2)) * 22.0
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), ink, 17.0, true)
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), Color("8a7a62") if not back else Color("5a4e3c"), 12.0, true)
	c.draw_circle(elbow, 8.0, ink)
	c.draw_circle(elbow, 6.0, Color("b0a080") if not back else Color("6a5e4a"))
	c.draw_line(elbow + Vector2(-3, 0), elbow + Vector2(3, 0), Color(col, 0.9), 2.0)
	c.draw_set_transform(hand, a + 0.5, Vector2.ONE)
	if not back:
		# macuahuitl: maza de madera con filos de obsidiana
		Gfx.grrect(c, Rect2(-4, -9, 54, 18), 4.0, Color("6a4a2c"), Color("34221a"), ink, 2.4)
		for k in 6:
			Gfx.poly(c, PackedVector2Array([Vector2(4.0 + float(k) * 8.0, -9), Vector2(8.0 + float(k) * 8.0, -17), Vector2(12.0 + float(k) * 8.0, -9)]), Color("14101a"), ink, 1.2)
			Gfx.poly(c, PackedVector2Array([Vector2(4.0 + float(k) * 8.0, 9), Vector2(8.0 + float(k) * 8.0, 17), Vector2(12.0 + float(k) * 8.0, 9)]), Color("14101a"), ink, 1.2)
		c.draw_rect(Rect2(40, -2, 8, 4), Color(col, 0.9))
	else:
		Gfx.gell(c, Vector2(8, 0), 14.0, 18.0, Color("a09070"), Color("5a4e3c"), ink, 2.4)
		c.draw_circle(Vector2(8, 0), 6.0, Color(col, 0.8))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_glyphs(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	for k in 4:
		var a := glyph_ang + TAU * float(k) / 4.0
		var r := lerpf(40.0, 86.0, glyph_k)
		var p := Vector2(cos(a) * r, sin(a) * r * 0.55)
		if glyph_k < 0.05:
			continue
		var s := 9.0 + glyph_k * 3.0
		var pts := Gfx.ell_pts(p, s, s, 6, PI / 6.0)
		Gfx.poly(c, pts, Color("b0a080"), ink, 2.0)
		Gfx.poly(c, Gfx.ell_pts(p, s * 0.5, s * 0.5, 6, PI / 6.0), Color(col, 0.9), Color(0, 0, 0, 0), 0.0)
		Gfx.draw_glow(c, p, 20.0, Color(col, 0.3 * glyph_k))


# ------------------------------------------------------------------ logica
func _after_spawn() -> void:
	state = ST_WALK
	st = 0.0
	cd = 1.2


func _on_phase_change(ph: int) -> void:
	if state == S_DYING:
		return
	state = ST_PHASE
	st = 0.0
	cd = 1.0
	phase_flash = 1.0
	game.bullets.clear_enemy_bullets(position, 2000.0)
	game.shake(0.7)
	game.hitstop(0.12)
	game.sfx.play("roar", 0.0, 0.65)
	game.slow_enemies(0.35, 0.5)
	var c := hit_center()
	var col := _pc()
	game.fx.ring(c, 20.0, 270.0, col, 0.6, 8.0)
	game.fx.ring(c, 10.0, 180.0, Color.WHITE, 0.4, 5.0)
	game.fx.flash(c, 230.0, Color(col, 0.9), 0.35)
	game.fx.burst(c, 40, 460.0, col, 0.7)
	for i in 14:
		game.fx.shard(c + Vector2(randf_range(-40, 40), randf_range(-20, 20)), Vector2.from_angle(randf() * TAU) * randf_range(120, 320), randf_range(140, 300), Color("8a7a62").lerp(Color("2a2218"), randf()), randf_range(4, 8), Color(col.r, col.g, col.b, 0.8))
	torso_p.queue_redraw()


func _think(dt: float) -> void:
	_check_phase()
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	eye = eye.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0))
	phase_flash = maxf(0.0, phase_flash - dt * 2.5)
	steam_t -= dt
	glyph_ang += dt * (1.2 + glyph_k * 2.4)
	disc_ang += dt * disc_speed
	var sp := speed * (1.0 + 0.25 * float(phase))
	match state:
		ST_WALK:
			core_glow = move_toward(core_glow, 0.3, dt)
			disc_speed = move_toward(disc_speed, 0.6 + 0.3 * float(phase), dt * 2.0)
			glyph_k = move_toward(glyph_k, 0.0, dt * 2.0)
			chest_open = move_toward(chest_open, 0.0, dt * 3.0)
			lean = lerpf(lean, 0.0, dt * 6.0)
			face_toward(pl.position, dt, 6.0)
			var dir := Vector2.ZERO
			if dist > 340.0:
				dir = dirp
			elif dist < 210.0:
				dir = -dirp * 0.7
			dir += Vector2(-dirp.y, dirp.x) * sin(t * 0.6) * 0.5
			steer(dir, sp if stun <= 0.0 else 0.0, dt, 260.0)
			cd -= dt
			if cd <= 0.0 and not pl.dead:
				_pick_attack(dist)
		ST_GLYPH_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			glyph_k = move_toward(glyph_k, 1.0, dt * 2.2)
			core_glow = clampf(st / 0.9, 0.0, 1.0)
			arm_ang = lerpf(arm_ang, -1.5, clampf(dt * 8.0, 0.0, 1.0))
			if int(st * 30.0) % 3 == 0:
				game.fx.mote(position + Vector2(0, -62) + Vector2.from_angle(randf() * TAU) * 90.0, position + Vector2(0, -62), _pc(), 0.22)
			if st >= 0.95:
				state = ST_GLYPH_FIRE
				st = 0.0
				volley_i = 0
				volley_t = 0.0
		ST_GLYPH_FIRE:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			volley_t -= dt
			if volley_t <= 0.0 and volley_i < 4 + phase * 2:
				_glyph_shot(volley_i)
				volley_i += 1
				volley_t = 0.17
			if volley_i >= 4 + phase * 2 and volley_t <= -0.2:
				_end_attack(0.9)
		ST_SMASH_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 8.0)
			core_glow = clampf(st / 0.8, 0.0, 1.0)
			arm_ang = lerpf(arm_ang, -2.3, clampf(dt * 9.0, 0.0, 1.0))
			lean = lerpf(lean, -0.14, dt * 9.0)
			if steam_t <= 0.0:
				steam_t = 0.07
				game.fx.puff(position + Vector2(randf_range(-30, 30), -100), Vector2(randf_range(-20, 20), -40), 8.0, Color(0.85, 0.8, 0.7, 0.4), 0.55, 2.4)
			if st >= (0.85 if phase < 2 else 0.65):
				state = ST_SMASH_HIT
				st = 0.0
				hit_done = false
		ST_SMASH_HIT:
			arm_ang = lerpf(arm_ang, 1.7, clampf(dt * 40.0, 0.0, 1.0))
			lean = lerpf(lean, 0.18, dt * 20.0)
			if not hit_done and st >= 0.05:
				hit_done = true
				_smash()
			if st >= 0.2:
				_end_attack(1.0)
		ST_SPIN:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 0.9 + 0.1 * sin(t * 20.0)
			disc_speed = move_toward(disc_speed, 9.0, dt * 7.0)
			spiral_a += dt * (1.8 + 0.5 * float(phase))
			spiral_t -= dt
			if spiral_t <= 0.0:
				spiral_t = 0.11
				_spiral_shot()
			if st >= 2.8:
				_end_attack(1.0)
		ST_SUMMON:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			chest_open = move_toward(chest_open, 1.0, dt * 3.0)
			core_glow = 0.7
			if steam_t <= 0.0:
				steam_t = 0.05
				game.fx.puff(position + Vector2(randf_range(-16, 16), -62), Vector2(randf_range(-30, 30), -50), 8.0, Color(0.4, 1.0, 0.8, 0.45), 0.6, 2.4)
			if not summon_done and st >= 1.0:
				summon_done = true
				_summon()
			if st >= 1.9:
				_end_attack(0.9)
		ST_CHARGE_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 14.0)
			squat = lerpf(squat, 1.0, dt * 8.0)
			core_glow = clampf(st / 0.9, 0.0, 1.0)
			charge_dir = charge_dir.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0)).normalized()
			if int(st * 30.0) % 3 == 0:
				game.fx.puff(position + Vector2(randf_range(-30, 30), -2), Vector2(randf_range(-30, 30), -20), 9.0, Color(0.8, 0.7, 0.55, 0.45), 0.5, 2.4)
			if st >= 0.9:
				state = ST_CHARGE
				st = 0.0
				charge_speed_cur = speed
				hit_done = false
				game.sfx.play("stomp", -2.0, 0.7)
		ST_CHARGE:
			squat = lerpf(squat, 0.3, dt * 6.0)
			charge_speed_cur = move_toward(charge_speed_cur, 300.0 + 40.0 * float(phase), 520.0 * dt)
			vel = charge_dir * charge_speed_cur
			if int(st * 40.0) % 3 == 0:
				game.fx.puff(position + Vector2(randf_range(-20, 20), -2), -charge_dir * 30.0, 10.0, Color(0.75, 0.68, 0.55, 0.5), 0.45, 2.2)
			var pl_d := pl.position.distance_to(position)
			if not hit_done and pl_d < radius + Player.RADIUS + 14.0 and pl.can_be_hit():
				hit_done = true
				pl.take_damage(2, charge_dir, 360.0)
			var ahead := position + charge_dir * (radius + 22.0)
			if not game.room.free_point(ahead, radius * 0.7):
				state = ST_STUN
				st = 0.0
				vel = -charge_dir * 80.0
				game.fx.ring(ahead, 8.0, 130.0, Color("ffd9a0"), 0.35, 6.0)
				game.fx.burst(ahead, 24, 360.0, Color("e8c06a"), 0.5)
				for i in 10:
					game.fx.shard(ahead, Vector2.from_angle(randf() * TAU) * randf_range(80, 260), randf_range(120, 260), Color("6a5a48"), randf_range(3, 6))
				game.shake(0.6)
				game.hitstop(0.06)
				game.sfx.play("slam", 0.0, 0.9)
			elif st >= 0.95:
				_end_attack(1.0)
		ST_STUN:
			vel = vel.move_toward(Vector2.ZERO, 600.0 * dt)
			core_glow = 1.0
			squat = lerpf(squat, 0.5, dt * 6.0)
			if steam_t <= 0.0:
				steam_t = 0.06
				game.fx.puff(position + Vector2(randf_range(-26, 26), -80), Vector2(randf_range(-30, 30), -60), 10.0, Color(0.9, 0.9, 1.0, 0.5), 0.7, 2.6)
			if st >= 2.0:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.8
		ST_REC:
			core_glow = move_toward(core_glow, 0.2, dt)
			squat = lerpf(squat, 0.2, dt * 6.0)
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			disc_speed = move_toward(disc_speed, 0.6, dt * 3.0)
			if st >= 0.9:
				state = ST_WALK
				st = 0.0
				squat = 0.0
		ST_PHASE:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 1.0
			squat = lerpf(squat, 0.5, dt * 8.0)
			arm_ang = -1.4 + sin(t * 30.0) * 0.1
			disc_speed = 6.0
			if steam_t <= 0.0:
				steam_t = 0.04
				game.fx.spark(position + Vector2(randf_range(-40, 40), -60), Vector2.UP, 2, 260.0, _pc(), 0.3, 1.2)
			if st >= 1.6:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.6


func _pick_attack(dist: float) -> void:
	var pool: Array = []
	pool.append(["glyph", 3.0 if last_attack != "glyph" else 0.8])
	if dist < 230.0:
		pool.append(["smash", 4.0 if last_attack != "smash" else 1.0])
	else:
		pool.append(["smash", 1.5 if last_attack != "smash" else 0.4])
	pool.append(["spin", 2.4 if last_attack != "spin" else 0.5])
	if phase >= 1:
		var adds := 0
		for e in game.enemies:
			if e != self:
				adds += 1
		if adds < 3:
			pool.append(["summon", 2.6 if last_attack != "summon" else 0.0])
		pool.append(["charge", 3.0 if last_attack != "charge" else 0.0])
	var total := 0.0
	for p in pool:
		total += float(p[1])
	var r := randf() * total
	var pick := "glyph"
	for p in pool:
		r -= float(p[1])
		if r <= 0.0:
			pick = p[0]
			break
	last_attack = pick
	st = 0.0
	match pick:
		"glyph":
			state = ST_GLYPH_WIND
			game.sfx.play("charge", -6.0, 0.8)
		"smash":
			state = ST_SMASH_WIND
			game.sfx.play("wind", -2.0, 0.5)
		"spin":
			state = ST_SPIN
			spiral_t = 0.0
			game.sfx.play("charge", -4.0, 0.6)
		"summon":
			state = ST_SUMMON
			summon_done = false
			game.sfx.play("roar", -6.0, 1.3)
		"charge":
			state = ST_CHARGE_WIND
			game.sfx.play("wind", -2.0, 0.45)


func _end_attack(_rest: float) -> void:
	state = ST_REC
	st = 0.0
	cd = maxf(0.5, 1.3 - 0.2 * float(phase))


func _glyph_shot(i: int) -> void:
	var pl := game.player
	var k := i % 4
	var a := glyph_ang + TAU * float(k) / 4.0
	var p := position + Vector2(0, -62) + Vector2(cos(a) * 86.0, sin(a) * 86.0 * 0.55)
	var d := (pl.hit_center() + pl.vel * 0.25 - p).normalized()
	var b := game.bullets.fire(p + d * 12.0, d, 300.0 + 20.0 * float(phase), 3.0, 1.0, Bullets.Style.SHARD, 1)
	b.col = _pc()
	game.fx.muzzle(p, d.angle(), 0.7, _pc())
	game.sfx.play("bolt", -7.0, 1.1, 0.05)
	game.shake(0.05)


func _smash() -> void:
	var pl := game.player
	var fwd := (pl.position - position).normalized()
	var c := position + fwd * 70.0 + Vector2(0, -6)
	var col := _pc()
	game.fx.ring(c, 10.0, 130.0, col.lightened(0.3), 0.3, 6.0)
	game.fx.flash(c, 120.0, Color(col, 0.8), 0.16)
	game.fx.burst(c, 28, 420.0, Color("ffd9a0"), 0.45)
	for i in 12:
		game.fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(80, 280), randf_range(120, 280), Color("6a5a48"), randf_range(3, 6))
	game.fx.add_decal(c, 1, 80.0, Color.BLACK)
	game.sfx.play("slam", 0.0, 1.0)
	game.shake(0.6)
	game.hitstop(0.05)
	# abanico de esquirlas
	var n := 9 + phase * 2
	for i in n:
		var a := fwd.angle() + (float(i) - float(n - 1) * 0.5) * (1.9 / float(n - 1))
		var b := game.bullets.fire(c, Vector2.from_angle(a), 250.0, 3.0, 1.0, Bullets.Style.SHARD, 1)
		b.col = col
	var to := pl.position - position
	if to.length() < 150.0 and absf(fwd.angle_to(to)) < 1.0 and pl.can_be_hit():
		pl.take_damage(2, to.normalized(), 360.0)


func _spiral_shot() -> void:
	var c := position + Vector2(0, -62)
	var arms := 2 + (1 if phase >= 2 else 0)
	for k in arms:
		var a := spiral_a + TAU * float(k) / float(arms)
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 28.0, Vector2.from_angle(a), 170.0, 3.6, 1.0, Bullets.Style.RUNE, 1)
		b.col = _pc()
	game.sfx.play("bolt", -16.0, 1.4 + randf() * 0.2, 0.05, 0.08)


func _summon() -> void:
	var ids: Array = ["cerbatana", "cerbatana"] if phase < 2 else ["jaguar", "cerbatana", "cerbatana"]
	for i in ids.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Gfx.push_out(position + Vector2(side * (80.0 + float(i) * 18.0), 30.0), 14.0, game.room.rects)
		game.fx.ring(pos, 8.0, 60.0, JADE, 0.4, 3.0)
		game.fx.burst(pos, 12, 220.0, Color("a8ffe0"), 0.4)
		game.director.spawn_enemy_at(ids[i], pos, false)
	game.sfx.play("spawn", -3.0)


# ------------------------------------------------------------------ animacion / muerte
func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (2.0 + spd * 0.08)
	var sw := sin(walk_ph)
	var amp := clampf(spd / maxf(speed, 1.0), 0.0, 1.3)
	var ss := signf(sw)
	if ss != step_sign and amp > 0.4 and state != ST_CHARGE:
		step_sign = ss
		game.fx.puff(position + Vector2(ss * 26.0, 0), Vector2(0, -6), 14.0, Color(0.6, 0.55, 0.45, 0.4), 0.5, 2.4)
		game.sfx.play("stomp", -10.0, 0.7, 0.1, 0.1)
		game.shake(0.05)
	elif amp <= 0.4:
		step_sign = ss
	var bob := absf(sw) * 3.0 * amp
	torso_p.position = Vector2(0, -26 - bob + squat * 5.0)
	torso_p.rotation = lean + sw * 0.02 * amp
	head_p.position = Vector2(lean * 36.0, -112 - bob * 1.1 + squat * 6.0)
	head_p.rotation = lean * 0.6
	glyphs_p.position = Vector2(0, -62 - bob + squat * 4.0)
	var tgt := 0.7 + sw * 0.08 * amp
	var rate := 7.0
	match state:
		ST_SMASH_WIND:
			tgt = -2.3
			rate = 12.0
		ST_SMASH_HIT:
			tgt = 1.7
			rate = 40.0
		ST_GLYPH_WIND, ST_GLYPH_FIRE, ST_PHASE:
			tgt = -1.5
			rate = 10.0
		ST_CHARGE_WIND:
			tgt = 0.0
		ST_CHARGE:
			tgt = 1.2
		_:
			pass
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * rate, 0.0, 1.0))
	arm_f.position = Vector2(46 + lean * 12.0, -80 - bob + squat * 5.0)
	arm_b.position = Vector2(-46 + lean * 12.0, -80 - bob + squat * 5.0)
	if state == S_SPAWN:
		core_glow = 0.2
	legs_p.queue_redraw()
	torso_p.queue_redraw()
	disc_p.queue_redraw()
	glow_p.soft_redraw()
	head_p.queue_redraw()
	arm_f.queue_redraw()
	arm_b.queue_redraw()
	glyphs_p.queue_redraw()


func _start_dying(_dir: Vector2) -> void:
	state = S_DYING
	dying_t = 0.0
	game.on_enemy_dying(self)
	game.bullets.clear_enemy_bullets(position, 3000.0)
	vel = Vector2.ZERO
	game.sfx.play("roar", 0.0, 0.5)
	game.slow_enemies(0.4, 2.4)
	game.shake(0.8)


func _dying(dt: float) -> void:
	dying_t += dt
	flash = 0.6 if int(dying_t * 20.0) % 2 == 0 else 0.1
	fmat.set_shader_parameter("flash", flash)
	vis.position = Vector2(randf_range(-3, 3), randf_range(-2, 2) + dying_t * 3.0)
	if int(dying_t * 14.0) != int((dying_t - dt) * 14.0):
		var p := position + Vector2(randf_range(-44, 44), randf_range(-100, -10))
		game.fx.burst(p, 8, 280.0, _pc(), 0.4)
		game.fx.flash(p, 50.0, Color(1, 0.85, 0.5, 0.8), 0.12)
		game.fx.shard(p, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 220), Color("8a7a62"), randf_range(3, 6), Color(_pc().r, _pc().g, _pc().b, 0.7))
		game.sfx.play("hit", -6.0, 0.6 + randf() * 0.4)
		game.shake(0.1)
	core_glow = 1.0
	disc_speed = 10.0
	_animate(dt)
	if dying_t >= 2.3:
		_explode()
