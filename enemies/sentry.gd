class_name Sentry
extends Enemy
## Torreta de la estacion. Inmovil y blindada mientras apunta; abre las placas para disparar (ahi es vulnerable).

const ST_IDLE := 1
const ST_AIM := 2
const ST_FIRE := 3
const ST_COOL := 4

var head: Part
var base_p: Part
var glow_p: Part
var aim_dir := Vector2.DOWN
var open := 0.0
var cd := 1.2
var burst_left := 0
var burst_t := 0.0
var recoil := 0.0
var patt := 0


func _build() -> void:
	kind_name = "sentry"
	hp = 24.0
	radius = 17.0
	hit_r = 20.0
	hit_off = Vector2(0, -22)
	speed = 0.0
	bar_y = -58.0
	glow_col = Color("ff7a3d")
	spawn_dur = 0.9
	cd = randf_range(1.0, 1.8)
	base_p = Part.make(vis, _paint_base, Vector2(0, 0))
	head = Part.make(vis, _paint_head, Vector2(0, -24))
	glow_p = Part.make(head, _paint_glow, Vector2.ZERO, true)


func _death_chunks() -> Array:
	return [Color("3a4668"), Color("232b44"), Color("8793b8"), Color("ff7a3d")]


func mass() -> float:
	return 99.0


func dmg_mult(_dir: Vector2) -> float:
	return 0.55 if open < 0.4 else 1.25


func _after_spawn() -> void:
	state = ST_IDLE
	st = 0.0


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, 30.0, Color(0, 0, 0, 0.55))


func _paint_base(c: Part) -> void:
	var ink := Gfx.INK
	Gfx.gell(c, Vector2(0, -2), 19.0, 10.0, Color("3a4668"), Color("1a2036"), ink, 2.2)
	Gfx.grrect(c, Rect2(-12, -26, 24, 24), 4.0, Color("56648e"), Color("2a3354"), ink, 2.0)
	c.draw_rect(Rect2(-12, -14, 24, 3), Color("c98a22"))
	c.draw_circle(Vector2(-7, -8), 1.6, Color("0b0f1a"))
	c.draw_circle(Vector2(7, -8), 1.6, Color("0b0f1a"))


func _paint_head(c: Part) -> void:
	var ink := Gfx.INK
	var o := open * 5.0
	# placas de blindaje (se abren hacia los lados)
	for s in [-1.0, 1.0]:
		var pts := PackedVector2Array([Vector2(s * (3.0 + o), -14), Vector2(s * (17.0 + o), -9), Vector2(s * (19.0 + o), 4), Vector2(s * (4.0 + o), 8)])
		Gfx.gpoly(c, pts, Color("8793b8"), Color("3a4668"), ink, 2.0)
		c.draw_line(Vector2(s * (7.0 + o), -9), Vector2(s * (14.0 + o), -6), Color(1, 1, 1, 0.35), 1.4)
	# nucleo
	Gfx.gell(c, Vector2(0, -2), 9.0, 10.0, Color("2a1a1a"), Color("120a0a"), ink, 2.0)
	c.draw_circle(Vector2(0, -2), 4.0 + open * 1.5, glow_col.lerp(Color.WHITE, open * 0.5))
	# canones gemelos orientados
	var ang := aim_dir.angle()
	c.draw_set_transform(Vector2(0, -2), ang, Vector2.ONE)
	for sy in [-4.5, 4.5]:
		var ext := 4.0 - recoil * 5.0 + open * 3.0
		Gfx.grrect(c, Rect2(4 + ext, sy - 2.2, 20, 4.4), 1.4, Color("9aa6c8"), Color("4a5675"), ink, 1.6)
		c.draw_rect(Rect2(22 + ext, sy - 1.0, 3, 2.0), glow_col.lerp(Color.WHITE, open))
	c.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _paint_glow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2(0, -2), 16.0 + open * 14.0, Color(glow_col, 0.3 + open * 0.4))


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.hit_center() - (position + Vector2(0, -24))
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	vel = Vector2.ZERO
	match state:
		ST_IDLE:
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 4.0, 0.0, 1.0)).normalized()
			open = maxf(0.0, open - dt * 3.0)
			cd -= dt
			if cd <= 0.0 and dist < 600.0 and not pl.dead and game.room.los(position + Vector2(0, -20), pl.hit_center()):
				state = ST_AIM
				st = 0.0
				game.sfx.play("charge", -10.0, 1.4)
		ST_AIM:
			open = minf(1.0, open + dt * 3.4)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 5.0, 0.0, 1.0)).normalized()
			if int(st * 40.0) % 4 == 0:
				var tip := position + Vector2(0, -26) + aim_dir * 26.0
				game.fx.mote(tip + Vector2.from_angle(randf() * TAU) * 16.0, tip, glow_col, 0.16)
			if st >= 0.62:
				state = ST_FIRE
				st = 0.0
				patt += 1
				burst_left = 3 if patt % 3 != 0 else 5
				burst_t = 0.0
		ST_FIRE:
			burst_t -= dt
			if burst_t <= 0.0 and burst_left > 0:
				_shoot(patt % 3 == 0)
				burst_left -= 1
				burst_t = 0.16 if patt % 3 != 0 else 0.0
			if burst_left <= 0:
				state = ST_COOL
				st = 0.0
		ST_COOL:
			open = maxf(0.0, open - dt * 1.6)
			if st >= 0.9:
				state = ST_IDLE
				st = 0.0
				cd = randf_range(1.5, 2.4)


func _shoot(fan: bool) -> void:
	var from := position + Vector2(0, -26)
	var base := aim_dir.angle()
	var n := 5 if fan else 1
	for i in n:
		var a := base + (float(i) - float(n - 1) * 0.5) * 0.2 if fan else base + randf_range(-0.04, 0.04)
		var b := game.bullets.fire(from + Vector2.from_angle(a) * 26.0, Vector2.from_angle(a), 300.0 if fan else 340.0, 3.0, 1.0, Bullets.Style.EBOLT, 1)
		b.col = glow_col
	recoil = 1.0
	game.fx.muzzle(from + aim_dir * 26.0, base, 0.8, glow_col)
	game.sfx.play("bolt", -9.0, 1.2, 0.06)
	game.shake(0.03)


func _animate(dt: float) -> void:
	recoil = maxf(0.0, recoil - dt * 7.0)
	vis.scale.x = 1.0
	head.position = Vector2(0, -24 + recoil * 1.5)
	head.queue_redraw()
	glow_p.soft_redraw()
	if state == S_SPAWN:
		open = 0.0


func face_toward(_p: Vector2, _dt: float, _rate: float = 14.0) -> void:
	pass


func _integrate(_dt: float) -> void:
	pass
