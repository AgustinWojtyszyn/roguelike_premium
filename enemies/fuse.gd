class_name Fuse
extends Enemy
## Dron bomba: rueda hacia el jugador acelerando. Al estar cerca se hincha y parpadea (postura) y estalla
## tras un instante: hay tiempo de sobra para alejarse. Si lo matas antes, solo se desarma.

const ST_CHASE := 1
const ST_PRIME := 2

var body_p: Part
var glow_p: Part
var wheel_ph := 0.0
var prime_t := 0.0
var chase_t := 0.0
var wobble_ph := 0.0
var swell := 0.0
var cur_speed := 90.0


func _build() -> void:
	kind_name = "fuse"
	hp = 5.0
	radius = 10.0
	hit_r = 13.0
	hit_off = Vector2(0, -11)
	speed = 175.0
	bar_y = -30.0
	glow_col = Color("ffb23d")
	spawn_dur = 0.55
	wobble_ph = randf() * 6.0
	body_p = Part.make(vis, _paint_body, Vector2(0, -11))
	glow_p = Part.make(body_p, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("5a4a6a"), Color("2a2336"), Color("ffb23d"), Color("b0b8d0")]


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 16.0, Color(0, 0, 0, 0.5))


func _paint_body(c: Part) -> void:
	var ink := Gfx.INK
	var k := 1.0 + swell * 0.28
	# orugas laterales
	for sy in [-1.0, 1.0]:
		var wy: float = 7.0 * sy * k
		Gfx.rrect(c, Rect2(-12 * k, wy - 3.0, 24 * k, 6.0), 3.0, Color("2a2336"), ink, 1.6)
		for q in 4:
			var x := -9.0 * k + fposmod(wheel_ph + float(q) * 6.0, 24.0) * k
			c.draw_line(Vector2(x, wy - 2.5), Vector2(x, wy + 2.5), Color("5a4a6a"), 1.4)
	# casco esferico
	Gfx.gell(c, Vector2(0, -2), 11.0 * k, 10.0 * k, Color("8a7aa0"), Color("3a2e52"), ink, 2.2)
	c.draw_arc(Vector2(0, -2), 7.0 * k, PI * 1.15, PI * 1.85, 10, Color(1, 1, 1, 0.3), 1.6, true)
	# banda de carga
	var blink := int(prime_t * 14.0) % 2 == 0 if state == ST_PRIME else int(t * 3.0 + cur_speed * 0.01) % 2 == 0
	c.draw_rect(Rect2(-8 * k, -3, 16 * k, 4), Color("1a0f12"))
	c.draw_rect(Rect2(-7 * k, -2, 14 * k * (0.35 + swell * 0.65), 2), Color("ffb23d").lerp(Color.WHITE, swell * 0.5) if blink else Color("7a4a14"))
	# mecha
	c.draw_line(Vector2(3, -11 * k), Vector2(6, -17 * k), ink, 3.0, true)
	c.draw_circle(Vector2(6, -17 * k), 2.3, Color("ffe27a") if blink else Color("a04a1a"))


func _paint_glow(c: Part) -> void:
	var a := 0.25 + swell * 0.7
	Gfx.draw_glow(c, Vector2(0, -2), 18.0 + swell * 26.0, Color(1.0, 0.65, 0.2, a * 0.5))


func _after_spawn() -> void:
	state = ST_CHASE
	st = 0.0


func _on_hurt(_d: float) -> void:
	stun = 0.1


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_CHASE:
			face_toward(pl.position, dt, 18.0)
			chase_t += dt
			var close_k := clampf(1.0 - dist / 300.0, 0.0, 1.0)
			cur_speed = move_toward(cur_speed, lerpf(95.0, speed, close_k), 260.0 * dt)
			wobble_ph += dt * 5.0
			var side := Vector2(-dirp.y, dirp.x) * sin(wobble_ph) * 0.45
			steer((dirp + side).normalized(), cur_speed if stun <= 0.0 else 0.0, dt, 900.0)
			if (dist < 46.0 or chase_t > 5.0) and not pl.dead:
				state = ST_PRIME
				st = 0.0
				prime_t = 0.0
				game.sfx.play("charge", -8.0, 2.0)
		ST_PRIME:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			prime_t += dt
			swell = clampf(prime_t / 0.55, 0.0, 1.0)
			if prime_t > 0.28:
				game.fx.ring(position + Vector2(0, -8), 8.0, 20.0 + swell * 40.0, Color("ffb23d"), 0.12, 2.0)
			if prime_t >= 0.62:
				_detonate()


func _detonate() -> void:
	game.explode(position + Vector2(0, -8), 72.0, 1.0, 1, "", Color("ffb23d"))
	hp = 0.0
	if state != S_DYING:
		_start_dying(Vector2.UP)
		dying_t = 1.0   # muerte inmediata


func _start_dying(dir: Vector2) -> void:
	swell = 0.0
	super._start_dying(dir)


func _animate(dt: float) -> void:
	wheel_ph += vel.length() * dt * 0.8
	body_p.position = Vector2(0, -11 + sin(wheel_ph * 0.5) * 0.5)
	body_p.rotation = clampf(vel.x / 400.0, -0.3, 0.3)
	body_p.queue_redraw()
	glow_p.queue_redraw()
