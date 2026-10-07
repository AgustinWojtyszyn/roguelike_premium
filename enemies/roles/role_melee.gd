class_name RoleMelee
extends Enemy
## Rol: cuerpo a cuerpo. Rodea al jugador, pide un slot de ataque (maximo 2 a la vez), se acerca con curva,
## carga el golpe (anticipacion por postura) y barre un cono. Nunca se queda pegado: reposiciona tras atacar.

const ST_CIRCLE := 1
const ST_APPROACH := 2
const ST_WIND := 3
const ST_STRIKE := 4
const ST_REC := 5

var ring_r := 210.0
var approach_mult := 1.35
var windup := 0.5
var strike_dur := 0.14
var rec_dur := 0.85
var reach := 62.0
var strike_dmg := 1
var strike_knock := 170.0
var attack_cd_min := 1.4
var attack_cd_max := 2.8
var cone := 1.1
var orbit := 1.0
var next_attack := 1.5
var has_slot := false
var swung := false
var side_bias := 1.0
var windup_k := 0.0
var strike_k := 0.0


func _after_spawn() -> void:
	state = ST_CIRCLE
	st = 0.0
	orbit = 1.0 if randf() < 0.5 else -1.0
	side_bias = 1.0 if randf() < 0.5 else -1.0
	ring_r = ring_r * randf_range(0.9, 1.15)
	next_attack = randf_range(attack_cd_min, attack_cd_max)


func _release() -> void:
	if has_slot:
		game.release_melee(self)
		has_slot = false


func _start_dying(dir: Vector2) -> void:
	_release()
	super._start_dying(dir)


func _on_hurt(_d: float) -> void:
	if state == ST_CIRCLE or state == ST_APPROACH:
		stun = 0.12


func _think(dt: float) -> void:
	var pl := game.player
	var to_p := pl.position - position
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	var tang := Vector2(-dirp.y, dirp.x) * orbit
	match state:
		ST_CIRCLE:
			windup_k = move_toward(windup_k, 0.0, dt * 5.0)
			if stun > 0.0:
				vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
				return
			face_toward(pl.position, dt)
			if st > randf_range(1.6, 3.0) and randf() < dt * 2.0:
				orbit = -orbit
				st = 0.0
			var radial := clampf((dist - ring_r) / 70.0, -1.0, 1.0)
			var dir := (tang * (0.85 + sin(t * 5.0) * 0.25) + dirp * radial * 1.1).normalized()
			steer(dir, speed * (1.0 if dist < ring_r + 60.0 else 1.25), dt)
			next_attack -= dt
			if next_attack <= 0.0 and not has_slot and not pl.dead:
				if game.claim_melee(self):
					has_slot = true
					state = ST_APPROACH
					st = 0.0
				else:
					next_attack = 0.5
		ST_APPROACH:
			face_toward(pl.position, dt)
			if stun > 0.0:
				vel = vel.move_toward(Vector2.ZERO, 900.0 * dt)
				return
			var curve := clampf((dist - 70.0) / 160.0, 0.0, 1.0) * 0.55 * side_bias
			steer(dirp.rotated(curve), speed * approach_mult, dt, 1500.0)
			if dist < reach + 4.0:
				state = ST_WIND
				st = 0.0
				swung = false
				game.sfx.play("wind", -8.0, 1.0 + randf() * 0.2)
			elif st > 3.5 or pl.dead:
				_release()
				state = ST_CIRCLE
				st = 0.0
				next_attack = randf_range(1.0, 2.0)
		ST_WIND:
			vel = vel.move_toward(Vector2.ZERO, 1400.0 * dt)
			face_toward(pl.position, dt, 20.0)
			windup_k = clampf(st / windup, 0.0, 1.0)
			if int(st * 40.0) % 4 == 0:
				var pp := position + Vector2(face_vis * 14.0, -14.0)
				game.fx.mote(pp + Vector2.from_angle(randf() * TAU) * randf_range(16, 26), pp, glow_col, 0.22)
			if st >= windup:
				state = ST_STRIKE
				st = 0.0
		ST_STRIKE:
			vel = vel.move_toward(Vector2(face * 40.0, 0.0), 1400.0 * dt)
			if not swung:
				swung = true
				_swipe()
			strike_k = clampf(st / strike_dur, 0.0, 1.0)
			if st >= strike_dur:
				state = ST_REC
				st = 0.0
				_release()
		ST_REC:
			windup_k = maxf(0.0, windup_k - dt * 3.0)
			steer((-dirp + tang * 0.6).normalized(), speed * 0.55, dt)
			face_toward(pl.position, dt)
			if st >= rec_dur:
				state = ST_CIRCLE
				st = 0.0
				next_attack = randf_range(attack_cd_min, attack_cd_max)
				orbit = -orbit


func _swipe() -> void:
	var pl := game.player
	var c := position + Vector2(face * 24.0, hit_off.y * 0.8)
	game.fx.arc(position + Vector2(face * 8.0, hit_off.y * 0.8), 0.0 if face > 0.0 else PI, reach * 0.65, glow_col.lightened(0.4), 0.18, cone * 2.0)
	game.fx.spark(c, Vector2(face, 0.0), 4, 240.0, glow_col, 0.2, 0.8)
	game.sfx.play("slash", -6.0)
	var to := pl.position - position
	if (to.length() < reach and signf(to.x) == face) or to.length() < 26.0:
		if pl.can_be_hit():
			pl.take_damage(strike_dmg, to.normalized(), strike_knock)
