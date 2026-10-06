class_name Lancer
extends Enemy
## Centinela flotante a distancia. Alza el canon, la lente se carga con particulas y dispara rafagas.

const ST_MOVE := 1
const ST_CHARGE := 2
const ST_FIRE := 3
const ST_RECOVER := 4

var goal := Vector2.ZERO
var next_goal_t := 0.0
var cooldown := 1.5
var shots_left := 0
var shot_t := 0.0
var aim_dir := Vector2.RIGHT
var charge := 0.0
var recoil := 0.0
var hover_t := 0.0
var pivot: Node2D
var barrel: Part
var body_p: Part
var wing_l: Part
var wing_r: Part
var glow_p: Part
var jets: Part
var open := 0.0
var strafe_dir := 1.0
var tilt := 0.0

const HOVER := 30.0


func _build() -> void:
	kind_name = "lancer"
	hp = 12.0
	radius = 13.0
	hit_r = 17.0
	hit_off = Vector2(0, -HOVER - 4.0)
	speed = 105.0
	bar_y = -HOVER - 36.0
	glow_col = Color("ff4fa8")
	strafe_dir = 1.0 if randf() < 0.5 else -1.0
	cooldown = randf_range(1.4, 2.4)
	spawn_dur = 0.8
	jets = Part.make(vis, _paint_jets, Vector2(0, -HOVER + 10.0), true)
	wing_l = Part.make(vis, _paint_wing, Vector2(-11, -HOVER - 2.0))
	wing_l.set_meta("left", true)
	wing_r = Part.make(vis, _paint_wing, Vector2(11, -HOVER - 2.0))
	wing_r.set_meta("left", false)
	body_p = Part.make(vis, _paint_body, Vector2(0, -HOVER))
	pivot = Node2D.new()
	pivot.use_parent_material = true
	pivot.position = Vector2(0, -HOVER + 4.0)
	vis.add_child(pivot)
	barrel = Part.make(pivot, _paint_barrel, Vector2(4, 0))
	glow_p = Part.make(vis, _paint_glow, Vector2(0, -HOVER), true)


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 22.0, Color(0, 0, 0, 0.45 - sin(hover_t * 2.0) * 0.04))


func _death_chunks() -> Array:
	return [Color("3a3050"), Color("5c4880"), Color("2a2238"), Color("a79bc8")]


func _paint_jets(c: Part) -> void:
	var f := 0.8 + 0.2 * sin(t * 40.0)
	Gfx.draw_glow(c, Vector2(0, 8), 24.0, Color(0.5, 0.6, 1.0, 0.35 * f))
	for sx in [-9.0, 9.0]:
		Gfx.draw_glow(c, Vector2(sx, 6), 11.0, Color(0.6, 0.8, 1.0, 0.7 * f))
		c.draw_colored_polygon(PackedVector2Array([Vector2(sx - 3, 2), Vector2(sx + 3, 2), Vector2(sx, 10.0 + 4.0 * f)]), Color(0.7, 0.9, 1.0, 0.8))


func _paint_wing(c: Part) -> void:
	var ink := Gfx.INK
	var left: bool = c.get_meta("left", true)
	var s := -1.0 if left else 1.0
	var pts := PackedVector2Array([Vector2(0, -5), Vector2(s * 13, -9), Vector2(s * 19, -3), Vector2(s * 14, 6), Vector2(0, 7)])
	Gfx.gpoly(c, pts, Color("5c4880"), Color("2a2040"), ink, 2.0)
	c.draw_line(Vector2(s * 3, -3), Vector2(s * 15, -5), Color(1, 1, 1, 0.2), 1.4)
	# propulsor
	Gfx.rrect(c, Rect2(s * 13 - 4, 1, 8, 10), 2.5, Color("1e1630"), ink, 1.8)
	c.draw_rect(Rect2(s * 13 - 2, 9, 4, 2), Color("8fb8ff"))


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	# cola/antena
	c.draw_line(Vector2(0, -12), Vector2(0, -22), ink, 3.0, true)
	c.draw_line(Vector2(0, -12), Vector2(0, -22), Color("7a6aa0"), 1.4, true)
	c.draw_circle(Vector2(0, -22.5), 2.4, ink)
	c.draw_circle(Vector2(0, -22.5), 1.6, Color("ff4fa8") if int(t * 3.0) % 2 == 0 else Color("6a1f48"))
	# chasis
	var shell := Gfx.ell_pts(Vector2(0, 0), 14.0, 15.5, 26)
	Gfx.gpoly(c, shell, Color("86729f"), Color("33274a"), ink, 2.4)
	# placas
	c.draw_arc(Vector2(0, 0), 10.5, PI * 1.1, PI * 1.9, 14, Color(1, 1, 1, 0.25), 1.6, true)
	c.draw_line(Vector2(-13, 3), Vector2(13, 3), Color(0.05, 0.02, 0.1, 0.55), 2.0, true)
	for sx in [-1.0, 1.0]:
		Gfx.poly(c, PackedVector2Array([Vector2(sx * 11, -7), Vector2(sx * 15, -2), Vector2(sx * 12, 8), Vector2(sx * 8, 3)]), Color("2a2040"), ink, 1.6)
	# lente
	Gfx.ell(c, Vector2(0, -2), 8.0, 7.5, Color("1a0e24"), ink, 2.0)
	Gfx.ell(c, Vector2(0, -2), 5.4, 5.0, Color("4a1236"), Color(0, 0, 0, 0), 0.0)
	c.draw_circle(Vector2(0, -2), 3.2, Color("ff4fa8").lerp(Color.WHITE, charge * 0.6))
	c.draw_circle(Vector2(-1.2, -3.4), 1.0, Color(1, 1, 1, 0.8))


