class_name RoleShooter
extends Enemy
## Rol: tirador. Mantiene distancia preferida, hace strafing y reposicionamiento, apunta (anticipacion por postura/brillo)
## y dispara rafagas con abanico. La clase hija solo pinta y ajusta parametros.

const ST_MOVE := 1
const ST_WIND := 2
const ST_FIRE := 3
const ST_REC := 4

var pref_min := 210.0
var pref_max := 360.0
var burst := 3
var burst_gap := 0.16
var windup := 0.55
var cd_min := 1.6
var cd_max := 2.6
var b_style := Bullets.Style.EBOLT
var b_speed := 330.0
var b_col := Color("ff6a4a")
var fan_n := 1
var fan_ang := 0.0
var lead := 0.0
var needs_los := true

var goal := Vector2.ZERO
var goal_t := 0.0
var cooldown := 1.5
var shots_left := 0
var shot_t := 0.0
var aim_dir := Vector2.DOWN
var windup_k := 0.0
var recoil := 0.0
var strafe_dir := 1.0
var rec_t := 0.7
var muzzle_off := Vector2(0, -22)


func _after_spawn() -> void:
	state = ST_MOVE
	st = 0.0
	strafe_dir = 1.0 if randf() < 0.5 else -1.0
	cooldown = randf_range(cd_min, cd_max)
	_pick_goal()


func face_toward(p: Vector2, _dt: float, _rate: float = 14.0) -> void:
	var dx := p.x - position.x
	if absf(dx) > 6.0:
		face = 1.0 if dx > 0.0 else -1.0


func _on_hurt(_d: float) -> void:
	stun = 0.07
	recoil = 0.6


func _muzzle() -> Vector2:
	return position + muzzle_off + aim_dir * 22.0


func _pick_goal() -> void:
	var pl := game.player
	var best := position
	var best_score := -1e9
	for i in 10:
		var a := randf() * TAU
		var d := randf_range(pref_min, pref_max)
		var p := pl.position + Vector2.from_angle(a) * d
		if not game.room.free_point(p, radius + 8.0):
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
	goal_t = randf_range(1.6, 2.6)


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.hit_center() - (position + muzzle_off)
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_MOVE:
			face_toward(pl.position, dt)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 8.0, 0.0, 1.0)).normalized()
			windup_k = move_toward(windup_k, 0.0, dt * 4.0)
			var to_g := goal - position
			var dir := Vector2.ZERO
			if to_g.length() > 22.0:
				dir = to_g.normalized()
			else:
				dir = Vector2(-dirp.y, dirp.x) * strafe_dir * 0.4
			if dist < pref_min * 0.85:
				dir = (-dirp * 1.2 + dir * 0.3).normalized()
			steer(dir, speed if stun <= 0.0 else 0.0, dt, 700.0)
			goal_t -= dt
			if goal_t <= 0.0:
				_pick_goal()
				strafe_dir = -strafe_dir
			cooldown -= dt
			var los_ok := (not needs_los) or game.room.los(position + muzzle_off, pl.hit_center())
			if cooldown <= 0.0 and los_ok and dist < pref_max + 120.0 and dist > 120.0 and not pl.dead:
				state = ST_WIND
				st = 0.0
				_on_windup_start()
		ST_WIND:
			vel = vel.move_toward(Vector2.ZERO, 600.0 * dt)
			face_toward(pl.position, dt)
			windup_k = clampf(st / windup, 0.0, 1.0)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 5.0, 0.0, 1.0)).normalized()
			_windup_fx(dt)
			if st >= windup:
				state = ST_FIRE
				st = 0.0
				shots_left = burst
				shot_t = 0.0
		ST_FIRE:
			vel = vel.move_toward(Vector2.ZERO, 600.0 * dt)
			face_toward(pl.position, dt)
			shot_t -= dt
			if shot_t <= 0.0 and shots_left > 0:
				_fire(dirp, dist)
				shots_left -= 1
				shot_t = burst_gap
			if shots_left <= 0 and shot_t <= 0.0:
				state = ST_REC
				st = 0.0
		ST_REC:
			windup_k = maxf(0.0, windup_k - dt * 3.0)
			steer(Vector2(-dirp.y, dirp.x) * strafe_dir, speed * 0.5, dt)
			face_toward(pl.position, dt)
			aim_dir = aim_dir.lerp(dirp, clampf(dt * 4.0, 0.0, 1.0)).normalized()
			if st >= rec_t:
				state = ST_MOVE
				st = 0.0
				cooldown = randf_range(cd_min, cd_max)
				_pick_goal()


func _on_windup_start() -> void:
	game.sfx.play("charge", -8.0, 1.2)


func _windup_fx(_dt: float) -> void:
	if int(st * 40.0) % 4 == 0:
		var tip := _muzzle()
		game.fx.mote(tip + Vector2.from_angle(randf() * TAU) * randf_range(16, 26), tip, b_col, 0.18)


func _fire(dirp: Vector2, dist: float) -> void:
	var pl := game.player
	var target := pl.hit_center() + pl.vel * lead * clampf(dist / b_speed, 0.0, 1.0)
	var d := (target - (position + muzzle_off)).normalized()
	aim_dir = d
	var m := _muzzle()
	for i in fan_n:
		var a := d.angle() + (float(i) - float(fan_n - 1) * 0.5) * fan_ang
		var b := game.bullets.fire(m, Vector2.from_angle(a), b_speed, 3.2, 1.0, b_style, 1)
		b.col = b_col
	recoil = 1.0
	vel -= d * 50.0
	game.fx.muzzle(m, d.angle(), 0.8, b_col)
	game.sfx.play("bolt", -7.0, 1.0, 0.06)
	game.shake(0.03)
