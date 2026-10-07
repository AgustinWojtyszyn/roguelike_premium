class_name BossMariscal
extends Boss
## MARISCAL ESCARLATA, señor de la Fortaleza: un coloso acorazado con mandoble y escudo torre.
## Todo ataque tiene LECTURA: marca roja en el suelo (cono, anillo o carril de carga) -> golpe -> recuperacion.
## Desde el frente el escudo absorbe parte del dano; flanquearlo o aprovechar el aturdimiento tras chocar con un muro paga mas.

const ST_WALK := 1
const ST_CLEAVE_WIND := 2
const ST_CLEAVE_HIT := 3
const ST_SLAM_WIND := 4
const ST_SLAM_HIT := 5
const ST_CHARGE_WIND := 6
const ST_CHARGE := 7
const ST_STUN := 8
const ST_SUMMON := 9
const ST_REC := 10
const ST_PHASE := 11

const CRIMSON := Color("e0405a")
const STEEL := Color("8a8fa6")
const PHASE_COLS := [Color("e0405a"), Color("ff8a3a"), Color("fff0c0")]

var legs_p: Part
var torso_p: Part
var head_p: Part
var arm_f: Part
var arm_b: Part
var tele_p: Part
var walk_ph := 0.0
var step_sign := 1.0
var cd := 1.4
var lean := 0.0
var squat := 0.0
var arm_ang := 0.7
var glow := 0.3
var phase_flash := 0.0
var last_attack := ""
var steam_t := 0.0
var aim_dir := Vector2.RIGHT
var charge_dir := Vector2.RIGHT
var charge_speed_cur := 0.0
var charges_left := 0
var hit_done := false
var summon_done := false
var tele_k := 0.0            # 0..1 progreso de la marca en el suelo
var tele_kind := ""          # "", "cone", "ring", "lane"
var tele_was := false


func _build() -> void:
	kind_name = "mariscal"
	hp = boss_data.hp
	radius = 32.0
	hit_r = 44.0
	hit_off = Vector2(0, -54.0)
	speed = 58.0
	bar_y = -146.0
	glow_col = boss_data.accent
	big = true
	spawn_dur = 1.6
	phase_marks_arr = [boss_data.phases[1], boss_data.phases[2]]
	tele_p = Part.make(self, _paint_tele, Vector2.ZERO)
	tele_p.show_behind_parent = true
	legs_p = Part.make(vis, _paint_legs, Vector2.ZERO)
	arm_b = Part.make(vis, _paint_shield, Vector2(-44, -78))
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -24))
	head_p = Part.make(vis, _paint_head, Vector2(0, -108))
	arm_f = Part.make(vis, _paint_sword_arm, Vector2(44, -78))


func _death_chunks() -> Array:
	return [Color("5a5f78"), Color("2a2a3a"), CRIMSON, Color("c8ccd8")]


func mass() -> float:
	return 40.0


func dmg_mult(dir: Vector2) -> float:
	match state:
		ST_STUN:
			return 1.8
		ST_REC:
			return 1.3
		ST_PHASE:
			return 0.25
		S_SPAWN:
			return 0.0
	# escudo: una bala que viaja contra la direccion en que mira le pega de frente
	if dir.x * face < -0.2 and state in [ST_WALK, ST_CLEAVE_WIND, ST_SLAM_WIND]:
		return 0.6
	return 0.9


func targetable() -> bool:
	return state != S_DYING and state != S_SPAWN


func _pc() -> Color:
	return PHASE_COLS[phase]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, 2), 96.0, Color(0, 0, 0, 0.62))