func _paint_barrel(c: Part) -> void:
	var ink := Gfx.INK
	var o := open * 4.0
	# soporte
	Gfx.rrect(c, Rect2(-8, -5, 12, 10), 3.0, Color("3a2e52"), ink, 1.8)
	# dos puas que se abren al cargar
	for sy in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(2, sy * (2.0 + o)), Vector2(24, sy * (1.4 + o * 1.6)), Vector2(31, sy * (0.6 + o * 1.8)), Vector2(24, sy * (4.8 + o * 1.4)), Vector2(2, sy * (5.0 + o))])
		Gfx.gpoly(c, pts, Color("9d8ac0"), Color("40305a"), ink, 1.8)
	# nucleo entre las puas
	c.draw_rect(Rect2(6, -1.5, 18, 3.0), Color("15091f"))
	c.draw_rect(Rect2(6, -1.0, 18.0 * (0.2 + charge * 0.8), 2.0), Color("ff4fa8").lerp(Color.WHITE, charge * 0.5))


func _paint_glow(c: Part) -> void:
	var g := 0.5 + charge * 0.8
	Gfx.draw_glow(c, Vector2(0, -2), 16.0 + charge * 14.0, Color(1.0, 0.25, 0.65, 0.5 * g))
	if charge > 0.05:
		var tip := pivot.transform * Vector2(30, 0) - glow_p.position
		Gfx.draw_glow(c, tip, 8.0 + charge * 16.0, Color(1.0, 0.4, 0.75, 0.7 * charge))


func face_toward(p: Vector2, _dt: float, _rate: float = 14.0) -> void:
	var dx := p.x - position.x
	if absf(dx) > 6.0:
		face = 1.0 if dx > 0.0 else -1.0


func _on_hurt(_d: float) -> void:
	stun = 0.08
	recoil = 0.6


func _after_spawn() -> void:
	state = ST_MOVE
	st = 0.0
	_pick_goal()


