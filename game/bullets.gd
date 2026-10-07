class_name Bullets
extends Node2D
## Gestor de proyectiles (jugador y enemigos). Un solo nodo con dibujo aditivo y POOL de objetos:
## no se crean ni destruyen proyectiles en caliente (sin presion de GC en movil).

enum Style { PULSE, PELLET, RAIL, ORB, PLASMA, GRENADE, NEEDLE, FLAME, MISSILE, EBOLT, SHARD, ARROW, RUNE, DRONE }

const RADIUS := [3.0, 4.0, 4.0, 6.0, 5.0, 5.0, 3.0, 7.0, 4.0, 3.0, 4.0, 3.0, 6.0, 5.0]
const MAX_BULLETS := 220

class B:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life: float = 1.0
	var team: int = 0
	var dmg: float = 1.0
	var style: int = 0
	var pierce: int = 0
	var r: float = 4.0
	var hit: Array = []
	var knock: float = 0.0
	var age: float = 0.0
	var trail: PackedVector2Array = PackedVector2Array()
	var col := Color.WHITE
	var bounce: int = 0
	var explode_r: float = 0.0
	var explode_mult: float = 1.0
	var homing: float = 0.0
	var accel: float = 0.0
	var fuse: float = 0.0
	var drag: float = 0.0
	var wobble: float = 0.0
	var cat: String = ""
	var crit := false
	var max_speed: float = 0.0
	var tint := Color.WHITE
	var seed_v: float = 0.0
	var target: Enemy = null
	var enemy_dmg: int = 1
	var dead := false

var list: Array[B] = []
var _free: Array[B] = []
var _spare := B.new()
var game: Game
var wall_sfx_t := 0.0


func _ready() -> void:
	material = Gfx.add_material()
	z_index = 11
	for i in 80:
		_free.append(B.new())


func fire(pos: Vector2, dir: Vector2, speed: float, life: float, dmg: float, style: int, team: int, pierce: int = 0, knock: float = 0.0) -> B:
	if list.size() >= MAX_BULLETS:
		return _spare   # saturado: el proyectil se descarta (objeto comodin fuera de la lista)
	var b: B = _free.pop_back() if not _free.is_empty() else B.new()
	b.pos = pos
	b.vel = dir * speed
	b.life = life
	b.dmg = dmg
	b.style = style
	b.team = team
	b.pierce = pierce
	b.knock = knock
	b.r = RADIUS[style]
	b.hit.clear()
	b.age = 0.0
	b.bounce = 0
	b.explode_r = 0.0
	b.explode_mult = 1.0
	b.homing = 0.0
	b.accel = 0.0
	b.fuse = 0.0
	b.drag = 0.0
	b.wobble = 0.0
	b.cat = ""
	b.crit = false
	b.max_speed = 0.0
	b.target = null
	b.enemy_dmg = 1
	b.dead = false
	b.seed_v = randf() * 10.0
	b.col = default_color(style)
	b.trail.clear()
	b.trail.append(pos)
	list.append(b)
	return b


static func default_color(style: int) -> Color:
	match style:
		Style.PULSE:
			return Color("3df2dc")
		Style.PELLET:
			return Color("ffc24a")
		Style.RAIL:
			return Color("6cc4ff")
		Style.ORB:
			return Color("ff5fb8")
		Style.PLASMA:
			return Color("7dff6a")
		Style.GRENADE:
			return Color("ff9a3d")
		Style.NEEDLE:
			return Color("ff6a6a")
		Style.FLAME:
			return Color("ff8a2a")
		Style.MISSILE:
			return Color("ffd23d")
		Style.EBOLT:
			return Color("ff6a4a")
		Style.SHARD:
			return Color("5fe8c0")
		Style.ARROW:
			return Color("e8d8b0")
		Style.RUNE:
			return Color("b47bff")
		Style.DRONE:
			return Color("6affb0")
	return Color.WHITE


func clear_all() -> void:
	for b in list:
		b.dead = false
		b.target = null
		_free.append(b)
	list.clear()


## Borra proyectiles enemigos (p. ej. barrera reactiva). Devuelve cuantos.
func clear_enemy_bullets(center: Vector2, radius: float) -> int:
	var n := 0
	for b in list:
		if not b.dead and b.team == 1 and b.pos.distance_squared_to(center) <= radius * radius:
			game.fx.burst(b.pos, 3, 100.0, b.col, 0.2)
			b.dead = true
			n += 1
	return n


