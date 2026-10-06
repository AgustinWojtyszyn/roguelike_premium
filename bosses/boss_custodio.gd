class_name BossCustodio
extends Boss
## CUSTODIO: el mecanismo de seguridad del nucleo, corrompido. Tres fases con ataques distintos que se leen por
## la POSTURA del cuerpo (se echa atras para pisar, alza el brazo para barrer, abre las rejillas para invocar).
## Sin telegrafos de suelo: brillo del nucleo, vapor, particulas y movimiento del chasis.

const ST_WALK := 1
const ST_STOMP_WIND := 2
const ST_STOMP_SLAM := 3
const ST_REC := 4
const ST_VOLLEY_AIM := 5
const ST_VOLLEY_FIRE := 6
const ST_SWEEP_WIND := 7
const ST_SWEEP_HIT := 8
const ST_SUMMON := 9
const ST_SPIRAL := 10
const ST_VENT := 11
const ST_PHASE := 12

var legs_p: Part
var torso_p: Part
var head_p: Part
var cannon_l: Part
var cannon_r: Part
var arm_f: Part
var arm_b: Part
var core_p: Part
var vents_p: Part
var walk_ph := 0.0
var cd := 1.6
var lean := 0.0
var squat := 0.0
var core_glow := 0.3
var arm_ang := 0.6
var sweep_ang := 0.0
var cannon_aim := Vector2.DOWN
var volley_left := 0
var volley_t := 0.0
var volley_side := 1.0
var ring_second := -1.0
var spiral_ang := 0.0
var spiral_t := 0.0
var steam_t := 0.0
var last_attack := ""
var attacks_since_vent := 0
var vent_open := 0.0
var eye := Vector2.DOWN
var phase_flash := 0.0
var dmg_taken_bar := 0.0
var summon_done := false
var slam_done := false

const PHASE_COLS := [Color("ff4fa8"), Color("c47bff"), Color("ff6a3a")]


func _build() -> void:
	kind_name = "custodio"
	hp = boss_data.hp
	radius = 34.0
	hit_r = 48.0
	hit_off = Vector2(0, -58.0)
	speed = 52.0
	bar_y = -150.0
	glow_col = boss_data.accent
	big = true
	spawn_dur = 1.6
	phase_marks_arr = [boss_data.phases[1], boss_data.phases[2]]
	legs_p = Part.make(vis, _paint_legs, Vector2(0, 0))
	arm_b = Part.make(vis, _paint_arm, Vector2(-44, -82))
	arm_b.set_meta("back", true)
	vents_p = Part.make(vis, _paint_vents, Vector2(0, -92))
	torso_p = Part.make(vis, _paint_torso, Vector2(0, -26))
	core_p = Part.make(torso_p, _paint_core, Vector2(0, -34), true)
	cannon_l = Part.make(vis, _paint_cannon, Vector2(-54, -92))
	cannon_l.set_meta("side", -1.0)
	cannon_r = Part.make(vis, _paint_cannon, Vector2(54, -92))
	cannon_r.set_meta("side", 1.0)
	head_p = Part.make(vis, _paint_head, Vector2(0, -112))
	arm_f = Part.make(vis, _paint_arm, Vector2(44, -82))
	arm_f.set_meta("back", false)


func _death_chunks() -> Array:
	return [Color("3a4668"), Color("232b44"), Color("8793b8"), Color("ff4fa8"), Color("c98a22")]


func mass() -> float:
	return 40.0


func dmg_mult(_dir: Vector2) -> float:
	match state:
		ST_VENT, ST_REC:
			return 1.5
		ST_PHASE:
			return 0.25
		S_SPAWN:
			return 0.0
	return 0.8


func targetable() -> bool:
	return state != S_DYING and state != S_SPAWN


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, 2), 96.0, Color(0, 0, 0, 0.62))


func _pc() -> Color:
	return PHASE_COLS[phase]


