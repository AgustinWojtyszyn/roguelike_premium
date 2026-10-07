class_name BossVigia
extends Boss
## VIGIA DE LA GRIETA: un ojo flotante rodeado de placas de realidad rota. No camina: se DESPLAZA.
## Sus ataques se anuncian con marcas en el suelo: lluvia de fracturas (circulos que estallan), salto dimensional
## (marca del destino -> desaparece -> reaparece lanzando un anillo y queda expuesto) y abanicos de proyectiles.

const ST_DRIFT := 1
const ST_RAIN_WIND := 2
const ST_RAIN := 3
const ST_BLINK_WIND := 4
const ST_BLINK_OUT := 5
const ST_FAN := 6
const ST_SUMMON := 7
const ST_REC := 8
const ST_PHASE := 9

const MAGENTA := Color("ff4fd8")
const PHASE_COLS := [Color("ff4fd8"), Color("8a6aff"), Color("fff0ff")]

var body_p: Part
var plates_p: Part
var glow_p: Part
var tele_p: Part
var cd := 1.4
var plate_ang := 0.0
var plate_k := 0.0         # 0 = pegadas al ojo, 1 = abiertas
var eye_k := 0.4
var phase_flash := 0.0
var last_attack := ""
var fade := 1.0
var eye := Vector2.DOWN
var orbit := 1.0
var blink_to := Vector2.ZERO
var blink_done := false
var zones: Array = []      # [pos, tiempo_restante]
var rain_left := 0
var fan_left := 0
var fan_t := 0.0
var summon_done := false
var hover := 0.0


func _build() -> void:
	kind_name = "vigia"
	hp = boss_data.hp
	radius = 30.0
	hit_r = 40.0
	hit_off = Vector2(0, -62.0)
	speed = 110.0
	bar_y = -132.0
	glow_col = boss_data.accent
	big = true
	spawn_dur = 1.6
	phase_marks_arr = [boss_data.phases[1], boss_data.phases[2]]
	tele_p = Part.make(self, _paint_tele, Vector2.ZERO)
	tele_p.show_behind_parent = true
	plates_p = Part.make(vis, _paint_plates, Vector2(0, -62))
	body_p = Part.make(vis, _paint_body, Vector2(0, -62))
	glow_p = Part.make(vis, _paint_glow, Vector2(0, -62), true)


func _death_chunks() -> Array:
	return [Color("2a1a44"), Color("5a3a8a"), MAGENTA, Color("d8c8ff")]


func mass() -> float:
	return 30.0


func dmg_mult(_dir: Vector2) -> float:
	match state:
		ST_REC:
			return 1.6
		ST_PHASE:
			return 0.25
		S_SPAWN:
			return 0.0
	return 0.85


func targetable() -> bool:
	return state != S_DYING and state != S_SPAWN and fade > 0.5


func _pc() -> Color:
	return PHASE_COLS[phase]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, 6), 70.0 - hover * 3.0, Color(0, 0, 0, 0.5 * fade))


# ------------------------------------------------------------------ dibujo
func _paint_tele(c: Part) -> void:
	var col := Color(1.0, 0.3, 0.9)
	var pulse := 0.6 + 0.4 * sin(t * 26.0)
	for z in zones:
		var lp: Vector2 = (z[0] as Vector2) - position
		var k := clampf(1.0 - float(z[1]) / 0.95, 0.0, 1.0)
		c.draw_circle(lp, 56.0, Color(col, (0.1 + 0.25 * k) * pulse))
		c.draw_arc(lp, 56.0, 0.0, TAU, 28, Color(col, 0.9), 2.2, true)
		c.draw_arc(lp, 56.0 * k, 0.0, TAU, 28, Color(1, 0.85, 1, 0.8), 2.0, true)
	if state == ST_BLINK_WIND or state == ST_BLINK_OUT:
		var lp2 := blink_to - position
		var k2 := clampf(st / 0.7, 0.0, 1.0)
		c.draw_arc(lp2, 40.0, 0.0, TAU, 24, Color(col, 0.9), 2.5, true)
		c.draw_arc(lp2, 40.0 * (1.0 - k2) + 8.0, 0.0, TAU, 24, Color(1, 0.85, 1, 0.8), 2.0, true)
		c.draw_line(lp2 + Vector2(-14, 0), lp2 + Vector2(14, 0), Color(col, 0.8), 2.0)
		c.draw_line(lp2 + Vector2(0, -14), lp2 + Vector2(0, 14), Color(col, 0.8), 2.0)


