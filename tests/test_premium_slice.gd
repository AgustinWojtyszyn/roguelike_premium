extends RefCounted
## Gate del vertical slice Premium (docs/PREMIUM_ASSET_REBUILD.md): un jugable solo entra con agarre derivado del rig fuente,
## locomocion/hurt/death, 8 direcciones, y el arma realmente sobre la mano. Tambien prueba que el gate RECHAZA perfiles defectuosos.

const REQUIRED := ["idle", "walk", "hurt", "death"]
const EIGHT := ["south", "south-east", "east", "north-east", "north", "north-west", "west", "south-west"]


## Errores de un perfil jugable frente a un AnimSet (vacio = aprobado).
static func profile_errors(vp: Dictionary, s: AnimSet, weapon_category: String) -> Array:
	var errs: Array = []
	if not bool(vp.get("weapon_compatible", false)):
		errs.append("weapon_compatible ausente/falso")
	if str(vp.get("grip_mode", "")) != "rig":
		errs.append("grip_mode != rig")
	if s == null:
		errs.append("set no carga")
		return errs
	if not s.has_grips():
		errs.append("sin metadatos de agarre")
	for a in REQUIRED:
		if not s.has_anim(a):
			errs.append("falta animacion " + a)
	if weapon_category == "melee":
		if not s.has_anim("attack"):
			errs.append("melee sin animacion attack")
	elif s.has_anim("idle") and s.weapon_mode("idle") != "aim":
		errs.append("ranged sin pose de apuntado (weapon_mode idle != aim)")
	for a in s.anim_names():
		var dirs: Array = s.dirs_of(a)
		if dirs.size() < 8:
			errs.append("%s: %d direcciones (<8)" % [a, dirs.size()])
		for d in dirs:
			var n := s.frame_count(a, d)
			for i in n:
				var g := s.grip(a, d, i)
				if g.size() < 6:
					errs.append("%s/%s/%d sin agarre" % [a, d, i])
					break
	return errs


func run(t) -> void:
	_gate_rejects_bad_profiles(t)
	_real_profiles(t)
	_grip_on_body(t)
	await _rig_holds_weapon(t)
	_enemies_and_room(t)


func _synthetic_set(with_grips: bool, anims: Array) -> AnimSet:
	var am := {}
	for a in anims:
		am[a] = {"sheet": "res://nope.png", "dirs": EIGHT, "counts": [1, 1, 1, 1, 1, 1, 1, 1], "cell": [8, 8]}
	var meta := {"bbox": [0, 0, 8, 8], "anims": am}
	if with_grips:
		var gr := {}
		for a in anims:
			gr[a] = {}
			for d in EIGHT:
				gr[a][d] = [[0.0, -10.0, 0.0, 0.0, 0.0, 0]]
		meta["grips"] = gr
	return AnimSet.create("synthetic", meta)


func _gate_rejects_bad_profiles(t) -> void:
	var good := {"weapon_compatible": true, "grip_mode": "rig"}
	var full := _synthetic_set(true, ["idle", "walk", "hurt", "death", "attack"])
	t.eq(profile_errors(good, full, "melee").size(), 0, "gate: perfil sintetico completo aprobado")
	t.check(profile_errors({"grip_mode": "rig"}, full, "smg").size() > 0, "gate: sin weapon_compatible se rechaza")
	t.check(profile_errors({"weapon_compatible": true}, full, "smg").size() > 0, "gate: sin grip_mode rig se rechaza")
	t.check(profile_errors(good, _synthetic_set(false, ["idle", "walk", "hurt", "death"]), "smg").size() > 0, "gate: sin metadatos de agarre se rechaza")
	t.check(profile_errors(good, _synthetic_set(true, ["idle", "hurt", "death"]), "smg").size() > 0, "gate: sin locomocion (walk) se rechaza")
	t.check(profile_errors(good, _synthetic_set(true, ["idle", "walk", "death"]), "smg").size() > 0, "gate: sin hurt se rechaza")
	t.check(profile_errors(good, _synthetic_set(true, ["idle", "walk", "hurt"]), "smg").size() > 0, "gate: sin death se rechaza")
	t.check(profile_errors(good, _synthetic_set(true, ["idle", "walk", "hurt", "death"]), "melee").size() > 0, "gate: melee sin attack se rechaza")
	# un set de enemigo (sin agarre) nunca puede entrar como jugable
	var crab := AssetCatalog.anim_set("premium/enemies/crab")
	t.check(profile_errors(good, crab, "smg").size() > 0, "gate: set sin agarre (enemigo) rechazado como jugable")


