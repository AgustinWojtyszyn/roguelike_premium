extends RefCounted
## Arte importado (assets/migrated): rutas, perfiles, frames, mapeos y, sobre todo, FALLBACKS (ningun asset puede romper una run).

func _frames(t, n: int) -> void:
	for i in n:
		await t.process_frame


func run(t) -> void:
	_manifest(t)
	_profiles(t)
	_static_art(t)
	_fallbacks(t)
	await _rig_modes(t)
	await _anchors(t)
	await _game_integration(t)


# ------------------------------------------------------------------ manifest y hojas
func _manifest(t) -> void:
	t.check(AssetManifest.ANIMS.size() >= 10, "manifest con al menos 10 sets animados (hay %d)" % AssetManifest.ANIMS.size())
	for id in AssetManifest.ANIMS:
		var s := AssetCatalog.anim_set(id)
		t.check(s != null, "set animado %s carga" % id)
		if s == null:
			continue
		var errs := s.validate()
		for e in errs:
			print("   ", e)
		t.eq(errs.size(), 0, "set %s: hojas validas" % id)
		for a in s.anim_names():
			for d in s.dirs_of(a):
				t.check(s.frame_count(a, d) > 0, "%s/%s/%s tiene frames" % [id, a, d])
				t.check(s.frames(a, d)[0] != null, "%s/%s/%s primer frame valido" % [id, a, d])
	for id in AssetManifest.STATIC:
		var info: Dictionary = AssetManifest.STATIC[id]
		t.check(ResourceLoader.exists(info["path"]), "estatico %s existe (%s)" % [id, info["path"]])
	for id in AssetManifest.ALIASES:
		t.check(AssetManifest.STATIC.has(AssetManifest.ALIASES[id]), "alias %s apunta a un estatico existente" % id)


# ------------------------------------------------------------------ perfiles
func _profiles(t) -> void:
	for cid in Catalog.characters:
		var lk: Dictionary = (Catalog.characters[cid] as CharacterData).look
		if lk.has("visual"):
			t.check(not VisualProfiles.character(str(lk["visual"])).is_empty(), "personaje %s: perfil visual '%s' existe" % [cid, lk["visual"]])
	for vid in VisualProfiles.CHARACTERS:
		var vp: Dictionary = VisualProfiles.CHARACTERS[vid]
		var s := AssetCatalog.anim_set(vp["set"])
		t.check(s != null, "perfil de personaje %s: set %s existe" % [vid, vp["set"]])
		if s == null:
			continue
		t.check(float(vp["height"]) > 20.0 and float(vp["height"]) < 120.0, "perfil %s: altura razonable" % vid)
		t.check(s.has_anim("walk"), "perfil %s: tiene walk" % vid)
		t.check(s.has_anim("idle") or vp.get("idle_from_walk", false), "perfil %s: idle o idle_from_walk" % vid)
		t.check(s.dirs_of("walk").size() >= 4, "perfil %s: walk con >= 4 direcciones" % vid)
		t.check(vp.has("weapon_anchor"), "perfil %s: ancla de arma" % vid)
		var holder := Node2D.new()
		var a := SpriteActor.create(holder, vp)
		t.check(a != null and a.texture != null, "perfil %s: SpriteActor crea con textura" % vid)
		if a != null:
			t.check(a.resolve("death") != "" and a.resolve("hurt") != "", "perfil %s: resuelve death y hurt (con fallback)" % vid)
		holder.free()
	var all := {}
	all.merge(VisualProfiles.ENEMIES)
	all.merge(VisualProfiles.BOSSES)
	for kind in all:
		var is_boss: bool = VisualProfiles.BOSSES.has(kind)
		t.check((is_boss and Catalog.bosses.has(_boss_id_for(kind))) or (not is_boss and Catalog.enemies.has(kind)), "perfil %s corresponde a un enemigo/jefe real" % kind)
		var pr: Dictionary = all[kind]
		var s2 := AssetCatalog.anim_set(pr["set"])
		t.check(s2 != null, "perfil de enemigo %s: set %s existe" % [kind, pr["set"]])
		if s2 == null:
			continue
		var holder2 := Node2D.new()
		var a2 := SpriteActor.create(holder2, pr)
		t.check(a2 != null, "perfil %s crea SpriteActor" % kind)
		if a2 != null:
			for ph in ["idle", "move", "windup", "strike", "recover", "death"]:
				t.check(a2.resolve(ph) != "", "perfil %s: la fase '%s' resuelve a una animacion real" % [kind, ph])
		holder2.free()
	for wid in AssetManifest.ORIENTED:
		var o: Dictionary = AssetManifest.ORIENTED[wid]
		t.check(Catalog.weapons.has(wid), "arte de arma %s corresponde a un arma Premium" % wid)
		t.check(AssetCatalog.load_tex(o["path"]) != null, "arte de arma %s carga" % wid)
		t.check(float(o["grip"][0]) < float(o["size"][0]) and float(o["grip"][1]) < float(o["size"][1]), "arma %s: agarre dentro de la imagen" % wid)
	t.check(AssetManifest.ORIENTED.size() >= 15, "al menos 15 armas con arte importado (hay %d)" % AssetManifest.ORIENTED.size())


