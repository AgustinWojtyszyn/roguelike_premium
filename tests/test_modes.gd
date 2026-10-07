extends RefCounted
## Modos de juego: supervivencia (oleadas por familia), boss rush, desafios y records. La campana no cambia.

func _frames(t, n: int) -> void:
	for i in n:
		await t.process_frame


func run(t) -> void:
	_waves(t)
	_records(t)
	_hazard_zones(t)
	await _integration(t)
	await _hazards(t)


func _waves(t) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var last_total := 0.0
	for n in range(1, 41):
		var ph := ModeRules.phase_of_wave(n)
		var ch: ChapterData = Catalog.chapter(ModeRules.chapter_of_phase(ph))
		var units := ModeRules.survival_wave(n, rng)
		t.check(units.size() >= 1 and units.size() <= 17, "oleada %d: tamano razonable (%d)" % [n, units.size()])
		var fam := {}
		for u in units:
			var d: EnemyData = Catalog.enemies[u["id"]]
			fam[d.family] = true
			t.eq(d.family, ch.theme, "oleada %d: %s es de la familia de la fase (%s)" % [n, u["id"], ch.theme])
		t.eq(fam.size(), 1, "oleada %d: una sola familia por oleada" % n)
	t.eq(ModeRules.chapter_of_phase(0), "ch1", "fase 1 = tecnologica")
	t.eq(ModeRules.chapter_of_phase(1), "ch2", "fase 2 = azteca")
	t.eq(ModeRules.chapter_of_phase(2), "ch3", "fase 3 = medieval")
	t.eq(ModeRules.chapter_of_phase(3), "ch4", "fase 4 = interdimensional")
	t.check(ModeRules.difficulty_scale(20, 3) > ModeRules.difficulty_scale(2, 0), "la dificultad crece con las oleadas")
	t.check(ModeRules.difficulty_scale(21, 4) > ModeRules.difficulty_scale(20, 3), "tras la vuelta completa sube un escalon extra")
	for i in 4:
		var st := ModeRules.survival_stage(i)
		t.check(Catalog.rooms.has(st["room"]) and (Catalog.rooms[st["room"]] as RoomDef).kind == "survival", "arena %d existe y es de supervivencia" % i)
		t.eq((Catalog.rooms[st["room"]] as RoomDef).theme, Catalog.chapter(st["chapter"]).theme, "arena %d con el tema de su fase" % i)
	var rush := ModeRules.boss_rush_plan(Catalog.rooms)
	t.eq(rush.size(), 4, "boss rush: 4 jefes")
	for i in 4:
		t.eq(rush[i]["kind"], "boss", "boss rush: etapa %d es un jefe" % i)
	t.eq(Catalog.chapter(rush[0]["chapter"]).boss, "custodio", "boss rush empieza por el Custodio")
	t.eq(Catalog.chapter(rush[3]["chapter"]).boss, "vigia", "boss rush termina con el Vigia")
	for cid in ModeRules.CHALLENGE_ORDER:
		t.check(ModeRules.CHALLENGES.has(cid) and not (ModeRules.CHALLENGES[cid]["mods"] as Dictionary).is_empty(), "desafio %s con reglas" % cid)


func _records(t) -> void:
	var p := PlayerProfile.new()
	t.check(p.data.has("records") and p.data["records"].has("survival"), "perfil nuevo con records")
	var base := {"character": "vesper", "chapter": "ch1", "won": false, "stages": 1, "rooms": 3, "kills": 40, "chests": 0, "perks": 1, "bosses": 0, "coins": 20, "time": 200.0, "mode": "survival", "wave": 9}
	var coins0 := p.coins()
	RunRewards.apply(p, base, null, Catalog.missions, "")
	t.eq(int(p.data["records"]["survival"]["best_wave"]), 9, "record de oleada guardado")
	t.check(p.coins() > coins0 + 20, "supervivencia da bono por oleada")
	t.eq(int(p.chapter_state("ch1").get("best_stage", 0)), 0, "supervivencia no altera el progreso de campana")
	var worse := base.duplicate()
	worse["wave"] = 4
	RunRewards.apply(p, worse, null, Catalog.missions, "")
	t.eq(int(p.data["records"]["survival"]["best_wave"]), 9, "el record no baja")
	var br := {"character": "vesper", "chapter": "ch4", "won": true, "stages": 4, "rooms": 4, "kills": 20, "chests": 0, "perks": 3, "bosses": 4, "coins": 100, "time": 600.0, "mode": "bossrush", "damage_taken": 5}
	RunRewards.apply(p, br, null, Catalog.missions, "")
	t.eq(int(p.data["records"]["bossrush"]["clears"]), 1, "boss rush: cuenta la victoria")
	t.eq(int(p.data["records"]["bossrush"]["least_damage"]), 5, "boss rush: menor dano registrado")
	var br2 := br.duplicate()
	br2["time"] = 500.0
	br2["damage_taken"] = 9
	RunRewards.apply(p, br2, null, Catalog.missions, "")
	t.eq(int(p.data["records"]["bossrush"]["best_time"]), 500, "boss rush: mejor tiempo")
	t.eq(int(p.data["records"]["bossrush"]["least_damage"]), 5, "boss rush: el menor dano no empeora")
	var ch := {"character": "vesper", "chapter": "ch1", "won": true, "stages": 5, "rooms": 5, "kills": 30, "chests": 1, "perks": 2, "bosses": 1, "coins": 60, "time": 400.0, "mode": "challenge", "challenge": "glass"}
	RunRewards.apply(p, ch, null, Catalog.missions, "")
	t.eq(int(p.data["records"]["challenges"]["glass"]["cleared"]), 1, "desafio superado registrado")


