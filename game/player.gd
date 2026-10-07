class_name Player
extends Node2D
## Jugador: logica (vida, escudo, energia, armas, habilidad). El aspecto lo da CharacterRig.

const RADIUS := 11.0
const HIT_R := 12.0
const BASE_SPEED := 262.0
const ACCEL := 3400.0
const DECEL := 4600.0

var game: Game
var run: RunState
var data: CharacterData
var rig: CharacterRig
var vel := Vector2.ZERO
var aim := Vector2.RIGHT
var face: float = 1.0
var kick: float = 0.0
var inv: float = 0.0
var dead := false
var t: float = 0.0

var hp: int = 6
var max_hp: int = 6
var shield: int = 0
var max_shield: int = 0
var shield_delay: float = 0.0
var shield_tick: float = 0.0
var energy: float = 100.0
var max_energy: float = 100.0
var energy_idle: float = 0.0
var frac_dmg: float = 0.0

var slots: Array[WeaponRuntime] = []
var cur: int = 0
var buffs: Dictionary = {}
var ability_cd: float = 0.0
var mark_shots: int = 0
var whirl_t: float = 0.0
var whirl_ticks: int = 0
var whirl_next: float = 0.0
var room_buff := ""
var regen_t: float = 0.0
var skin_bullet := Color(0, 0, 0, 0)
var trail_col := Color(0, 0, 0, 0)
var aura: Part


func build(g: Game, r: RunState, look: Dictionary) -> void:
	game = g
	run = r
	data = r.character
	rig = CharacterRig.new()
	add_child(rig)
	rig.build(look, Catalog.weapon(r.weapons[0]))
	rig.stepped.connect(_on_step)
	aura = Part.make(self, _paint_aura, Vector2.ZERO, true)
	aura.z_index = 2
	for wid in r.weapons:
		slots.append(WeaponRuntime.new(self, Catalog.weapon(wid)))
	max_hp = data.hp
	hp = max_hp
	recompute_stats()
	shield = max_shield
	energy = max_energy
	_equip_visual()


func recompute_stats() -> void:
	max_hp = data.hp
	max_shield = maxi(0, data.shield + int(run.mod("shield_max")))
	max_energy = float(data.energy) + run.mod("energy_max")
	shield = mini(shield, max_shield)
	energy = minf(energy, max_energy)
	hp = mini(hp, max_hp)


# ------------------------------------------------------------------ modificadores
func weapon() -> WeaponData:
	return slots[cur].data


func dmg_mult() -> float:
	var m := 1.0 + run.mod("dmg_mult")
	if has_buff("overclock"):
		m += 0.25
	if run.has_hook("overcharge") and energy >= max_energy - 0.5:
		m += 0.3
	if room_buff == "dmg":
		m += 0.3
	return m


func rate_mult() -> float:
	var m := 1.0 + run.mod("rate_mult")
	if has_buff("overclock"):
		m += 0.55
	if room_buff == "rate":
		m += 0.3
	return m


func crit_chance() -> float:
	var c := 0.05 + run.mod("crit")
	if data.passive_id == "eagle_eye":
		c += 0.18
	return c


func energy_cost_mult() -> float:
	return 0.7 if data.passive_id == "arcane_flow" else 1.0


func move_speed() -> float:
	var m := data.speed_mult * (1.0 + run.mod("speed_mult"))
	if room_buff == "speed":
		m += 0.2
	var w := weapon()
	if firing_now and w.behavior.has("move_mult"):
		m *= float(w.behavior["move_mult"])
	if w.behavior.has("spool") and slots[cur].spool > 0.3:
		m *= float(w.behavior.get("move_mult", 1.0))
	return BASE_SPEED * m


func bullet_color(default: Color) -> Color:
	return skin_bullet if skin_bullet.a > 0.0 else default


func passive_is(id: String) -> bool:
	return data.passive_id == id


# ------------------------------------------------------------------ buffs
func add_buff(name: String, dur: float) -> void:
	buffs[name] = dur


func has_buff(name: String) -> bool:
	return buffs.get(name, 0.0) > 0.0


func use_mark() -> void:
	mark_shots -= 1
	if mark_shots <= 0:
		buffs.erase("mark")


# ------------------------------------------------------------------ armas
var firing_now := false


func swap_weapon(quiet: bool = false) -> void:
	if slots.size() < 2:
		return
	cur = (cur + 1) % slots.size()
	_equip_visual()
	if not quiet:
		game.sfx.play("swap", -4.0)