func _paint_plates(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	for k in 6:
		var a := plate_ang + TAU * float(k) / 6.0
		var r := lerpf(38.0, 66.0, plate_k)
		var p := Vector2(cos(a), sin(a) * 0.8) * r
		var pts := PackedVector2Array([p + Vector2.from_angle(a) * 14.0, p + Vector2.from_angle(a + 2.4) * 11.0, p + Vector2.from_angle(a - 2.4) * 11.0])
		Gfx.gpoly(c, pts, Color("5a3a8a"), Color("1e1236"), ink, 2.2)
		c.draw_line(pts[0], (pts[1] + pts[2]) * 0.5, Color(col, 0.7), 1.6)


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var col := _pc()
	Gfx.ell(c, Vector2.ZERO, 36.0, 36.0, Color("1e1236"), ink, 3.0)
	Gfx.gell(c, Vector2.ZERO, 31.0, 31.0, Color("4a2a78"), Color("1a0e30"), ink, 1.6)
	# fisuras de la grieta
	c.draw_polyline(PackedVector2Array([Vector2(-26, -14), Vector2(-14, -6), Vector2(-20, 8), Vector2(-8, 18)]), Color(col, 0.85), 1.8, true)
	c.draw_polyline(PackedVector2Array([Vector2(24, -16), Vector2(14, -4), Vector2(22, 10)]), Color(col, 0.85), 1.8, true)
	# ojo
	var open := 8.0 + eye_k * 14.0
	var pts := PackedVector2Array()
	for i in 15:
		var x := -26.0 + 52.0 * float(i) / 14.0
		pts.append(Vector2(x, -open * sin(PI * float(i) / 14.0)))
	for i in 15:
		var x2 := 26.0 - 52.0 * float(i) / 14.0
		pts.append(Vector2(x2, open * sin(PI * float(i) / 14.0) * 0.8))
	c.draw_colored_polygon(pts, Color("0a0414"))
	c.draw_polyline(pts + PackedVector2Array([pts[0]]), col, 2.0, true)
	var ip := Vector2(clampf(eye.x * 9.0, -9.0, 9.0), clampf(eye.y * 4.0, -4.0, 4.0))
	c.draw_circle(ip, 9.0 + eye_k * 3.0, col.lerp(Color.WHITE, phase_flash))
	c.draw_circle(ip, 4.0, Color("0a0414"))


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 54.0 + eye_k * 40.0, Color(_pc(), (0.18 + eye_k * 0.35) * fade))


# ------------------------------------------------------------------ sprite (Rift Warden)
func sprite_phase() -> String:
	match state:
		ST_RAIN_WIND, ST_BLINK_WIND, ST_SUMMON, ST_PHASE:
			return "windup"
		ST_RAIN, ST_FAN, ST_BLINK_OUT:
			return "strike"
		ST_REC:
			return "recover"
	return "idle"


# ------------------------------------------------------------------ logica
func _after_spawn() -> void:
	state = ST_DRIFT
	st = 0.0
	cd = 1.2


func _on_phase_change(_ph: int) -> void:
	if state == S_DYING:
		return
	state = ST_PHASE
	st = 0.0
	cd = 1.0
	zones.clear()
	fade = 1.0
	phase_flash = 1.0
	game.bullets.clear_enemy_bullets(position, 2000.0)
	game.shake(0.7)
	game.hitstop(0.12)
	game.sfx.play("roar", 0.0, 1.3)
	game.slow_enemies(0.35, 0.5)
	var c := hit_center()
	var col := _pc()
	game.fx.ring(c, 20.0, 270.0, col, 0.6, 8.0)
	game.fx.ring(c, 10.0, 180.0, Color.WHITE, 0.4, 5.0)
	game.fx.flash(c, 230.0, Color(col, 0.9), 0.35)
	game.fx.burst(c, 40, 460.0, col, 0.7)
	for i in 12:
		game.fx.shard(c + Vector2(randf_range(-40, 40), randf_range(-20, 20)), Vector2.from_angle(randf() * TAU) * randf_range(120, 320), randf_range(140, 300), Color("5a3a8a").lerp(Color("1e1236"), randf()), randf_range(4, 8), Color(col.r, col.g, col.b, 0.8))