# ------------------------------------------------------------------ dibujo
func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	for s in [-1.0, 1.0]:
		var lift: float = maxf(0.0, sin(walk_ph + (0.0 if s < 0.0 else PI))) * 7.0 * clampf(vel.length() / speed, 0.0, 1.0)
		var x: float = s * 27.0
		var y := -8.0 - lift - squat * 5.0
		# piston
		Gfx.grrect(c, Rect2(x - 5, y - 36, 10, 30), 2.0, Color("8793b8"), Color("3a4668"), ink, 2.0)
		c.draw_rect(Rect2(x - 3, y - 36, 6, 8), Color("c8d4ee"))
		# pie
		var foot := PackedVector2Array([Vector2(x - 19, y - 8), Vector2(x + 19, y - 8), Vector2(x + 24, y + 6), Vector2(x + 18, y + 12), Vector2(x - 18, y + 12), Vector2(x - 24, y + 6)])
		Gfx.gpoly(c, foot, Color("5a6890"), Color("1e2744"), ink, 2.6)
		c.draw_line(Vector2(x - 14, y - 4), Vector2(x + 14, y - 4), Color(1, 1, 1, 0.22), 1.6)
		c.draw_rect(Rect2(x - 18, y + 4, 36, 3), Color("c98a22"))


func _paint_torso(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	# chasis principal
	var body := PackedVector2Array([Vector2(-44, 0), Vector2(44, 0), Vector2(52, -22), Vector2(48, -52), Vector2(30, -72), Vector2(-30, -72), Vector2(-48, -52), Vector2(-52, -22)])
	Gfx.gpoly(c, body, Color("56648e"), Color("1e2744"), ink, 3.0)
	# placas laterales (se pierden por fase)
	for s in [-1.0, 1.0]:
		if phase < 2 or s > 0.0:
			var plate := PackedVector2Array([Vector2(s * 40, -12), Vector2(s * 56, -26), Vector2(s * 53, -58), Vector2(s * 38, -64)])
			Gfx.gpoly(c, plate, Color("8793b8"), Color("3a4668"), ink, 2.2)
			c.draw_line(Vector2(s * 44, -24), Vector2(s * 50, -50), Color(1, 1, 1, 0.3), 1.6)
		else:
			# placa arrancada: cables y bordes quemados
			c.draw_line(Vector2(-42, -20), Vector2(-52, -34), ink, 4.0, true)
			c.draw_line(Vector2(-42, -20), Vector2(-52, -34), Color("c98a22"), 1.8, true)
			c.draw_line(Vector2(-40, -44), Vector2(-50, -52), ink, 4.0, true)
			c.draw_line(Vector2(-40, -44), Vector2(-50, -52), col, 1.8, true)
	# peto
	var chest := PackedVector2Array([Vector2(-30, -6), Vector2(30, -6), Vector2(34, -38), Vector2(20, -64), Vector2(-20, -64), Vector2(-34, -38)])
	Gfx.gpoly(c, chest, Color("a8b4d4"), Color("5a6890"), ink, 2.4)
	# abdomen oscuro
	Gfx.rrect(c, Rect2(-22, -14, 44, 14), 3.0, Color("14192c"), ink, 2.0)
	for k in 5:
		c.draw_line(Vector2(-18 + k * 9.0, -12), Vector2(-18 + k * 9.0, -2), Color(col, 0.7), 1.6)
	# remaches y franjas
	c.draw_rect(Rect2(-44, -2, 88, 4), Color("c98a22"))
	for k in 6:
		c.draw_circle(Vector2(-36 + k * 14.4, -66), 1.8, Color("1a2038"))
	# grietas segun fase
	if phase >= 1:
		c.draw_polyline(PackedVector2Array([Vector2(-12, -64), Vector2(-6, -52), Vector2(-14, -44), Vector2(-8, -34)]), ink, 3.0, true)
		c.draw_polyline(PackedVector2Array([Vector2(-12, -64), Vector2(-6, -52), Vector2(-14, -44), Vector2(-8, -34)]), Color(col, 0.9), 1.4, true)
	if phase >= 2:
		c.draw_polyline(PackedVector2Array([Vector2(16, -62), Vector2(10, -48), Vector2(18, -40)]), ink, 3.0, true)
		c.draw_polyline(PackedVector2Array([Vector2(16, -62), Vector2(10, -48), Vector2(18, -40)]), Color(col, 0.9), 1.4, true)


func _paint_core(c: Part) -> void:
	var col := _pc()
	var g := core_glow
	var hex := Gfx.ell_pts(Vector2.ZERO, 14.0, 14.0, 6, PI / 6.0)
	c.draw_colored_polygon(hex, Color(col.lightened(0.2), 0.4 + g * 0.5))
	Gfx.outline(c, hex, Color(1, 1, 1, 0.5 + g * 0.5), 2.0)
	Gfx.draw_glow(c, Vector2.ZERO, 36.0 + g * 40.0, Color(col, 0.3 + g * 0.5))
	c.draw_circle(Vector2.ZERO, 5.0 + g * 3.0, Color(1, 1, 1, 0.8))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	var head := PackedVector2Array([Vector2(-20, 0), Vector2(20, 0), Vector2(24, -10), Vector2(18, -22), Vector2(-18, -22), Vector2(-24, -10)])
	Gfx.gpoly(c, head, Color("7684a8"), Color("2c3552"), ink, 2.6)
	# visor ancho con ojo que sigue al jugador
	Gfx.rrect(c, Rect2(-17, -17, 34, 10), 4.0, Color("0a0610"), ink, 1.8)
	var ex := clampf(eye.x * 8.0, -10.0, 10.0)
	var ey := clampf(eye.y * 1.5, -1.5, 2.0)
	c.draw_rect(Rect2(-6 + ex, -14 + ey, 12, 4), col.lerp(Color.WHITE, phase_flash))
	c.draw_line(Vector2(-14, -20), Vector2(14, -20), Color(1, 1, 1, 0.3), 1.6)
	for s in [-1.0, 1.0]:
		c.draw_line(Vector2(s * 12, -22), Vector2(s * 16, -32), ink, 4.0, true)
		c.draw_line(Vector2(s * 12, -22), Vector2(s * 16, -32), Color("8793b8"), 2.0, true)
		c.draw_circle(Vector2(s * 16, -32.5), 2.2, col if int(t * 3.0) % 2 == 0 else col.darkened(0.6))


func _paint_cannon(c: Part) -> void:
	var ink := Gfx.INK
	var side: float = c.get_meta("side", 1.0)
	var col := _pc()
	Gfx.gell(c, Vector2.ZERO, 13.0, 12.0, Color("8793b8"), Color("3a4668"), ink, 2.4)
	var open_k := 1.0 if state == ST_VOLLEY_AIM or state == ST_VOLLEY_FIRE else 0.0
	var ang := cannon_aim.angle()
	c.draw_set_transform(Vector2.ZERO, ang, Vector2.ONE)
	Gfx.grrect(c, Rect2(2, -5, 26 + open_k * 4.0, 10), 2.0, Color("c0cce8"), Color("5a6890"), ink, 2.0)
	Gfx.rrect(c, Rect2(24 + open_k * 4.0, -6.5, 6, 13), 1.5, Color("232b44"), ink, 1.6)
	c.draw_rect(Rect2(26 + open_k * 4.0, -1.4, 3, 2.8), col.lerp(Color.WHITE, open_k * 0.6 * (0.5 + 0.5 * sin(t * 30.0))))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	c.draw_circle(Vector2(0, 0), 3.6, col.darkened(0.3))


func _paint_arm(c: Part) -> void:
	var ink := Gfx.INK
	var back: bool = c.get_meta("back", false)
	var s := -1.0 if back else 1.0
	var col := _pc()
	var a := arm_ang if not back else 0.5 + sin(walk_ph) * 0.1
	# brazo hidraulico: dos tramos
	var elbow := Vector2.from_angle(a) * 24.0
	var hand := elbow + Vector2.from_angle(a + (0.6 if not back else 0.2)) * 22.0
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), ink, 17.0, true)
	c.draw_polyline(PackedVector2Array([Vector2.ZERO, elbow, hand]), Color("56648e") if not back else Color("34405e"), 12.0, true)
	c.draw_circle(elbow, 9.0, ink)
	c.draw_circle(elbow, 7.0, Color("8793b8") if not back else Color("4a5878"))
	# puno / garra
	c.draw_set_transform(hand, a + 0.6, Vector2(1.0, 1.0))
	Gfx.grrect(c, Rect2(-8, -11, 22, 22), 4.0, Color("8793b8") if not back else Color("4a5878"), Color("2a3354"), ink, 2.4)
	c.draw_rect(Rect2(6, -9, 5, 18), col.darkened(0.2))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_vents(c: Part) -> void:
	var ink := Gfx.INK
	var o := vent_open * 10.0
	for s in [-1.0, 1.0]:
		var p := PackedVector2Array([Vector2(s * 8, 0), Vector2(s * 26, -4 - o), Vector2(s * 26, -14 - o), Vector2(s * 8, -10)])
		Gfx.gpoly(c, p, Color("3a4668"), Color("141a2c"), ink, 2.0)
		if vent_open > 0.1:
			Gfx.draw_glow(c, Vector2(s * 17, -10 - o), 18.0, Color(1.0, 0.6, 0.3, 0.3 * vent_open))


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
	game.sfx.play("roar", 0.0, 0.7)
	game.slow_enemies(0.35, 0.5)
	var c := hit_center()
	var col := _pc()
	game.fx.ring(c, 20.0, 260.0, col, 0.6, 8.0)
	game.fx.ring(c, 10.0, 180.0, Color.WHITE, 0.4, 5.0)
	game.fx.flash(c, 220.0, Color(col, 0.9), 0.35)
	game.fx.burst(c, 40, 460.0, col, 0.7)
	for i in 14:
		game.fx.shard(c + Vector2(randf_range(-40, 40), randf_range(-20, 20)), Vector2.from_angle(randf() * TAU) * randf_range(120, 320), randf_range(140, 300), Color("8793b8").lerp(Color("232b44"), randf()), randf_range(4, 8), Color(col.r, col.g, col.b, 0.8))
	var m := _pc()
	game.hud.banner("", 0.1)
	torso_p.queue_redraw()


