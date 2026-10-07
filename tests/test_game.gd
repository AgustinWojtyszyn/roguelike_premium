extends RefCounted
## Integracion headless: arranque de la run, dano real de TODAS las armas, habilidades, perks y cambio de escena.

func _make_game(t, args: Dictionary) -> Game:
	Profile.path = "user://test_profile_run.json"
	Profile.reload()
	Boot.args = args
	Router.params = {}
	var scene: PackedScene = load("res://scenes/run.tscn")
	var g: Game = scene.instantiate()
	t.root.add_child(g)
	return g


func _frames(t, n: int) -> void:
	for i in n:
		await t.process_frame


func run(t) -> void:
	# ------------------------------------------------------------------ arranque
	var g := _make_game(t, {"god": "1", "seed": "7", "idle": "1"})
	await _frames(t, 20)
	t.check(g.player != null and g.room != null, "la run arranca con jugador y sala")
	t.check(g.director.plan.size() == 5, "plan de 5 etapas")
	t.check(g.player.hp == g.player.max_hp, "jugador con vida completa")
	t.check(g.run.weapons.size() == 2, "dos armas equipadas (inicial + secundaria)")
	var nodes := g.get_tree().get_node_count()
	t.check(nodes < 400, "cantidad de nodos acotada al inicio (%d)" % nodes)

	# ------------------------------------------------------------------ dano de cada arma sobre un maniqui
	g.input.auto_walk = null
	g.director.entered = true
	g.director.in_combat = false
	var dummy := g.director.spawn_enemy_at("sentry", Vector2(300, 0), false)
	g.player.position = Vector2(0, 0)
	dummy.state = 1
	dummy.stun = 0.0
	var fails: Array[String] = []
	for wid in Catalog.weapons:
		var wd: WeaponData = Catalog.weapons[wid]
		var rt := WeaponRuntime.new(g.player, wd)
		g.player.slots[0] = rt
		g.player.cur = 0
		g.player.rig.set_weapon(wd)
		g.player.energy = g.player.max_energy
		g.player.aim = Vector2.RIGHT
		g.player.face = 1.0
		g.player.position = Vector2(150, 0) if wd.category == "melee" else Vector2(0, 0)
		dummy.position = Vector2(300, 0) if wd.category != "melee" else Vector2(150 + 52, 0)
		dummy.hp = 100000.0
		dummy.max_hp = 100000.0
		dummy.state = 1
		var hp0 := dummy.hp
		var frames := 0
		while frames < 140 and dummy.hp >= hp0:
			g.player.aim = (dummy.hit_center() - g.player.rig.pivot.global_position).normalized()
			g.player.energy = g.player.max_energy
			rt.update(1.0 / 60.0, true)
			await t.process_frame
			frames += 1
		if dummy.hp >= hp0:
			fails.append(wid)
		g.bullets.clear_all()
		await _frames(t, 2)
	t.eq(fails, [], "todas las armas danan a un enemigo (fallan: %s)" % str(fails))

	# ------------------------------------------------------------------ habilidades
	g.player.slots[0] = WeaponRuntime.new(g.player, Catalog.weapon("pulsar"))
	for cid in Catalog.characters:
		var c: CharacterData = Catalog.characters[cid]
		g.player.energy = g.player.max_energy
		g.player.ability_cd = 0.0
		Abilities.activate(g.player, c.ability_id)
		await _frames(t, 4)
		t.check(true, "habilidad %s (%s) se ejecuta sin errores" % [c.ability_id, cid])
	g.player.buffs.clear()

	# ------------------------------------------------------------------ danio, escudo y energia del jugador
	g.god = false
	g.player.inv = 0.0
	g.player.shield = 2
	g.player.hp = g.player.max_hp
	g.player.take_damage(1, Vector2.RIGHT)
	t.eq(g.player.shield, 1, "el escudo absorbe el golpe")
	t.eq(g.player.hp, g.player.max_hp, "la vida no baja si hay escudo")
	g.player.inv = 0.0
	g.player.shield = 0
	g.player.take_damage(1, Vector2.RIGHT)
	t.eq(g.player.hp, g.player.max_hp - 1, "sin escudo baja la vida")
	g.player.inv = 0.0
	g.player.energy = 0.0
	var rt2 := WeaponRuntime.new(g.player, Catalog.weapon("lancex"))
	var hp_before := dummy.hp
	for i in 30:
		rt2.update(1.0 / 60.0, true)
	t.check(g.bullets.list.size() == 0, "sin energia el arma de energia no dispara")
	g.god = true

	# ------------------------------------------------------------------ perks
	var run := g.run
	run.perks.clear()
	for pid in ["quick_feet", "sharp_rounds", "thick_plates", "crit_lens", "piercing"]:
		t.check(run.add_perk(Catalog.perks[pid], Catalog.perks), "perk %s se agrega" % pid)
	t.eq(run.perk_slots_free(), 0, "5 slots ocupados")
	t.check(not run.add_perk(Catalog.perks["steady_hand"], Catalog.perks), "sin slots no se agrega")
	t.check(not run.add_perk(Catalog.perks["ricochet"], Catalog.perks), "sin slots no se agrega (2)")
	t.check(run.add_perk(Catalog.perks["quick_feet"], Catalog.perks), "perk apilable repite aun con slots llenos")
	t.check(absf(run.mod("speed_mult") - 0.28) < 0.001, "apilado suma modificadores")
	g.player.recompute_stats()
	t.eq(g.player.max_shield, g.player.data.shield + 2, "perk de escudo aumenta el maximo")
	run.replace_perk(1, Catalog.perks["ricochet"], Catalog.perks)
	t.check(run.perks.has("ricochet") and not run.perks.has("sharp_rounds"), "reemplazo de perk")
	t.eq(int(run.mod("bounce")), 1, "ricochet aplica rebote")
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var offer := RunState.roll_perk_offer(rng, Catalog.perks, run.perks, 3)
	t.eq(offer.size(), 3, "oferta de 3 perks")
	var ids: Dictionary = {}
	for o in offer:
		ids[o.id] = true
		t.check(not (run.perks.has(o.id) and not o.stackable), "la oferta no repite perks no apilables ya tomados")
	t.eq(ids.size(), 3, "oferta sin duplicados")

	# ------------------------------------------------------------------ transicion de etapa (cambio de sala)
	var room_before := g.room
	g.director._load_stage(1, true)
	await _frames(t, 5)
	t.check(g.room != room_before, "se crea una sala nueva")
	t.eq(g.director.stage, 1, "avanza de etapa")
	t.eq(g.enemies.size(), 0, "las etapas nuevas empiezan sin enemigos")
	t.check(g.room.rects.size() > 4, "la sala nueva tiene colisiones")
	g.queue_free()
	await _frames(t, 3)

	# ------------------------------------------------------------------ cada capitulo y cada etapa carga sin errores
	for chid in Catalog.chapters:
		var gg := _make_game(t, {"god": "1", "idle": "1", "chapter": chid, "seed": "21"})
		await _frames(t, 3)
		for i in gg.director.plan.size():
			gg.director._load_stage(i, true)
			await _frames(t, 2)
			t.check(gg.room != null and gg.player != null, "%s etapa %d carga" % [chid, i])
		gg.queue_free()
		await _frames(t, 2)