# ------------------------------------------------------------------ dibujo
func _paint_tele(c: Part) -> void:
	if tele_kind == "":
		return
	var col := Color(1.0, 0.25, 0.25)
	var pulse := 0.55 + 0.45 * sin(t * 24.0)
	var a := (0.18 + 0.32 * tele_k) * pulse + 0.1
	match tele_kind:
		"cone":
			var base := aim_dir.angle()
			var pts := PackedVector2Array([Vector2.ZERO])
			for i in 13:
				pts.append(Vector2.from_angle(base - 0.95 + 1.9 * float(i) / 12.0) * 150.0)
			c.draw_colored_polygon(pts, Color(col, a * 0.7))
			c.draw_arc(Vector2.ZERO, 150.0, base - 0.95, base + 0.95, 20, Color(col, 0.9), 2.0, true)
			c.draw_arc(Vector2.ZERO, 150.0 * tele_k, base - 0.95, base + 0.95, 20, Color(1, 0.8, 0.6, 0.8), 2.0, true)
		"ring":
			c.draw_circle(Vector2.ZERO, 118.0, Color(col, a * 0.45))
			c.draw_arc(Vector2.ZERO, 118.0, 0.0, TAU, 40, Color(col, 0.9), 2.5, true)
			c.draw_arc(Vector2.ZERO, 118.0 * tele_k, 0.0, TAU, 40, Color(1, 0.8, 0.6, 0.8), 2.0, true)
		"lane":
			var side := charge_dir.orthogonal() * (radius + 4.0)
			var len := 560.0
			var pts2 := PackedVector2Array([side, side + charge_dir * len, -side + charge_dir * len, -side])
			c.draw_colored_polygon(pts2, Color(col, a * 0.7))
			c.draw_line(side, side + charge_dir * len, Color(col, 0.9), 2.0)
			c.draw_line(-side, -side + charge_dir * len, Color(col, 0.9), 2.0)
			c.draw_line(charge_dir * len * tele_k, charge_dir * len * tele_k + side, Color(1, 0.8, 0.6, 0.7), 2.0)


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for s in [-1.0, 1.0]:
		var lift: float = maxf(0.0, sin(walk_ph + (0.0 if s < 0.0 else PI))) * 7.0 * clampf(vel.length() / speed, 0.0, 1.0)
		var x: float = s * 24.0
		var y := -6.0 - lift - squat * 4.0
		Gfx.grrect(c, Rect2(x - 14, y - 38, 28, 34), 4.0, STEEL, Color("3a3e54"), ink, 2.4)
		c.draw_rect(Rect2(x - 12, y - 24, 24, 3), Color(CRIMSON, 0.7))
		Gfx.gpoly(c, PackedVector2Array([Vector2(x - 18, y - 6), Vector2(x + 18, y - 6), Vector2(x + 22, y + 6), Vector2(x - 22, y + 6)]), Color("6a6e86"), Color("2a2c3c"), ink, 2.4)


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var body := PackedVector2Array([Vector2(-38, 0), Vector2(38, 0), Vector2(52, -24), Vector2(46, -54), Vector2(26, -72), Vector2(-26, -72), Vector2(-46, -54), Vector2(-52, -24)])
	Gfx.gpoly(c, body, Color("7a809a"), Color("34384c"), ink, 3.0)
	# peto escarlata con emblema
	Gfx.gpoly(c, PackedVector2Array([Vector2(-26, -6), Vector2(26, -6), Vector2(30, -40), Vector2(0, -62), Vector2(-30, -40)]), col.darkened(0.15), col.darkened(0.55), ink, 2.2)
	c.draw_line(Vector2(0, -56), Vector2(0, -12), Color(1, 0.9, 0.7, 0.55 + glow * 0.4), 2.4)
	c.draw_line(Vector2(-14, -34), Vector2(14, -34), Color(1, 0.9, 0.7, 0.55 + glow * 0.4), 2.4)
	# hombreras
	for s in [-1.0, 1.0]:
		Gfx.gell(c, Vector2(s * 46, -58), 17.0, 13.0, Color("a0a6c0"), Color("4a4e66"), ink, 2.4)
		for k in 3:
			c.draw_line(Vector2(s * (40 + k * 6), -66), Vector2(s * (40 + k * 6), -50), Color(0, 0, 0, 0.35), 1.4)
	c.draw_rect(Rect2(-38, -4, 76, 6), ink)
	c.draw_rect(Rect2(-36, -3, 72, 4), Color("c8a050"))
	if phase >= 1:
		c.draw_polyline(PackedVector2Array([Vector2(-18, -66), Vector2(-12, -52), Vector2(-20, -42)]), Color(col, 0.95), 2.0, true)
	if phase >= 2:
		c.draw_polyline(PackedVector2Array([Vector2(18, -64), Vector2(12, -50), Vector2(20, -38)]), Color(col, 0.95), 2.0, true)


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	# cresta
	Gfx.poly(c, PackedVector2Array([Vector2(-4, -22), Vector2(0, -44 - glow * 4.0), Vector2(4, -22)]), col, ink, 1.8)
	for s in [-1.0, 1.0]:
		Gfx.poly(c, PackedVector2Array([Vector2(s * 14, -14), Vector2(s * 30, -34), Vector2(s * 20, -8)]), Color("c8ccd8"), ink, 1.8)
	var helm := PackedVector2Array([Vector2(-18, 10), Vector2(-22, -8), Vector2(-14, -22), Vector2(14, -22), Vector2(22, -8), Vector2(18, 10), Vector2(8, 14), Vector2(-8, 14)])
	Gfx.gpoly(c, helm, Color("9a9fb8"), Color("4a4e66"), ink, 2.6)
	c.draw_rect(Rect2(-15, -6, 30, 6), Color("0a0a12"))
	c.draw_rect(Rect2(-13, -5, 26, 3), col.lerp(Color.WHITE, phase_flash))
	c.draw_line(Vector2(0, -22), Vector2(0, 12), Color(0, 0, 0, 0.4), 2.0)


