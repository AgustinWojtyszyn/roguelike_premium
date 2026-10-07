class_name Skitter
extends Enemy
## Pequeño y agresivo. Rodea al jugador, se acerca, alza las garras (anticipacion) y las abate.

const ST_CIRCLE := 1
const ST_APPROACH := 2
const ST_WIND := 3
const ST_STRIKE := 4
const ST_RECOVER := 5

var legs: Part
var body_p: Part
var claw_f: Part
var claw_b: Part
var glow_p: Part
var orbit := 1.0
var ring_r := 200.0
var next_attack := 1.0
var has_slot := false
var walk_ph := 0.0
var glow := 0.0
var claw_ang := 0.5
var swung := false
var side_bias := 1.0
var squat := 0.0
var lunge := 0.0


func _build() -> void:
	kind_name = "skitter"
	hp = 7.0
	radius = 11.0
	hit_r = 15.0
	hit_off = Vector2(0, -13)
	speed = 150.0
	bar_y = -34.0
	glow_col = Color("ffa23d")
	orbit = 1.0 if randf() < 0.5 else -1.0
	ring_r = randf_range(190.0, 260.0)
	next_attack = randf_range(1.2, 2.4)
	side_bias = 1.0 if randf() < 0.5 else -1.0
	legs = Part.make(vis, _paint_legs)
	claw_b = Part.make(vis, _paint_claw, Vector2(9, -9))
	claw_b.set_meta("far", true)
	body_p = Part.make(vis, _paint_body, Vector2(0, -13))
	claw_f = Part.make(vis, _paint_claw, Vector2(10, -6))
	claw_f.set_meta("far", false)
	glow_p = Part.make(body_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("3b2858"), Color("59418a"), Color("d8ccf0"), Color("231638")]


func _paint_legs(c: Part) -> void:
	var ink := Gfx.INK
	var cols := [Color("4a3470"), Color("7a5cb0")]
	# 3 patas lejanas (oscuras) y 3 cercanas
	for layer in 2:
		for i in 3:
			var near := layer == 1
			var hx := -9.0 + i * 9.0
			var hip := Vector2(hx, -10.0 if near else -13.0)
			var ph := walk_ph + float(i) * 2.1 + (PI if (i % 2 == 0) != near else 0.0)
			var step := sin(ph)
			var lift := maxf(0.0, cos(ph)) * 5.0
			var fx := hx + step * 7.0 + (i - 1) * 4.0
			var foot := Vector2(fx, -lift - (0.0 if near else 4.0))
			var knee := Vector2((hip.x + foot.x) * 0.5 + (i - 1) * 3.0, hip.y - 9.0 - lift * 0.3)
			var pts := PackedVector2Array([hip, knee, foot])
			c.draw_polyline(pts, ink, 5.0, true)
			c.draw_polyline(pts, cols[layer], 3.0, true)
			c.draw_circle(knee, 2.2, ink)
			c.draw_circle(knee, 1.2, Color("d9c8ff") if near else Color("9a7cd0"))
			c.draw_line(foot, foot + Vector2(2.5, 1.2), ink, 3.0, true)


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	# espinas dorsales
	for k in 3:
		var bx := -10.0 + k * 6.0
		Gfx.poly(c, PackedVector2Array([Vector2(bx, -8 + k * 0.8), Vector2(bx + 1.5, -17 + k * 1.5), Vector2(bx + 5, -9)]), Color("2a1a44"), ink, 1.8)
	# caparazon
	var shell := PackedVector2Array([Vector2(-16, 3), Vector2(-15, -5), Vector2(-9, -10.5), Vector2(1, -12), Vector2(11, -8.5), Vector2(15, -1.5), Vector2(13, 5.5), Vector2(0, 8), Vector2(-12, 7)])
	Gfx.gpoly(c, shell, Color("7656a8"), Color("2a1a46"), ink, 2.4)
	# placas
	for k in 3:
		var x := -9.0 + k * 7.0
		c.draw_polyline(PackedVector2Array([Vector2(x, -11.0 + k * 0.6), Vector2(x - 2.0, -3), Vector2(x - 1.0, 5.5)]), Color(0.05, 0.02, 0.1, 0.7), 1.8, true)
		c.draw_line(Vector2(x + 1.2, -10.0), Vector2(x - 0.8, -3), Color(1, 1, 1, 0.14), 1.2, true)
	# resplandor ambar en el lomo (rendijas)
	for k in 3:
		var x := -10.0 + k * 7.0
		c.draw_line(Vector2(x, -8.5 + k * 0.7), Vector2(x + 3.5, -8.0 + k * 0.7), Color("ffb23d").lerp(Color.WHITE, glow * 0.7), 2.0, true)
	# cabeza
	var head := Gfx.ell_pts(Vector2(14, -2), 7.5, 6.5, 16)
	Gfx.gpoly(c, head, Color("5a3f86"), Color("2a1a46"), ink, 2.0)
	# ojo
	Gfx.ell(c, Vector2(16.5, -3.2), 3.6, 3.2, Color("ffb23d").lerp(Color.WHITE, glow * 0.8), ink, 1.5)
	c.draw_line(Vector2(16.5, -5.8), Vector2(16.5, -0.7), ink, 1.6)
	# mandibulas
	c.draw_polyline(PackedVector2Array([Vector2(19, 1.5), Vector2(23, 4), Vector2(21, 7)]), ink, 3.2, true)
	c.draw_polyline(PackedVector2Array([Vector2(19, 1.5), Vector2(23, 4), Vector2(21, 7)]), Color("d8ccf0"), 1.6, true)