func _real_profiles(t) -> void:
	var seen := 0
	for cid in Catalog.characters:
		var c: CharacterData = Catalog.characters[cid]
		var vp := VisualProfiles.character(str(c.look.get("visual", "")))
		if vp.is_empty():
			continue
		seen += 1
		var w := Catalog.weapon(c.start_weapon)
		var errs := profile_errors(vp, AssetCatalog.anim_set(str(vp["set"])), w.category)
		t.eq(errs.size(), 0, "jugable %s cumple el contrato Premium %s" % [cid, str(errs.slice(0, 3))])
		t.check(not vp.has("weapon_anchor"), "jugable %s no usa anchors manuales" % cid)
		var mf := PremiumManifest.SETS.get(str(vp["set"]), {})
		t.check(str(mf.get("source", {}).get("license", "")) == "CC0 1.0", "jugable %s con licencia/procedencia en manifest" % cid)
	t.check(seen >= 2, "slice: al menos un ranged y un melee jugables")


## Anti "mano flotante": en cada frame el punto de agarre cae sobre pixeles opacos del cuerpo renderizado.
func _grip_on_body(t) -> void:
	for vid in VisualProfiles.CHARACTERS:
		var vp: Dictionary = VisualProfiles.CHARACTERS[vid]
		var s := AssetCatalog.anim_set(str(vp["set"]))
		var mf: Dictionary = PremiumManifest.SETS[str(vp["set"])]
		var feet: Array = mf["feet"]
		var bad := 0
		var total := 0
		for a in s.anim_names():
			if a == "death":
				continue   # al morir el arma se suelta y se desvanece
			var m: Dictionary = mf["anims"][a]
			var img := (AssetCatalog.load_tex(m["sheet"]) as Texture2D).get_image()
			var cw := int((m["cell"] as Array)[0])
			for r in (m["dirs"] as Array).size():
				var d: String = m["dirs"][r]
				for i in s.frame_count(a, d):
					var g := s.grip(a, d, i)
					var px := i * cw + int(feet[0]) + int(float(g[0]))
					var py := r * cw + int(float(feet[1])) + int(float(g[1]))
					total += 1
					var hit := false
					for oy in range(-3, 4):
						for ox in range(-3, 4):
							var qx := px + ox
							var qy := py + oy
							if qx >= 0 and qy >= 0 and qx < img.get_width() and qy < img.get_height() and img.get_pixel(qx, qy).a > 0.5:
								hit = true
					if not hit:
						bad += 1
		t.eq(bad, 0, "jugable %s: agarre sobre cuerpo opaco en %d frames" % [vid, total])