func _paint_sword_arm(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var a := arm_ang
	var elbow := Vector2.from_angle(a) * 22.0
	var hand := elbow + Vector2.from_angle(a + 0.5) * 20.0
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), ink, 16.0, true)
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), Color("7a809a"), 11.0, true)
	c.draw_circle(elbow, 7.0, ink)
	c.draw_circle(elbow, 5.0, Color("a0a6c0"))
	c.draw_set_transform(hand, a + 0.5, Vector2.ONE)
	# mandoble
	Gfx.rrect(c, Rect2(-4, -3, 14, 6), 2.0, Color("6a4a2c"), ink, 1.6)
	c.draw_rect(Rect2(8, -9, 4, 18), ink)
	c.draw_rect(Rect2(9, -8, 2, 16), Color("c8a050"))
	var blade := PackedVector2Array([Vector2(12, -5), Vector2(82, -3), Vector2(94, 0), Vector2(82, 3), Vector2(12, 5)])
	Gfx.gpoly(c, blade, Color("e8ecf8"), Color("8a8fa6"), ink, 2.0)
	c.draw_line(Vector2(14, 0), Vector2(86, 0), Color(col, 0.55 + glow * 0.4), 1.6)
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_shield(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var pts := PackedVector2Array([Vector2(-8, -34), Vector2(12, -30), Vector2(18, 0), Vector2(12, 34), Vector2(-8, 38), Vector2(-14, 0)])
	Gfx.gpoly(c, pts, Color("6a6e86"), Color("2a2c3c"), ink, 3.0)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-2, -24), Vector2(8, -20), Vector2(10, 0), Vector2(8, 22), Vector2(-2, 26), Vector2(-6, 0)]), col.darkened(0.2), col.darkened(0.6), ink, 1.6)
	c.draw_circle(Vector2(2, 0), 4.0, Color("e8c870"))


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
	tele_kind = ""
	phase_flash = 1.0
	game.bullets.clear_enemy_bullets(position, 2000.0)
	game.shake(0.7)
	game.hitstop(0.12)
	game.sfx.play("roar", 0.0, 0.7)
	game.slow_enemies(0.35, 0.5)
	var c := hit_center()
	var col := _pc()
	game.fx.ring(c, 20.0, 260.0, col, 0.6, 8.0)
	game.fx.ring(c, 10.0, 170.0, Color.WHITE, 0.4, 5.0)
	game.fx.flash(c, 220.0, Color(col, 0.9), 0.35)
	game.fx.burst(c, 36, 440.0, col, 0.7)
	for i in 12:
		game.fx.shard(c + Vector2(randf_range(-40, 40), randf_range(-20, 20)), Vector2.from_angle(randf() * TAU) * randf_range(120, 320), randf_range(140, 300), Color("5a5f78").lerp(Color("2a2a3a"), randf()), randf_range(4, 8), Color(col.r, col.g, col.b, 0.8))
	torso_p.queue_redraw()
	head_p.queue_redraw()