func _think(dt: float) -> void:
	_check_phase()
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	eye = eye.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0))
	phase_flash = maxf(0.0, phase_flash - dt * 2.5)
	plate_ang += dt * (0.9 + plate_k * 2.0)
	_update_zones(dt)
	match state:
		ST_DRIFT:
			eye_k = move_toward(eye_k, 0.4, dt * 2.0)
			plate_k = move_toward(plate_k, 0.0, dt * 2.0)
			fade = move_toward(fade, 1.0, dt * 6.0)
			face_toward(pl.position, dt, 10.0)
			if randf() < dt * 0.4:
				orbit = -orbit
			var radial := clampf((dist - 300.0) / 80.0, -1.0, 1.0)
			steer((Vector2(-dirp.y, dirp.x) * orbit * 0.9 + dirp * radial).normalized(), speed * (1.0 + 0.2 * float(phase)), dt, 420.0)
			cd -= dt
			if cd <= 0.0 and not pl.dead:
				_pick_attack(dist)
		ST_RAIN_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			plate_k = move_toward(plate_k, 1.0, dt * 3.0)
			eye_k = clampf(st / 0.7, 0.0, 1.0)
			if st >= 0.7:
				state = ST_RAIN
				st = 0.0
				rain_left = 4 + phase * 2
		ST_RAIN:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			if rain_left > 0 and st >= 0.0:
				_drop_zone(rain_left == 4 + phase * 2)
				rain_left -= 1
				st = -0.16
			if rain_left <= 0 and zones.is_empty():
				_end_attack()
		ST_BLINK_WIND:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			eye_k = 1.0
			plate_k = move_toward(plate_k, 1.0, dt * 4.0)
			fade = clampf(1.0 - st / 0.7, 0.0, 1.0)
			if st >= 0.7:
				state = ST_BLINK_OUT
				st = 0.0
				blink_done = false
				fade = 0.0
				game.fx.burst(hit_center(), 14, 260.0, _pc(), 0.4)
				game.fx.ring(hit_center(), 10.0, 80.0, _pc(), 0.25, 4.0)
		ST_BLINK_OUT:
			if not (blink_done and st >= 0.5):
				fade = 0.0   # (antes se reseteaba cada frame y el jefe quedaba invisible e intargeteable para siempre)
			if not blink_done and st >= 0.35:
				blink_done = true
				position = blink_to
				vel = Vector2.ZERO
				_blink_arrive()
			if blink_done and st >= 0.5:
				fade = move_toward(fade, 1.0, dt * 8.0)
				if fade >= 1.0:
					_end_attack()
		ST_FAN:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			eye_k = 1.0
			plate_k = move_toward(plate_k, 1.0, dt * 3.0)
			fan_t -= dt
			if fan_t <= 0.0 and fan_left > 0:
				_fan_volley(fan_left)
				fan_left -= 1
				fan_t = 0.55 if phase < 2 else 0.42
			if fan_left <= 0 and fan_t <= -0.2:
				_end_attack()
		ST_SUMMON:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			eye_k = 0.8
			plate_k = move_toward(plate_k, 1.0, dt * 3.0)
			if not summon_done and st >= 0.9:
				summon_done = true
				_summon()
			if st >= 1.7:
				_end_attack()
		ST_REC:
			eye_k = move_toward(eye_k, 0.15, dt * 2.0)
			plate_k = move_toward(plate_k, 0.0, dt * 2.0)
			fade = move_toward(fade, 1.0, dt * 8.0)
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			if st >= 1.0:
				state = ST_DRIFT
				st = 0.0
		ST_PHASE:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			eye_k = 1.0
			plate_k = 1.0
			if st >= 1.6:
				state = ST_DRIFT
				st = 0.0
				cd = 0.6
	if not zones.is_empty() or state in [ST_BLINK_WIND, ST_BLINK_OUT] or tele_was:
		tele_p.queue_redraw()
	tele_was = not zones.is_empty() or state in [ST_BLINK_WIND, ST_BLINK_OUT]


