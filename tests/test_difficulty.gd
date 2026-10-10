extends RefCounted
## Escalado de dano/vida centralizado (DamageScale): monotonia, topes, aplicacion UNICA en Player.take_damage y dificultades reales.


func _make_game(t, args: Dictionary) -> Game:
	Profile.path = "user://test_profile_run.json"
	Profile.reload()
	Boot.args = args
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	return g


func run(t) -> void:
	_pure(t)
	await _integration(t)


func _pure(t) -> void:
	var base := {"chapter_order": 0, "stage": 0, "mode": ModeRules.CAMPAIGN, "wave": 1, "difficulty": "normal", "mod_dmg": 1.0, "boss": false}
	t.eq(DamageScale.multiplier(base), 1.0, "capitulo 1 nivel 1 normal = x1.00")
	# monotonia por capitulo y por etapa
	var prev := 0.0
	for ch in 4:
		var c := base.duplicate()
		c["chapter_order"] = ch
		var m := DamageScale.multiplier(c)
		t.check(m > prev, "el dano sube con el capitulo (ch%d = %.2f)" % [ch + 1, m])
		prev = m
	prev = 0.0
	for st in 8:
		var c2 := base.duplicate()
		c2["stage"] = st
		var m2 := DamageScale.multiplier(c2)
		t.check(m2 > prev, "el dano sube con la etapa (etapa %d = %.2f)" % [st + 1, m2])
		prev = m2
	var e5 := base.duplicate()
	e5["stage"] = 4
	t.check(DamageScale.multiplier(e5) > DamageScale.multiplier(base), "enemigo de nivel 5 > nivel 1 en el mismo capitulo")
	var ch2 := base.duplicate()
	ch2["chapter_order"] = 1
	t.check(DamageScale.multiplier(ch2) > DamageScale.multiplier(base), "capitulo 2 > capitulo 1")
	# dificultades
	var lv := {}
	for d in DamageScale.ORDER:
		var c3 := base.duplicate()
		c3["difficulty"] = d
		c3["stage"] = 3
		lv[d] = DamageScale.multiplier(c3)
	t.check(lv["normal"] < lv["hard"] and lv["hard"] < lv["nightmare"], "dificultad: normal < dificil < pesadilla (%s)" % str(lv))
	t.check(DamageScale.difficulty("hard")["hp"] > DamageScale.difficulty("normal")["hp"], "dificil tiene mas vida enemiga")
	t.check(DamageScale.difficulty("nightmare")["elite"] > DamageScale.difficulty("hard")["elite"], "pesadilla trae mas elites")
	t.check(DamageScale.difficulty("nightmare")["reward"] > DamageScale.difficulty("hard")["reward"] and DamageScale.difficulty("hard")["reward"] > 1.0, "mas riesgo = mas recompensa")
	t.eq(DamageScale.difficulty("basura")["name"], "NORMAL", "dificultad invalida cae a normal")
	# jefe: recibe menos escalado que un enemigo normal
	var late := base.duplicate()
	late["chapter_order"] = 3
	late["stage"] = 7
	late["difficulty"] = "nightmare"
	var boss := late.duplicate()
	boss["boss"] = true
	t.check(DamageScale.multiplier(boss) < DamageScale.multiplier(late) and DamageScale.multiplier(boss) > 1.0, "el jefe escala menos que un enemigo (%.2f < %.2f)" % [DamageScale.multiplier(boss), DamageScale.multiplier(late)])
	# modos con oleadas: crecen pero con tope
	for mode in [ModeRules.SURVIVAL, ModeRules.HORDE]:
		var w1 := base.duplicate()
		w1["mode"] = mode
		var w50 := w1.duplicate()
		w50["wave"] = 50
		var w500 := w1.duplicate()
		w500["wave"] = 500
		t.check(DamageScale.multiplier(w50) > DamageScale.multiplier(w1), "%s: el dano crece con la oleada" % mode)
		t.eq(DamageScale.multiplier(w50), DamageScale.multiplier(w500), "%s: el escalado por oleada tiene tope" % mode)
	var worst := {"chapter_order": 3, "stage": 7, "mode": ModeRules.HORDE, "wave": 999, "difficulty": "nightmare", "mod_dmg": 5.0, "boss": false}
	t.check(DamageScale.multiplier(worst) <= DamageScale.MAX_MULT + 0.0001, "el multiplicador nunca supera MAX_MULT")
	# tope por golpe: el escalado nunca elimina de un golpe a quien no moriria con el dano base
	t.check(DamageScale.final_hit(1.0, 3.0, 6) <= 3.0, "un golpe de 1 escalado x3 no pasa de 3 (vida 6)")
	t.check(DamageScale.final_hit(2.0, 3.0, 6) <= 3.0 + 0.0001, "un golpe de 2 escalado x3 no pasa de 3 (vida 6)")
	t.eq(DamageScale.final_hit(2.0, 3.0, 2), 2.0, "personaje de 2 de vida: el escalado no agrega dano")
	t.eq(DamageScale.final_hit(1.0, 1.0, 6), 1.0, "x1 = dano base")
	t.eq(DamageScale.final_hit(0.0, 3.0, 6), 0.0, "dano 0 sigue en 0")
	# vida: composicion lineal, asignada
	t.check(absf(DamageScale.hp_multiplier(1.25, 1.0, "hard") - 1.25 * 1.2) < 0.0001, "vida = capitulo x modo x dificultad")
	t.check(DamageScale.hp_multiplier(1.0, 1.0, "normal", 1.35) > 1.34, "modificador de vida de expedicion")