func _think(dt: float) -> void:
	_check_phase()
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	phase_flash = maxf(0.0, phase_flash - dt * 2.5)
	steam_t -= dt
	var sp := speed * (1.0 + 0.25 * float(phase))
	match state:
		ST_WALK:
			glow = move_toward(glow, 0.3, dt)
			lean = lerpf(lean, 0.0, dt * 6.0)
			tele_kind = ""
			face_toward(pl.position, dt, 6.0)
			var dir := Vector2.ZERO
			if dist > 300.0:
				dir = dirp
			elif dist < 170.0:
				dir = -dirp * 0.6
			dir += Vector2(-dirp.y, dirp.x) * sin(t * 0.7) * 0.5
			steer(dir, sp if stun <= 0.0 else 0.0, dt, 280.0)
			cd -= dt
			if cd <= 0.0 and not pl.dead:
				_pick_attack(dist)
		ST_CLEAVE_WIND:
			vel = vel.move_toward(dirp * 40.0, 700.0 * dt)
			face_toward(pl.position, dt, 10.0)
			if st < 0.45:
				aim_dir = aim_dir.lerp(dirp, clampf(dt * 10.0, 0.0, 1.0)).normalized()
			tele_k = clampf(st / 0.75, 0.0, 1.0)
			glow = tele_k
			lean = lerpf(lean, -0.14, dt * 9.0)
			if st >= (0.75 if phase < 2 else 0.58):
				state = ST_CLEAVE_HIT
				st = 0.0
				hit_done = false
		ST_CLEAVE_HIT:
			lean = lerpf(lean, 0.2, dt * 20.0)
			if not hit_done and st >= 0.04:
				hit_done = true
				_cleave()
			if st >= 0.22:
				_end_attack()
		ST_SLAM_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 8.0)
			tele_k = clampf(st / 0.95, 0.0, 1.0)
			glow = tele_k
			squat = lerpf(squat, -0.4, dt * 8.0)
			if st >= (0.95 if phase < 2 else 0.75):
				state = ST_SLAM_HIT
				st = 0.0
				hit_done = false
		ST_SLAM_HIT:
			squat = lerpf(squat, 0.6, dt * 30.0)
			if not hit_done:
				hit_done = true
				_slam()
			if st >= 0.3:
				_end_attack()
		ST_CHARGE_WIND:
			vel = vel.move_toward(Vector2.ZERO, 1100.0 * dt)
			face_toward(pl.position, dt, 14.0)
			var wind := 0.9 if charges_left >= 1 + phase else 0.55
			if st < wind * 0.55:
				charge_dir = charge_dir.lerp(dirp, clampf(dt * 8.0, 0.0, 1.0)).normalized()
			tele_k = clampf(st / wind, 0.0, 1.0)
			glow = tele_k
			squat = lerpf(squat, 0.8, dt * 8.0)
			if steam_t <= 0.0:
				steam_t = 0.05
				game.fx.puff(position + Vector2(randf_range(-30, 30), -2), Vector2(randf_range(-30, 30), -20), 9.0, Color(0.8, 0.7, 0.65, 0.45), 0.5, 2.4)
			if st >= wind:
				state = ST_CHARGE
				st = 0.0
				charge_speed_cur = speed
				hit_done = false
				tele_kind = ""
				game.sfx.play("stomp", -2.0, 0.7)
		ST_CHARGE:
			squat = lerpf(squat, 0.3, dt * 6.0)
			charge_speed_cur = move_toward(charge_speed_cur, 330.0 + 40.0 * float(phase), 620.0 * dt)
			vel = charge_dir * charge_speed_cur
			if int(st * 40.0) % 3 == 0:
				game.fx.puff(position + Vector2(randf_range(-20, 20), -2), -charge_dir * 30.0, 10.0, Color(0.75, 0.68, 0.6, 0.5), 0.45, 2.2)
			if not hit_done and pl.position.distance_to(position) < radius + Player.RADIUS + 14.0 and pl.can_be_hit():
				hit_done = true
				pl.take_damage(2, charge_dir, 380.0)
			var ahead := position + charge_dir * (radius + 22.0)
			if not game.room.free_point(ahead, radius * 0.7):
				_wall_crash(ahead)
			elif st >= 0.9:
				charges_left -= 1
				if charges_left > 0:
					state = ST_CHARGE_WIND
					st = 0.0
					tele_kind = "lane"
				else:
					_end_attack()
		ST_STUN:
			vel = vel.move_toward(Vector2.ZERO, 600.0 * dt)
			glow = 1.0
			squat = lerpf(squat, 0.5, dt * 6.0)
			if steam_t <= 0.0:
				steam_t = 0.06
				game.fx.puff(position + Vector2(randf_range(-26, 26), -80), Vector2(randf_range(-30, 30), -60), 10.0, Color(0.9, 0.9, 1.0, 0.5), 0.7, 2.6)
			if st >= 2.0:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.8
		ST_SUMMON:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			glow = 0.8
			arm_ang = lerpf(arm_ang, -1.6, clampf(dt * 8.0, 0.0, 1.0))
			if not summon_done and st >= 0.9:
				summon_done = true
				_summon()
			if st >= 1.7:
				_end_attack()
		ST_REC:
			tele_kind = ""
			glow = move_toward(glow, 0.2, dt)
			squat = lerpf(squat, 0.2, dt * 6.0)
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			if st >= 0.8:
				state = ST_WALK
				st = 0.0
				squat = 0.0
		ST_PHASE:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			glow = 1.0
			squat = lerpf(squat, 0.5, dt * 8.0)
			if steam_t <= 0.0:
				steam_t = 0.04
				game.fx.spark(position + Vector2(randf_range(-40, 40), -60), Vector2.UP, 2, 260.0, _pc(), 0.3, 1.2)
			if st >= 1.6:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.6
	if tele_kind != "" or tele_was:
		tele_p.queue_redraw()
	tele_was = tele_kind != ""


