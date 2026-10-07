class_name Sacerdote
extends RoleShooter
## Sacerdote de jade: figura con tunica y baston de plumas que flota entre las columnas. Cada pocos segundos alza los
## brazos (postura) mientras un circulo de glifos brilla bajo sus pies, e invoca escarabajos. Entre invocaciones lanza dardos de jade.

var robe_p: Part
var head_p: Part
var staff_p: Part
var circle_p: Part
var hover_t := 0.0
var summon_cd := 3.5
var channel_t := -1.0
const HOVER := 14.0


func _build() -> void:
	kind_name = "sacerdote"
	hp = 18.0
	radius = 12.0
	hit_r = 17.0
	hit_off = Vector2(0, -34)
	muzzle_off = Vector2(0, -34)
	speed = 90.0
	bar_y = -64.0
	glow_col = Color("3dd9a8")
	b_col = Color("3dd9a8")
	b_style = Bullets.Style.SHARD
	b_speed = 300.0
	burst = 2
	burst_gap = 0.2
	windup = 0.6
	pref_min = 260.0
	pref_max = 400.0
	cd_min = 2.4
	cd_max = 3.6
	spawn_dur = 0.8
	circle_p = Part.make(vis, _paint_circle, Vector2(0, -2), true)
	robe_p = Part.make(vis, _paint_robe, Vector2(0, -HOVER))
	head_p = Part.make(vis, _paint_head, Vector2(0, -HOVER - 36))
	staff_p = Part.make(vis, _paint_staff, Vector2(14, -HOVER - 22))


func _death_chunks() -> Array:
	return [Color("a8442a"), Color("3dd9a8"), Color("e8c06a"), Color("2a1a14")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 20.0, Color(0, 0, 0, 0.4 - sin(hover_t * 2.0) * 0.04))


func _paint_circle(c: Part) -> void:
	var k := 0.0 if channel_t < 0.0 else clampf(channel_t / 1.0, 0.0, 1.0)
	if k <= 0.0:
		return
	var e := Gfx.ell_pts(Vector2.ZERO, 34.0 * k, 17.0 * k, 24)
	Gfx.outline(c, e, Color(glow_col, 0.8 * k), 2.4)
	for q in 6:
		var a := hover_t * 3.0 + TAU * float(q) / 6.0
		c.draw_circle(Vector2(cos(a) * 28.0 * k, sin(a) * 14.0 * k), 2.4, Color(glow_col.lightened(0.4), 0.9))
	Gfx.draw_glow(c, Vector2.ZERO, 46.0 * k, Color(glow_col, 0.25 * k))


func _paint_robe(c: Part) -> void:
	var ink := Gfx.INK
	var up := 1.0 if channel_t >= 0.0 else 0.0
	var tunic := PackedVector2Array([Vector2(-13, 0), Vector2(13, 0), Vector2(15, -16), Vector2(10, -32), Vector2(-10, -32), Vector2(-15, -16)])
	Gfx.gpoly(c, tunic, Color("a8442a"), Color("5a2414"), ink, 2.4)
	for k in 4:
		c.draw_line(Vector2(-12 + float(k) * 8.0, 0), Vector2(-10 + float(k) * 7.0, -22), Color(0, 0, 0, 0.25), 1.4)
	Gfx.gpoly(c, PackedVector2Array([Vector2(-8, -3), Vector2(8, -3), Vector2(6, -26), Vector2(-6, -26)]), Color("e8c06a"), Color("8a6a2a"), ink, 1.4)
	Gfx.poly(c, PackedVector2Array([Vector2(0, -22), Vector2(4, -17), Vector2(0, -12), Vector2(-4, -17)]), glow_col, ink, 1.2)
	# brazos (se alzan al invocar)
	for s in [-1.0, 1.0]:
		var sh := Vector2(s * 10.0, -28.0)
		var hand := Vector2(s * (16.0 + up * 4.0), -20.0 - up * 24.0)
		c.draw_line(sh, hand, ink, 7.0, true)
		c.draw_line(sh, hand, Color("c08060"), 4.0, true)
		c.draw_circle(hand, 3.4, Color("d9a070"))
		c.draw_circle(hand, 4.8, Color(glow_col, 0.5 * up))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	for k in 7:
		var a := -PI * 0.5 + (float(k) - 3.0) * 0.28
		var tip := Vector2(cos(a), sin(a)) * 16.0 + Vector2(0, -4)
		c.draw_line(Vector2(0, -6), tip, ink, 5.0, true)
		c.draw_line(Vector2(0, -6), tip, Color("3dd9a8") if k % 2 == 0 else Color("e0405a"), 3.0, true)
	Gfx.ell(c, Vector2(0, 0), 8.0, 8.6, Color("d9a070"), ink, 2.0)
	c.draw_rect(Rect2(-6, -3.0, 12, 2.4), Color("1a1410"))
	c.draw_circle(Vector2(-2.6, -1.8), 1.0, Color(glow_col, 0.5 + windup_k * 0.5))
	c.draw_circle(Vector2(2.6, -1.8), 1.0, Color(glow_col, 0.5 + windup_k * 0.5))
	c.draw_line(Vector2(-3, 4), Vector2(3, 4), Color("5a2414"), 1.6)


