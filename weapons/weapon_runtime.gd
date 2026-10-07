class_name WeaponRuntime
extends RefCounted
## Ejecuta el comportamiento de un arma equipada: cadencia, rafagas, arranque (spool), carga, rebotes, cadena,
## tajo melee, haz. Los datos viven en WeaponData; aqui solo el estado de combate.

var player: Player
var data: WeaponData
var cd: float = 0.0
var burst_left: int = 0
var burst_t: float = 0.0
var spool: float = 0.0
var charge: float = 0.0
var shots: int = 0
var empty_t: float = 0.0
var firing_prev := false


func _init(p: Player, d: WeaponData) -> void:
	player = p
	data = d


func charge_frac() -> float:
	var ch: float = float(data.behavior.get("charge", 0.0))
	return clampf(charge / ch, 0.0, 1.0) if ch > 0.0 else 0.0


func update(dt: float, firing: bool) -> void:
	var b: Dictionary = data.behavior
	cd -= dt
	empty_t -= dt
	# arranque del minigun
	if b.has("spool"):
		var sp: Dictionary = b["spool"]
		spool = clampf(spool + (dt / float(sp["time"]) if firing else -dt * 1.2 / float(sp["time"])), 0.0, 1.0)
	# carga
	if b.has("charge"):
		if firing and not player.game.over:
			if player.energy >= energy_cost() or energy_cost() <= 0.0:
				charge += dt
				if int(charge * 30.0) % 4 == 0:
					player.game.fx.mote(player.muzzle_world() + Vector2.from_angle(randf() * TAU) * 26.0, player.muzzle_world(), data.color, 0.18)
				if charge >= float(b["charge"]):
					player.energy = maxf(0.0, player.energy - energy_cost())
					player.energy_idle = 0.0
					_fire()
					charge = 0.0
					cd = data.rate
			else:
				_dry()
		else:
			charge = maxf(0.0, charge - dt * 2.5)
		return
	# rafaga en curso
	if burst_left > 0:
		burst_t -= dt
		if burst_t <= 0.0:
			_fire_projectiles()
			burst_left -= 1
			burst_t = float(b.get("burst_gap", 0.06))
		return
	if firing and cd <= 0.0 and not player.game.over:
		var cost := energy_cost()
		if cost > player.energy:
			_dry()
			return
		player.energy -= cost
		player.energy_idle = 0.0
		cd = _current_rate()
		_fire()
	firing_prev = firing


func _dry() -> void:
	if empty_t <= 0.0:
		empty_t = 0.35
		player.game.sfx.play("empty", -8.0)
		player.game.hud.flash_energy()


func energy_cost() -> float:
	if data.energy_cost <= 0.0:
		return 0.0
	return data.energy_cost * player.energy_cost_mult()


func _current_rate() -> float:
	var r := data.rate
	if data.behavior.has("spool"):
		var sp: Dictionary = data.behavior["spool"]
		r = lerpf(float(sp["rate_min"]), float(sp["rate_max"]), spool)
	return r / maxf(0.25, player.rate_mult())


func _fire() -> void:
	var b := data.behavior
	player.kick = 1.0
	player.rig.heat = minf(1.0, player.rig.heat + (0.25 if data.rate < 0.15 else 1.0))
	shots += 1
	player.game.run.shots_fired += 1
	if b.has("arc"):
		_slash(b["arc"])
	elif b.has("chain"):
		_chain(b["chain"])
	elif b.has("beam"):
		_beam(float(b["beam"]))
	elif b.has("burst"):
		burst_left = int(b["burst"]) - 1
		burst_t = float(b.get("burst_gap", 0.06))
		_fire_projectiles()
	else:
		_fire_projectiles()
	player.game.shake(data.shake)
	var mv := data.body_kick
	if mv > 0.0:
		player.vel -= player.aim * mv * (0.0 if player.has_buff("bulwark") else 1.0)


func _spread_angle(base: float, i: int, cnt: int, spread: float) -> float:
	var ang := base
	if cnt > 1:
		ang += (float(i) - float(cnt - 1) * 0.5) * (spread * 2.0 / float(cnt - 1)) + randf_range(-0.05, 0.05)
	else:
		ang += randf_range(-spread, spread)
	return ang