func _boss_id_for(kind: String) -> String:
	for id in Catalog.bosses:
		var scr: GDScript = load((Catalog.bosses[id] as BossData).script_path)
		if scr != null and str(id) == kind:
			return str(id)
	return kind


# ------------------------------------------------------------------ props, cofres, decoracion, VFX
func _static_art(t) -> void:
	for kind in VisualProfiles.PROPS:
		t.check(PropArt.STATS.has(kind) or kind in ["tank", "terminal", "rack"], "prop %s es un kind real" % kind)
		for art in VisualProfiles.PROPS[kind]["art"]:
			t.check(AssetCatalog.has_tex(art), "prop %s: arte %s carga" % [kind, art])
	for theme in VisualProfiles.DECOR:
		var d: Dictionary = VisualProfiles.DECOR[theme]
		for grp in ["floor", "stand"]:
			for spec in d.get(grp, []):
				t.check(AssetCatalog.has_tex(spec["art"]), "decor %s/%s: %s carga" % [theme, grp, spec["art"]])
	for kind in Chest.ART:
		for variant in [Chest.ART[kind], Chest.ART_ANOMALY.get(kind, Chest.ART[kind])]:
			t.check(AssetCatalog.has_tex("rpg/chests/" + variant) and AssetCatalog.has_tex("rpg/chests/" + variant + "_open"), "cofre %s: %s cerrado/abierto" % [kind, variant])
	for v in Fx.USED_VFX:
		t.check(AssetCatalog.has_tex("rpg/vfx/" + v), "vfx %s carga" % v)
	for side in VisualProfiles.HOME_PROPS:
		for spec in VisualProfiles.HOME_PROPS[side]:
			t.check(AssetCatalog.has_tex(spec["art"]), "HOME prop %s carga" % spec["art"])
	for nid in VisualProfiles.NPCS:
		t.check(AssetCatalog.anim_set(VisualProfiles.NPCS[nid]["set"]) != null, "NPC %s: set existe" % nid)
		var s := AssetCatalog.anim_set(VisualProfiles.NPCS[nid]["set"])
		t.check(s.has_anim("walk") and s.has_anim("idle"), "NPC %s: walk e idle" % nid)