func _paint_staff(c: Part) -> void:
	var ink := Gfx.INK
	c.draw_line(Vector2(0, 18), Vector2(0, -26), ink, 5.0, true)
	c.draw_line(Vector2(0, 18), Vector2(0, -26), Color("6a4a2c"), 2.8, true)
	for k in 3:
		var a := -PI * 0.5 + (float(k) - 1.0) * 0.5
		c.draw_line(Vector2(0, -24), Vector2(0, -24) + Vector2.from_angle(a) * 12.0, Color("3dd9a8"), 2.4, true)
	c.draw_circle(Vector2(0, -26), 4.0, Color("e8c06a"))
	c.draw_circle(Vector2(0, -26), 2.2, glow_col.lerp(Color.WHITE, windup_k))


func _think(dt: float) -> void:
	summon_cd -= dt
	if channel_t >= 0.0:
		vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
		channel_t += dt
		face_toward(game.player.position, dt)
		if int(channel_t * 30.0) % 3 == 0:
			game.fx.mote(position + Vector2.from_angle(randf() * TAU) * 40.0, position + Vector2(0, -HOVER - 20.0), glow_col, 0.25)
		if channel_t >= 1.0:
			_summon()
			channel_t = -1.0
			summon_cd = randf_range(6.0, 8.0)
		return
	var scarabs := 0
	for e in game.enemies:
		if e is Escarabajo:
			scarabs += 1
	if summon_cd <= 0.0 and scarabs < 3 and state == ST_MOVE and not game.player.dead:
		channel_t = 0.0
		game.sfx.play("roar", -10.0, 1.6)
		return
	super._think(dt)


func _summon() -> void:
	for i in 2:
		var side := -1.0 if i == 0 else 1.0
		var pos := Gfx.push_out(position + Vector2(side * 36.0, 18.0), 10.0, game.room.rects)
		game.fx.ring(pos, 6.0, 40.0, glow_col, 0.35, 3.0)
		game.fx.burst(pos, 10, 200.0, Color("a8ffe0"), 0.4)
		game.director.spawn_enemy_at("escarabajo", pos, false)
	game.sfx.play("spawn", -5.0, 1.2)


func _animate(dt: float) -> void:
	hover_t += dt
	recoil = maxf(0.0, recoil - dt * 6.0)
	var bob := sin(hover_t * 2.6) * 2.4
	robe_p.position = Vector2(0, -HOVER + bob)
	head_p.position = Vector2(0, -HOVER - 36 + bob * 1.1)
	staff_p.position = Vector2(14, -HOVER - 22 + bob)
	staff_p.rotation = -0.1 + (0.5 if channel_t >= 0.0 else 0.0) * -1.0 + windup_k * -0.4
	hit_off = Vector2(0, -34 + bob)
	muzzle_off = Vector2(0, -34 + bob)
	robe_p.queue_redraw()
	head_p.queue_redraw()
	staff_p.queue_redraw()
	circle_p.soft_redraw()
	shadow.soft_redraw()