func select_weapon(i: int) -> void:
	if i >= 0 and i < slots.size() and i != cur:
		cur = i
		_equip_visual()
		game.sfx.play("swap", -4.0)


func _equip_visual() -> void:
	rig.set_weapon(slots[cur].data)
	rig.heat = 0.0


## Equipa un arma nueva en el slot activo (o en el segundo si hay hueco). Devuelve el arma reemplazada ("" si no).
func equip_weapon(id: String) -> String:
	var wd := Catalog.weapon(id)
	run.note_weapon(id)
	var replaced := ""
	if slots.size() < RunState.WEAPON_SLOTS:
		slots.append(WeaponRuntime.new(self, wd))
		run.weapons.append(id)
		cur = slots.size() - 1
	else:
		replaced = slots[cur].data.id
		slots[cur] = WeaponRuntime.new(self, wd)
		run.weapons[cur] = id
	_equip_visual()
	game.sfx.play("swap", -2.0)
	return replaced


func muzzle_world() -> Vector2:
	return rig.muzzle_world()


func hit_center() -> Vector2:
	return position + Vector2(0, -26)


func can_be_hit() -> bool:
	return not dead and inv <= 0.0 and not has_buff("phase")


func try_reflect(b: Bullets.B) -> bool:
	if has_buff("mirror"):
		game.bullets.reflect_in_radius(b.pos, 4.0, Vector2.ZERO)
		game.sfx.play("reflect", -8.0, 1.0, 0.1, 0.05)
		return true
	return false


# ------------------------------------------------------------------ bucle
func _process(delta: float) -> void:
	Prof.begin("player_proc")
	__process_impl(delta)
	Prof.end("player_proc")


func __process_impl(delta: float) -> void:
	var dt := minf(delta, 1.0 / 30.0) * Game.tscale
	t += dt
	if dead:
		rig.update_dead(dt)
		return
	_update_buffs(dt)
	_move(dt)
	_aim(dt)
	_fire(dt)
	_update_resources(dt)
	_animate(dt)


func _update_buffs(dt: float) -> void:
	for k in buffs.keys():
		buffs[k] -= dt
		if buffs[k] <= 0.0:
			buffs.erase(k)
	ability_cd = maxf(0.0, ability_cd - dt)
	if has_buff("regen"):
		regen_t -= dt
		if regen_t <= 0.0:
			regen_t = 0.8
			add_shield(1)
			game.fx.puff(position + Vector2(randf_range(-8, 8), -26), Vector2(0, -30), 6.0, Color(0.4, 1.0, 0.8, 0.5), 0.5, 1.6)
	if whirl_t > 0.0:
		whirl_t -= dt
		whirl_next -= dt
		if whirl_next <= 0.0 and whirl_ticks > 0:
			whirl_ticks -= 1
			whirl_next = 0.18
			_whirl_hit()
		rig.pivot.rotation += dt * TAU / 0.18 * 0.0   # el giro visual lo aplica _animate


func _whirl_hit() -> void:
	var c := hit_center()
	var wd := weapon()
	for e in game.enemies.duplicate():
		var to: Vector2 = e.hit_center() - c
		if to.length() < 92.0 + e.hit_r:
			game.hit_enemy_direct(e, wd.damage * 1.2 * dmg_mult(), to.normalized(), 200.0, e.hit_center(), wd.category)
	game.bullets.reflect_in_radius(c, 100.0)
	game.fx.slash_arc(c, randf() * TAU, 92.0, TAU * 0.8, Color("ff6a8a"))
	game.sfx.play("slash", -3.0, 1.0 + randf() * 0.2, 0.05)
	game.shake(0.12)


func _move(dt: float) -> void:
	var dir := game.move_input()
	var tgt := dir * move_speed() * (0.0 if whirl_t > 0.0 else 1.0)
	var a := ACCEL if dir != Vector2.ZERO else DECEL
	vel = vel.move_toward(tgt, a * dt)
	var old := position
	var np := Gfx.push_out(position + vel * dt, RADIUS, game.room.rects)
	if dt > 0.0:
		var actual := (np - old) / dt
		if actual.length() < vel.length() - 1.0:
			vel = vel.lerp(actual, 0.6)
	position = np


func _aim(_dt: float) -> void:
	var o := rig.pivot.global_position
	var a := game.aim_input(o)
	if a != Vector2.ZERO:
		aim = a.normalized()
	if absf(aim.x) > 0.12:
		face = 1.0 if aim.x > 0.0 else -1.0