func _make(t, args: Dictionary) -> Game:
	Profile.path = "user://test_profile_modes.json"
	Profile.reload()
	Boot.args = args
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	return g


func _integration(t) -> void:
	# supervivencia: arena propia, sin salida, la oleada 1 arranca con enemigos de la familia tecnologica
	var g := _make(t, {"god": "1", "seed": "3", "mode": "survival", "idle": "1"})
	await _frames(t, 20)
	t.eq(g.mode_id, "survival", "modo supervivencia activo")
	t.eq(g.room.def.kind, "survival", "se carga una arena de supervivencia")
	t.check(not g.room.has_exit, "la arena no tiene salida")
	g.director.entered = true
	g.director._begin_encounter()
	await _frames(t, 10)
	t.eq(g.director.surv_wave, 1, "oleada 1 lanzada")
	t.check(g.director.pending.size() >= 1, "hay enemigos en cola")
	for e in g.director.pending:
		t.eq((Catalog.enemies[e[0]] as EnemyData).family, "tech", "oleada 1: enemigo %s tecnologico" % e[0])
	g.queue_free()
	await _frames(t, 2)
	# boss rush: jefes en orden con su capitulo
	var g2 := _make(t, {"god": "1", "seed": "3", "mode": "bossrush", "idle": "1"})
	await _frames(t, 20)
	t.eq(g2.director.plan.size(), 4, "boss rush: plan de 4 jefes")
	t.eq(g2.chapter.id, "ch1", "boss rush: empieza en el capitulo 1")
	g2.director.entered = true
	g2.director._begin_encounter()
	await _frames(t, 10)
	t.check(g2.director.boss_alive(), "boss rush: el primer jefe aparece")
	g2.queue_free()
	await _frames(t, 2)
	# desafios
	var g3 := _make(t, {"god": "1", "seed": "3", "mode": "challenge", "challenge": "glass", "chapter": "ch1", "idle": "1"})
	await _frames(t, 20)
	t.check(g3.player.max_hp <= 3 and g3.player.max_shield == 0, "desafio Cristal: 3 de vida y sin escudo")
	g3.queue_free()
	await _frames(t, 2)
	var g4 := _make(t, {"god": "1", "seed": "3", "mode": "challenge", "challenge": "one_weapon", "chapter": "ch1", "idle": "1"})
	await _frames(t, 20)
	t.eq(g4.run.weapons.size(), 1, "desafio Una Arma: un solo arma")
	g4.pickups.drop_weapon(Vector2.ZERO, "pulsar")
	t.check(g4.pickups.weapon_near(Vector2.ZERO, 200.0) == null, "desafio Una Arma: no se sueltan armas (se cambian por monedas)")
	g4.queue_free()
	await _frames(t, 2)
	var g5 := _make(t, {"god": "1", "seed": "3", "mode": "challenge", "challenge": "fast_bullets", "chapter": "ch1", "idle": "1"})
	await _frames(t, 10)
	var b := g5.bullets.fire(Vector2.ZERO, Vector2.RIGHT, 100.0, 1.0, 1.0, Bullets.Style.PULSE, 1)
	t.check(b.vel.length() > 135.0, "desafio Balas Rapidas: proyectil enemigo mas veloz (%.0f)" % b.vel.length())
	g5.queue_free()
	await _frames(t, 2)


func _hazard_zones(t) -> void:
	for st_i in 4:
		var def: RoomDef = Catalog.rooms[ModeRules.survival_stage(st_i)["room"]]
		for z in ArenaHazard.ZONES:
			t.check(def.size.x * -0.5 + 60.0 < z.position.x and z.end.x < def.size.x * 0.5 - 60.0, "%s: zona de peligro dentro de la arena" % def.id)
			for p in def.props:
				var pr := Rect2(float(p[1]), float(p[2]), float(p[3]), float(p[4]))
				t.check(not pr.intersects(z), "%s: el prop %s no solapa una zona de peligro" % [def.id, p[0]])
			for sp in def.spawns:
				t.check(not z.grow(40.0).has_point(sp), "%s: ningun spawn dentro de una zona de peligro" % def.id)


func _hazards(t) -> void:
	var g := _make(t, {"seed": "3", "mode": "survival", "idle": "1"})
	await _frames(t, 20)
	var hz: Array = []
	for c in g.room.get_children():
		if c is ArenaHazard:
			hz.append(c)
	t.eq(hz.size(), 3, "la arena de supervivencia tiene 3 peligros")
	g.director.entered = true
	g.director.in_combat = true
	var h: ArenaHazard = hz[2]
	g.player.position = h.rect.get_center() + Vector2(0, 4)
	g.player.inv = 0.0
	var hp0 := g.player.hp + g.player.shield
	h.state = ArenaHazard.ACTIVE
	h.st = 0.0
	await _frames(t, 6)
	t.check(g.player.hp + g.player.shield < hp0, "el peligro activo dana al jugador que lo pisa")
	g.queue_free()
	await _frames(t, 2)
