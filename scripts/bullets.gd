class_name Bullets
extends Node2D
## Gestor de proyectiles (jugador y enemigos). Un solo nodo, dibujo aditivo.

class B:
	var pos := Vector2.ZERO
	var vel := Vector2.ZERO
	var life: float = 1.0
	var team: int = 0
	var dmg: float = 1.0
	var kind: int = 0
	var pierce: int = 0
	var r: float = 4.0
	var hit: Array = []
	var knock: float = 0.0
	var age: float = 0.0
	var trail: PackedVector2Array = PackedVector2Array()

var list: Array[B] = []
var game: Game
var wall_sfx_t := 0.0


func _ready() -> void:
	material = Gfx.add_material()
	z_index = 11


func fire(pos: Vector2, dir: Vector2, speed: float, life: float, dmg: float, kind: int, team: int, pierce: int = 0, knock: float = 0.0) -> void:
	var b := B.new()
	b.pos = pos
	b.vel = dir * speed
	b.life = life
	b.dmg = dmg
	b.kind = kind
	b.team = team
	b.pierce = pierce
	b.knock = knock
	b.r = [3.0, 4.0, 4.0, 6.0][kind]
	b.trail.append(pos)
	list.append(b)


func clear_all() -> void:
	list.clear()


func _process(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	wall_sfx_t -= dt
	var i := list.size() - 1
	while i >= 0:
		var b := list[i]
		if _step(b, dt):
			list.remove_at(i)
		i -= 1
	queue_redraw()


func _step(b: B, dt: float) -> bool:
	b.life -= dt
	b.age += dt
	if b.life <= 0.0:
		_fizzle(b)
		return true
	var a := b.pos
	var c := b.pos + b.vel * dt
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
				# t aproximado del impacto
				var ab := c - a
				var tt := clampf((hc - a).dot(ab) / maxf(ab.length_squared(), 0.001), 0.0, 1.0)
				if tt <= best_t:
					var ip := a + ab * tt
					en.hurt(b.dmg, b.vel.normalized(), b.knock, ip, b.kind)
					b.hit.append(en)
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
				pl.take_damage(1, b.vel.normalized(), 150.0)
				game.fx.burst(hc, 8, 220.0, Color("ff5fb8"), 0.3)
				game.fx.ring(hc, 4.0, 22.0, Color("ff7ac8"), 0.2, 3.0)
				return true
	if best_t <= 1.0:
		var hp := a + (c - a) * best_t
		var n := Gfx.rect_normal(best_rect, hp)
		_impact(b, hp, n, best_prop)
		return true
	b.pos = c
	b.trail.append(c)
	var cap := 9 if b.kind == 2 else 6
	if b.trail.size() > cap:
		b.trail.remove_at(0)
	return false


func _fizzle(b: B) -> void:
	var col := _col(b)
	game.fx.burst(b.pos, 3, 80.0, col, 0.2)


func _col(b: B) -> Color:
	match b.kind:
		0:
			return Color("3df2dc")
		1:
			return Color("ffc24a")
		2:
			return Color("6cc4ff")
	return Color("ff5fb8")


func _impact(b: B, p: Vector2, n: Vector2, prop) -> void:
	var col := _col(b)
	var fx := game.fx
	fx.spark(p, n, 5 if b.kind != 2 else 9, 260.0, col, 0.22, 0.9)
	fx.flash(p, 14.0 if b.kind != 2 else 24.0, Color(col, 0.7), 0.1)
	fx.puff(p + n * 3.0, n * 30.0, 6.0, Color(0.55, 0.6, 0.72, 0.35), 0.35, 2.2)
	if b.kind != 3 and randf() < 0.5:
		fx.add_decal(p + Vector2(0, 14), 0, 9.0, Color.BLACK)
	if prop != null and b.team == 0:
		prop.hit(b.dmg, p)
	if wall_sfx_t <= 0.0:
		game.sfx.play("wall", -10.0, 1.0, 0.15)
		wall_sfx_t = 0.04


func _draw() -> void:
	for b in list:
		var d := b.vel.normalized()
		match b.kind:
			0:
				var l := 20.0
				draw_line(b.pos - d * l, b.pos, Color(0.24, 0.95, 0.86, 0.22), 8.0, true)
				draw_line(b.pos - d * l * 0.8, b.pos, Color(0.24, 0.95, 0.86, 0.9), 3.6, true)
				draw_line(b.pos - d * l * 0.5, b.pos + d * 3.0, Color(0.9, 1.0, 1.0, 1.0), 1.8, true)
				Gfx.draw_glow(self, b.pos, 11.0, Color(0.3, 1.0, 0.9, 0.55))
			1:
				var l := 11.0
				draw_line(b.pos - d * l, b.pos, Color(1.0, 0.7, 0.2, 0.3), 6.5, true)
				var perp := Vector2(-d.y, d.x)
				var pts := PackedVector2Array([b.pos + d * 5.0, b.pos + perp * 2.6, b.pos - d * 6.0, b.pos - perp * 2.6])
				draw_colored_polygon(pts, Color(1.0, 0.84, 0.4, 1.0))
				draw_circle(b.pos, 1.6, Color.WHITE)
				Gfx.draw_glow(self, b.pos, 11.0, Color(1.0, 0.7, 0.2, 0.5))
			2:
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					var w := PackedVector2Array()
					for k in n:
						var f := float(k) / float(n - 1)
						cols.append(Color(0.45, 0.78, 1.0, f * 0.7))
						w.append(b.trail[k])
					var tail := b.pos - d * 52.0
					w[0] = w[0].lerp(tail, 0.0)
					draw_polyline_colors(w, cols, 9.0, true)
					draw_line(b.pos - d * 38.0, b.pos, Color(0.7, 0.92, 1.0, 0.55), 5.0, true)
				draw_line(b.pos - d * 26.0, b.pos + d * 4.0, Color(1, 1, 1, 1), 2.4, true)
				Gfx.draw_glow(self, b.pos, 24.0, Color(0.45, 0.8, 1.0, 0.7))
				Gfx.draw_glow(self, b.pos, 10.0, Color(1, 1, 1, 0.8))
			3:
				var pulse := 1.0 + 0.15 * sin(b.age * 30.0)
				var n := b.trail.size()
				if n > 1:
					var cols := PackedColorArray()
					for k in n:
						cols.append(Color(1.0, 0.25, 0.65, float(k) / float(n - 1) * 0.55))
					draw_polyline_colors(b.trail, cols, 9.0, true)
				Gfx.draw_glow(self, b.pos, 22.0 * pulse, Color(1.0, 0.2, 0.62, 0.7))
				draw_circle(b.pos, 6.5 * pulse, Color(1.0, 0.35, 0.72, 0.95))
				draw_circle(b.pos, 3.6, Color(1.0, 0.9, 0.95, 1.0))
				for k in 3:
					var ang := b.age * 14.0 + TAU * float(k) / 3.0
					draw_circle(b.pos + Vector2.from_angle(ang) * 9.0, 1.3, Color(1.0, 0.7, 0.9, 0.9))