func _paint_glow(c: Part) -> void:
	var g := 0.35 + glow * 0.9
	Gfx.draw_glow(c, Vector2(16.5, -3), 12.0 + glow * 14.0, Color(1.0, 0.65, 0.2, 0.6 * g))
	Gfx.draw_glow(c, Vector2(-2, -8), 16.0 + glow * 10.0, Color(1.0, 0.6, 0.15, 0.25 * g))


func _paint_claw(c: Part) -> void:
	var ink := Gfx.INK
	var far: bool = c.get_meta("far", false)
	var blade := PackedVector2Array([Vector2(0, -2.5), Vector2(9, -4.5), Vector2(19, -1), Vector2(25, 7), Vector2(15, 3.5), Vector2(6, 3)])
	Gfx.gpoly(c, blade, Color("f0e8ff") if not far else Color("9a8cb8"), Color("8a78b4") if not far else Color("4a3a68"), ink, 2.0)
	c.draw_line(Vector2(5, -2.5), Vector2(18, -0.5), Color(1, 1, 1, 0.7 if not far else 0.25), 1.2, true)
	c.draw_circle(Vector2(0, 0), 3.4, ink)
	c.draw_circle(Vector2(0, 0), 2.2, Color("ffb23d") if not far else Color("a86a1e"))


func targetable() -> bool:
	return state != S_DYING and not (state == S_SPAWN and st < spawn_dur * 0.6)


func _on_hurt(_d: float) -> void:
	if state == ST_CIRCLE or state == ST_APPROACH:
		stun = 0.14


func _after_spawn() -> void:
	state = ST_CIRCLE
	st = 0.0


func _release() -> void:
	if has_slot:
		game.release_melee(self)
		has_slot = false