func _fire(dt: float) -> void:
	firing_now = game.fire_input() and not game.over and whirl_t <= 0.0 and not game.input_locked
	for i in slots.size():
		slots[i].update(dt if i == cur else dt, firing_now and i == cur)
	kick = maxf(0.0, kick - dt * (7.0 if weapon().rate < 0.6 else 4.5))
	if game.ability_input():
		try_ability()


func try_ability() -> bool:
	if dead or ability_cd > 0.0 or game.over:
		return false
	if energy < float(data.ability_cost):
		game.hud.flash_energy()
		game.sfx.play("ui_error", -6.0)
		return false
	energy -= float(data.ability_cost)
	ability_cd = data.ability_cd * maxf(0.3, 1.0 + run.mod("cd_mult"))
	Abilities.activate(self, data.ability_id)
	return true


func ability_ready() -> bool:
	return ability_cd <= 0.0 and energy >= float(data.ability_cost)


func _update_resources(dt: float) -> void:
	# energia
	energy_idle += dt
	var regen := 4.0 + run.mod("energy_regen")
	energy = minf(max_energy, energy + regen * dt)
	# escudo
	if shield < max_shield:
		shield_delay -= dt
		if shield_delay <= 0.0:
			shield_tick -= dt
			if shield_tick <= 0.0:
				shield += 1
				shield_tick = 0.5 if data.passive_id == "self_repair" else 1.1
				game.fx.ring(position + Vector2(0, -24), 6.0, 30.0, Color("8fe8ff"), 0.3, 2.5)
				game.sfx.play("pickup", -16.0, 1.4)


func _animate(dt: float) -> void:
	rig.vel = vel
	rig.aim = aim
	rig.face = face
	rig.kick = kick
	inv = maxf(0.0, inv - dt)
	var a := 1.0
	if inv > 0.0:
		a = 0.45 if int(t * 22.0) % 2 == 0 else 1.0
	if has_buff("phase"):
		a = 0.35
	rig.alpha = a
	rig.animate(dt)
	if whirl_t > 0.0:
		rig.pivot.rotation = (0.54 - whirl_t) / 0.54 * TAU * 3.0 + aim.angle()
		rig.wnode.queue_redraw()
	if has_buff("overclock") or has_buff("bulwark") or has_buff("mirror") or has_buff("phase") or has_buff("mark") or has_buff("regen"):
		aura.queue_redraw()
	elif aura.get_meta("on", false):
		aura.queue_redraw()
	aura.set_meta("on", has_buff("overclock") or has_buff("bulwark") or has_buff("mirror") or has_buff("phase") or has_buff("mark") or has_buff("regen"))


func _on_step(strength: float) -> void:
	if trail_col.a > 0.0:
		game.fx.spark(position + Vector2(-vel.x * 0.03, -2), Vector2(-vel.x, -30).normalized(), 4, 140.0, trail_col, 0.35, 0.9)
	game.fx.puff(position + Vector2(randf_range(-4, 4), -1), Vector2(-vel.x * 0.1, -8), 6.0, Color(0.6, 0.66, 0.8, 0.28), 0.4, 2.2)
	game.sfx.play("step", -16.0, 1.0, 0.15, 0.06)


func _paint_aura(c: Part) -> void:
	var cc := Vector2(0, -26)
	if has_buff("bulwark"):
		var p := 0.6 + 0.4 * sin(t * 12.0)
		c.draw_arc(cc, 34.0, 0, TAU, 28, Color(1.0, 0.7, 0.35, 0.8 * p), 4.0, true)
		Gfx.draw_glow(c, cc, 46.0, Color(1.0, 0.6, 0.25, 0.28))
	if has_buff("mirror"):
		c.draw_arc(cc, 40.0, t * 3.0, t * 3.0 + TAU * 0.8, 24, Color(0.6, 0.95, 1.0, 0.9), 3.0, true)
		Gfx.draw_glow(c, cc, 54.0, Color(0.5, 0.9, 1.0, 0.22))
	if has_buff("phase"):
		Gfx.draw_glow(c, cc, 44.0, Color(1.0, 0.3, 0.85, 0.3))
	if has_buff("overclock"):
		Gfx.draw_glow(c, cc, 40.0, Color(1.0, 0.7, 0.2, 0.22 + 0.1 * sin(t * 20.0)))
	if has_buff("mark"):
		c.draw_arc(cc, 24.0, 0, TAU, 20, Color(1.0, 0.3, 0.25, 0.8), 2.0, true)
	if has_buff("regen"):
		Gfx.draw_glow(c, cc, 38.0, Color(0.3, 1.0, 0.7, 0.2))


