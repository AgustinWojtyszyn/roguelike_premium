class_name Enemy
extends Node2D
## Base de enemigos: movimiento con esquive de obstaculos, daño, muerte.

const S_SPAWN := 0
const S_DYING := 99

var game: Game
var kind_name := "enemy"
var hp: float = 10.0
var max_hp: float = 10.0
var radius: float = 11.0
var hit_r: float = 14.0
var hit_off := Vector2(0, -16)
var speed: float = 100.0
var vel := Vector2.ZERO
var state: int = S_SPAWN
var st: float = 0.0
var face: float = 1.0
var face_vis: float = 1.0
var flash: float = 0.0
var stun: float = 0.0
var t: float = 0.0
var bar_y: float = -40.0
var dying_t: float = 0.0
var spawn_dur: float = 0.7
var vulnerable_mult: float = 1.0
var glow_col := Color("ff4fa0")
var big := false
var hp_show: float = 0.0

var data: EnemyData
var elite := false
var last_cat: String = ""
var last_hit_t: float = 0.0
var aura: Part

var vis: Node2D
var fmat: ShaderMaterial
var shadow: Part
var bar: Part


func setup(g: Game, pos: Vector2) -> void:
	game = g
	position = pos
	shadow = Part.make(self, _paint_shadow)
	vis = Node2D.new()
	fmat = Gfx.flash_material()
	vis.material = fmat
	add_child(vis)
	_build()
	hp *= g.hp_scale
	if elite:
		hp *= 1.9
		speed *= 1.08
		big = true
	bar = Part.make(self, _paint_bar)
	bar.z_index = 3
	if elite:
		aura = Part.make(self, _paint_elite, Vector2.ZERO, true)
	max_hp = hp
	face = 1.0 if randf() < 0.5 else -1.0
	face_vis = face
	t = randf() * 10.0
	vis.modulate.a = 0.0


# ---- a sobreescribir ----
func _build() -> void:
	pass


func _think(_dt: float) -> void:
	pass


func _animate(_dt: float) -> void:
	pass


func _paint_shadow(c: Part) -> void:
	Gfx.draw_glow(c, Vector2.ZERO, radius * 2.2, Color(0, 0, 0, 0.55))


func _death_chunks() -> Array:
	return [Color("3a2a52")]


func dmg_mult(_dir: Vector2) -> float:
	return vulnerable_mult


func _paint_elite(c: Part) -> void:
	var p := 0.6 + 0.4 * sin(t * 5.0)
	Gfx.draw_glow(c, Vector2.ZERO, radius * 2.6, Color(1.0, 0.75, 0.2, 0.28 * p))
	c.draw_arc(Vector2.ZERO, radius * 1.5, t * 1.5, t * 1.5 + TAU * 0.7, 20, Color(1.0, 0.85, 0.3, 0.8), 2.0, true)


func _paint_bar(c: Part) -> void:
	if hp >= max_hp or hp <= 0.0:
		return
	var w := 28.0 if not big else 44.0
	var r := Rect2(-w * 0.5, bar_y, w, 5.0)
	c.draw_rect(r.grow(1.5), Color(0, 0, 0, 0.75))
	var f := clampf(hp / max_hp, 0.0, 1.0)
	c.draw_rect(Rect2(r.position, Vector2(w * f, 5.0)), glow_col.lerp(Color.WHITE, 0.2))
	c.draw_rect(Rect2(r.position, Vector2(w * f, 1.5)), Color(1, 1, 1, 0.45))


# ---- comun ----
func targetable() -> bool:
	return state != S_DYING and not (state == S_SPAWN and st < spawn_dur * 0.6)


func hit_center() -> Vector2:
	return position + hit_off


func hurt(dmg: float, dir: Vector2, knock: float, p: Vector2, bkind: int, crit: bool = false, cat: String = "") -> void:
	var m := dmg_mult(dir)
	hp -= dmg * m
	if cat != "":
		last_cat = cat
	if crit:
		game.fx.spark(p, -dir, 6, 380.0, Color("fff2a0"), 0.3, 1.2)
		game.fx.ring(p, 3.0, 20.0, Color("fff2a0"), 0.15, 2.0)
	flash = maxf(flash, 0.5)
	hp_show = 1.5
	bar.queue_redraw()
	var fx := game.fx
	var armored := m < 0.99 and vulnerable_mult <= 1.0
	if armored:
		fx.spark(p, -dir, 7, 340.0, Color("ffe8b0"), 0.25, 0.8)
		game.sfx.play("tink", -8.0, 1.0, 0.1, 0.03)
	else:
		fx.spark(p, -dir + Vector2(randf_range(-0.4, 0.4), randf_range(-0.4, 0.4)), 5, 300.0, glow_col, 0.28, 0.9)
		fx.puff(p, -dir * 30.0, 6.0, glow_col.lerp(Color(0.5, 0.5, 0.6), 0.5) * Color(1, 1, 1, 0.5), 0.3, 2.0)
		game.sfx.play("hit", -9.0, 1.0 + randf() * 0.2, 0.1, 0.025)
	fx.flash(p, 18.0, Color(1, 1, 1, 0.6), 0.07)
	vel += dir * knock * (0.45 if armored else 1.0) / maxf(0.6, mass())
	_on_hurt(dmg * m)
	if hp <= 0.0 and state != S_DYING:
		_start_dying(dir)


func mass() -> float:
	return 1.0


func _on_hurt(_d: float) -> void:
	pass


func _start_dying(dir: Vector2) -> void:
	state = S_DYING
	dying_t = 0.0
	game.on_enemy_dying(self)
	vel = dir * 160.0 / maxf(0.8, mass())
	game.sfx.play("die_big" if big else "die", -2.0)


