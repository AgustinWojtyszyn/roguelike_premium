extends RefCounted
## Visual QA. Playables are sprite/pre-render only; enemies may retain their procedural safety fallback.

func _frames(t, n: int) -> void:
	for i in n:
		await t.process_frame

func run(t) -> void:
	_manifest(t)
	_playable_gate(t)
	_profiles(t)
	_static_art(t)
	_fallbacks(t)
	await _rig_modes(t)
	await _game_integration(t)

func _manifest(t) -> void:
	for id in AssetManifest.ANIMS:
		var s := AssetCatalog.anim_set(id)
		t.check(s != null, "set animado %s carga" % id)
		if s == null:
			continue
		var errs := s.validate()
		t.eq(errs.size(), 0, "set %s: hojas validas" % id)
	for id in AssetManifest.STATIC:
		var info: Dictionary = AssetManifest.STATIC[id]
		t.check(ResourceLoader.exists(info["path"]), "estatico %s existe" % id)

func _playable_gate(t) -> void:
	t.check(not ResourceLoader.exists("res://assets/migrated/rpg/characters/human_ranger/idle.png"), "legacy playable sheets fuera del runtime")
	var f := FileAccess.open("res://characters/character_rig.gd", FileAccess.READ)
	t.check(f != null, "CharacterRig legible")
	if f != null:
		var src := f.get_as_text()
		t.check(src.find("Gfx.gpoly") == -1, "CharacterRig sin cuerpos poligonales")
		t.check(src.find("_paint_torso") == -1, "CharacterRig sin torso procedural")
	for cid in Catalog.characters:
		var c: CharacterData = Catalog.characters[cid]
		var pr := VisualProfiles.character(str(c.look.get("visual", "")))
		if pr.is_empty():
			continue
		t.check(bool(pr.get("weapon_compatible", false)), "jugable %s marcado weapon_compatible" % cid)
		# contrato Premium: agarre generado desde el hueso del rig fuente (no anchors a mano); lo valida tests/test_premium_slice.gd
		t.check(pr.has("weapon_anchor") or str(pr.get("grip_mode", "")) == "rig", "jugable %s tiene agarre (rig fuente) o anchors" % cid)

func _profiles(t) -> void:
	for vid in VisualProfiles.CHARACTERS:
		var vp: Dictionary = VisualProfiles.CHARACTERS[vid]
		t.check(bool(vp.get("weapon_compatible", false)), "perfil %s aprobado para arma" % vid)
		var s := AssetCatalog.anim_set(vp.get("set", ""))
		t.check(s != null, "perfil %s: set existe" % vid)
		if s == null:
			continue
		t.check(s.has_anim("walk"), "perfil %s: walk" % vid)
		t.check(s.has_anim("idle") or vp.get("idle_from_walk", false), "perfil %s: idle" % vid)
		t.check(s.has_anim("hurt"), "perfil %s: hurt real" % vid)
		t.check(s.has_anim("death"), "perfil %s: death real" % vid)
		t.check(s.dirs_of("walk").size() >= 4, "perfil %s: >=4 direcciones" % vid)
		var holder := Node2D.new()
		var a := SpriteActor.create(holder, vp)
		t.check(a != null and a.texture != null, "perfil %s crea SpriteActor" % vid)
		holder.free()

	var all := {}
	all.merge(VisualProfiles.ENEMIES)
	all.merge(VisualProfiles.BOSSES)
	for kind in all:
		var pr: Dictionary = all[kind]
		var s2 := AssetCatalog.anim_set(pr["set"])
		t.check(s2 != null, "perfil enemigo %s: set existe" % kind)
		if s2 == null:
			continue
		var holder2 := Node2D.new()
		var a2 := SpriteActor.create(holder2, pr)
		t.check(a2 != null, "perfil enemigo %s crea SpriteActor" % kind)
		if a2 != null:
			for ph in ["idle", "move", "windup", "strike", "recover", "death"]:
				t.check(a2.resolve(ph) != "", "enemigo %s fase %s resuelve" % [kind, ph])
		holder2.free()

	for wid in AssetManifest.ORIENTED:
		var o: Dictionary = AssetManifest.ORIENTED[wid]
		t.check(Catalog.weapons.has(wid), "arte arma %s corresponde a arma real" % wid)
		t.check(AssetCatalog.load_tex(o["path"]) != null, "arte arma %s carga" % wid)