var tele_was := false


func _pick_attack(dist: float) -> void:
	var pool: Array = []
	pool.append(["rain", 3.0 if last_attack != "rain" else 0.5])
	pool.append(["fan", 3.0 if last_attack != "fan" else 0.8])
	pool.append(["blink", (3.5 if dist < 220.0 else 2.2) if last_attack != "blink" else 0.0])
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
	match pick:
		"rain":
			state = ST_RAIN_WIND
			game.sfx.play("charge", -5.0, 1.2)
		"fan":
			state = ST_FAN
			fan_left = 3 + phase
			fan_t = 0.5
			game.sfx.play("charge", -5.0, 0.9)
		"blink":
			state = ST_BLINK_WIND
			blink_to = _pick_blink()
			game.sfx.play("wind", -4.0, 1.5)
		"summon":
			state = ST_SUMMON
			summon_done = false
			game.sfx.play("roar", -6.0, 1.5)


func _end_attack() -> void:
	state = ST_REC
	st = 0.0
	cd = maxf(0.6, 1.4 - 0.2 * float(phase))


func _pick_blink() -> Vector2:
	var pl := game.player
	var best := position
	var best_score := -1e9
	for i in 12:
		var p := pl.position + Vector2.from_angle(randf() * TAU) * randf_range(190.0, 290.0)
		if not game.room.free_point(p, radius + 8.0):
			continue
		var s := randf() * 20.0
		if game.room.los(p, pl.position):
			s += 60.0
		s += minf(p.distance_to(position), 300.0) * 0.1
		if s > best_score:
			best_score = s
			best = p
	return best


func _blink_arrive() -> void:
	var c := hit_center()
	var col := _pc()
	game.fx.ring(c, 10.0, 130.0, col, 0.4, 6.0)
	game.fx.flash(c, 120.0, Color(col, 0.9), 0.2)
	game.fx.burst(c, 22, 360.0, col, 0.45)
	game.sfx.play("slam", -4.0, 1.4)
	game.shake(0.3)
	var n := 12 + phase * 4
	var off := randf() * TAU
	for i in n:
		if i % 4 == 1:
			continue
		var a := off + TAU * float(i) / float(n)
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 30.0, Vector2.from_angle(a), 200.0, 3.2, 1.0, Bullets.Style.ORB, 1)
		b.col = col


func _drop_zone(first: bool) -> void:
	var pl := game.player
	var p := pl.position + pl.vel * 0.5
	if not first:
		p = pl.position + Vector2.from_angle(randf() * TAU) * randf_range(40.0, 170.0)
	p = Gfx.push_out(p, 20.0, game.room.rects)
	zones.append([p, 0.95])
	game.sfx.play("bolt", -12.0, 0.6, 0.05)


func _update_zones(dt: float) -> void:
	var i := zones.size() - 1
	while i >= 0:
		zones[i][1] -= dt
		if float(zones[i][1]) <= 0.0:
			_detonate(zones[i][0])
			zones.remove_at(i)
		i -= 1


func _detonate(p: Vector2) -> void:
	var col := _pc()
	game.fx.ring(p, 8.0, 70.0, col, 0.3, 5.0)
	game.fx.flash(p, 90.0, Color(col, 0.85), 0.16)
	game.fx.burst(p, 18, 340.0, col, 0.4)
	game.fx.add_decal(p, 0, 50.0, Color.BLACK)
	game.sfx.play("slam", -8.0, 1.5, 0.1, 0.04)
	game.shake(0.12)
	var pl := game.player
	if pl.position.distance_to(p) < 56.0 + Player.RADIUS and pl.can_be_hit():
		pl.take_damage(1, (pl.position - p).normalized(), 300.0)
	if phase >= 2:
		for k in 4:
			var b := game.bullets.fire(p, Vector2.from_angle(TAU * float(k) / 4.0 + 0.4), 170.0, 1.6, 1.0, Bullets.Style.ORB, 1)
			b.col = col