func _pick_attack(dist: float) -> void:
	var pool: Array = []
	pool.append(["cleave", (4.0 if dist < 240.0 else 1.2) * (1.0 if last_attack != "cleave" else 0.3)])
	pool.append(["slam", (3.0 if dist < 260.0 else 1.5) * (1.0 if last_attack != "slam" else 0.3)])
	pool.append(["charge", 3.0 if last_attack != "charge" else 0.0])
	if phase >= 1:
		var adds := 0
		for e in game.enemies:
			if e != self:
				adds += 1
		if adds < 3:
			pool.append(["summon", 2.2 if last_attack != "summon" else 0.0])
	var total := 0.0
	for p in pool:
		total += float(p[1])
	var r := randf() * total
	var pick: String = pool[0][0]
	for p in pool:
		r -= float(p[1])
		if r <= 0.0:
			pick = p[0]
			break
	last_attack = pick
	st = 0.0
	var dirp := (game.player.position - position).normalized()
	aim_dir = dirp
	match pick:
		"cleave":
			state = ST_CLEAVE_WIND
			tele_kind = "cone"
			game.sfx.play("wind", -2.0, 0.55)
		"slam":
			state = ST_SLAM_WIND
			tele_kind = "ring"
			game.sfx.play("charge", -4.0, 0.7)
		"charge":
			state = ST_CHARGE_WIND
			tele_kind = "lane"
			charge_dir = dirp
			charges_left = 1 + phase
			game.sfx.play("wind", -2.0, 0.45)
		"summon":
			state = ST_SUMMON
			summon_done = false
			game.sfx.play("roar", -6.0, 1.2)