# ------------------------------------------------------------------ dano / curas
func take_damage(n: int, dir: Vector2, knock: float = 120.0) -> void:
	if dead or inv > 0.0 or game.god or has_buff("phase"):
		return
	if data.passive_id == "ether_step" and randf() < 0.12:
		inv = 0.4
		game.fx.ring(hit_center(), 6.0, 40.0, Color("ff4fd8"), 0.3, 3.0)
		game.sfx.play("reflect", -6.0)
		return
	var amount := float(n)
	if has_buff("bulwark"):
		amount *= 0.3
	frac_dmg += amount
	var whole := int(frac_dmg)
	if whole <= 0:
		game.fx.ring(hit_center(), 6.0, 36.0, Color("ffb070"), 0.2, 3.0)
		game.sfx.play("shield_hit", -6.0)
		inv = 0.25
		return
	frac_dmg -= float(whole)
	run.damaged_in_room = true
	shield_delay = 1.6 if data.passive_id == "immovable" else 2.8
	shield_tick = 0.0
	game.run.damage_taken += whole
	var absorbed := mini(shield, whole)
	var rest := whole - absorbed
	if absorbed > 0:
		var had := shield
		shield -= absorbed
		game.sfx.play("shield_hit", -2.0)
		game.fx.ring(hit_center(), 8.0, 38.0, Color("8fe8ff"), 0.25, 3.0)
		game.fx.sprite("combat/shield_hit", hit_center(), 30.0, 52.0, 0.22, Color(1, 1, 1, 0.9), 0.0, true)
		if had > 0 and shield == 0:
			game.sfx.play("shield_break", -2.0)
			game.fx.burst(hit_center(), 14, 260.0, Color("8fe8ff"), 0.4)
			PerkEffects.on_shield_break(game)
	if rest > 0:
		hp -= rest
		game.sfx.play("hurt", -2.0)
		game.fx.burst(hit_center(), 10, 260.0, Color("9fe9ff"), 0.35)
		game.fx.ring(hit_center(), 6.0, 34.0, Color("bff3ff"), 0.22, 3.0)
		game.fx.sprite("combat/blood_hit", hit_center() + Vector2(0, 8), 26.0, 40.0, 0.3, Color(1, 1, 1, 0.9))
	inv = 1.0 if rest > 0 else 0.7
	rig.flash = 1.0
	if OS.has_feature("mobile") and bool(Profile.p.setting("vibration")):
		Input.vibrate_handheld(45 if rest > 0 else 20)
	if data.passive_id != "immovable" and not has_buff("bulwark"):
		vel += dir * knock
	game.shake(0.45 if rest > 0 else 0.25)
	game.hitstop(0.07 if rest > 0 else 0.04)
	game.hud_flash()
	PerkEffects.on_damage_taken(game)
	if hp <= 0:
		hp = 0
		die(dir)


func heal(n: int) -> void:
	var before := hp
	hp = mini(max_hp, hp + n)
	if hp > before:
		game.fx.ring(position + Vector2(0, -20), 8.0, 40.0, Color("5fffc8"), 0.45, 3.0)
		game.fx.burst(position + Vector2(0, -22), 12, 160.0, Color("5fffc8"), 0.6)
		game.sfx.play("heal", -6.0)


func add_shield(n: int) -> void:
	shield = mini(max_shield, shield + n)


func add_energy(n: float) -> void:
	energy = minf(max_energy, energy + n)


func die(dir: Vector2) -> void:
	dead = true
	rig.start_death(dir)
	game.sfx.play("player_die", 0.0)
	var c := hit_center()
	game.fx.burst(c, 30, 380.0, Color("9fe9ff"), 0.7)
	game.fx.ring(c, 10.0, 90.0, Color("bff3ff"), 0.4, 4.0)
	game.fx.flash(c, 120.0, Color(0.6, 0.95, 1.0, 0.9), 0.25)
	for i in 8:
		game.fx.shard(c, Vector2.from_angle(randf() * TAU) * randf_range(60, 200), randf_range(80, 200), Color("46547d"), randf_range(3, 5.5), Color(0.15, 0.9, 0.8, 0.8))
	game.fx.add_decal(position, 0, 38.0, Color.BLACK)
	aura.visible = false
	game.on_player_died()
