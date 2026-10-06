class_name PerkEffects
extends RefCounted
## Comportamientos especiales de perks (hooks). Los numeros viven en PerkData.mods / RunState.mods.

static func on_enemy_killed(game: Game, e: Enemy) -> void:
	var run := game.run
	if run.has_hook("chain_kill"):
		var best: Enemy = null
		var bd := 200.0 * 200.0
		for o in game.enemies:
			if o == e or not o.targetable():
				continue
			var d := o.hit_center().distance_squared_to(e.hit_center())
			if d < bd:
				bd = d
				best = o
		if best != null:
			game.fx.bolt(e.hit_center(), best.hit_center(), Color("8fd8ff"), 0.18)
			game.hit_enemy_direct(best, 5.0, (best.position - e.position).normalized(), 60.0, e.hit_center(), "perk")
	if run.has_hook("detonator"):
		game.explode(e.hit_center(), 70.0, 6.0, 0, "perk", Color("ff9a3d"))
	if run.has_hook("bloodlust") and run.kills % 25 == 0 and run.kills > 0:
		game.player.heal(1)
	if run.has_hook("scavenger"):
		game.pickups.drop_coins(e.hit_center(), 1 + (1 if randf() < 0.5 else 0))
		if randf() < 0.3:
			game.pickups.drop_energy(e.hit_center(), 6)


static func on_damage_taken(game: Game) -> void:
	if game.run.has_hook("time_slip"):
		game.slow_enemies(0.55, 1.5)


static func on_shield_break(game: Game) -> void:
	if game.run.has_hook("reactive"):
		var p := game.player.hit_center()
		game.fx.ring(p, 10.0, 150.0, Color("8fe8ff"), 0.4, 5.0)
		game.fx.flash(p, 120.0, Color(0.5, 0.9, 1.0, 0.7), 0.25)
		game.bullets.clear_enemy_bullets(p, 190.0)
		for e in game.enemies:
			if e.hit_center().distance_to(p) < 170.0:
				var d: Vector2 = (e.position - game.player.position).normalized()
				game.hit_enemy_direct(e, 4.0, d, 340.0, e.hit_center(), "perk")
		game.shake(0.3)
		game.sfx.play("reflect", -2.0)


static func on_room_clear(game: Game) -> void:
	if game.run.has_hook("vital_pulse"):
		game.player.add_shield(1)
		game.player.add_energy(30.0)