func _end_attack() -> void:
	state = ST_REC
	st = 0.0
	tele_kind = ""
	cd = maxf(0.5, 1.3 - 0.2 * float(phase))


func _cleave() -> void:
	var pl := game.player
	var col := _pc()
	var origin := position + Vector2(0, -50)
	game.fx.slash_arc(origin, aim_dir.angle(), 140.0, 1.9, col.lightened(0.4))
	game.fx.burst(origin + aim_dir * 100.0, 16, 380.0, Color("ffd9c0"), 0.4)
	game.sfx.play("slam", -2.0, 1.1)
	game.shake(0.45)
	game.hitstop(0.04)
	var to := pl.position - position
	if to.length() < 150.0 + Player.RADIUS and absf(aim_dir.angle_to(to)) < 0.95 and pl.can_be_hit():
		pl.take_damage(2, to.normalized(), 380.0)
	if phase >= 1:
		var n := 5 + phase * 2
		for i in n:
			var a := aim_dir.angle() + (float(i) - float(n - 1) * 0.5) * 0.22
			var b := game.bullets.fire(origin + aim_dir * 60.0, Vector2.from_angle(a), 260.0, 2.6, 1.0, Bullets.Style.SHARD, 1)
			b.col = col


func _slam() -> void:
	var pl := game.player
	var col := _pc()
	var c := position + Vector2(0, -4)
	tele_kind = ""
	game.fx.ring(c, 10.0, 150.0, col.lightened(0.3), 0.35, 7.0)
	game.fx.ring(c, 6.0, 90.0, Color.WHITE, 0.25, 4.0)
	game.fx.flash(c, 140.0, Color(col, 0.8), 0.18)
	game.fx.burst(c, 30, 440.0, Color("ffd9c0"), 0.45)
	for i in 12:
		game.fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(80, 280), randf_range(120, 280), Color("5a5f78"), randf_range(3, 6))
	game.fx.add_decal(c, 1, 90.0, Color.BLACK)
	game.sfx.play("slam", 0.0, 0.9)
	game.shake(0.7)
	game.hitstop(0.05)
	if pl.position.distance_to(position) < 118.0 + Player.RADIUS and pl.can_be_hit():
		pl.take_damage(2, (pl.position - position).normalized(), 400.0)
	# onda de proyectiles con huecos: hay que colarse entre ellos
	var n := 14 + phase * 3
	var off := randf() * TAU
	for i in n:
		if i % 5 == 2:
			continue
		var a := off + TAU * float(i) / float(n)
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 36.0, Vector2.from_angle(a), 210.0, 3.2, 1.0, Bullets.Style.SHARD, 1)
		b.col = col
	if phase >= 1:
		get_tree().create_timer(0.4).timeout.connect(_slam_echo.bind(off + TAU / float(n) * 0.5, n))


func _slam_echo(off: float, n: int) -> void:
	if state == S_DYING or not is_inside_tree():
		return
	var c := position + Vector2(0, -4)
	game.fx.ring(c, 8.0, 100.0, _pc(), 0.25, 4.0)
	for i in n:
		if i % 5 == 2:
			continue
		var a := off + TAU * float(i) / float(n)
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 36.0, Vector2.from_angle(a), 190.0, 3.2, 1.0, Bullets.Style.SHARD, 1)
		b.col = _pc()