func _explode() -> void:
	var fx := game.fx
	var c := position + hit_off
	fx.burst(c, 26 if big else 18, 420.0 if big else 330.0, glow_col, 0.55)
	fx.burst(c, 10, 220.0, Color.WHITE, 0.3)
	fx.ring(c, 8.0, 80.0 if big else 52.0, glow_col, 0.3, 4.0)
	fx.flash(c, 110.0 if big else 70.0, Color(glow_col, 0.9), 0.2)
	fx.puff(c, Vector2.ZERO, 30.0 if big else 20.0, Color(0.45, 0.4, 0.55, 0.55), 0.7, 2.6)
	fx.puff(c + Vector2(6, -4), Vector2(10, -20), 18.0, Color(0.3, 0.28, 0.4, 0.5), 0.9, 2.2)
	var chunks := _death_chunks()
	var n := (14 if big else 9)
	for i in n:
		var col: Color = chunks[i % chunks.size()]
		fx.shard(c + Vector2(randf_range(-8, 8), randf_range(-6, 6)), Vector2.from_angle(randf() * TAU) * randf_range(70, 240), randf_range(90, 250), col.lerp(Color.WHITE, randf() * 0.2), randf_range(2.6, 6.0 if big else 4.6), Color(glow_col.r, glow_col.g, glow_col.b, 0.9 if i % 3 == 0 else 0.0))
	fx.add_decal(position, 0, 44.0 if big else 30.0, Color.BLACK)
	if big:
		fx.add_decal(position, 1, 60.0, Color.BLACK)
	game.shake(0.3 if big else 0.14)
	game.hitstop(0.06 if big else 0.035)
	game.on_enemy_dead(self)
	queue_free()


func _process(delta: float) -> void:
	Prof.begin("enemy_proc")
	__process_impl(delta)
	Prof.end("enemy_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale * game.enemy_time
	t += dt
	st += dt
	flash = maxf(0.0, flash - dt * 12.0)
	stun = maxf(0.0, stun - dt)
	hp_show = maxf(0.0, hp_show - dt)
	if state == S_DYING:
		_dying(dt)
		return
	if state == S_SPAWN:
		var k := clampf(st / spawn_dur, 0.0, 1.0)
		vis.modulate.a = clampf(k * 2.5, 0.0, 1.0)
		vis.position.y = (1.0 - Gfx.ease_out(k)) * 26.0
		vis.scale = Vector2.ONE * (0.75 + 0.25 * Gfx.ease_out(k))
		if k >= 1.0:
			vis.scale = Vector2.ONE
			vis.position = Vector2.ZERO
			vis.modulate.a = 1.0
			state = 1
			st = 0.0
			_after_spawn()
		_animate(dt)
		fmat.set_shader_parameter("flash", flash)
		return
	_think(dt)
	_integrate(dt)
	_animate(dt)
	fmat.set_shader_parameter("flash", flash)
	if hp_show > 0.0:
		bar.queue_redraw()
	if aura != null:
		aura.queue_redraw()


func _after_spawn() -> void:
	pass


func _dying(dt: float) -> void:
	dying_t += dt
	var k := dying_t / 0.26
	vis.position = Vector2(randf_range(-2, 2), randf_range(-2, 2))
	flash = 1.0 if int(dying_t * 40.0) % 2 == 0 else 0.4
	fmat.set_shader_parameter("flash", flash)
	vis.rotation = sin(dying_t * 60.0) * 0.12 * (1.0 + k)
	vel = vel.move_toward(Vector2.ZERO, 500.0 * dt)
	position = Gfx.push_out(position + vel * dt, radius, game.room.rects)
	if int(dying_t * 40.0) % 3 == 0:
		game.fx.spark(position + hit_off, Vector2.UP, 1, 160.0, glow_col, 0.2, 3.0)
	_animate(dt)
	if dying_t >= 0.26:
		_explode()


func face_toward(p: Vector2, dt: float, rate: float = 14.0) -> void:
	var dx := p.x - position.x
	if absf(dx) > 6.0:
		face = 1.0 if dx > 0.0 else -1.0
	face_vis = move_toward(face_vis, face, dt * rate)
	vis.scale.x = face_vis if absf(face_vis) > 0.1 else 0.1 * face


## Mueve esquivando obstaculos y separandose de otros enemigos.
func steer(dir: Vector2, spd: float, dt: float, accel: float = 1100.0) -> void:
	if dir != Vector2.ZERO:
		dir = dir.normalized()
		var look := radius + 26.0
		if not game.room.free_point(position + dir * look, radius * 0.85):
			for ang in [0.55, -0.55, 1.1, -1.1, 1.7, -1.7]:
				var d2: Vector2 = dir.rotated(ang)
				if game.room.free_point(position + d2 * look, radius * 0.85):
					dir = d2
					break
	var target := dir * spd
	# separacion con otros enemigos
	var sep := Vector2.ZERO
	for o in game.enemies:
		if o == self:
			continue
		var d := position - o.position
		var l := d.length()
		var min_d: float = radius + o.radius + 22.0
		if l < min_d and l > 0.01:
			sep += d / l * (1.0 - l / min_d)
	target += sep * 150.0
	vel = vel.move_toward(target, accel * dt)


func _integrate(dt: float) -> void:
	var np := position + vel * dt
	# nunca se pegan al jugador
	var pl := game.player
	var d := np - pl.position
	var min_d := radius + Player.RADIUS + 8.0
	if d.length() < min_d and d.length() > 0.01:
		np = pl.position + d.normalized() * min_d
	position = Gfx.push_out(np, radius, game.room.rects)
	vel *= maxf(0.0, 1.0 - 2.0 * dt) if stun > 0.0 else 1.0