func _fire_projectiles() -> void:
	var g := player.game
	var m := player.muzzle_world()
	var base := player.aim.angle()
	var opt := _roll_variant()
	var cnt: int = int(opt.get("count", data.count))
	var spread: float = float(opt.get("spread", data.spread)) * maxf(0.1, 1.0 + player.run.mod("spread_mult"))
	if data.behavior.has("spool"):
		spread += float((data.behavior["spool"] as Dictionary).get("spread_add", 0.0)) * (1.0 - spool * 0.4)
	var dmg: float = float(opt.get("dmg", data.damage)) * player.dmg_mult()
	var spd: float = float(opt.get("speed", data.speed))
	var life: float = data.life
	var col: Color = opt.get("color", player.bullet_color(data.color))
	var crit_p := player.crit_chance()
	var extra := 0
	if player.run.has_hook("echo_shot") and randf() < 0.15:
		extra = 1
	if player.run.has_hook("anomaly_seed") and shots % 6 == 0:
		opt = {"pierce": 2, "bounce": 1, "explode": 40.0, "explode_mult": 1.0, "color": Color("ff4fd8")}
		col = opt["color"]
	for i in cnt + extra:
		var ang := _spread_angle(base, i, cnt, spread) if i < cnt else base + randf_range(-0.14, 0.14)
		var l := life
		var s := spd
		if cnt > 1:
			l *= randf_range(0.8, 1.15)
			s *= randf_range(0.88, 1.1)
		var is_crit := randf() < crit_p
		var d := dmg * (2.0 if is_crit else 1.0)
		var b := g.bullets.fire(m, Vector2.from_angle(ang), s, l, d, data.bullet, 0, int(opt.get("pierce", data.pierce)) + int(player.run.mod("pierce")), data.knock)
		b.col = col
		b.cat = data.category
		b.crit = is_crit
		var bh: Dictionary = data.behavior
		b.bounce = int(opt.get("bounce", bh.get("bounce", 0))) + int(player.run.mod("bounce"))
		b.explode_r = float(opt.get("explode", bh.get("explode", 0.0)))
		b.explode_mult = float(opt.get("explode_mult", bh.get("explode_mult", 1.0)))
		b.homing = float(bh.get("homing", 0.0))
		b.accel = float(bh.get("accel", 0.0))
		b.max_speed = s * 2.4
		b.fuse = float(bh.get("fuse", 0.0))
		b.drag = float(bh.get("drag", 0.0))
		b.wobble = float(bh.get("wobble", 0.0)) * (1.0 if i % 2 == 0 else -1.0)
		if player.has_buff("mark"):
			b.dmg *= 2.5
			b.pierce += 2
			b.col = Color("ff5a4a")
	if player.has_buff("mark"):
		player.use_mark()
	# presentacion
	if data.muzzle_scale > 0.0:
		g.fx.muzzle(m, base, data.muzzle_scale, col)
	if data.body_kick >= 50.0:
		g.fx.spark(m, player.aim, 8, 520.0, col, 0.3, 0.55)
		g.fx.puff(m + player.aim * 8.0, player.aim * 90.0, 10.0, Color(0.7, 0.72, 0.8, 0.4), 0.45, 2.4)
	elif data.shake >= 0.14:
		g.fx.ring(m + player.aim * 6.0, 4.0, 26.0, col, 0.18, 2.5)
		g.fx.spark(m, player.aim, 6, 420.0, col, 0.22, 0.35)
	if data.casing:
		var side := Vector2(-player.aim.y, player.aim.x) * player.face
		g.fx.casing(player.position + Vector2(0, -26) + player.aim * 6.0, (side * 0.8 + Vector2(0, -0.4)).normalized())
	g.sfx.play(data.sfx, data.sfx_vol, data.sfx_pitch, 0.06, 0.03 if data.sfx == "flame" else 0.0)


func _roll_variant() -> Dictionary:
	if data.behavior.has("random"):
		var arr: Array = data.behavior["random"]
		return arr[randi() % arr.size()]
	return {}