func _static_art(t) -> void:
	for kind in VisualProfiles.PROPS:
		for art in VisualProfiles.PROPS[kind]["art"]:
			t.check(AssetCatalog.has_tex(art), "prop %s/%s carga" % [kind, art])
	for theme in VisualProfiles.DECOR:
		for grp in ["floor", "stand"]:
			for spec in VisualProfiles.DECOR[theme].get(grp, []):
				t.check(AssetCatalog.has_tex(spec["art"]), "decor %s carga" % spec["art"])
	for v in Fx.USED_VFX:
		t.check(AssetCatalog.has_tex("rpg/vfx/" + v), "VFX %s carga" % v)

func _fallbacks(t) -> void:
	t.check(AssetCatalog.anim_set("no/existe") == null, "set inexistente -> null")
	var holder := Node2D.new()
	t.check(SpriteActor.create(holder, {"set": "no/existe", "height": 50.0}) == null, "SpriteActor roto -> null")
	holder.free()

func _rig_modes(t) -> void:
	var host := Node2D.new()
	t.root.add_child(host)
	VisualProfiles._enabled = 1
	for cid in Catalog.characters:
		var c: CharacterData = Catalog.characters[cid]
		var rig := CharacterRig.new()
		host.add_child(rig)
		rig.build(c.look, Catalog.weapon(c.start_weapon), true)
		var pr := VisualProfiles.character(str(c.look.get("visual", "")))
		if pr.is_empty():
			t.check(rig.is_placeholder and not rig.sprite_mode, "jugable %s pendiente usa placeholder, no poligonos" % cid)
		else:
			t.check(rig.sprite_mode and not rig.is_placeholder, "jugable %s usa sprite Premium" % cid)
		t.check(rig.vis != null and rig.pivot != null and rig.wnode != null, "rig %s conserva API base" % cid)
		for i in 60:
			rig.vel = Vector2.from_angle(float(i) * 0.21) * (220.0 if i % 12 > 3 else 0.0)
			rig.aim = Vector2.from_angle(float(i) * 0.17)
			rig.face = 1.0 if rig.aim.x >= 0 else -1.0
			rig.animate(1.0 / 60.0)
		var m := rig.muzzle_world()
		t.check(is_finite(m.x) and is_finite(m.y), "rig %s muzzle finito" % cid)
		rig.start_death(Vector2.RIGHT)
		for i in 20:
			rig.update_dead(1.0 / 60.0)
		rig.queue_free()
	VisualProfiles._enabled = 0
	var c0: CharacterData = Catalog.characters[Catalog.char_order[0]]
	var r0 := CharacterRig.new()
	host.add_child(r0)
	r0.build(c0.look, Catalog.weapon(c0.start_weapon), false)
	t.check(r0.is_placeholder, "--no-sprites en jugador cae a placeholder, nunca a poligonos")
	r0.queue_free()
	VisualProfiles._enabled = -1
	host.queue_free()
	await _frames(t, 2)

func _game_integration(t) -> void:
	Profile.path = "user://test_profile_visual.json"
	Profile.reload()
	Boot.args = {"god": "1", "seed": "9", "idle": "1", "chapter": "ch3", "character": "vesper"}
	Router.params = {}
	var g: Game = (load("res://scenes/run.tscn") as PackedScene).instantiate()
	t.root.add_child(g)
	await _frames(t, 20)
	t.check(g.player != null and g.player.rig != null, "run real crea jugador")
	t.check(g.player.rig.is_placeholder or g.player.rig.sprite_mode, "jugador renderiza sprite/placeholder, no procedural")
	g.director.entered = true
	g.director.in_combat = false
	var spawned: Array = []
	for kind in VisualProfiles.ENEMIES:
		var e := g.director.spawn_enemy_at(kind, Vector2(randf_range(-200, 200), randf_range(-120, 120)), false)
		t.check(e.spr != null and e.spr.texture != null, "enemigo %s sprite activo" % kind)
		spawned.append(e)
	await _frames(t, 30)
	for e in spawned:
		if is_instance_valid(e):
			e.hurt(9999.0, Vector2.RIGHT, 0.0, e.position, 0, true)
	await _frames(t, 30)
	# Enemigos conservan fallback procedural como red de seguridad; la prohibicion de poligonos aplica al jugador.
	VisualProfiles._enabled = 0
	var e2 := g.director.spawn_enemy_at("caballero", Vector2(100, 0), false)
	t.check(e2.spr == null, "enemigo sin sprites conserva fallback logico")
	VisualProfiles._enabled = -1
	g.queue_free()
	await _frames(t, 2)