func _pick_goal() -> void:
	var pl := game.player
	var best := position
	var best_score := -1e9
	for i in 10:
		var a := randf() * TAU
		var d := randf_range(270.0, 380.0)
		var p := pl.position + Vector2.from_angle(a) * d
		if not game.room.free_point(p, 22.0):
			continue
		var s := 0.0
		if game.room.los(p, pl.position):
			s += 100.0
		s -= p.distance_to(position) * 0.12
		for o in game.enemies:
			if o != self and o.position.distance_to(p) < 90.0:
				s -= 60.0
		s += randf() * 25.0
		if s > best_score:
			best_score = s
			best = p
	goal = best
	next_goal_t = randf_range(1.6, 2.6)


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_MOVE:
			face_toward(pl.position, dt)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 8.0, 0.0, 1.0)).normalized()
			var to_g := goal - position
			var dir := Vector2.ZERO
			if to_g.length() > 22.0:
				dir = to_g.normalized()
			else:
				dir = Vector2(-dirp.y, dirp.x) * strafe_dir * 0.4
			if dist < 190.0:
				dir = (-dirp * 1.2 + dir * 0.3).normalized()
			steer(dir, speed if stun <= 0.0 else 0.0, dt, 700.0)
			next_goal_t -= dt
			if next_goal_t <= 0.0:
				_pick_goal()
				strafe_dir = -strafe_dir
			cooldown -= dt
			if cooldown <= 0.0 and game.room.los(position, pl.position) and dist < 520.0 and dist > 170.0 and not pl.dead:
				state = ST_CHARGE
				st = 0.0
				game.sfx.play("charge", -7.0)
		ST_CHARGE:
			vel = vel.move_toward(Vector2.ZERO, 500.0 * dt)
			face_toward(pl.position, dt)
			charge = clampf(st / 0.8, 0.0, 1.0)
			open = charge
			# apunta con retraso: el jugador puede reaccionar
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 5.0, 0.0, 1.0)).normalized()
			var tip := position + Vector2(0, -HOVER + 4.0) + aim_dir * 32.0
			if int(st * 60.0) % 3 == 0:
				game.fx.mote(tip + Vector2.from_angle(randf() * TAU) * randf_range(20, 34), tip, Color("ff6fb8"), 0.2)
			if st >= 0.8:
				state = ST_FIRE
				st = 0.0
				shots_left = 3
				shot_t = 0.0
		ST_FIRE:
			vel = vel.move_toward(Vector2.ZERO, 500.0 * dt)
			face_toward(pl.position, dt)
			shot_t -= dt
			if shot_t <= 0.0 and shots_left > 0:
				_shoot(dirp)
				shots_left -= 1
				shot_t = 0.17
			if shots_left <= 0 and shot_t <= 0.0:
				state = ST_RECOVER
				st = 0.0
		ST_RECOVER:
			charge = maxf(0.0, charge - dt * 3.0)
			open = maxf(0.0, open - dt * 3.0)
			steer(Vector2(-dirp.y, dirp.x) * strafe_dir, speed * 0.5, dt)
			face_toward(pl.position, dt)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 4.0, 0.0, 1.0)).normalized()
			if int(st * 30.0) % 5 == 0:
				game.fx.puff(position + Vector2(face_vis * 10.0, -HOVER - 6.0), Vector2(randf_range(-10, 10), -26), 5.0, Color(0.8, 0.8, 0.95, 0.35), 0.5, 2.0)
			if st >= 0.7:
				state = ST_MOVE
				st = 0.0
				cooldown = randf_range(1.8, 3.0)
				_pick_goal()


func _shoot(dirp: Vector2) -> void:
	var pl := game.player
	var from := position + Vector2(0, -HOVER + 4.0)
	var d := (pl.hit_center() - from).normalized()
	aim_dir = d
	var m := from + d * 34.0
	game.bullets.fire(m, d, 310.0, 3.2, 1.0, 3, 1)
	recoil = 1.0
	vel -= d * 60.0
	game.fx.muzzle(m, d.angle(), 0.9, Color("ff6fb8"))
	game.fx.ring(m, 4.0, 22.0, Color("ff8ac8"), 0.16, 2.5)
	game.sfx.play("bolt", -6.0, 1.0, 0.06)
	game.shake(0.04)


func _animate(dt: float) -> void:
	hover_t += dt
	var spd := vel.length()
	recoil = maxf(0.0, recoil - dt * 6.0)
	var bob := sin(hover_t * 3.2) * 2.2
	tilt = lerpf(tilt, clampf(vel.x / 140.0, -1.0, 1.0) * 0.22, clampf(dt * 8.0, 0.0, 1.0))
	vis.rotation = tilt if state != S_DYING else vis.rotation
	body_p.position = Vector2(0, -HOVER + bob - recoil * 1.5 * -1.0)
	var wspread := sin(hover_t * 2.1) * 0.06
	wing_l.position = Vector2(-11, -HOVER - 2.0 + bob)
	wing_r.position = Vector2(11, -HOVER - 2.0 + bob)
	wing_l.rotation = -0.2 + wspread - clampf(vel.x / 200.0, -1, 1) * 0.15 - open * 0.25
	wing_r.rotation = 0.2 - wspread - clampf(vel.x / 200.0, -1, 1) * 0.15 + open * 0.25
	jets.position = Vector2(0, -HOVER + 10.0 + bob)
	pivot.position = Vector2(0, -HOVER + 4.0 + bob)
	var ang := aim_dir.angle()
	pivot.rotation = ang
	pivot.scale.y = 1.0 if aim_dir.x >= 0.0 else -1.0
	barrel.position = Vector2(4.0 - recoil * 6.0, 0.0)
	glow_p.position = Vector2(0, -HOVER + bob)
	if state == S_SPAWN:
		charge = 0.3
	barrel.queue_redraw()
	body_p.queue_redraw()
	wing_l.queue_redraw()
	wing_r.queue_redraw()
	glow_p.queue_redraw()
	jets.queue_redraw()
	shadow.queue_redraw()
