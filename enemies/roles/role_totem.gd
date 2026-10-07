class_name RoleTotem
extends Enemy
## Rol: torreta flotante / totem. Inmovil; se "abre" (ojos/placas) para disparar patrones (espiral, anillo, abanico)
## y opcionalmente repara aliados. Cerrado = blindado; abierto = vulnerable.

const ST_IDLE := 1
const ST_OPEN := 2
const ST_FIRE := 3
const ST_HEAL := 4
const ST_COOL := 5

var b_style := Bullets.Style.RUNE
var b_col := Color("3dd9a8")
var b_speed := 190.0
var pattern_a := "spiral"
var pattern_b := "fan"
var heals := false
var open_k := 0.0
var cd := 1.4
var cd_min := 1.8
var cd_max := 2.8
var fire_t := 0.0
var spiral_a := 0.0
var shot_t := 0.0
var aim_dir := Vector2.DOWN
var cur_pattern := ""
var cycle := 0
var hover_t := 0.0
var float_h := 0.0
var muzzle_off := Vector2(0, -36)
var heal_pulse := -1.0


func sprite_phase() -> String:
	match state:
		ST_OPEN:
			return "windup"
		ST_FIRE, ST_HEAL:
			return "strike"
	return "idle"


func sprite_progress() -> float:
	return open_k if state == ST_OPEN else -1.0


func mass() -> float:
	return 99.0


func dmg_mult(_dir: Vector2) -> float:
	return 0.5 if open_k < 0.4 else 1.25


func _after_spawn() -> void:
	state = ST_IDLE
	st = 0.0
	cd = randf_range(1.0, cd_max)


func face_toward(_p: Vector2, _dt: float, _rate: float = 14.0) -> void:
	pass


func _integrate(_dt: float) -> void:
	pass


func _on_hurt(_d: float) -> void:
	pass


func _think(dt: float) -> void:
	vel = Vector2.ZERO
	var pl := game.player
	var to_p := pl.hit_center() - (position + muzzle_off)
	var dist := to_p.length()
	var dirp := to_p / maxf(dist, 0.01)
	hover_t += dt
	aim_dir = aim_dir.lerp(dirp, clampf(dt * 3.0, 0.0, 1.0)).normalized()
	match state:
		ST_IDLE:
			open_k = maxf(0.0, open_k - dt * 3.0)
			cd -= dt
			if cd <= 0.0 and dist < 640.0 and not pl.dead:
				if heals and _ally_hurt() and cycle % 3 == 2:
					state = ST_HEAL
					cycle += 1
				else:
					state = ST_OPEN
				st = 0.0
				game.sfx.play("charge", -9.0, 0.9)
		ST_OPEN:
			open_k = minf(1.0, open_k + dt * 2.6)
			if st >= 0.7:
				state = ST_FIRE
				st = 0.0
				cur_pattern = pattern_a if cycle % 2 == 0 else pattern_b
				cycle += 1
				fire_t = 0.0
				shot_t = 0.0
				spiral_a = randf() * TAU
		ST_FIRE:
			var dur := 2.2 if cur_pattern == "spiral" else 0.9
			shot_t -= dt
			match cur_pattern:
				"spiral":
					spiral_a += dt * 2.2
					if shot_t <= 0.0:
						shot_t = 0.12
						for k in 2:
							_shoot(spiral_a + float(k) * PI, b_speed * 0.9)
				"ring":
					if shot_t <= 0.0 and fire_t < 0.1:
						shot_t = 1.0
						var n := 12
						var off := randf() * TAU
						for k in n:
							_shoot(off + TAU * float(k) / float(n), b_speed * 0.85)
				_:
					if shot_t <= 0.0 and fire_t < 0.5:
						shot_t = 0.22
						for k in 5:
							_shoot(aim_dir.angle() + (float(k) - 2.0) * 0.2, b_speed)
			fire_t += dt
			if fire_t >= dur:
				state = ST_COOL
				st = 0.0
		ST_HEAL:
			open_k = minf(1.0, open_k + dt * 2.6)
			if st >= 0.6 and heal_pulse < 0.0:
				heal_pulse = 0.0
				_heal()
			if heal_pulse >= 0.0:
				heal_pulse += dt
			if st >= 1.2:
				heal_pulse = -1.0
				state = ST_COOL
				st = 0.0
		ST_COOL:
			open_k = maxf(0.0, open_k - dt * 1.4)
			if st >= 0.8:
				state = ST_IDLE
				st = 0.0
				cd = randf_range(cd_min, cd_max)


func _ally_hurt() -> bool:
	for e in game.enemies:
		if e != self and e.hp < e.max_hp * 0.8:
			return true
	return false


func _heal() -> void:
	var c := position + muzzle_off
	game.fx.ring(c, 10.0, 170.0, b_col, 0.5, 4.0)
	game.sfx.play("heal", -8.0, 0.9)
	for e in game.enemies:
		if e == self or e.state == S_DYING:
			continue
		if e.position.distance_to(position) < 190.0 and e.hp < e.max_hp:
			e.hp = minf(e.max_hp, e.hp + e.max_hp * 0.25)
			e.hp_show = 1.5
			e.bar.queue_redraw()
			game.fx.bolt(c, e.hit_center(), b_col, 0.25)


func _shoot(angle: float, spd: float) -> void:
	var from := position + muzzle_off
	var b := game.bullets.fire(from + Vector2.from_angle(angle) * 22.0, Vector2.from_angle(angle), spd, 3.4, 1.0, b_style, 1)
	b.col = b_col
	game.sfx.play("bolt", -15.0, 1.3 + randf() * 0.2, 0.05, 0.07)
