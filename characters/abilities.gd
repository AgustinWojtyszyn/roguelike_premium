class_name Abilities
extends RefCounted
## Habilidades activas de personaje (identificadas por `ability_id`). Ninguna es un dash ofensivo ni un salto:
## todas son buffs, areas, aliados o ventanas de defensa.

static func activate(p: Player, id: String) -> void:
	var g := p.game
	var c := p.hit_center()
	match id:
		"overclock":
			p.add_buff("overclock", 4.0)
			g.fx.ring(c, 10.0, 90.0, Color("ffb23d"), 0.4, 4.0)
			g.fx.burst(c, 16, 240.0, Color("ffd27a"), 0.4)
		"mirror":
			p.add_buff("mirror", 3.0)
			g.bullets.reflect_in_radius(c, 90.0)
			g.fx.ring(c, 14.0, 80.0, Color("9fe9ff"), 0.4, 4.0)
		"nanocloud":
			p.heal(2)
			p.add_shield(2)
			p.add_buff("regen", 5.0)
			g.fx.ring(c, 10.0, 110.0, Color("5fffc8"), 0.5, 4.0)
			g.fx.burst(c, 22, 200.0, Color("5fffc8"), 0.7)
		"turret":
			g.spawn_ally_turret(p.position + p.aim * 46.0)
			g.fx.ring(p.position + p.aim * 46.0, 8.0, 60.0, Color("36e0d0"), 0.4, 3.0)
		"mark":
			p.add_buff("mark", 10.0)
			p.mark_shots = 3
			g.fx.ring(c, 10.0, 70.0, Color("ff5a4a"), 0.4, 3.0)
		"whirl":
			p.whirl_t = 0.54
			p.whirl_ticks = 3
			p.whirl_next = 0.0
			g.fx.ring(c, 6.0, 100.0, Color("ff6a8a"), 0.3, 4.0)
		"phase":
			p.add_buff("phase", 1.6)
			g.fx.ring(c, 10.0, 70.0, Color("ff4fd8"), 0.4, 3.0)
			g.fx.burst(c, 14, 180.0, Color("d9a8ff"), 0.5)
		"roar":
			g.fx.ring(c, 10.0, 170.0, Color("ffb23d"), 0.45, 6.0)
			g.fx.ring(c, 6.0, 110.0, Color("ffe0a0"), 0.35, 4.0)
			g.fx.flash(c, 150.0, Color(1.0, 0.7, 0.3, 0.6), 0.25)
			g.bullets.clear_enemy_bullets(c, 180.0)
			for e in g.enemies.duplicate():
				var to: Vector2 = e.hit_center() - c
				if to.length() < 160.0 + e.hit_r:
					g.hit_enemy_direct(e, 6.0 * p.dmg_mult(), to.normalized(), 320.0, e.hit_center(), "ability")
					e.stun = maxf(e.stun, 1.1)
			g.shake(0.5)
			g.hitstop(0.05)
			g.sfx.play("roar", -1.0)
		"bulwark":
			p.add_buff("bulwark", 4.0)
			g.fx.ring(c, 10.0, 60.0, Color("ffb070"), 0.35, 5.0)
		"storm":
			var targets: Array = g.enemies.duplicate()
			targets.sort_custom(func(a, b): return a.position.distance_squared_to(p.position) < b.position.distance_squared_to(p.position))
			var from := p.muzzle_world()
			var n := 0
			for e in targets:
				if not e.targetable():
					continue
				g.fx.bolt(from, e.hit_center(), Color("6fe8ff"), 0.3)
				g.hit_enemy_direct(e, 7.0 * p.dmg_mult(), (e.hit_center() - from).normalized(), 90.0, e.hit_center(), "ability")
				from = e.hit_center()
				n += 1
				if n >= 5:
					break
			if n == 0:
				g.fx.bolt(from, from + p.aim * 160.0, Color("6fe8ff"), 0.2)
			g.shake(0.25)
			g.sfx.play("zap", -2.0)
		"echo":
			g.slow_enemies(0.5, 3.5)
			g.fx.ring(c, 10.0, 220.0, Color("4fffe8"), 0.6, 4.0)
			g.fx.flash(c, 200.0, Color(0.3, 1.0, 0.9, 0.35), 0.4)
	g.sfx.play("ability", -3.0)