func _think(dt: float) -> void:
	_check_phase()
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	eye = eye.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0))
	phase_flash = maxf(0.0, phase_flash - dt * 2.5)
	vent_open = move_toward(vent_open, 1.0 if state in [ST_SUMMON, ST_VENT] else 0.0, dt * 3.0)
	steam_t -= dt
	var sp := speed * (1.0 + 0.25 * float(phase))
	match state:
		ST_WALK:
			core_glow = move_toward(core_glow, 0.3, dt)
			lean = lerpf(lean, 0.0, dt * 6.0)
			face_toward(pl.position, dt, 6.0)
			var goal := 300.0
			var dir := Vector2.ZERO
			if dist > goal + 50.0:
				dir = dirp
			elif dist < goal - 80.0:
				dir = -dirp * 0.7
			dir += Vector2(-dirp.y, dirp.x) * sin(t * 0.6) * 0.5
			steer(dir, sp if stun <= 0.0 else 0.0, dt, 260.0)
			cd -= dt
			if cd <= 0.0 and not pl.dead:
				_pick_attack(dist)
		ST_STOMP_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = clampf(st / 0.85, 0.0, 1.0)
			lean = lerpf(lean, -0.12, dt * 9.0)
			squat = lerpf(squat, 1.0, dt * 8.0)
			if steam_t <= 0.0:
				steam_t = 0.06
				game.fx.puff(position + Vector2(randf_range(-30, 30), -100), Vector2(randf_range(-30, 30), -50), 9.0, Color(0.9, 0.9, 1.0, 0.45), 0.6, 2.6)
			if int(st * 30.0) % 3 == 0:
				game.fx.mote(position + Vector2(0, -58) + Vector2.from_angle(randf() * TAU) * 70.0, position + Vector2(0, -58), _pc(), 0.22)
			if st >= (0.85 if phase < 2 else 0.65):
				state = ST_STOMP_SLAM
				st = 0.0
				slam_done = false
		ST_STOMP_SLAM:
			vel = Vector2.ZERO
			squat = lerpf(squat, -0.6, dt * 30.0)
			if not slam_done and st >= 0.06:
				slam_done = true
				_slam()
			if ring_second > 0.0 and st >= ring_second:
				ring_second = -1.0
				_ring(phase_ring_count() , 150.0, 0.2)
			if st >= 0.2:
				_end_attack(1.0)
		ST_REC:
			core_glow = move_toward(core_glow, 0.2, dt)
			squat = lerpf(squat, 0.3, dt * 6.0)
			lean = lerpf(lean, 0.1, dt * 6.0)
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			if st >= 0.9:
				state = ST_WALK
				st = 0.0
				squat = 0.0
		ST_VOLLEY_AIM:
			vel = vel.move_toward(Vector2.ZERO, 700.0 * dt)
			core_glow = clampf(st / 0.6, 0.0, 1.0) * 0.8
			cannon_aim = cannon_aim.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0)).normalized()
			face_toward(pl.position, dt, 5.0)
			if st >= 0.6:
				state = ST_VOLLEY_FIRE
				st = 0.0
				volley_left = 4 + phase * 2
				volley_t = 0.0
				volley_side = 1.0
		ST_VOLLEY_FIRE:
			vel = vel.move_toward(Vector2.ZERO, 700.0 * dt)
			cannon_aim = cannon_aim.lerp(dirp, clampf(dt * 3.0, 0.0, 1.0)).normalized()
			volley_t -= dt
			if volley_t <= 0.0 and volley_left > 0:
				_fire_cannon(volley_side)
				volley_side = -volley_side
				volley_left -= 1
				volley_t = 0.2 - 0.03 * float(phase)
			if volley_left <= 0 and volley_t <= 0.0:
				_end_attack(0.8)
		ST_SWEEP_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt, 8.0)
			core_glow = clampf(st / 0.55, 0.0, 1.0)
			sweep_ang = lerpf(sweep_ang, -2.0, clampf(dt * 8.0, 0.0, 1.0))
			lean = lerpf(lean, -0.14, dt * 9.0)
			if st >= 0.55:
				state = ST_SWEEP_HIT
				st = 0.0
				_sweep()
		ST_SWEEP_HIT:
			sweep_ang = lerpf(sweep_ang, 1.7, clampf(dt * 30.0, 0.0, 1.0))
			lean = lerpf(lean, 0.18, dt * 20.0)
			if st >= 0.18:
				_end_attack(1.0)
		ST_SUMMON:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 0.6
			if steam_t <= 0.0:
				steam_t = 0.05
				game.fx.puff(position + Vector2(randf_range(-20, 20), -96), Vector2(randf_range(-40, 40), -70), 9.0, Color(1.0, 0.8, 0.5, 0.5), 0.6, 2.4)
			if not summon_done and st >= 0.9:
				summon_done = true
				_summon()
			if st >= 1.8:
				_end_attack(0.9)
		ST_SPIRAL:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 0.9 + 0.1 * sin(t * 20.0)
			spiral_ang += dt * (1.9 + 0.5 * float(phase))
			spiral_t -= dt
			if spiral_t <= 0.0:
				spiral_t = 0.1
				_spiral_shot()
			if st >= 3.0:
				_end_attack(1.0)
		ST_VENT:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 1.0
			squat = lerpf(squat, 0.4, dt * 6.0)
			if steam_t <= 0.0:
				steam_t = 0.05
				game.fx.puff(position + Vector2(randf_range(-30, 30), -90), Vector2(randf_range(-30, 30), -60), 10.0, Color(0.9, 0.9, 1.0, 0.5), 0.7, 2.6)
			if st >= 1.7:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.8
				attacks_since_vent = 0
		ST_PHASE:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			core_glow = 1.0
			squat = lerpf(squat, 0.5, dt * 8.0)
			if steam_t <= 0.0:
				steam_t = 0.04
				game.fx.spark(position + Vector2(randf_range(-40, 40), -60), Vector2.UP, 2, 260.0, _pc(), 0.3, 1.2)
			if st >= 1.6:
				state = ST_WALK
				st = 0.0
				squat = 0.0
				cd = 0.6