## Tajo en arco: golpea a todos los enemigos dentro del cono y puede desviar proyectiles.
func _slash(arc: Dictionary) -> void:
	var g := player.game
	var origin := player.hit_center()
	var reach: float = float(arc["range"])
	var half: float = float(arc["angle"]) * 0.5
	var dir := player.aim
	player.rig.swing = 1.0
	var dmg := data.damage * player.dmg_mult()
	var hit_any := false
	for e in g.enemies.duplicate():
		if not e.targetable():
			continue
		var to: Vector2 = e.hit_center() - origin
		var dist: float = to.length() - e.hit_r
		if dist > reach:
			continue
		if absf(dir.angle_to(to)) > half:
			continue
		var crit := randf() < player.crit_chance()
		g.hit_enemy_direct(e, dmg * (2.0 if crit else 1.0), to.normalized(), data.knock, origin + to.normalized() * minf(to.length(), reach), data.category, crit)
		hit_any = true
	# props cercanos
	for p in g.room.props.duplicate():
		if p.destructible and p.position.distance_to(origin) < reach + 20.0:
			var tp: Vector2 = p.position - origin
			if absf(dir.angle_to(tp)) < half:
				p.hit(dmg, p.position)
	if bool(arc.get("reflect", false)) or player.passive_is("deflect"):
		var n := g.bullets.reflect_in_radius(origin + dir * reach * 0.5, reach * 0.9, dir)
		if n > 0:
			g.sfx.play("reflect", -4.0)
			g.shake(0.1)
	g.fx.slash_arc(origin, dir.angle(), reach, half * 2.0, data.color)
	player.vel += dir * 55.0
	if hit_any:
		g.hitstop(0.025)
	g.sfx.play(data.sfx, data.sfx_vol, 1.0, 0.08)


## Arco electrico encadenado: golpea al primer enemigo en la mira y salta a los mas cercanos.
func _chain(ch: Dictionary) -> void:
	var g := player.game
	var m := player.muzzle_world()
	var dir := player.aim
	var reach: float = float(ch.get("reach", 320.0))
	var first: Enemy = null
	var best := 1e9
	for e in g.enemies:
		if not e.targetable():
			continue
		var to: Vector2 = e.hit_center() - m
		var d := to.length()
		if d > reach + e.hit_r:
			continue
		var along := to.dot(dir)
		if along < 0.0:
			continue
		var perp := absf(to.cross(dir))
		if perp > e.hit_r + 26.0 + along * 0.1:
			continue
		var score := d + perp * 3.0
		if score < best:
			best = score
			first = e
	g.sfx.play(data.sfx, data.sfx_vol, 1.0, 0.08)
	g.fx.muzzle(m, dir.angle(), 0.9, data.color)
	if first == null:
		g.fx.bolt(m, m + dir * 70.0, data.color, 0.1)
		return
	var dmg := data.damage * player.dmg_mult()
	var hit: Array = [first]
	var cur := first
	var from := m
	var falloff := float(ch.get("falloff", 0.8))
	for k in int(ch.get("n", 3)):
		g.fx.bolt(from, cur.hit_center(), data.color, 0.16)
		var crit := randf() < player.crit_chance()
		g.hit_enemy_direct(cur, dmg * (2.0 if crit else 1.0), (cur.hit_center() - from).normalized(), data.knock, cur.hit_center(), data.category, crit)
		dmg *= falloff
		from = cur.hit_center()
		var nxt: Enemy = null
		var nd := float(ch.get("range", 170.0)) * float(ch.get("range", 170.0))
		for e in g.enemies:
			if hit.has(e) or not e.targetable():
				continue
			var d2 := e.hit_center().distance_squared_to(from)
			if d2 < nd:
				nd = d2
				nxt = e
		if nxt == null:
			break
		hit.append(nxt)
		cur = nxt


## Haz instantaneo que atraviesa todo hasta la pared.
func _beam(reach: float) -> void:
	var g := player.game
	var m := player.muzzle_world()
	var dir := player.aim
	var end := m + dir * reach
	var wall_t := 2.0
	for item in g.room.bullet_rects:
		var t := Gfx.seg_rect(m, end, item[0])
		if t >= 0.0 and t < wall_t:
			wall_t = t
	if wall_t <= 1.0:
		end = m + (end - m) * wall_t
	var dmg := data.damage * player.dmg_mult()
	for e in g.enemies.duplicate():
		if not e.targetable():
			continue
		if Gfx.seg_point_dist2(m, end, e.hit_center()) <= (e.hit_r + 10.0) * (e.hit_r + 10.0):
			var crit := randf() < player.crit_chance()
			g.hit_enemy_direct(e, dmg * (2.0 if crit else 1.0), dir, data.knock, e.hit_center(), data.category, crit)
	for p in g.room.props.duplicate():
		if p.destructible and Gfx.seg_point_dist2(m, end, p.position) < 900.0:
			p.hit(dmg, p.position)
	g.fx.beam(m, end, data.color, 0.28)
	g.fx.muzzle(m, dir.angle(), data.muzzle_scale, data.color)
	g.fx.spark(end, -dir, 12, 360.0, data.color, 0.3, 0.9)
	g.fx.ring(end, 4.0, 40.0, data.color, 0.25, 3.0)
	g.sfx.play(data.sfx, data.sfx_vol, 1.0, 0.04)
	g.hitstop(0.04)
