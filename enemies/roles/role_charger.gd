class_name RoleCharger
extends Enemy
## Rol: embestidor SIN dash absurdo. Acecha en curvas, se agazapa (postura/vapor) y arranca una carrera con ACELERACION
## gradual y trayectoria recta que se puede esquivar de lado; si choca con un muro queda aturdido y vulnerable.

const ST_STALK := 1
const ST_REAR := 2
const ST_CHARGE := 3
const ST_STUN := 4
const ST_REC := 5

var charge_speed := 330.0
var charge_accel := 700.0
var charge_time := 0.8
var rear_time := 0.75
var stun_time := 1.1
var hit_dmg := 1
var hit_knock := 260.0
var cd_min := 1.6
var cd_max := 3.0
var stalk_r := 260.0

var cd := 1.6
var charge_dir := Vector2.RIGHT
var cur_speed := 0.0
var orbit := 1.0
var rear_k := 0.0
var hit_done := false


func _after_spawn() -> void:
	state = ST_STALK
	st = 0.0
	cd = randf_range(cd_min, cd_max)
	orbit = 1.0 if randf() < 0.5 else -1.0


func dmg_mult(_dir: Vector2) -> float:
	return 1.5 if state == ST_STUN else 1.0


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	match state:
		ST_STALK:
			rear_k = move_toward(rear_k, 0.0, dt * 5.0)
			face_toward(pl.position, dt)
			var radial := clampf((dist - stalk_r) / 80.0, -1.0, 1.0)
			var dir := (Vector2(-dirp.y, dirp.x) * orbit * 0.8 + dirp * radial).normalized()
			steer(dir, speed if stun <= 0.0 else 0.0, dt, 800.0)
			if randf() < dt * 0.35:
				orbit = -orbit
			cd -= dt
			if cd <= 0.0 and dist < 440.0 and dist > 130.0 and not pl.dead and game.room.los(position, pl.position):
				state = ST_REAR
				st = 0.0
				game.sfx.play("wind", -4.0, 0.6)
		ST_REAR:
			vel = vel.move_toward(Vector2.ZERO, 1200.0 * dt)
			face_toward(pl.position, dt, 18.0)
			rear_k = clampf(st / rear_time, 0.0, 1.0)
			charge_dir = charge_dir.lerp(dirp, clampf(dt * 6.0, 0.0, 1.0)).normalized()
			if int(st * 30.0) % 3 == 0:
				game.fx.puff(position + Vector2(-face * 14.0, -4.0), Vector2(randf_range(-20, 20), -26), 6.0, Color(0.8, 0.75, 0.7, 0.4), 0.4, 2.2)
			if st >= rear_time:
				state = ST_CHARGE
				st = 0.0
				cur_speed = speed
				hit_done = false
				game.sfx.play("stomp", -3.0, 1.2)
		ST_CHARGE:
			cur_speed = move_toward(cur_speed, charge_speed, charge_accel * dt)
			vel = charge_dir * cur_speed
			if int(st * 40.0) % 3 == 0:
				game.fx.puff(position + Vector2(0, -2.0), -charge_dir * 24.0, 6.0, Color(0.7, 0.65, 0.6, 0.4), 0.35, 2.0)
			var hit_d := pl.position.distance_to(position)
			if not hit_done and hit_d < radius + Player.RADIUS + 10.0 and pl.can_be_hit():
				hit_done = true
				pl.take_damage(hit_dmg, charge_dir, hit_knock)
			var ahead := position + charge_dir * (radius + 18.0)
			if not game.room.free_point(ahead, radius * 0.7) or st >= charge_time:
				if not game.room.free_point(ahead, radius * 0.7):
					state = ST_STUN
					game.fx.burst(ahead, 12, 260.0, Color("ffd9a0"), 0.35)
					game.fx.ring(ahead, 6.0, 40.0, Color.WHITE, 0.2, 3.0)
					game.shake(0.2)
					game.sfx.play("slam", -6.0, 1.3)
					vel = -charge_dir * 90.0
				else:
					state = ST_REC
				st = 0.0
		ST_STUN:
			vel = vel.move_toward(Vector2.ZERO, 700.0 * dt)
			rear_k = 0.0
			if st >= stun_time:
				state = ST_REC
				st = 0.0
		ST_REC:
			vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
			face_toward(pl.position, dt)
			if st >= 0.5:
				state = ST_STALK
				st = 0.0
				cd = randf_range(cd_min, cd_max)


func _integrate(dt: float) -> void:
	var np := position + vel * dt
	var pl := game.player
	if state != ST_CHARGE:
		var d := np - pl.position
		var min_d := radius + Player.RADIUS + 8.0
		if d.length() < min_d and d.length() > 0.01:
			np = pl.position + d.normalized() * min_d
	position = Gfx.push_out(np, radius, game.room.rects)