func phase_ring_count() -> int:
	return 14 + phase * 4


func _pick_attack(dist: float) -> void:
	var pool: Array = []
	pool.append(["stomp", 3.0 if last_attack != "stomp" else 0.8])
	pool.append(["volley", 3.0 if last_attack != "volley" else 0.8])
	if dist < 210.0:
		pool.append(["sweep", 5.0 if last_attack != "sweep" else 1.5])
	if phase >= 1:
		var adds := 0
		for e in game.enemies:
			if e != self:
				adds += 1
		if adds < 3:
			pool.append(["summon", 3.0 if last_attack != "summon" else 0.0])
		pool.append(["spiral", 2.5 if last_attack != "spiral" else 0.0])
	var total := 0.0
	for p in pool:
		total += float(p[1])
	var r := randf() * total
	var pick := "stomp"
	for p in pool:
		r -= float(p[1])
		if r <= 0.0:
			pick = p[0]
			break
	last_attack = pick
	st = 0.0
	match pick:
		"stomp":
			state = ST_STOMP_WIND
			game.sfx.play("wind", -2.0, 0.5)
		"volley":
			state = ST_VOLLEY_AIM
			game.sfx.play("charge", -6.0, 0.8)
		"sweep":
			state = ST_SWEEP_WIND
			game.sfx.play("wind", -4.0, 0.7)
		"summon":
			state = ST_SUMMON
			summon_done = false
			game.sfx.play("roar", -6.0, 1.4)
		"spiral":
			state = ST_SPIRAL
			spiral_t = 0.0
			game.sfx.play("charge", -4.0, 0.6)