func _fan_volley(left: int) -> void:
	var pl := game.player
	var c := hit_center()
	var base := (pl.hit_center() + pl.vel * 0.2 - c).angle()
	var n := 5 + phase * 2
	var spread := 0.95
	var col := _pc()
	var shift := 0.0 if left % 2 == 0 else spread / float(n - 1) * 0.5
	for i in n:
		var a := base + shift + (float(i) - float(n - 1) * 0.5) * (spread / float(n - 1))
		var b := game.bullets.fire(c + Vector2.from_angle(a) * 30.0, Vector2.from_angle(a), 270.0 + 25.0 * float(phase), 3.2, 1.0, Bullets.Style.EBOLT, 1)
		b.col = col
	game.fx.muzzle(c + Vector2.from_angle(base) * 30.0, base, 0.9, col)
	game.sfx.play("bolt", -6.0, 0.9, 0.05)
	game.shake(0.08)


func _summon() -> void:
	var ids: Array = ["fulgor", "fulgor"] if phase < 2 else ["acechador", "fulgor", "fulgor"]
	for i in ids.size():
		var side := -1.0 if i % 2 == 0 else 1.0
		var pos := Gfx.push_out(position + Vector2(side * (90.0 + float(i) * 18.0), 30.0), 14.0, game.room.rects)
		game.fx.ring(pos, 8.0, 60.0, MAGENTA, 0.4, 3.0)
		game.fx.burst(pos, 12, 220.0, Color("ffc8f4"), 0.4)
		game.director.spawn_enemy_at(ids[i], pos, false)
	game.sfx.play("spawn", -3.0)


# ------------------------------------------------------------------ animacion / muerte
func _animate(dt: float) -> void:
	hover += dt * 2.4
	var bob := sin(hover) * 5.0
	body_p.position = Vector2(0, -62 + bob)
	plates_p.position = body_p.position
	glow_p.position = body_p.position
	vis.modulate.a = fade if state != S_SPAWN else vis.modulate.a
	if spr != null:
		spr.position = Vector2(0, -6 + bob)
	body_p.rotation = sin(hover * 0.7) * 0.05
	body_p.queue_redraw()
	plates_p.queue_redraw()
	glow_p.soft_redraw()


func _start_dying(_dir: Vector2) -> void:
	state = S_DYING
	dying_t = 0.0
	zones.clear()
	tele_p.queue_redraw()
	fade = 1.0
	vis.modulate.a = 1.0
	game.on_enemy_dying(self)
	game.bullets.clear_enemy_bullets(position, 3000.0)
	vel = Vector2.ZERO
	game.sfx.play("roar", 0.0, 1.1)
	game.slow_enemies(0.4, 2.4)
	game.shake(0.8)


func _dying(dt: float) -> void:
	dying_t += dt
	flash = 0.6 if int(dying_t * 20.0) % 2 == 0 else 0.1
	fmat.set_shader_parameter("flash", flash)
	vis.position = Vector2(randf_range(-3, 3), randf_range(-2, 2))
	plate_k = minf(1.5, plate_k + dt * 0.6)
	eye_k = 1.0
	if int(dying_t * 14.0) != int((dying_t - dt) * 14.0):
		var p := position + Vector2(randf_range(-44, 44), randf_range(-100, -20))
		game.fx.burst(p, 8, 280.0, _pc(), 0.4)
		game.fx.flash(p, 50.0, Color(1, 0.85, 1, 0.8), 0.12)
		game.fx.shard(p, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 220), Color("5a3a8a"), randf_range(3, 6), Color(_pc().r, _pc().g, _pc().b, 0.7))
		game.sfx.play("hit", -6.0, 0.6 + randf() * 0.4)
		game.shake(0.1)
	_animate(dt)
	if dying_t >= 2.3:
		_explode()