## Convierte los proyectiles enemigos cercanos en proyectiles del jugador (campo espejo / filo).
func reflect_in_radius(center: Vector2, radius: float, dir_hint: Vector2 = Vector2.ZERO, to_player_team: bool = true) -> int:
	var n := 0
	for b in list:
		if not b.dead and b.team == 1 and b.pos.distance_squared_to(center) <= radius * radius:
			var d := -b.vel.normalized() if dir_hint == Vector2.ZERO else dir_hint
			b.vel = d * maxf(b.vel.length() * 1.2, 520.0)
			b.team = 0 if to_player_team else 1
			b.dmg = maxf(b.dmg, 3.0)
			b.hit.clear()
			b.life = maxf(b.life, 1.0)
			b.tint = Color(0.7, 1, 1)
			game.fx.ring(b.pos, 3.0, 18.0, Color("9fe9ff"), 0.18, 2.0)
			n += 1
	return n


## Compacta la lista: los proyectiles marcados `dead` vuelven al pool (una sola pasada, segura ante cambios durante el paso).
func _compact() -> void:
	var w := 0
	for r in list.size():
		var b := list[r]
		if b.dead:
			b.target = null
			_free.append(b)
		else:
			list[w] = b
			w += 1
	list.resize(w)


func _process(delta: float) -> void:
	Prof.begin("bul_proc")
	__process_impl(delta)
	Prof.end("bul_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	wall_sfx_t -= dt
	var n := list.size()
	for i in n:
		var b := list[i]
		if b.dead:
			continue
		if _step(b, dt):
			b.dead = true
	_compact()
	queue_redraw()


func _slow_factor(b: B) -> float:
	return game.enemy_time if b.team == 1 else 1.0


func _step(b: B, dt: float) -> bool:
	dt *= _slow_factor(b)
	b.age += dt
	if b.fuse > 0.0:
		b.fuse -= dt
		if b.fuse <= 0.0:
			_detonate(b)
			return true
	b.life -= dt
	if b.life <= 0.0:
		if b.explode_r > 0.0 and b.style != Style.GRENADE and b.style != Style.PLASMA:
			_detonate(b)
		else:
			_fizzle(b)
		return true
	if b.homing > 0.0:
		_home(b, dt)
	if b.accel != 0.0:
		var sp := b.vel.length()
		var cap := b.max_speed if b.max_speed > 0.0 else 1400.0
		if sp < cap:
			b.vel = b.vel.normalized() * minf(cap, sp + b.accel * dt)
	if b.drag > 0.0:
		b.vel *= exp(-b.drag * dt)
	var a := b.pos
	var c := b.pos + b.vel * dt
	if b.wobble > 0.0:
		c += b.vel.orthogonal().normalized() * sin(b.age * 18.0 + b.seed_v) * 22.0 * b.wobble * dt
	# --- muros y props
	var best_t := 2.0
	var best_rect := Rect2()
	var best_prop = null
	for item in game.room.bullet_rects:
		var rr: Rect2 = item[0]
		var t := Gfx.seg_rect(a, c, rr)
		if t >= 0.0 and t < best_t:
			best_t = t
			best_rect = rr
			best_prop = item[1]
	# --- objetivos
	if b.team == 0:
		for e in game.enemies:
			var en: Enemy = e
			if not en.targetable() or b.hit.has(en):
				continue
			var hc := en.hit_center()
			var rad := en.hit_r + b.r
			if Gfx.seg_point_dist2(a, c, hc) <= rad * rad:
				var ab := c - a
				var tt := clampf((hc - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
				if tt <= best_t:
					var ip := a + ab * tt
					game.hit_enemy(en, b, ip)
					b.hit.append(en)
					if b.explode_r > 0.0 and (b.style == Style.PLASMA or b.style == Style.MISSILE or b.style == Style.DRONE):
						b.pos = ip
						_detonate(b)
						return true
					if b.pierce <= 0:
						b.pos = ip
						return true
					b.pierce -= 1
					b.dmg *= 0.85
	else:
		var pl := game.player
		if pl.can_be_hit():
			var hc := pl.hit_center()
			var rad := pl.HIT_R + b.r * 0.6
			if Gfx.seg_point_dist2(a, c, hc) <= rad * rad:
				if pl.try_reflect(b):
					return false
				pl.take_damage(b.enemy_dmg, b.vel.normalized(), 150.0)
				game.fx.burst(hc, 8, 220.0, b.col, 0.3)
				game.fx.ring(hc, 4.0, 22.0, b.col.lightened(0.2), 0.2, 3.0)
				return true
	if best_t <= 1.0:
		var hp := a + (c - a) * best_t
		var n := Gfx.rect_normal(best_rect, hp)
		if b.bounce > 0:
			b.bounce -= 1
			b.vel = b.vel.bounce(n)
			b.pos = hp + n * 2.5
			b.trail.clear()
			b.trail.append(b.pos)
			b.hit.clear()
			game.fx.spark(hp, n, 3, 160.0, b.col, 0.15, 0.9)
			if best_prop != null and b.team == 0:
				best_prop.hit(b.dmg * 0.5, hp)
			if wall_sfx_t <= 0.0:
				game.sfx.play("tink", -14.0, 1.4, 0.1)
				wall_sfx_t = 0.05
			return false
		_impact(b, hp, n, best_prop)
		return true
	b.pos = c
	b.trail.append(c)
	var cap_n := 9 if b.style == Style.RAIL else (4 if b.style == Style.FLAME else 6)
	if b.trail.size() > cap_n:
		b.trail.remove_at(0)
	return false


func _home(b: B, dt: float) -> void:
	if b.target == null or not is_instance_valid(b.target) or not b.target.targetable():
		b.target = _pick_target(b)
	var tgt: Vector2
	if b.team == 0:
		if b.target == null:
			return
		tgt = b.target.hit_center()
	else:
		tgt = game.player.hit_center()
	var want := (tgt - b.pos).angle()
	var cur := b.vel.angle()
	var diff := wrapf(want - cur, -PI, PI)
	var step := clampf(diff, -b.homing * dt, b.homing * dt)
	b.vel = b.vel.rotated(step)


func _pick_target(b: B) -> Enemy:
	var best: Enemy = null
	var bd := 360.0 * 360.0
	for e in game.enemies:
		if not e.targetable():
			continue
		var d := b.pos.distance_squared_to(e.hit_center())
		if d < bd:
			bd = d
			best = e
	return best


func _detonate(b: B) -> void:
	var r := maxf(b.explode_r, 24.0)
	game.explode(b.pos, r, b.dmg * b.explode_mult, b.team, b.cat, b.col)


func _fizzle(b: B) -> void:
	if b.style == Style.FLAME:
		return
	game.fx.burst(b.pos, 3, 80.0, b.col, 0.2)


func _impact(b: B, p: Vector2, n: Vector2, prop) -> void:
	var col := b.col
	var fx := game.fx
	if b.explode_r > 0.0 and (b.style == Style.PLASMA or b.style == Style.GRENADE or b.style == Style.MISSILE or b.style == Style.DRONE):
		b.pos = p + n * 3.0
		_detonate(b)
		return
	if b.style == Style.FLAME:
		fx.puff(p + n * 3.0, n * 40.0, 7.0, Color(1.0, 0.6, 0.2, 0.4), 0.3, 2.2)
		return
	fx.spark(p, n, 5 if b.style != Style.RAIL else 9, 260.0, col, 0.22, 0.9)
	fx.flash(p, 14.0 if b.style != Style.RAIL else 24.0, Color(col, 0.7), 0.1)
	fx.puff(p + n * 3.0, n * 30.0, 6.0, Color(0.55, 0.6, 0.72, 0.35), 0.35, 2.2)
	if b.team == 0 and randf() < 0.5:
		fx.add_decal(p + Vector2(0, 14), 0, 9.0, Color.BLACK)
	if prop != null and b.team == 0:
		prop.hit(b.dmg, p)
	if wall_sfx_t <= 0.0:
		game.sfx.play("wall", -10.0, 1.0, 0.15)
		wall_sfx_t = 0.04


# ---------------------------------------------------------------- dibujo
func _draw() -> void:
	Prof.begin("bul_draw")
	__draw_impl()
	Prof.end("bul_draw")


func __draw_impl() -> void:
	for b in list:
		if b.dead:
			continue
		var d := b.vel.normalized()
		var col := b.col
		match b.style:
			Style.PULSE:
				var l := 20.0
				draw_line(b.pos - d * l, b.pos, Color(col, 0.22), 8.0, true)
				draw_line(b.pos - d * l * 0.8, b.pos, Color(col, 0.9), 3.6, true)
				draw_line(b.pos - d * l * 0.5, b.pos + d * 3.0, Color(0.9, 1.0, 1.0, 1.0), 1.8, true)
				Gfx.draw_glow(self, b.pos, 11.0, Color(col, 0.55))
			Style.PELLET:
				var l := 11.0
				draw_line(b.pos - d * l, b.pos, Color(col, 0.3), 6.5, true)
				var perp := Vector2(-d.y, d.x)
				var pts := PackedVector2Array([b.pos + d * 5.0, b.pos + perp * 2.6, b.pos - d * 6.0, b.pos - perp * 2.6])
				draw_colored_polygon(pts, col.lightened(0.3))
				draw_circle(b.pos, 1.6, Color.WHITE)
				Gfx.draw_glow(self, b.pos, 11.0, Color(col, 0.5))
			Style.RAIL:
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					for k in n:
						cols.append(Color(col.r, col.g, col.b, float(k) / float(n - 1) * 0.7))
					draw_polyline_colors(b.trail, cols, 9.0, true)
					draw_line(b.pos - d * 38.0, b.pos, Color(col.lightened(0.5), 0.55), 5.0, true)
				draw_line(b.pos - d * 26.0, b.pos + d * 4.0, Color(1, 1, 1, 1), 2.4, true)
				Gfx.draw_glow(self, b.pos, 24.0, Color(col, 0.7))
				Gfx.draw_glow(self, b.pos, 10.0, Color(1, 1, 1, 0.8))
			Style.ORB:
				var pulse := 1.0 + 0.15 * sin(b.age * 30.0)
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					for k in n:
						cols.append(Color(col.r, col.g, col.b, float(k) / float(n - 1) * 0.55))
					draw_polyline_colors(b.trail, cols, 9.0, true)
				Gfx.draw_glow(self, b.pos, 22.0 * pulse, Color(col, 0.7))
				draw_circle(b.pos, 6.5 * pulse, Color(col.lightened(0.2), 0.95))
				draw_circle(b.pos, 3.6, Color(1.0, 0.9, 0.95, 1.0))
				for k in 3:
					var ang := b.age * 14.0 + TAU * float(k) / 3.0
					draw_circle(b.pos + Vector2.from_angle(ang) * 9.0, 1.3, Color(col.lightened(0.5), 0.9))
			Style.PLASMA:
				var pulse := 1.0 + 0.12 * sin(b.age * 26.0 + b.seed_v)
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					for k in n:
						cols.append(Color(col.r, col.g, col.b, float(k) / float(n - 1) * 0.5))
					draw_polyline_colors(b.trail, cols, 8.0, true)
				Gfx.draw_glow(self, b.pos, 20.0 * pulse, Color(col, 0.55))
				draw_circle(b.pos, 5.0 * pulse, Color(col.lightened(0.15), 0.95))
				draw_circle(b.pos + Vector2(-1.2, -1.2), 2.4, Color(1, 1, 1, 0.9))
			Style.GRENADE:
				var blink := 0.5 + 0.5 * sin(b.age * (10.0 + (1.0 - clampf(b.fuse / 0.85, 0.0, 1.0)) * 30.0))
				Gfx.draw_glow(self, b.pos, 14.0, Color(col, 0.3 + 0.3 * blink))
				draw_circle(b.pos, 5.6, Color(0.2, 0.15, 0.1, 0.9))
				draw_circle(b.pos, 4.2, Color(col, 0.9))
				draw_circle(b.pos + Vector2(-1.2, -1.2), 1.6, Color(1, 1, 1, 0.9))
				draw_circle(b.pos + Vector2(0, -5.4), 1.4, Color(1, 0.9, 0.5, blink))
			Style.NEEDLE:
				draw_line(b.pos - d * 46.0, b.pos, Color(col, 0.18), 6.0, true)
				draw_line(b.pos - d * 28.0, b.pos + d * 4.0, Color(col.lightened(0.2), 0.95), 2.4, true)
				draw_line(b.pos - d * 14.0, b.pos + d * 5.0, Color.WHITE, 1.4, true)
				Gfx.draw_glow(self, b.pos, 12.0, Color(col, 0.55))
			Style.FLAME:
				var k := clampf(b.age / 0.27, 0.0, 1.0)
				var rad := 5.0 + 11.0 * k
				var c1 := Color(1.0, 0.85 - 0.5 * k, 0.25 - 0.1 * k, 0.55 * (1.0 - k) + 0.1)
				Gfx.draw_glow(self, b.pos, rad * 1.6, c1)
				draw_circle(b.pos, rad * 0.45, Color(1.0, 0.95, 0.6, 0.5 * (1.0 - k)))
			Style.MISSILE:
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					for k in n:
						cols.append(Color(1.0, 0.7, 0.3, float(k) / float(n - 1) * 0.5))
					draw_polyline_colors(b.trail, cols, 5.0, true)
				var perp := Vector2(-d.y, d.x)
				draw_colored_polygon(PackedVector2Array([b.pos + d * 6.0, b.pos + perp * 2.4 - d * 3.0, b.pos - d * 6.0, b.pos - perp * 2.4 - d * 3.0]), Color(col.lightened(0.3), 1.0))
				Gfx.draw_glow(self, b.pos - d * 6.0, 9.0, Color(1.0, 0.65, 0.2, 0.7))
			Style.EBOLT:
				draw_line(b.pos - d * 22.0, b.pos, Color(col, 0.2), 6.0, true)
				draw_line(b.pos - d * 14.0, b.pos + d * 3.0, Color(col.lightened(0.25), 0.95), 2.8, true)
				draw_line(b.pos - d * 7.0, b.pos + d * 3.0, Color(1, 0.95, 0.9, 1.0), 1.4, true)
				Gfx.draw_glow(self, b.pos, 10.0, Color(col, 0.5))
			Style.SHARD:
				var perp := Vector2(-d.y, d.x)
				var spin := b.age * 12.0
				draw_colored_polygon(PackedVector2Array([b.pos + d * 8.0, b.pos + perp * 3.4 * cos(spin), b.pos - d * 6.0, b.pos - perp * 3.4 * cos(spin)]), Color(col.lightened(0.4), 1.0))
				draw_line(b.pos - d * 14.0, b.pos, Color(col, 0.3), 4.0, true)
				Gfx.draw_glow(self, b.pos, 11.0, Color(col, 0.5))
			Style.ARROW:
				var perp := Vector2(-d.y, d.x)
				draw_line(b.pos - d * 18.0, b.pos + d * 5.0, Color(0.1, 0.07, 0.05, 0.9), 3.2, true)
				draw_line(b.pos - d * 18.0, b.pos + d * 5.0, Color(col, 1.0), 1.8, true)
				draw_colored_polygon(PackedVector2Array([b.pos + d * 10.0, b.pos + d * 3.0 + perp * 3.0, b.pos + d * 3.0 - perp * 3.0]), Color(1, 1, 1, 0.95))
				Gfx.draw_glow(self, b.pos, 8.0, Color(col, 0.35))
			Style.RUNE:
				var pulse := 1.0 + 0.2 * sin(b.age * 20.0)
				Gfx.draw_glow(self, b.pos, 20.0 * pulse, Color(col, 0.6))
				var rot := b.age * 5.0
				var pts := PackedVector2Array()
				for k in 4:
					pts.append(b.pos + Vector2.from_angle(rot + TAU * float(k) / 4.0) * 7.0 * pulse)
				draw_colored_polygon(pts, Color(col.lightened(0.3), 0.9))
				draw_circle(b.pos, 2.6, Color.WHITE)
			Style.DRONE:
				var blink := 0.6 + 0.4 * sin(b.age * 24.0)
				Gfx.draw_glow(self, b.pos, 14.0, Color(col, 0.45 * blink))
				draw_circle(b.pos, 4.4, Color(0.05, 0.12, 0.1, 0.95))
				draw_circle(b.pos, 3.0, Color(col, 0.95))
				draw_line(b.pos + Vector2(-6, -3), b.pos + Vector2(6, -3), Color(1, 1, 1, 0.55 + 0.3 * sin(b.age * 60.0)), 1.6, true)
				draw_circle(b.pos + Vector2(1.5, 0), 1.2, Color.WHITE)