# ------------------------------------------------------------------ fallbacks
func _fallbacks(t) -> void:
	t.check(AssetCatalog.anim_set("no/existe") == null, "set inexistente -> null (sin crash)")
	t.check(AssetCatalog.tex("no/existe") == null, "textura inexistente -> null")
	t.check(AssetCatalog.load_tex("res://assets/migrated/no_existe.png") == null, "ruta rota -> null")
	var holder := Node2D.new()
	t.check(SpriteActor.create(holder, {"set": "no/existe", "height": 50.0}) == null, "SpriteActor con set roto -> null")
	t.check(SpriteActor.create(holder, {}) == null, "SpriteActor sin perfil -> null")
	holder.free()
	# direccion o animacion inexistente: nunca devuelve null donde hay arte
	var s := AssetCatalog.anim_set("rpg/characters/combat_android")
	t.check(s.frames("walk", "direccion-rara").size() > 0, "direccion inexistente cae a una disponible")
	t.eq(s.frames("animacion-rara", "south").size(), 0, "animacion inexistente -> lista vacia (el llamador usa fallback)")
	t.check(s.best_dir("walk", Vector2(1, 1)) in s.dirs_of("walk"), "diagonal en set de 4 direcciones se resuelve a una existente")
	t.check(s.best_dir("walk", Vector2.ZERO) in s.dirs_of("walk"), "vector cero no rompe la resolucion de direccion")
	# arma sin arte importado -> sigue habiendo dibujo procedural
	var w := WeaponData.new()
	w.id = "arma_sin_arte"
	t.check(not AssetManifest.ORIENTED.has(w.id), "arma desconocida no tiene arte importado (usa WeaponArt procedural)")


func _rig_modes(t) -> void:
	var host := Node2D.new()
	t.root.add_child(host)
	var wp := Catalog.weapon("pulsar")
	var modes := [true, false]
	for en in modes:
		VisualProfiles._enabled = 1 if en else 0
		for cid in Catalog.characters:
			var c: CharacterData = Catalog.characters[cid]
			var rig := CharacterRig.new()
			host.add_child(rig)
			rig.build(c.look, Catalog.weapon(c.start_weapon), true)
			var want_sprite: bool = en and not VisualProfiles.character(str(c.look.get("visual", ""))).is_empty()
			t.eq(rig.sprite_mode, want_sprite, "rig %s (sprites=%s): modo sprite esperado" % [cid, str(en)])
			t.check(rig.vis != null and rig.pivot != null and rig.wnode != null, "rig %s: nodos base presentes (nunca invisible)" % cid)
			# anima con movimiento / apuntado variados: sin errores y con muzzle finito
			for i in 90:
				rig.vel = Vector2.from_angle(float(i) * 0.3) * (0.0 if i % 20 < 5 else 240.0)
				rig.aim = Vector2.from_angle(float(i) * 0.21)
				rig.face = 1.0 if rig.aim.x >= 0.0 else -1.0
				rig.kick = 1.0 if i % 17 == 0 else rig.kick * 0.9
				if i == 40:
					rig.flash = 1.0
				rig.animate(1.0 / 60.0)
			var m := rig.muzzle_world()
			t.check(is_finite(m.x) and is_finite(m.y), "rig %s: muzzle_world finito" % cid)
			rig.set_weapon(wp)
			rig.animate(1.0 / 60.0)
			rig.start_death(Vector2.RIGHT)
			for i in 30:
				rig.update_dead(1.0 / 60.0)
			t.check(rig.vis.modulate.a > 0.0, "rig %s: tras morir sigue renderizando" % cid)
			rig.queue_free()
	VisualProfiles._enabled = -1
	host.queue_free()
	await _frames(t, 2)