func _end_attack(rest: float) -> void:
	attacks_since_vent += 1
	if phase >= 1 and attacks_since_vent >= (2 if phase == 2 else 3):
		state = ST_VENT
		st = 0.0
		game.sfx.play("stomp", -2.0, 0.7)
		return
	state = ST_REC
	st = 0.0
	cd = maxf(0.5, 1.3 - 0.2 * float(phase))


func _ring(n: int, speed_v: float, offset_t: float) -> void:
	var c := position + Vector2(0, -30)
	var off := randf() * TAU
	for i in n:
		var a := off + TAU * float(i) / float(n)
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 36.0, Vector2.from_angle(a), speed_v + offset_t * 60.0, 3.2, 1.0, Bullets.Style.ORB, 1)
		b.col = _pc()


func _slam() -> void:
	var c := position + Vector2(0, -4)
	var fx := game.fx
	var col := _pc()
	fx.ring(c, 14.0, 150.0, col.lightened(0.3), 0.35, 7.0)
	fx.ring(c, 8.0, 120.0, Color(0.75, 0.72, 0.85, 0.5), 0.4, 14.0, false)
	fx.flash(c, 130.0, Color(col, 0.8), 0.16)
	fx.burst(c, 30, 440.0, Color("ffc86a"), 0.5)
	for i in 16:
		fx.puff(c + Vector2.from_angle(randf() * TAU) * randf_range(10, 70), Vector2.from_angle(randf() * TAU) * 50.0, 14.0, Color(0.55, 0.55, 0.68, 0.5), 0.8, 2.4)
	for i in 12:
		fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(80, 280), randf_range(120, 280), Color("3a3350"), randf_range(2.5, 6.0))
	fx.add_decal(c, 1, 90.0, Color.BLACK)
	game.sfx.play("slam", 0.0)
	game.shake(0.65)
	game.hitstop(0.05)
	_ring(phase_ring_count(), 190.0, 0.0)
	if phase >= 1:
		ring_second = 0.35 if phase == 1 else 0.28
	var pl := game.player
	if pl.position.distance_to(position) < 96.0 and pl.can_be_hit():
		pl.take_damage(2, (pl.position - position).normalized(), 340.0)