func _wall_crash(ahead: Vector2) -> void:
	state = ST_STUN
	st = 0.0
	tele_kind = ""
	vel = -charge_dir * 80.0
	game.fx.ring(ahead, 8.0, 130.0, Color("ffd9a0"), 0.35, 6.0)
	game.fx.burst(ahead, 24, 360.0, Color("ffd9c0"), 0.5)
	for i in 10:
		game.fx.shard(ahead, Vector2.from_angle(randf() * TAU) * randf_range(80, 260), randf_range(120, 260), Color("5a5f78"), randf_range(3, 6))
	if phase >= 1:
		var base := (-charge_dir).angle()
		for i in 7:
			var b := game.bullets.fire(ahead, Vector2.from_angle(base + (float(i) - 3.0) * 0.3), 200.0, 2.4, 1.0, Bullets.Style.SHARD, 1)
			b.col = _pc()
	game.shake(0.65)
	game.hitstop(0.06)
	game.sfx.play("slam", 0.0, 0.8)


func _summon() -> void:
	var ids: Array = ["sabueso", "sabueso"] if phase < 2 else ["caballero", "sabueso", "sabueso"]
	for i in ids.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Gfx.push_out(position + Vector2(side * (90.0 + float(i) * 18.0), 30.0), 14.0, game.room.rects)
		game.fx.ring(pos, 8.0, 60.0, CRIMSON, 0.4, 3.0)
		game.fx.burst(pos, 12, 220.0, Color("ffb0b8"), 0.4)
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
		game.fx.puff(position + Vector2(ss * 24.0, 0), Vector2(0, -6), 14.0, Color(0.6, 0.55, 0.5, 0.4), 0.5, 2.4)
		game.sfx.play("stomp", -10.0, 0.7, 0.1, 0.1)
		game.shake(0.05)
	elif amp <= 0.4:
		step_sign = ss
	var bob := absf(sw) * 3.0 * amp
	torso_p.position = Vector2(0, -24 - bob + squat * 5.0)
	torso_p.rotation = lean + sw * 0.02 * amp
	head_p.position = Vector2(lean * 34.0, -108 - bob * 1.1 + squat * 6.0)
	head_p.rotation = lean * 0.6
	var tgt := 0.7 + sw * 0.08 * amp
	var rate := 7.0
	match state:
		ST_CLEAVE_WIND:
			tgt = -2.4
			rate = 12.0
		ST_CLEAVE_HIT:
			tgt = 1.5
			rate = 40.0
		ST_SLAM_WIND:
			tgt = -2.5
			rate = 10.0
		ST_SLAM_HIT:
			tgt = 1.9
			rate = 40.0
		ST_SUMMON, ST_PHASE:
			tgt = -1.6
			rate = 10.0
		ST_CHARGE_WIND:
			tgt = -0.2
		ST_CHARGE:
			tgt = 1.1
		_:
			pass
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * rate, 0.0, 1.0))
	arm_f.position = Vector2(44 + lean * 12.0, -78 - bob + squat * 5.0)
	arm_b.position = Vector2(-44 + lean * 12.0, -78 - bob + squat * 5.0)
	legs_p.queue_redraw()
	torso_p.queue_redraw()
	head_p.queue_redraw()
	arm_f.queue_redraw()
	arm_b.queue_redraw()


func _start_dying(_dir: Vector2) -> void:
	state = S_DYING
	dying_t = 0.0
	tele_kind = ""
	tele_p.queue_redraw()
	game.on_enemy_dying(self)
	game.bullets.clear_enemy_bullets(position, 3000.0)
	vel = Vector2.ZERO
	game.sfx.play("roar", 0.0, 0.55)
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
		game.fx.shard(p, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 220), Color("5a5f78"), randf_range(3, 6), Color(_pc().r, _pc().g, _pc().b, 0.7))
		game.sfx.play("hit", -6.0, 0.6 + randf() * 0.4)
		game.shake(0.1)
	glow = 1.0
	_animate(dt)
	if dying_t >= 2.3:
		_explode()
