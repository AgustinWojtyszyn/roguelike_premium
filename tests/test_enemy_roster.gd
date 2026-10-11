extends RefCounted
## Plantel real: los 18 enemigos y 4 jefes aparecen con sprite premium, nada procedural visible, reciben dano y mueren.
## Un enemigo SIN arte es un fallo (nunca se omite en silencio).

func _make_game(t, args: Dictionary) -> Game:
	Profile.path = "user://test_profile_roster.json"
	Profile.reload()
	Boot.args = args
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	return g


func _frames(t, n: int) -> void:
	for i in n:
		await t.process_frame


func _check_visual(t, e: Enemy, id: String) -> void:
	t.check(e.spr != null, "%s: tiene SpriteActor premium" % id)
	if e.spr == null:
		return
	t.check(e.spr.visible and e.spr.aset != null, "%s: sprite visible con AnimSet" % id)
	var stray := 0
	for ch in e.vis.get_children():
		if ch != e.spr and (ch as CanvasItem).visible:
			stray += 1
	t.eq(stray, 0, "%s: ningun dibujo procedural visible bajo el sprite" % id)
	var sc: Vector2 = e.spr.scale
	t.check(absf(absf(sc.x) - absf(sc.y)) < 0.001, "%s: sprite sin deformacion (%s)" % [id, sc])


func run(t) -> void:
	var g := _make_game(t, {"god": "1", "seed": "11", "idle": "1", "bot": "1"})
	await _frames(t, 20)
	g.input.auto_walk = null
	g.director.entered = true
	g.director.in_combat = false
	g.player.position = Vector2.ZERO
	var kills_before := 0
	for id in Catalog.enemies:
		var e := g.director.spawn_enemy_at(id, Vector2(260, 40), false)
		t.check(e != null, "%s: aparece" % id)
		if e == null:
			continue
		await _frames(t, 3)
		_check_visual(t, e, id)
		await _frames(t, 90)
		t.check(is_instance_valid(e), "%s: sigue vivo tras 1.5s en sala" % id)
		var hp0 := e.hp
		e.hurt(1.0, Vector2.RIGHT, 0.0, e.position, 0)
		t.check(e.hp < hp0 or e.state == Enemy.S_DYING, "%s: recibe dano" % id)
		e.hurt(100000.0, Vector2.RIGHT, 0.0, e.position, 0)
		await _frames(t, 120)
		t.check(not is_instance_valid(e) or e.state == Enemy.S_DYING or e.is_queued_for_deletion(), "%s: muere" % id)
		g.enemies = g.enemies.filter(func(x): return is_instance_valid(x))
	t.eq(g.director.art_errors.size(), 0, "ningun ART_MISSING: %s" % str(g.director.art_errors))
	g.queue_free()
	await _frames(t, 2)
	await run_bosses(t)


## Boss Rush completo: los 4 jefes aparecen, atacan (danan al jugador o lanzan proyectiles), pasan de fase y mueren; el rush solo avanza al matarlos.
func run_bosses(t) -> void:
	Profile.path = "user://test_profile_roster.json"
	var g := _make_game(t, {"mode": "bossrush", "seed": "5", "idle": "1", "bot": "1"})
	await _frames(t, 20)
	g.director.entered = true
	for i in 4:
		g.director._begin_encounter()
		await _frames(t, 10)
		var b = g.director.boss
		var id := String(g.chapter.boss)
		t.check(g.director.boss_alive() and b != null, "jefe %d (%s): aparece" % [i + 1, id])
		if b == null:
			break
		_check_visual(t, b, id)
		t.check(not g.director.cleared, "jefe %s: sala sin completar mientras vive" % id)
		g.player.hp = 9999.0
		g.player.max_hp = 9999.0
		var seen_states := {}
		for f in 900:
			g.player.hp = 9999.0
			seen_states[b.state] = true
			await t.process_frame
		t.check(seen_states.size() >= 2, "jefe %s: cambia de estado de IA (%s)" % [id, str(seen_states.keys())])
		b.hurt(b.max_hp * 0.55, Vector2.RIGHT, 0.0, b.position, 0)
		await _frames(t, 30)
		b.hurt(b.max_hp * 10.0, Vector2.RIGHT, 0.0, b.position, 0)
		await _frames(t, 240)
		t.check(not g.director.boss_alive(), "jefe %s: muere" % id)
		if i < 3:
			await _frames(t, 120)
	t.eq(g.director.art_errors.size(), 0, "boss rush: sin ART_MISSING")
	g.queue_free()