func _fire_cannon(side: float) -> void:
	var from := position + Vector2(54.0 * side, -92.0)
	var d := cannon_aim
	var n := 1 + (1 if phase >= 2 else 0)
	for i in n:
		var a := d.angle() + (float(i) - float(n - 1) * 0.5) * 0.22
		var b := game.bullets.fire(from + Vector2.from_angle(a) * 32.0, Vector2.from_angle(a), 350.0, 3.0, 1.0, Bullets.Style.EBOLT, 1)
		b.col = _pc()
	game.fx.muzzle(from + d * 32.0, d.angle(), 1.0, _pc())
	game.sfx.play("bolt", -4.0, 0.9, 0.05)
	game.shake(0.06)
	(cannon_l if side < 0.0 else cannon_r).queue_redraw()


func _sweep() -> void:
	var pl := game.player
	var c := position + Vector2(0, -50)
	var fwd := (pl.position - position).normalized()
	game.fx.arc(c, fwd.angle(), 130.0, _pc().lightened(0.3), 0.22, 2.6)
	game.fx.arc(c, fwd.angle(), 110.0, Color.WHITE, 0.16, 2.2)
	game.fx.spark(c + fwd * 90.0, fwd, 12, 420.0, _pc(), 0.3, 1.2)
	game.sfx.play("slam", -4.0, 1.2)
	game.shake(0.4)
	game.hitstop(0.04)
	var to := pl.position - position
	if to.length() < 150.0 and absf(fwd.angle_to(to)) < 1.2 and pl.can_be_hit():
		pl.take_damage(2, to.normalized(), 380.0)


