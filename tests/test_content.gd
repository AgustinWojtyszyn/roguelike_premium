extends RefCounted
## Integridad del contenido data-driven: referencias cruzadas, recursos faltantes y generacion de runs.

func run(t) -> void:
	var errs: Array[String] = Catalog.validate()
	for e in errs:
		print("   validate: ", e)
	t.eq(errs.size(), 0, "Catalog.validate() sin problemas de referencias")
	t.check(Catalog.characters.size() >= 8, "al menos 8 personajes (hay %d)" % Catalog.characters.size())
	t.check(Catalog.weapons.size() >= 12, "al menos 12 armas (hay %d)" % Catalog.weapons.size())
	t.check(Catalog.chapters.size() >= 4, "4 capitulos")
	t.check(Catalog.enemies.size() >= 12, "enemigos suficientes (hay %d)" % Catalog.enemies.size())
	# todos los scripts de enemigos / jefes existen y cargan
	for id in Catalog.enemies:
		var d: EnemyData = Catalog.enemies[id]
		t.check(ResourceLoader.exists(d.script_path), "script de enemigo %s existe" % id)
		var scr = load(d.script_path)
		t.check(scr != null and scr.can_instantiate(), "enemigo %s instanciable" % id)
	for id in Catalog.bosses:
		t.check(ResourceLoader.exists((Catalog.bosses[id] as BossData).script_path), "script de jefe %s existe" % id)
	# personajes: look completo y sin colisiones de estilo
	for id in Catalog.characters:
		var c: CharacterData = Catalog.characters[id]
		var lk := CharacterRig.resolve_look(c.look)
		for key in ["suit", "plate", "helmet", "glow", "head", "torso", "back"]:
			t.check(lk.has(key), "personaje %s tiene look.%s" % [id, key])
		t.check(c.hp >= 2 and c.hp <= 10, "personaje %s: vida en rango 2-10" % id)
		t.check(c.shield >= 0 and c.shield <= 10, "personaje %s: escudo 0-10" % id)
		t.check(c.energy >= 0 and c.energy <= 250, "personaje %s: energia 0-250" % id)
	# siluetas distintas: ningun par de personajes comparte la misma combinacion de estilos
	var combos: Dictionary = {}
	for id in Catalog.characters:
		var lk := CharacterRig.resolve_look((Catalog.characters[id] as CharacterData).look)
		var key := "%s|%s|%s" % [lk["head"], lk["torso"], lk["back"]]
		t.check(not combos.has(key), "silueta unica: %s vs %s (%s)" % [id, combos.get(key, ""), key])
		combos[key] = id
	# armas: mecanicas realmente distintas (no clones con +2 de dano)
	var sigs: Dictionary = {}
	for id in Catalog.weapons:
		var w: WeaponData = Catalog.weapons[id]
		var sig := "%s|%d|%s" % [w.category, w.bullet, ",".join(PackedStringArray(w.behavior.keys()))]
		sigs[sig] = sigs.get(sig, 0) + 1
	t.check(sigs.size() >= 12, "firmas de mecanica distintas entre armas (hay %d)" % sigs.size())
	# generacion de dungeons: determinista y completa para cada capitulo y varias semillas
	for chid in Catalog.chapters:
		var ch: ChapterData = Catalog.chapters[chid]
		for sd in [1, 2, 3, 77, 12345]:
			var a := DungeonGenerator.generate(ch, sd, Catalog.rooms, Catalog.encounters)
			var b := DungeonGenerator.generate(ch, sd, Catalog.rooms, Catalog.encounters)
			t.eq(a, b, "%s seed %d: generacion determinista" % [chid, sd])
			t.eq(a.size(), ch.stage_plan.size(), "%s seed %d: una etapa por plan" % [chid, sd])
			var prev_exit := ""
			for i in a.size():
				var st: Dictionary = a[i]
				var def: RoomDef = Catalog.rooms[st["room"]]
				if st["kind"] != "cache":
					t.check(st["encounter"] != "", "%s #%d etapa %d con encuentro" % [chid, sd, i])
				if i > 0 and prev_exit != "":
					t.eq(st["entry"], DungeonGenerator.OPP[prev_exit], "%s #%d etapa %d: entrada opuesta a la salida previa" % [chid, sd, i])
				prev_exit = st["exit"]
				t.check(def.theme == ch.theme, "%s: sala %s del tema correcto" % [chid, st["room"]])
			t.eq(a[a.size() - 1]["exit"], "", "%s: ultima etapa sin salida" % chid)
