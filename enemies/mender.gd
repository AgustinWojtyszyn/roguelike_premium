class_name Mender
extends Enemy
## Dron de soporte: flota detras de sus aliados y cada pocos segundos emite un pulso que los repara.
## Huye del jugador. Prioridad de eliminacion: es fragil.

var body_p: Part
var glow_p: Part
var pulse_cd := 2.5
var pulse_t := -1.0
var hover_t := 0.0
var goal := Vector2.ZERO
var lone_t := 0.0
var shoot_cd := 2.0
const HOVER := 30.0


func _build() -> void:
	kind_name = "mender"
	hp = 12.0
	radius = 11.0
	hit_r = 16.0
	hit_off = Vector2(0, -HOVER - 2.0)
	speed = 95.0
	bar_y = -HOVER - 28.0
	glow_col = Color("5fffc8")
	spawn_dur = 0.8
	body_p = Part.make(vis, _paint_body, Vector2(0, -HOVER))
	glow_p = Part.make(vis, _paint_glow, Vector2(0, -HOVER), true)


func _death_chunks() -> Array:
	return [Color("e8f2f6"), Color("8ab0c8"), Color("5fffc8"), Color("2a4a4a")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 18.0, Color(0, 0, 0, 0.4 - sin(hover_t * 2.0) * 0.04))


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	# aspas / aros
	for s in [-1.0, 1.0]:
		var ph := sin(hover_t * 14.0 + s) * 0.5
		c.draw_arc(Vector2(s * 13.0, -3), 8.0, 0, TAU, 14, Color(1, 1, 1, 0.35 + ph * 0.1), 2.0, true)
		c.draw_line(Vector2(s * 6.0, -1), Vector2(s * 13.0, -3), ink, 3.0, true)
	Gfx.gell(c, Vector2(0, 0), 10.0, 11.0, Color("e8f2f6"), Color("8ab0c8"), ink, 2.4)
	c.draw_rect(Rect2(-2.2, -6, 4.4, 12), glow_col.darkened(0.2))
	c.draw_rect(Rect2(-6.2, -2.2, 12.4, 4.4), glow_col.darkened(0.2))
	c.draw_rect(Rect2(-2.2, -6, 4.4, 12), ink, false, 1.2)
	c.draw_rect(Rect2(-6.2, -2.2, 12.4, 4.4), ink, false, 1.2)
	c.draw_line(Vector2(0, -11), Vector2(0, -19), ink, 3.0, true)
	c.draw_circle(Vector2(0, -19.5), 2.4, glow_col if int(hover_t * 3.0) % 2 == 0 else glow_col.darkened(0.6))


func _paint_glow(c: Part) -> void:
	var k := 0.0 if pulse_t < 0.0 else clampf(1.0 - pulse_t / 0.5, 0.0, 1.0)
	Gfx.draw_glow(c, Vector2.ZERO, 22.0 + k * 20.0, Color(glow_col, 0.28 + 0.4 * k))


func _after_spawn() -> void:
	state = 1
	st = 0.0
	goal = position


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	face_toward(pl.position, dt)
	# busca aliados
	var ally_c := Vector2.ZERO
	var n := 0
	for e in game.enemies:
		if e != self and not (e is Mender):
			ally_c += e.position
			n += 1
	var dir := Vector2.ZERO
	if n > 0:
		ally_c /= float(n)
		lone_t = 0.0
		# se coloca del lado opuesto al jugador respecto al grupo
		var behind := ally_c + (ally_c - pl.position).normalized() * 110.0
		var to_b := behind - position
		if to_b.length() > 24.0:
			dir = to_b.normalized()
		if dist < 190.0:
			dir = (dir - dirp * 1.3).normalized()
	else:
		lone_t += dt
		dir = -dirp + Vector2(-dirp.y, dirp.x) * sin(t * 1.5) * 0.8
		shoot_cd -= dt
		if shoot_cd <= 0.0 and dist < 420.0:
			shoot_cd = 2.2
			var b := game.bullets.fire(position + Vector2(0, -HOVER), (pl.hit_center() - position - Vector2(0, -HOVER)).normalized(), 260.0, 3.0, 1.0, Bullets.Style.ORB, 1)
			b.col = glow_col
			game.sfx.play("bolt", -10.0, 1.4)
	steer(dir, speed if stun <= 0.0 else 0.0, dt, 600.0)
	pulse_cd -= dt
	if pulse_t >= 0.0:
		pulse_t += dt
		if pulse_t > 0.5:
			pulse_t = -1.0
	if pulse_cd <= 0.0 and n > 0:
		pulse_cd = 4.6
		pulse_t = 0.0
		_pulse()


func _pulse() -> void:
	var c := position + Vector2(0, -HOVER)
	game.fx.ring(c, 8.0, 150.0, glow_col, 0.5, 4.0)
	game.sfx.play("heal", -8.0, 1.2)
	for e in game.enemies:
		if e == self or e.state == S_DYING:
			continue
		if e.position.distance_to(position) < 170.0 and e.hp < e.max_hp:
			e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.12)
			e.hp_show = 1.5
			e.bar.queue_redraw()
			game.fx.bolt(c, e.hit_center(), glow_col, 0.25)
			game.fx.burst(e.hit_center(), 6, 120.0, glow_col, 0.4)


func face_toward(p: Vector2, _dt: float, _rate: float = 14.0) -> void:
	var dx := p.x - position.x
	if absf(dx) > 6.0:
		face = 1.0 if dx > 0.0 else -1.0


func _animate(dt: float) -> void:
	hover_t += dt
	var bob := sin(hover_t * 3.4) * 2.4
	body_p.position = Vector2(0, -HOVER + bob)
	body_p.rotation = clampf(vel.x / 300.0, -0.25, 0.25)
	glow_p.position = Vector2(0, -HOVER + bob)
	body_p.queue_redraw()
	glow_p.soft_redraw()
	shadow.soft_redraw()