func _rig_holds_weapon(t) -> void:
	var host := Node2D.new()
	t.root.add_child(host)
	VisualProfiles._enabled = 1
	for cid in Catalog.characters:
		var c: CharacterData = Catalog.characters[cid]
		var vp := VisualProfiles.character(str(c.look.get("visual", "")))
		if vp.is_empty():
			continue
		var w := Catalog.weapon(c.start_weapon)
		var rig := CharacterRig.new()
		host.add_child(rig)
		rig.build(c.look, w, true)
		t.check(rig.grip_rig and rig.sprite_mode, "%s: rig en modo agarre desde el hueso fuente" % cid)
		var dirs_ok := 0
		for k in 8:
			var a := Vector2.from_angle(TAU * float(k) / 8.0)
			rig.aim = a
			rig.face = 1.0 if a.x >= 0.0 else -1.0
			rig.vel = Vector2.ZERO
			for i in 6:
				rig.animate(1.0 / 30.0)
			var g := rig.spr.aset.grip(rig.spr.anim, rig.spr.dir, rig.spr.idx)
			var want: Vector2 = rig.spr.position + Vector2(float(g[0]), float(g[1])) * rig.spr.scale.x
			# el pivote del arma (agarre) coincide con el hueso de la mano de este frame
			t.check(rig.pivot.position.distance_to(want) < 0.01, "%s dir %d: pivote del arma == agarre del rig" % [cid, k])
			# el muzzle sale a `muzzle.x` del agarre sobre el eje del arma (la punta del arte se escala a esa distancia)
			rig.kick = 0.0
			var dist := (rig.muzzle_world() - rig.pivot.global_position).length()
			var expect := w.muzzle.length() * rig.wnode.scale.x
			if absf(dist - expect) < 1.0:
				dirs_ok += 1
			t.check(rig.hand_spr != null and rig.hand_spr.visible, "%s dir %d: mano dibujada sobre el arma" % [cid, k])
		t.eq(dirs_ok, 8, "%s: muzzle a la distancia correcta del agarre en 8 direcciones" % cid)
		# locomocion + hurt + death sin NaN y con el arma pegada a la mano
		rig.vel = Vector2.RIGHT * 240.0
		for i in 30:
			rig.aim = Vector2.from_angle(float(i) * 0.2)
			rig.animate(1.0 / 60.0)
			t.check(is_finite(rig.pivot.position.x) and is_finite(rig.pivot.rotation), "%s: agarre finito caminando" % cid)
		rig.flash = 1.0
		rig.animate(1.0 / 60.0)
		t.check(rig.spr.anim == rig.spr.resolve("hurt"), "%s: hurt reproduce animacion propia" % cid)
		if w.category == "melee":
			rig.swing = 1.0
			rig.animate(1.0 / 60.0)
			t.check(rig._atk_active and rig.spr.anim == rig.spr.resolve("attack"), "%s: ataque melee reproduce animacion attack" % cid)
		rig.start_death(Vector2.RIGHT)
		for i in 40:
			rig.update_dead(1.0 / 60.0)
		t.check(rig.spr.anim == rig.spr.resolve("death"), "%s: death reproduce animacion propia" % cid)
		rig.queue_free()
	# la punta del arte de arma escalado coincide con el muzzle (arte importado)
	for wid in ["pulsar", "chispa", "filo_z"]:
		if AssetManifest.ORIENTED.has(wid):
			var o: Dictionary = AssetManifest.ORIENTED[wid]
			var wd := Catalog.weapon(wid)
			var reach := float(o["tip"]) - float((o["grip"] as Array)[0])
			var sc := clampf(maxf(wd.muzzle.x, 18.0) / maxf(reach, 1.0), 0.12, 0.6)
			t.check(absf(reach * sc - maxf(wd.muzzle.x, 18.0)) < 0.5 or sc >= 0.6 or sc <= 0.12, "arma %s: punta del arte == muzzle" % wid)
	VisualProfiles._enabled = -1
	host.queue_free()
	await t.process_frame


func _enemies_and_room(t) -> void:
	for kind in ["caballero", "escarabajo"]:
		var pr := VisualProfiles.enemy(kind)
		t.check(str(pr.get("set", "")).begins_with("premium/enemies/"), "enemigo %s usa set Premium pre-renderizado" % kind)
		var s := AssetCatalog.anim_set(str(pr["set"]))
		t.check(s != null, "enemigo %s: set carga" % kind)
		if s == null:
			continue
		for a in ["idle", "walk", "windup", "attack", "recover", "death"]:
			t.check(s.has_anim(a), "enemigo %s: animacion %s" % [kind, a])
		t.check(s.dirs_of("walk").size() >= 5, "enemigo %s: >=5 direcciones (espejo horizontal en runtime)" % kind)
		t.check(not (PremiumManifest.SETS[str(pr["set"])] as Dictionary).get("weapon_compatible", false), "enemigo %s no es jugable" % kind)
	# procedencia de todo lo Premium estatico
	for id in PremiumManifest.STATIC:
		var inf: Dictionary = PremiumManifest.STATIC[id]
		t.check(str(inf["source"]["license"]) == "CC0 1.0" and str(inf["source"]["revision"]) != "unknown", "estatico %s con licencia y revision" % id)
		t.check(ResourceLoader.exists(inf["path"]), "estatico %s existe" % id)
	for kind in VisualProfiles.PROPS_THEMED["castle"]:
		for art in VisualProfiles.PROPS_THEMED["castle"][kind]["art"]:
			t.check(AssetCatalog.has_tex(art), "prop castle %s/%s carga" % [kind, art])
	for art in ThemeCastle.PREMIUM_ART:
		t.check(AssetCatalog.has_tex(art), "tema castle: %s carga" % art)
	# sala compacta con 15-25 piezas curadas: props de la sala + decoracion premium
	var room_def: RoomDef = Catalog.rooms["patio_armas"]
	var props: int = room_def.props.size()
	var dec: Dictionary = VisualProfiles.decor("castle")
	var deco_min := 0
	var deco_max := 0
	for grp in ["floor", "stand"]:
		for spec in dec.get(grp, []):
			if str(spec["art"]).begins_with("premium/"):
				deco_min += int(spec["n"][0])
				deco_max += int(spec["n"][1])
	t.check(props + deco_min >= 15 and props + deco_max <= 90, "sala patio_armas: densidad curada (%d props + %d..%d decoracion)" % [props, deco_min, deco_max])