# ------------------------------------------------------------------ integracion en una run real
func _game_integration(t) -> void:
	Profile.path = "user://test_profile_visual.json"
	Profile.reload()
	Boot.args = {"god": "1", "seed": "9", "idle": "1", "chapter": "ch3", "character": "vesper"}
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	await _frames(t, 20)
	g.director.entered = true
	g.director.in_combat = false
	var spawned: Array = []
	for kind in VisualProfiles.ENEMIES:
		var e := g.director.spawn_enemy_at(kind, Vector2(randf_range(-200, 200), randf_range(-120, 120)), false)
		t.check(e.spr != null and e.spr.texture != null, "enemigo %s: sprite activo con textura" % kind)
		t.check(e.vis.get_child_count() >= 1, "enemigo %s: tiene representacion" % kind)
		spawned.append(e)
	await _frames(t, 90)
	for e in spawned:
		t.check(is_instance_valid(e) and e.spr != null and e.spr.visible and e.spr.texture != null, "enemigo %s sigue visible tras 90 frames" % e.kind_name)
		t.check(e.spr.texture != null and e.vis.visible, "enemigo %s no queda invisible" % e.kind_name)
	# matar a todos: la animacion de muerte y la explosion no deben fallar
	for e in spawned:
		if is_instance_valid(e):
			e.hurt(9999.0, Vector2.RIGHT, 0.0, e.position, 0, true)
	await _frames(t, 60)
	# desactivar sprites (--no-sprites) no cambia la logica: el enemigo vuelve a su render procedural
	VisualProfiles._enabled = 0
	var e2 := g.director.spawn_enemy_at("caballero", Vector2(100, 0), false)
	t.check(e2.spr == null, "sin sprites el enemigo usa el render procedural")
	t.check(e2.vis.get_child_count() >= 3, "caballero procedural conserva sus partes")
	VisualProfiles._enabled = -1
	# cofres de cada tipo en cada tema: dibujan sin error
	for k in ["coin", "weapon", "perk", "rare"]:
		var ch := Chest.make(g, k, Vector2(0, 100))
		g.add_child(ch)
		await _frames(t, 2)
		ch.queue_free()
	# efecto de sprite del Fx
	var before := g.fx.ps.size()
	var pp := g.fx.sprite("combat/hit_spark", Vector2.ZERO, 10.0, 20.0, 0.1)
	t.check(pp != null and g.fx.ps.size() == before + 1, "Fx.sprite crea una particula del pool")
	await _frames(t, 20)
	t.check(g.fx.ps.size() <= Fx.MAX_P, "el pool de Fx sigue acotado")
	g.queue_free()
	await _frames(t, 2)


## El arma debe caer sobre la mano del sprite en cada direccion: ancla definida para las 8 direcciones, dentro de la silueta,
## y la punta visual (muzzle_world) coherente con el apuntado.
func _anchors(t) -> void:
	t.check(not VisualProfiles.HOME_LIFE_ENABLED, "HOME limpio: HomeLife desactivado")
	var host := Node2D.new()
	t.root.add_child(host)
	for vid in VisualProfiles.CHARACTERS:
		var vp: Dictionary = VisualProfiles.CHARACTERS[vid]
		var a: Dictionary = vp["weapon_anchor"]
		for d in AnimSet.DIR_VEC:
			t.check(a.has(d), "perfil %s: ancla de arma para %s" % [vid, d])
			var v: Vector2 = a.get(d, a["default"])
			t.check(absf(v.x) <= 20.0 and v.y < -20.0 and v.y > -45.0, "perfil %s/%s: ancla dentro de la silueta (%s)" % [vid, d, str(v)])
		var rig := CharacterRig.new()
		host.add_child(rig)
		var look := {"visual": vid}
		rig.build(look, Catalog.weapon("pulsar"), false)
		t.check(rig.sprite_mode, "rig %s en modo sprite" % vid)
		for d in AnimSet.DIR_VEC:
			var aim: Vector2 = AnimSet.DIR_VEC[d]
			rig.aim = aim
			rig.face = 1.0 if aim.x >= 0.0 else -1.0
			for i in 30:
				rig.animate(1.0 / 60.0)
			var m := rig.muzzle_world()
			var local := rig.to_local(m)
			var grip := rig.to_local(rig.pivot.global_position)
			t.check(local.distance_to(grip) > 8.0 and local.distance_to(grip) < 45.0, "rig %s/%s: la punta del arma esta cerca de la mano (%.1f px)" % [vid, d, local.distance_to(grip)])
			t.check((local - grip).normalized().dot(aim) > 0.98, "rig %s/%s: el muzzle sale en la direccion de apuntado" % [vid, d])
			t.check(grip.y < -20.0 and grip.y > -60.0, "rig %s/%s: empunadura a altura de torso (%.1f)" % [vid, d, grip.y])
		rig.queue_free()
	host.queue_free()