func _start_dying(dir: Vector2) -> void:
	_release()
	super._start_dying(dir)


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	var tang := Vector2(-dirp.y, dirp.x) * orbit
	match state:
		ST_CIRCLE:
			if stun > 0.0:
				vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
				return
			face_toward(pl.position, dt)
			if st > randf_range(1.6, 3.0) and randf() < dt * 2.0:
				orbit = -orbit
				st = 0.0
			var radial := clampf((dist - ring_r) / 70.0, -1.0, 1.0)
			var wig := sin(t * 5.0) * 0.25
			var dir := (tang * (0.85 + wig) + dirp * radial * 1.1).normalized()
			steer(dir, speed * (1.0 if dist < ring_r + 60.0 else 1.25), dt)
			next_attack -= dt
			if next_attack <= 0.0 and not has_slot and not pl.dead:
				if game.claim_melee(self):
					has_slot = true
					state = ST_APPROACH
					st = 0.0
				else:
					next_attack = 0.5
		ST_APPROACH:
			face_toward(pl.position, dt)
			if stun > 0.0:
				vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
				return
			# curva lateral para no ir en linea recta
			var curve := clampf((dist - 70.0) / 160.0, 0.0, 1.0) * 0.55 * side_bias
			var dir := dirp.rotated(curve)
			steer(dir, speed * 1.35, dt, 1500.0)
			if dist < 66.0:
				state = ST_WIND
				st = 0.0
				swung = false
				game.sfx.play("wind", -8.0, 1.0 + randf() * 0.2)
			elif st > 3.5 or pl.dead:
				_release()
				state = ST_CIRCLE
				st = 0.0
				next_attack = randf_range(1.0, 2.0)
		ST_WIND:
			vel = vel.move_toward(Vector2.ZERO, 1400.0 * dt)
			face_toward(pl.position, dt, 20.0)
			glow = clampf(st / 0.5, 0.0, 1.0)
			if int(st * 40.0) % 4 == 0:
				var pp := position + Vector2(face_vis * 14.0, -14.0)
				game.fx.mote(pp + Vector2.from_angle(randf() * TAU) * randf_range(16, 26), pp, Color("ffb23d"), 0.22)
			if st >= 0.5:
				state = ST_STRIKE
				st = 0.0
		ST_STRIKE:
			vel = vel.move_toward(Vector2.ZERO, 1400.0 * dt)
			if not swung:
				swung = true
				_swipe()
			if st >= 0.14:
				state = ST_RECOVER
				st = 0.0
				_release()
		ST_RECOVER:
			glow = maxf(0.0, glow - dt * 2.5)
			var away := -dirp
			steer((away + tang * 0.6).normalized(), speed * 0.55, dt)
			face_toward(pl.position, dt)
			if st >= 0.85:
				state = ST_CIRCLE
				st = 0.0
				next_attack = randf_range(1.5, 3.0)
				orbit = -orbit


func _swipe() -> void:
	var pl := game.player
	var fwd := Vector2(face, 0.0)
	var c := position + Vector2(face * 26.0, -12.0)
	game.fx.arc(position + Vector2(face * 8.0, -13.0), 0.0 if face > 0.0 else PI, 40.0, Color("ffd9a0"), 0.18, 2.4)
	game.fx.spark(c, fwd, 4, 240.0, Color("ffd9a0"), 0.2, 0.8)
	game.sfx.play("slash", -6.0)
	var to := pl.position - position
	if to.length() < 60.0 and signf(to.x) == face or to.length() < 26.0:
		if pl.can_be_hit():
			pl.take_damage(1, to.normalized(), 170.0)


func _animate(dt: float) -> void:
	var spd := vel.length()
	walk_ph += dt * (4.0 + spd * 0.085)
	if state == S_SPAWN:
		glow = 0.6
	# garras
	var target_claw := 0.55
	match state:
		ST_WIND:
			target_claw = -1.5 + sin(t * 50.0) * 0.06
		ST_STRIKE:
			target_claw = 1.0
		ST_RECOVER:
			target_claw = 0.9
		ST_APPROACH:
			target_claw = 0.1
	var rate := 40.0 if state == ST_STRIKE else 14.0
	claw_ang = lerpf(claw_ang, target_claw, clampf(dt * rate, 0.0, 1.0))
	claw_f.rotation = claw_ang
	claw_b.rotation = claw_ang * 0.8 - 0.1
	# cuerpo
	var bob := absf(sin(walk_ph)) * 1.5 * clampf(spd / speed, 0.0, 1.2)
	var sq_t := 0.0
	var lean_t := 0.0
	if state == ST_WIND:
		sq_t = 1.0
		lean_t = -4.0
	elif state == ST_STRIKE:
		sq_t = -0.4
		lean_t = 5.0
	elif state == ST_RECOVER:
		sq_t = 0.6
	squat = lerpf(squat, sq_t, clampf(dt * 16.0, 0.0, 1.0))
	lunge = lerpf(lunge, lean_t, clampf(dt * 22.0, 0.0, 1.0))
	body_p.position = Vector2(lunge, -13.0 - bob + squat * 2.5)
	body_p.scale = Vector2(1.0 + squat * 0.07, 1.0 - squat * 0.12)
	body_p.rotation = squat * -0.1 + (spd * 0.0006) * face
	claw_f.position = Vector2(10.0 + lunge, -6.0 + squat * 2.5 - bob)
	claw_b.position = Vector2(9.0 + lunge, -9.0 + squat * 2.5 - bob)
	legs.queue_redraw()
	body_p.queue_redraw()
	glow_p.soft_redraw()
	if state != S_SPAWN and state != S_DYING:
		legs.position.y = squat * 1.5