func _summon() -> void:
	var ids: Array = ["fuse", "fuse"] if phase < 2 else ["fuse", "mender", "fuse"]
	for i in ids.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Gfx.push_out(position + Vector2(side * (70.0 + float(i) * 20.0), 40.0), 14.0, game.room.rects)
		game.fx.ring(pos, 8.0, 60.0, Color("c07aff"), 0.4, 3.0)
		game.fx.burst(pos, 12, 220.0, Color("e2c2ff"), 0.4)
		game.director.spawn_enemy_at(ids[i], pos, false)
	game.sfx.play("spawn", -3.0)


func _spiral_shot() -> void:
	var c := position + Vector2(0, -58)
	for k in (2 + (1 if phase >= 2 else 0)):
		var a := spiral_ang + TAU * float(k) / float(2 + (1 if phase >= 2 else 0))
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 30.0, Vector2.from_angle(a), 175.0, 3.6, 1.0, Bullets.Style.ORB, 1)
		b.col = _pc()
	game.sfx.play("bolt", -16.0, 1.5 + randf() * 0.2, 0.05, 0.08)


# ------------------------------------------------------------------ animacion / muerte
func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (2.0 + spd * 0.08)
	var sw := sin(walk_ph)
	var amp := clampf(spd / maxf(speed, 1.0), 0.0, 1.3)
	# paso pesado
	var ss := signf(sw)
	if ss != step_sign and amp > 0.4:
		step_sign = ss
		game.fx.puff(position + Vector2(ss * 26.0, 0), Vector2(0, -6), 14.0, Color(0.55, 0.58, 0.7, 0.4), 0.5, 2.4)
		game.sfx.play("stomp", -10.0, 0.7, 0.1, 0.1)
		game.shake(0.05)
	elif amp <= 0.4:
		step_sign = ss
	var bob := absf(sw) * 3.0 * amp
	torso_p.position = Vector2(0, -26 - bob + squat * 5.0)
	torso_p.rotation = lean + sw * 0.02 * amp
	head_p.position = Vector2(lean * 36.0, -112 - bob * 1.1 + squat * 6.0)
	head_p.rotation = lean * 0.6
	cannon_l.position = Vector2(-54 + lean * 14.0, -92 - bob + squat * 5.0)
	cannon_r.position = Vector2(54 + lean * 14.0, -92 - bob + squat * 5.0)
	vents_p.position = Vector2(0, -92 - bob + squat * 5.0)
	var tgt := 0.6 + sw * 0.08 * amp
	var rate := 7.0
	match state:
		ST_SWEEP_WIND:
			tgt = -1.9
			rate = 14.0
		ST_SWEEP_HIT:
			tgt = 1.55
			rate = 40.0
		ST_STOMP_WIND:
			tgt = -0.8
		ST_PHASE:
			tgt = -1.2 + sin(t * 30.0) * 0.1
	arm_ang = lerpf(arm_ang, tgt, clampf(dt * rate, 0.0, 1.0))
	if state != ST_VOLLEY_AIM and state != ST_VOLLEY_FIRE:
		cannon_aim = cannon_aim.lerp(Vector2(0, 1), clampf(dt * 2.0, 0.0, 1.0)).normalized()
	arm_f.position = Vector2(44 + lean * 12.0, -82 - bob + squat * 5.0)
	arm_b.position = Vector2(-44 + lean * 12.0, -82 - bob + squat * 5.0)
	var low := core_glow
	if state == S_SPAWN:
		core_glow = 0.2
	legs_p.queue_redraw()
	torso_p.queue_redraw()
	core_p.queue_redraw()
	head_p.queue_redraw()
	arm_f.queue_redraw()
	arm_b.queue_redraw()
	vents_p.queue_redraw()
	if state == ST_VOLLEY_AIM or state == ST_VOLLEY_FIRE:
		cannon_l.queue_redraw()
		cannon_r.queue_redraw()


var step_sign := 1.0


func _start_dying(dir: Vector2) -> void:
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
		game.fx.flash(p, 50.0, Color(1, 0.8, 0.5, 0.8), 0.12)
		game.fx.shard(p, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 220), Color("56648e"), randf_range(3, 6), Color(_pc().r, _pc().g, _pc().b, 0.7))
		game.sfx.play("hit", -6.0, 0.6 + randf() * 0.4)
		game.shake(0.1)
	core_glow = 1.0
	_animate(dt)
	if dying_t >= 2.3:
		_explode()