## take_damage aplica el escalado UNA vez: (vida + escudo perdidos + fraccion) == final_hit esperado, en varios contextos.
func _integration(t) -> void:
	var g := _make_game(t, {"seed": "7", "idle": "1", "bot": "1"})
	for i in 20:
		await t.process_frame
	g.god = false
	var p := g.player
	g.input.auto_walk = null
	var cases := [
		["campaign ch1 normal", 0, 0, "normal", "", 1.0],
		["campaign ch1 etapa 6 normal", 0, 5, "normal", "", 1.0],
		["campaign ch4 etapa 8 pesadilla", 3, 7, "nightmare", "", 1.0],
		["jefe ch3 dificil", 2, 3, "hard", "boss", 2.0],
		["expedicion frenesi", 1, 2, "normal", "", 1.0],
	]
	for cs in cases:
		var ch: ChapterData = Catalog.chapter(Catalog.chapter_order[cs[1]])
		g.chapter = ch
		g.director.stage = cs[2]
		g.difficulty_id = cs[3]
		g.mods = {"enemy_dmg_mult": 1.15} if str(cs[0]).contains("frenesi") else {}
		p.hp = 6
		p.max_hp = 6
		p.shield = 0
		p.max_shield = 0
		p.frac_dmg = 0.0
		p.inv = 0.0
		var base: float = float(cs[5])
		var expected := DamageScale.final_hit(base, DamageScale.multiplier(DamageScale.context(g, cs[4] == "boss")), 6)
		p.take_damage(base, Vector2.RIGHT, 0.0, cs[4])
		var spent := float(6 - p.hp) + p.frac_dmg
		t.check(absf(spent - expected) < 0.001, "%s: dano aplicado %.3f == esperado %.3f (una sola vez)" % [cs[0], spent, expected])
		# segundo golpe inmediato: lo ignora la invulnerabilidad, no se vuelve a escalar
		var hp_now := p.hp
		var fr := p.frac_dmg
		p.take_damage(base, Vector2.RIGHT, 0.0, cs[4])
		t.check(p.hp == hp_now and p.frac_dmg == fr, "%s: el golpe durante la invulnerabilidad no cobra" % cs[0])
	# el escudo absorbe lo ya escalado (no se escala dos veces al pasar al escudo)
	g.chapter = Catalog.chapter("ch4")
	g.director.stage = 7
	g.difficulty_id = "nightmare"
	g.mods = {}
	p.hp = 6
	p.shield = 4
	p.max_shield = 4
	p.frac_dmg = 0.0
	p.inv = 0.0
	var exp2 := DamageScale.final_hit(1.0, DamageScale.multiplier(DamageScale.context(g, false)), 6)
	p.take_damage(1.0, Vector2.RIGHT, 0.0)
	var lost := float(4 - p.shield) + float(6 - p.hp) + p.frac_dmg
	t.check(absf(lost - exp2) < 0.001, "escudo + vida pierden exactamente el dano escalado (%.3f vs %.3f)" % [lost, exp2])
	# vida enemiga: hp_scale se ASIGNA (llamarlo dos veces no acumula)
	g.chapter = Catalog.chapter("ch2")
	g.difficulty_id = "hard"
	g.mods = {}
	g.recalc_hp_scale()
	var h1 := g.hp_scale
	g.recalc_hp_scale()
	t.eq(g.hp_scale, h1, "recalc_hp_scale es idempotente (no acumula)")
	t.check(absf(h1 - g.chapter.difficulty * 1.2) < 0.0001, "hp_scale = dificultad del capitulo x dificil")
	g.queue_free()
